library weather_hub_provider;

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart' show ChangeNotifier;

import '../models/city_search_result.dart';
import '../models/saved_city_weather.dart';
import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../services/weather_api_service.dart';
import '../utils/constants.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherApiService _weatherApiService = WeatherApiService();

  WeatherData? _currentLocationWeather;
  final List<SavedCityWeather> _savedCities = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  List<CitySearchResult> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';
  String? _currentLocationName;
  DateTime? _lastUpdated;
  String? _expandedCityId;

  Timer? _searchDebounceTimer;
  int _searchRequestId = 0;

  WeatherData? get weatherData =>
      _currentLocationWeather ??
      expandedCity?.weatherData ??
      (_savedCities.isNotEmpty ? _savedCities.first.weatherData : null);

  WeatherData? get currentLocationWeather => _currentLocationWeather;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  List<CitySearchResult> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;
  String? get currentLocationName => _currentLocationName;
  bool get isUsingCurrentLocation => _currentLocationWeather != null;
  DateTime? get lastUpdated => _lastUpdated;
  bool get hasData =>
      _currentLocationWeather != null || _savedCities.isNotEmpty;
  bool get hasError => _errorMessage != null;
  List<SavedCityWeather> get savedCities => List.unmodifiable(_savedCities);
  String? get expandedCityId => _expandedCityId;

  SavedCityWeather? get expandedCity {
    if (_expandedCityId == null) {
      return null;
    }

    for (final city in _savedCities) {
      if (city.id == _expandedCityId) {
        return city;
      }
    }

    return null;
  }

  Future<WeatherData> _fetchWeatherBundle({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    final weatherData = await _weatherApiService.getWeatherByLocation(
      latitude,
      longitude,
      locationName: locationName,
    );

    try {
      final airQuality = await _weatherApiService.getAirQualityByLocation(
        latitude,
        longitude,
      );
      return weatherData.copyWith(airQuality: airQuality);
    } catch (error) {
      debugPrint('WeatherProvider: failed to load air quality - $error');
      return weatherData;
    }
  }

  void _upsertSavedCity(SavedCityWeather cityWeather) {
    final existingIndex =
        _savedCities.indexWhere((item) => item.id == cityWeather.id);

    if (existingIndex >= 0) {
      _savedCities.removeAt(existingIndex);
    }

    _savedCities.insert(0, cityWeather);
    _expandedCityId = cityWeather.id;
  }

  String _mapErrorToMessage(Object error) {
    debugPrint('WeatherProvider: caught error - ${error.runtimeType}: $error');

    if (error is LocationServiceDisabledException) {
      return '定位服务未开启，请先开启系统定位服务。';
    }

    if (error is LocationPermissionPermanentlyDeniedException) {
      return '定位权限被永久拒绝，请到系统设置里手动开启权限。';
    }

    if (error is LocationPermissionDeniedException) {
      return '没有定位权限，无法获取你当前所在城市。';
    }

    if (error is LocationServiceException) {
      return error.message;
    }

    if (error is CityNotFoundException) {
      return '没有找到与“${error.keyword}”匹配的城市。';
    }

    if (error is InvalidResponseException) {
      return '天气数据格式异常，请稍后再试。';
    }

    if (error is WeatherApiException) {
      final message = error.message.toLowerCase();
      if (message.contains('socket') ||
          message.contains('network') ||
          message.contains('connection')) {
        return '网络连接失败，请检查当前网络状态。';
      }
      if (message.contains('timeout')) {
        return '请求超时了，请稍后重新刷新。';
      }
      return error.message;
    }

    return '加载失败：$error';
  }

  Future<void> _loadDefaultCity({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final weatherData = await _fetchWeatherBundle(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        locationName: AppConstants.defaultCity,
      );

      _currentLocationWeather = weatherData;
      _currentLocationName = AppConstants.defaultCity;
      _lastUpdated = DateTime.now();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> init() async {
    await loadCurrentLocationWeather();
  }

  Future<void> loadCurrentLocationWeather({bool showLoading = true}) async {
    if (kIsWeb) {
      await _loadDefaultCity(showLoading: showLoading);
      return;
    }

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final position = await LocationService.getCurrentPosition();
      final weatherData = await _fetchWeatherBundle(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: '我的位置',
      );

      _currentLocationWeather = weatherData;
      _currentLocationName = weatherData.location;
      _lastUpdated = DateTime.now();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadWeatherByCity(String city, {bool showLoading = true}) async {
    if (city.trim().isEmpty) {
      _errorMessage = '城市名称不能为空。';
      notifyListeners();
      return;
    }

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final results = await _weatherApiService.searchCity(city.trim());
      if (results.isEmpty) {
        throw CityNotFoundException(city.trim());
      }

      final cityResult = results.first;
      final weatherData = await _fetchWeatherBundle(
        latitude: cityResult.latitude,
        longitude: cityResult.longitude,
        locationName: cityResult.displayName,
      );

      _upsertSavedCity(
        SavedCityWeather(
          city: cityResult,
          weatherData: weatherData,
          updatedAt: DateTime.now(),
        ),
      );
      _lastUpdated = DateTime.now();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> addCity(
    CitySearchResult city, {
    bool showLoading = true,
  }) async {
    final isNewCity =
        !_savedCities.any((item) => item.id == SavedCityWeather.buildId(city));

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final weatherData = await _fetchWeatherBundle(
        latitude: city.latitude,
        longitude: city.longitude,
        locationName: city.displayName,
      );

      _upsertSavedCity(
        SavedCityWeather(
          city: city,
          weatherData: weatherData,
          updatedAt: DateTime.now(),
        ),
      );
      _searchResults = [];
      _currentQuery = '';
      _lastUpdated = DateTime.now();
      return isNewCity;
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
      return false;
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> selectCity(CitySearchResult city) {
    return addCity(city);
  }

  void toggleCityExpanded(String cityId) {
    _expandedCityId = _expandedCityId == cityId ? null : cityId;
    notifyListeners();
  }

  Future<void> refreshWeather() async {
    if (_isRefreshing || _isLoading) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await loadCurrentLocationWeather(showLoading: false);

      if (_savedCities.isNotEmpty) {
        final refreshedCities = <SavedCityWeather>[];
        for (final cityWeather in _savedCities) {
          try {
            final weatherData = await _fetchWeatherBundle(
              latitude: cityWeather.city.latitude,
              longitude: cityWeather.city.longitude,
              locationName: cityWeather.displayName,
            );

            refreshedCities.add(
              cityWeather.copyWith(
                weatherData: weatherData,
                updatedAt: DateTime.now(),
              ),
            );
          } catch (error) {
            debugPrint('WeatherProvider: failed to refresh city - $error');
            refreshedCities.add(cityWeather);
          }
        }

        _savedCities
          ..clear()
          ..addAll(refreshedCities);
      }

      _lastUpdated = DateTime.now();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> searchCity(String keyword) async {
    final requestId = ++_searchRequestId;
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
    } catch (_) {
      if (requestId == _searchRequestId) {
        _searchResults = [];
      }
    } finally {
      if (requestId == _searchRequestId) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void debounceSearch(String keyword) {
    _currentQuery = keyword;
    _searchDebounceTimer?.cancel();

    if (keyword.trim().isEmpty) {
      _searchRequestId++;
      _searchResults = [];
      _isSearching = false;
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _searchDebounceTimer = Timer(
      AppConstants.searchDebounce,
      () => searchCity(keyword),
    );
  }

  void clearSearchResults() {
    _searchDebounceTimer?.cancel();
    _searchRequestId++;
    _searchResults = [];
    _isSearching = false;
    _currentQuery = '';
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _weatherApiService.dispose();
    super.dispose();
  }
}
