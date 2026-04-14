class AppConstants {
  static const String weatherApiBaseUrl = 'https://api.open-meteo.com/v1';
  static const String geocodingApiUrl =
      'https://geocoding-api.open-meteo.com/v1';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration searchTimeout = Duration(seconds: 10);

  static const int searchResultCount = 10;
  static const Duration searchDebounce = Duration(milliseconds: 500);

  static const int hourlyForecastCount = 8;
  static const int dailyForecastCount = 7;

  static const String defaultCity = '北京';
  static const double defaultLatitude = 39.9042;
  static const double defaultLongitude = 116.4074;
}

class ErrorMessages {
  static const String networkError = '网络连接失败，请检查网络设置';
  static const String locationPermissionDenied = '定位权限被拒绝';
  static const String locationPermissionPermanentlyDenied =
      '定位权限被永久拒绝，请前往系统设置开启';
  static const String locationServiceDisabled = '定位服务未启用';
  static const String unknownError = '未知错误';
  static const String noData = '暂无数据';
  static const String searchNoResult = '未找到相关城市';
  static const String loadWeatherFailed = '获取天气数据失败';
}

enum WeatherBackgroundType {
  clearDay,
  clearNight,
  cloudy,
  rainy,
  snowy,
  foggy,
  thunderstorm,
  unknown,
}
