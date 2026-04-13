/// 天气 Provider
/// 状态管理: 使用 ChangeNotifier 管理天气数据、加载状态、搜索状态等

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart' show ChangeNotifier;
import '../models/weather_model.dart';
import '../models/city_search_result.dart';
import '../services/weather_api_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

/// 天气数据 Provider
///
/// 职责:
/// - 管理天气数据状态
/// - 管理定位与城市切换
/// - 管理搜索建议与防抖
/// - 统一异常处理
class WeatherProvider extends ChangeNotifier {
  // ==================== 服务实例 ====================

  /// 天气 API 服务
  final WeatherApiService _weatherApiService = WeatherApiService();

  // ==================== 公开状态字段 ====================

  /// 当前天气数据
  WeatherData? _weatherData;

  /// 是否正在加载中(首次加载)
  bool _isLoading = false;

  /// 是否正在刷新中(下拉刷新)
  bool _isRefreshing = false;

  /// 错误信息
  String? _errorMessage;

  /// 城市搜索结果列表
  List<CitySearchResult> _searchResults = [];

  /// 是否正在搜索中
  bool _isSearching = false;

  /// 当前搜索查询词
  String _currentQuery = '';

  /// 当前位置名称
  String? _currentLocationName;

  /// 是否使用当前位置(与城市模式区分)
  bool _isUsingCurrentLocation = false;

  /// 最后更新时间
  DateTime? _lastUpdated;

  // ==================== 私有状态字段 ====================

  /// 搜索防抖定时器
  Timer? _searchDebounceTimer;

  /// 上次搜索的城市名
  String? _lastSearchedCity;

  /// 上次获取的纬度
  double? _lastLatitude;

  /// 上次获取的经度
  double? _lastLongitude;

  /// 天气请求序列号，用于避免旧数据回写
  int _weatherRequestId = 0;

  /// 搜索请求序列号，用于避免旧结果覆盖
  int _searchRequestId = 0;

  // ==================== Getters ====================

  /// 天气数据
  WeatherData? get weatherData => _weatherData;

  /// 是否加载中
  bool get isLoading => _isLoading;

  /// 是否刷新中
  bool get isRefreshing => _isRefreshing;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 搜索结果列表
  List<CitySearchResult> get searchResults => _searchResults;

  /// 是否搜索中
  bool get isSearching => _isSearching;

  /// 当前搜索查询词
  String get currentQuery => _currentQuery;

  /// 当前位置名称
  String? get currentLocationName => _currentLocationName;

  /// 是否使用当前位置
  bool get isUsingCurrentLocation => _isUsingCurrentLocation;

  /// 最后更新时间
  DateTime? get lastUpdated => _lastUpdated;

  /// 是否有数据
  bool get hasData => _weatherData != null;

  /// 是否有错误
  bool get hasError => _errorMessage != null;

  // ==================== 私有辅助方法 ====================

  /// 加载默认城市(北京)
  ///
  /// 用于 Web 平台或定位失败时的降级方案
  Future<void> _loadDefaultCity({bool showLoading = true}) async {
    debugPrint('WeatherProvider: 加载默认城市 - 北京');

    final requestId = ++_weatherRequestId;

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final weatherData = await _weatherApiService.getWeatherByLocation(
        AppConstants.defaultLatitude,
        AppConstants.defaultLongitude,
        locationName: AppConstants.defaultCity,
      );

      debugPrint('WeatherProvider: 默认城市加载成功 - ${AppConstants.defaultCity}');
      _updateWeather(weatherData, isUsingLocation: false);
      _lastSearchedCity = AppConstants.defaultCity;

      // 异步加载空气质量
      _loadAirQualityByCoordinates(
        AppConstants.defaultLatitude,
        AppConstants.defaultLongitude,
        requestId: requestId,
      );
    } catch (e) {
      debugPrint('WeatherProvider: 加载默认城市失败 - $e');
      _errorMessage = _mapErrorToMessage(e);
      notifyListeners();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      debugPrint(
          'WeatherProvider: 加载完成 - hasData: $hasData, hasError: $hasError');
      notifyListeners();
    }
  }

  /// 通过经纬度加载空气质量数据
  ///
  /// 异步执行,不影响主流程
  Future<void> _loadAirQualityByCoordinates(double latitude, double longitude,
      {int? requestId}) async {
    try {
      debugPrint('WeatherProvider: 开始加载空气质量 - lat:$latitude, lon:$longitude');
      final airQuality = await _weatherApiService.getAirQualityByLocation(
        latitude,
        longitude,
      );

      debugPrint('WeatherProvider: 空气质量加载成功 - AQI: ${airQuality.aqiValue}');

      // 检查请求是否过期，并且坐标是否匹配当前天气数据
      if (requestId != null && requestId != _weatherRequestId) {
        debugPrint('WeatherProvider: 空气质量请求已过期，丢弃结果');
        return;
      }

      // 更新 weatherData 中的空气质量字段
      if (_weatherData != null) {
        _weatherData = _weatherData!.copyWith(airQuality: airQuality);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WeatherProvider: 空气质量加载失败 - $e');
      // 不影响主流程,静默失败
    }
  }

  /// 通过城市名加载空气质量数据
  ///
  /// 先搜索城市获取经纬度,再请求空气质量
  Future<void> _loadAirQualityByCity(String cityName, {int? requestId}) async {
    try {
      debugPrint('WeatherProvider: 开始加载城市空气质量 - $cityName');
      final searchResults = await _weatherApiService.searchCity(cityName);

      if (searchResults.isEmpty) {
        debugPrint('WeatherProvider: 城市搜索无结果,跳过空气质量加载');
        return;
      }

      final city = searchResults.first;
      await _loadAirQualityByCoordinates(
        city.latitude,
        city.longitude,
        requestId: requestId,
      );
    } catch (e) {
      debugPrint('WeatherProvider: 城市空气质量加载失败 - $e');
      // 不影响主流程
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置刷新状态
  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  /// 设置搜索状态
  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 更新天气数据
  void _updateWeather(WeatherData data, {bool isUsingLocation = false}) {
    _weatherData = data;
    _isUsingCurrentLocation = isUsingLocation;
    _errorMessage = null;
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  /// 将底层异常映射为用户可读的错误信息
  String _mapErrorToMessage(Object error) {
    debugPrint('WeatherProvider: 捕获异常 - ${error.runtimeType}: $error');

    if (error is LocationServiceDisabledException) {
      return '定位服务未启用,请在设置中开启定位服务';
    }

    if (error is LocationPermissionPermanentlyDeniedException) {
      return '定位权限被永久拒绝,请在系统设置中手动开启此应用的定位权限';
    }

    if (error is LocationPermissionDeniedException) {
      return '定位权限被拒绝,请允许定位权限以获取当前位置';
    }

    if (error is LocationServiceException) {
      return error.message;
    }

    if (error is CityNotFoundException) {
      return '未找到城市: ${error.keyword}';
    }

    if (error is InvalidResponseException) {
      return '数据格式错误,请稍后重试';
    }

    if (error is WeatherApiException) {
      // 检查是否是网络或超时相关
      final message = error.message.toLowerCase();
      if (message.contains('socket') ||
          message.contains('network') ||
          message.contains('connection')) {
        return '网络连接失败,请检查网络设置';
      }
      if (message.contains('timeout')) {
        return '请求超时,请稍后重试';
      }
      return error.message;
    }

    // 未知异常
    return '加载失败: $error';
  }

  // ==================== 公开方法 ====================

  /// 初始化方法(兼容旧版 main.dart 调用)
  ///
  /// 首次进入自动加载当前位置天气
  Future<void> init() async {
    debugPrint('WeatherProvider: 初始化,开始加载天气数据...');
    await loadCurrentLocationWeather();
  }

  /// 加载当前位置天气
  ///
  /// 流程:
  /// 1. Web 平台跳过定位,直接加载默认城市(北京)
  /// 2. 请求定位权限
  /// 3. 获取当前位置
  /// 4. 调用 API 获取天气
  /// 5. 更新状态
  ///
  /// 失败时:
  /// - 不清空旧数据
  /// - 写入 errorMessage
  /// - 记录 isUsingCurrentLocation
  Future<void> loadCurrentLocationWeather({bool showLoading = true}) async {
    debugPrint('WeatherProvider: 开始加载当前位置天气...');

    // Web 平台不支持定位,自动加载默认城市
    if (kIsWeb) {
      debugPrint('WeatherProvider: Web 平台,自动加载默认城市');
      await _loadDefaultCity(showLoading: showLoading);
      return;
    }

    final requestId = ++_weatherRequestId;

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      // 1. 获取当前位置
      debugPrint('WeatherProvider: 正在获取定位...');
      final position = await LocationService.getCurrentPosition();
      debugPrint(
          'WeatherProvider: 获取定位成功 - lat:${position.latitude}, lon:${position.longitude}');

      // 2. 记录经纬度
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;
      _currentLocationName = '当前位置';
      _isUsingCurrentLocation = true;

      // 3. 调用 API 获取天气
      final weatherData = await _weatherApiService.getWeatherByLocation(
        position.latitude,
        position.longitude,
        locationName: _currentLocationName,
      );

      debugPrint('WeatherProvider: 获取天气成功 - ${weatherData.location}');

      // 4. 先更新天气，再异步加载 AQI，避免竞态导致 AQI 丢失
      _updateWeather(weatherData, isUsingLocation: true);

      // 5. 异步加载空气质量 (不阻塞主流程)
      _loadAirQualityByCoordinates(
        position.latitude,
        position.longitude,
        requestId: requestId,
      );
    } catch (e) {
      debugPrint('WeatherProvider: 获取定位天气失败 - $e');
      _errorMessage = _mapErrorToMessage(e);
      // 不清空旧数据,保留已有天气信息
      notifyListeners();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      debugPrint(
          'WeatherProvider: 加载完成 - hasData: ${hasData}, hasError: ${hasError}');
      notifyListeners();
    }
  }

  /// 通过城市名加载天气
  ///
  /// [city] 城市名称
  ///
  /// 流程:
  /// 1. 校验城市名非空
  /// 2. 调用 API 获取城市天气
  /// 3. 更新状态
  /// 4. 记录搜索历史
  /// 5. 设置 isUsingCurrentLocation = false
  ///
  /// 失败时:
  /// - 不清空旧数据
  /// - 写入 errorMessage
  Future<void> loadWeatherByCity(String city, {bool showLoading = true}) async {
    debugPrint('WeatherProvider: 开始加载城市天气 - $city');

    // 1. 校验参数
    if (city.trim().isEmpty) {
      _errorMessage = '城市名称不能为空';
      notifyListeners();
      return;
    }

    final requestId = ++_weatherRequestId;

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      // 2. 调用 API
      final weatherData =
          await _weatherApiService.getWeatherByCity(city.trim());

      debugPrint('WeatherProvider: 获取城市天气成功 - ${weatherData.location}');

      // 3. 更新状态
      _weatherData = weatherData;
      _currentLocationName = weatherData.location;
      _lastSearchedCity = city.trim();
      _isUsingCurrentLocation = false;
      _lastUpdated = DateTime.now();
      _errorMessage = null;

      notifyListeners();

      // 4. 异步加载空气质量 (不阻塞主流程)
      // 需要先获取城市经纬度,这里简化处理
      _loadAirQualityByCity(city.trim(), requestId: requestId);
    } catch (e) {
      debugPrint('WeatherProvider: 获取城市天气失败 - $e');
      _errorMessage = _mapErrorToMessage(e);
      // 不清空旧数据
      notifyListeners();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      debugPrint(
          'WeatherProvider: 加载完成 - hasData: ${hasData}, hasError: ${hasError}');
      notifyListeners();
    }
  }

  /// 刷新天气
  ///
  /// 根据当前数据来源模式刷新:
  /// - 定位模式: 重新获取当前位置天气
  /// - 城市模式: 重新获取当前搜索城市天气
  ///
  /// 刷新使用 isRefreshing 标记,不影响 isLoading
  /// 刷新失败时不清空旧数据
  Future<void> refreshWeather() async {
    debugPrint('WeatherProvider: 开始刷新天气...');

    // 防止并发刷新
    if (_isRefreshing || _isLoading) {
      debugPrint('WeatherProvider: 正在加载/刷新中,跳过刷新');
      return;
    }

    _setRefreshing(true);

    try {
      // 根据当前模式刷新
      if (_isUsingCurrentLocation && !kIsWeb) {
        // 定位模式: 重新获取定位
        debugPrint('WeatherProvider: 刷新模式 - 重新定位');
        await loadCurrentLocationWeather(showLoading: false);
      } else if (_lastSearchedCity != null) {
        // 城市模式: 重新加载城市
        debugPrint('WeatherProvider: 刷新模式 - 重新加载城市 $_lastSearchedCity');
        await loadWeatherByCity(_lastSearchedCity!, showLoading: false);
      } else {
        // 没有上下文,默认刷新定位
        debugPrint('WeatherProvider: 刷新模式 - 无上下文,默认刷新定位');
        await loadCurrentLocationWeather(showLoading: false);
      }
    } catch (e) {
      debugPrint('WeatherProvider: 刷新失败 - $e');
      _errorMessage = _mapErrorToMessage(e);
      // 不清空旧数据
      notifyListeners();
    } finally {
      _isRefreshing = false;
      debugPrint('WeatherProvider: 刷新完成');
      notifyListeners();
    }
  }

  /// 搜索城市(立即搜索)
  ///
  /// [keyword] 搜索关键词
  ///
  /// 功能:
  /// - 调用 API 搜索城市
  /// - 更新 searchResults
  /// - 不影响当前 weatherData
  ///
  /// 注意: 此方法不带防抖,防抖请使用 debounceSearch
  Future<void> searchCity(String keyword) async {
    debugPrint('WeatherProvider: 搜索城市 - $keyword');
    final requestId = ++_searchRequestId;

    // 清空旧结果
    _searchResults = [];

    if (keyword.trim().isEmpty) {
      _currentQuery = '';
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _currentQuery = keyword;
    notifyListeners();

    try {
      final results = await _weatherApiService.searchCity(keyword.trim());
      if (requestId != _searchRequestId || keyword != _currentQuery) {
        return;
      }
      _searchResults = results;
      debugPrint('WeatherProvider: 搜索成功,找到 ${results.length} 个结果');
    } catch (e) {
      debugPrint('WeatherProvider: 搜索失败 - $e');
      if (requestId == _searchRequestId) {
        _searchResults = [];
      }
      // 搜索失败不设置 errorMessage,不影响当前天气显示
    } finally {
      if (requestId == _searchRequestId) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  /// 带防抖的搜索
  ///
  /// [keyword] 搜索关键词
  /// 防抖时间: 500ms
  ///
  /// 用于 UI 输入框联动:
  /// - 每次调用取消旧定时器
  /// - 500ms 后执行实际搜索
  void debounceSearch(String keyword) {
    _currentQuery = keyword;

    // 取消旧定时器
    _searchDebounceTimer?.cancel();

    if (keyword.trim().isEmpty) {
      _searchRequestId++;
      _searchResults = [];
      _isSearching = false;
      _currentQuery = '';
      notifyListeners();
      return;
    }

    // 设置新定时器
    _searchDebounceTimer = Timer(AppConstants.searchDebounce, () {
      searchCity(keyword);
    });
  }

  /// 选择搜索结果
  ///
  /// [city] 选中的城市
  ///
  /// 功能:
  /// - 调用 API 获取该城市天气
  /// - 更新 weatherData
  /// - 切换为城市模式
  /// - 清空搜索结果列表
  Future<void> selectCity(CitySearchResult city) async {
    debugPrint('WeatherProvider: 选择城市 - ${city.displayName}');
    final requestId = ++_weatherRequestId;

    _isLoading = true;
    _errorMessage = null;
    _searchResults = [];
    notifyListeners();

    try {
      final weatherData = await _weatherApiService.getWeatherByLocation(
        city.latitude,
        city.longitude,
        locationName: city.displayName,
      );

      _weatherData = weatherData;
      _currentLocationName = city.displayName;
      _lastSearchedCity = city.name;
      _isUsingCurrentLocation = false;
      _lastUpdated = DateTime.now();
      _errorMessage = null;

      debugPrint('WeatherProvider: 城市选择成功 - ${weatherData.location}');
      _loadAirQualityByCoordinates(
        city.latitude,
        city.longitude,
        requestId: requestId,
      );
    } catch (e) {
      debugPrint('WeatherProvider: 城市选择失败 - $e');
      _errorMessage = _mapErrorToMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清空搜索结果
  ///
  /// 不影响当前天气数据
  void clearSearchResults() {
    debugPrint('WeatherProvider: 清空搜索结果');
    _searchDebounceTimer?.cancel();
    _searchRequestId++;
    _searchResults = [];
    _isSearching = false;
    _currentQuery = '';
    notifyListeners();
  }

  /// 清空错误
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 释放资源
  @override
  void dispose() {
    debugPrint('WeatherProvider: 释放资源');
    _searchDebounceTimer?.cancel();
    _weatherApiService.dispose();
    super.dispose();
  }
}
