/// 天气 API 服务
/// 封装 Open-Meteo API 调用逻辑

library weather_api_service;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/city_search_result.dart';
import '../models/air_quality_model.dart';
import '../utils/constants.dart';

/// 天气 API 异常基类
class WeatherApiException implements Exception {
  /// 异常消息
  final String message;

  WeatherApiException(this.message);

  @override
  String toString() => 'WeatherApiException: $message';
}

/// 城市未找到异常
class CityNotFoundException extends WeatherApiException {
  /// 搜索关键词
  final String keyword;

  CityNotFoundException(this.keyword) : super('未找到城市: $keyword');
}

/// 无效响应异常
class InvalidResponseException extends WeatherApiException {
  InvalidResponseException(super.message);
}

/// 天气 API 服务类
///
/// 封装 Open-Meteo 地理编码和天气预报 API 调用
class WeatherApiService {
  /// HTTP 客户端 (支持依赖注入)
  final http.Client client;

  /// 请求超时时间
  final Duration timeout;

  /// 地理编码 API 基础 URL
  static const String _geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1';

  /// 天气预报 API 基础 URL
  static const String _weatherBaseUrl = 'https://api.open-meteo.com/v1';

  /// 构造函数
  ///
  /// [client] HTTP 客户端,默认为 http.Client()
  /// [timeout] 请求超时时间,默认为 15 秒
  WeatherApiService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : client = client ?? http.Client();

  /// 搜索城市
  ///
  /// 使用 Open-Meteo Geocoding API 搜索城市并返回匹配结果列表
  ///
  /// [keyword] 搜索关键词(城市名称)
  /// 返回匹配的城市列表,最多返回 10 条结果
  ///
  /// 抛出异常:
  /// - WeatherApiException: 关键词为空或请求失败
  /// - InvalidResponseException: 响应数据格式错误
  Future<List<CitySearchResult>> searchCity(String keyword) async {
    // 参数校验
    if (keyword.trim().isEmpty) {
      throw WeatherApiException('搜索关键词不能为空');
    }

    try {
      // 构建请求 URI
      final uri = _buildGeocodingUri(keyword.trim());

      // 发送 HTTP GET 请求
      final response = await client.get(uri).timeout(timeout);

      // 检查 HTTP 状态码
      if (response.statusCode != 200) {
        throw WeatherApiException(
          '搜索城市失败: HTTP ${response.statusCode}',
        );
      }

      // 解析 JSON 响应
      final Map<String, dynamic> data = _decodeJson(response.body);

      // 检查是否有 results 字段
      if (!data.containsKey('results') || data['results'] == null) {
        throw InvalidResponseException('响应数据缺少 results 字段');
      }

      final resultsList = data['results'] as List<dynamic>;

      // 检查是否为空结果
      if (resultsList.isEmpty) {
        throw CityNotFoundException(keyword.trim());
      }

      // 解析为 CitySearchResult 列表
      return resultsList
          .map(
              (json) => CitySearchResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } on WeatherApiException {
      rethrow;
    } on FormatException catch (e) {
      throw InvalidResponseException('JSON 解析失败: ${e.message}');
    } catch (e) {
      throw WeatherApiException('搜索城市时发生错误: $e');
    }
  }

  /// 通过城市名称获取天气
  ///
  /// 内部流程:
  /// 1. 调用 searchCity() 搜索城市
  /// 2. 取第一个匹配结果
  /// 3. 使用其经纬度调用 getWeatherByLocation()
  ///
  /// [cityName] 城市名称
  /// 返回该城市的天气数据
  ///
  /// 抛出异常:
  /// - CityNotFoundException: 城市未找到
  /// - WeatherApiException: 请求失败
  Future<WeatherData> getWeatherByCity(String cityName) async {
    // 参数校验
    if (cityName.trim().isEmpty) {
      throw WeatherApiException('城市名称不能为空');
    }

    try {
      // 先搜索城市获取经纬度
      final searchResults = await searchCity(cityName);

      if (searchResults.isEmpty) {
        throw CityNotFoundException(cityName.trim());
      }

      // 取第一个最匹配的结果
      final city = searchResults.first;

      // 构建位置名称 (城市名 + 行政区 + 国家)
      final locationName = city.displayName;

      // 使用经纬度获取天气
      return await getWeatherByLocation(
        city.latitude,
        city.longitude,
        locationName: locationName,
      );
    } on WeatherApiException {
      rethrow;
    } catch (e) {
      throw WeatherApiException('获取城市天气失败: $e');
    }
  }

  /// 通过经纬度获取天气
  ///
  /// 使用 Open-Meteo Forecast API 获取指定位置的天气数据
  ///
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [locationName] 位置名称(可选,用于显示)
  /// 返回完整的天气数据(含当前天气、逐小时预报、逐日预报)
  ///
  /// 抛出异常:
  /// - WeatherApiException: 请求失败或数据无效
  /// - InvalidResponseException: 响应数据格式错误
  Future<WeatherData> getWeatherByLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    try {
      // 构建请求 URI
      final uri = _buildForecastUri(latitude, longitude);

      // 发送 HTTP GET 请求
      final response = await client.get(uri).timeout(timeout);

      // 检查 HTTP 状态码
      if (response.statusCode != 200) {
        throw WeatherApiException(
          '获取天气数据失败: HTTP ${response.statusCode}',
        );
      }

      // 解析 JSON 响应
      final Map<String, dynamic> data = _decodeJson(response.body);

      // 验证必需字段
      _validateWeatherResponse(data);

      // 解析为 WeatherData 模型
      final weatherData = WeatherData.fromJson(
        data,
        locationName ?? 'Unknown Location',
      );

      return weatherData;
    } on WeatherApiException {
      rethrow;
    } on FormatException catch (e) {
      throw InvalidResponseException('JSON 解析失败: ${e.message}');
    } catch (e) {
      throw WeatherApiException('获取天气数据时发生错误: $e');
    }
  }

  /// 构建地理编码请求 URI
  ///
  /// [keyword] 搜索关键词
  /// 返回完整的 URI 对象
  Uri _buildGeocodingUri(String keyword) {
    return Uri.parse('$_geocodingBaseUrl/search').replace(
      queryParameters: {
        'name': keyword,
        'count': AppConstants.searchResultCount.toString(),
        'language': 'zh',
        'format': 'json',
      },
    );
  }

  /// 构建天气预报请求 URI
  ///
  /// [latitude] 纬度
  /// [longitude] 经度
  /// 返回完整的 URI 对象
  Uri _buildForecastUri(double latitude, double longitude) {
    return Uri.parse('$_weatherBaseUrl/forecast').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,surface_pressure,wind_speed_10m',
        'hourly':
            'temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,precipitation_probability,visibility,wind_speed_10m',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_speed_10m_max',
        'timezone': 'auto',
      },
    );
  }

  /// 解析 JSON 字符串
  ///
  /// [body] JSON 字符串
  /// 返回解析后的 Map
  Map<String, dynamic> _decodeJson(String body) {
    try {
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw InvalidResponseException('响应数据格式错误: 期望 Map 类型');
      }
      return data;
    } catch (e) {
      if (e is InvalidResponseException) {
        rethrow;
      }
      throw InvalidResponseException('JSON 解析失败: $e');
    }
  }

  /// 验证天气响应数据
  ///
  /// [data] API 响应数据
  /// 如果数据无效则抛出异常
  void _validateWeatherResponse(Map<String, dynamic> data) {
    // 检查必须有 top-level 字段
    if (!data.containsKey('current')) {
      throw InvalidResponseException('响应数据缺少 current 字段');
    }
    if (!data.containsKey('hourly')) {
      throw InvalidResponseException('响应数据缺少 hourly 字段');
    }
    if (!data.containsKey('daily')) {
      throw InvalidResponseException('响应数据缺少 daily 字段');
    }

    final current = data['current'] as Map<String, dynamic>?;
    final hourly = data['hourly'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;

    // 检查 current 关键字段
    if (current == null || !current.containsKey('temperature_2m')) {
      throw InvalidResponseException('当前天气数据缺少 temperature_2m 字段');
    }

    // 检查 hourly 数组
    if (hourly == null) {
      throw InvalidResponseException('逐小时预报数据为空');
    }

    final hourlyTimes = hourly['time'] as List<dynamic>?;
    if (hourlyTimes == null || hourlyTimes.isEmpty) {
      throw InvalidResponseException('逐小时预报时间列表为空');
    }

    // 检查 daily 数组
    if (daily == null) {
      throw InvalidResponseException('逐日预报数据为空');
    }

    final dailyTimes = daily['time'] as List<dynamic>?;
    if (dailyTimes == null || dailyTimes.isEmpty) {
      throw InvalidResponseException('逐日预报时间列表为空');
    }
  }

  /// 释放资源
  void dispose() {
    client.close();
  }

  // ==================== 空气质量 API ====================

  /// 空气质量 API 基础 URL
  static const String _airQualityBaseUrl =
      'https://air-quality-api.open-meteo.com/v1';

  /// 通过经纬度获取空气质量数据
  ///
  /// [latitude] 纬度
  /// [longitude] 经度
  /// 返回空气质量数据
  ///
  /// 抛出异常:
  /// - WeatherApiException: 请求失败或数据无效
  /// - InvalidResponseException: 响应数据格式错误
  Future<AirQualityData> getAirQualityByLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      // 构建请求 URI
      final uri = _buildAirQualityUri(latitude, longitude);

      // 发送 HTTP GET 请求
      final response = await client.get(uri).timeout(timeout);

      // 检查 HTTP 状态码
      if (response.statusCode != 200) {
        throw WeatherApiException(
          '获取空气质量数据失败: HTTP ${response.statusCode}',
        );
      }

      // 解析 JSON 响应
      final Map<String, dynamic> data = _decodeJson(response.body);

      // 验证必需字段
      if (!data.containsKey('current')) {
        throw InvalidResponseException('响应数据缺少 current 字段');
      }

      // 解析为 AirQualityData 模型
      return AirQualityData.fromJson(data);
    } on WeatherApiException {
      rethrow;
    } on FormatException catch (e) {
      throw InvalidResponseException('JSON 解析失败: ${e.message}');
    } catch (e) {
      throw WeatherApiException('获取空气质量数据时发生错误: $e');
    }
  }

  /// 构建空气质量请求 URI
  Uri _buildAirQualityUri(double latitude, double longitude) {
    return Uri.parse('$_airQualityBaseUrl/air-quality').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'us_aqi,european_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,uv_index',
        'timezone': 'auto',
      },
    );
  }
}
