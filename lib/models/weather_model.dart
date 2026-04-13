/// 天气数据模型
/// 基于 Open-Meteo API 返回结构映射

import '../utils/weather_utils.dart';
import '../utils/constants.dart';
import 'air_quality_model.dart';

/// 天气数据模型 - 包含当前天气和预报数据
class WeatherData {
  /// 位置名称
  final String location;

  /// 当前温度 (°C)
  final double temperature;

  /// 体感温度 (°C)
  final double feelsLike;

  /// 天气状况中文描述
  final String condition;

  /// WMO 天气代码
  final int conditionCode;

  /// 相对湿度 (%)
  final int humidity;

  /// 气压 (hPa)
  final int pressure;

  /// 能见度 (米)
  final double visibility;

  /// 紫外线指数
  final int uvIndex;

  /// 风速 (km/h)
  final double windSpeed;

  /// 日出时间 (格式化后的字符串)
  final String sunrise;

  /// 日落时间 (格式化后的字符串)
  final String sunset;

  /// 是否为白天
  final bool isDayTime;

  /// 当日最高温 (°C)
  final double highTemp;

  /// 当日最低温 (°C)
  final double lowTemp;

  /// 逐小时预报列表
  final List<HourlyForecast> hourlyForecast;

  /// 逐日预报列表
  final List<DailyForecast> dailyForecast;

  /// 空气质量数据 (可选)
  final AirQualityData? airQuality;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.conditionCode,
    required this.humidity,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    required this.isDayTime,
    required this.highTemp,
    required this.lowTemp,
    required this.hourlyForecast,
    required this.dailyForecast,
    this.airQuality,
  });

  /// 从 Open-Meteo API 返回的 JSON 解析
  ///
  /// [json] Open-Meteo Forecast API 响应数据
  /// [locationName] 位置名称(优先使用传入值)
  factory WeatherData.fromJson(Map<String, dynamic> json, String locationName) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};
    final daily = json['daily'] as Map<String, dynamic>? ?? {};

    // 解析当前天气数据
    final temperature = (current['temperature_2m'] ?? 0).toDouble();
    final feelsLike = (current['apparent_temperature'] ?? 0).toDouble();
    final conditionCode = (current['weather_code'] ?? 0).toInt();
    final humidity = (current['relative_humidity_2m'] ?? 0).toInt();
    final pressure = (current['surface_pressure'] ?? 0).toInt();
    final windSpeed = (current['wind_speed_10m'] ?? 0).toDouble();
    final isDayTime = (current['is_day'] ?? 1).toInt() == 1;

    // 解析逐小时预报
    final hourlyForecasts = _parseHourlyForecast(hourly);

    // 解析逐日预报
    final dailyForecasts = _parseDailyForecast(daily);

    // 解析能见度 (取当前小时对应值)
    final visibility = _parseVisibility(
        hourly, hourlyForecasts.isNotEmpty ? hourlyForecasts[0].time : null);

    // 解析 UV 指数 (取第一天)
    final uvIndexRaw =
        (daily['uv_index_max'] as List<dynamic>?)?.isNotEmpty == true
            ? (daily['uv_index_max'] as List<dynamic>)[0]
            : 0;
    final uvIndex = uvIndexRaw.toDouble().toInt();

    // 解析日出日落时间
    final sunrise = _parseSunrise(daily);
    final sunset = _parseSunset(daily);

    // 解析当日高低温
    final highTemp =
        (daily['temperature_2m_max'] as List<dynamic>?)?.isNotEmpty == true
            ? (daily['temperature_2m_max'] as List<dynamic>)[0].toDouble()
            : temperature;
    final lowTemp =
        (daily['temperature_2m_min'] as List<dynamic>?)?.isNotEmpty == true
            ? (daily['temperature_2m_min'] as List<dynamic>)[0].toDouble()
            : temperature;

    return WeatherData(
      location: locationName.isNotEmpty ? locationName : 'Unknown Location',
      temperature: temperature,
      feelsLike: feelsLike,
      condition: WeatherUtils.getWeatherConditionText(conditionCode),
      conditionCode: conditionCode,
      humidity: humidity,
      pressure: pressure,
      visibility: visibility,
      uvIndex: uvIndex,
      windSpeed: windSpeed,
      sunrise: sunrise,
      sunset: sunset,
      isDayTime: isDayTime,
      highTemp: highTemp,
      lowTemp: lowTemp,
      hourlyForecast: hourlyForecasts,
      dailyForecast: dailyForecasts,
    );
  }

  /// 解析逐小时预报
  static List<HourlyForecast> _parseHourlyForecast(
      Map<String, dynamic> hourly) {
    final times = (hourly['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final temps =
        (hourly['temperature_2m'] as List<dynamic>?)?.cast<num>() ?? [];
    final codes = (hourly['weather_code'] as List<dynamic>?)?.cast<num>() ?? [];

    if (times.isEmpty || temps.isEmpty || codes.isEmpty) {
      return [];
    }

    // 找到当前小时索引
    final currentIndex = _findCurrentHourIndex(times);

    // 取未来 N 小时 (根据配置)
    final forecasts = <HourlyForecast>[];
    final count = AppConstants.hourlyForecastCount;
    for (int i = currentIndex;
        i < currentIndex + count && i < times.length;
        i++) {
      forecasts.add(HourlyForecast(
        time: WeatherUtils.formatHourLabel(times[i],
            currentIndex: i == currentIndex),
        temperature: temps[i].toDouble(),
        conditionCode: codes[i].toInt(),
      ));
    }

    return forecasts;
  }

  /// 解析逐日预报
  static List<DailyForecast> _parseDailyForecast(Map<String, dynamic> daily) {
    final times = (daily['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final maxTemps =
        (daily['temperature_2m_max'] as List<dynamic>?)?.cast<num>() ?? [];
    final minTemps =
        (daily['temperature_2m_min'] as List<dynamic>?)?.cast<num>() ?? [];
    final codes = (daily['weather_code'] as List<dynamic>?)?.cast<num>() ?? [];
    final precipProbs =
        (daily['precipitation_probability_max'] as List<dynamic>?)
                ?.cast<num>() ??
            [];

    if (times.isEmpty) {
      return [];
    }

    // 取未来 N 天 (根据配置)
    final count = times.length > AppConstants.dailyForecastCount
        ? AppConstants.dailyForecastCount
        : times.length;
    final forecasts = <DailyForecast>[];
    for (int i = 0; i < count; i++) {
      forecasts.add(DailyForecast(
        date: WeatherUtils.formatDailyLabel(times[i], index: i),
        highTemp: maxTemps.isNotEmpty && i < maxTemps.length
            ? maxTemps[i].toDouble()
            : 0,
        lowTemp: minTemps.isNotEmpty && i < minTemps.length
            ? minTemps[i].toDouble()
            : 0,
        conditionCode:
            codes.isNotEmpty && i < codes.length ? codes[i].toInt() : 0,
        precipitationChance: precipProbs.isNotEmpty && i < precipProbs.length
            ? precipProbs[i].toInt()
            : 0,
      ));
    }

    return forecasts;
  }

  /// 查找当前小时索引
  static int _findCurrentHourIndex(List<String> times) {
    final now = DateTime.now();
    for (int i = 0; i < times.length; i++) {
      try {
        final time = DateTime.parse(times[i]);
        if (time.isAfter(now) || time.isAtSameMomentAs(now)) {
          return i;
        }
      } catch (e) {
        continue;
      }
    }
    return 0;
  }

  /// 解析能见度
  static double _parseVisibility(
      Map<String, dynamic> hourly, String? currentTime) {
    final visibilities =
        (hourly['visibility'] as List<dynamic>?)?.cast<num>() ?? [];
    if (visibilities.isEmpty) {
      return 0;
    }

    // 如果有当前小时索引,使用对应值
    if (currentTime != null) {
      final times = (hourly['time'] as List<dynamic>?)?.cast<String>() ?? [];
      final index = times.indexOf(currentTime);
      if (index >= 0 && index < visibilities.length) {
        return visibilities[index].toDouble();
      }
    }

    // 降级: 使用第一个值
    return visibilities[0].toDouble();
  }

  /// 解析日出时间
  static String _parseSunrise(Map<String, dynamic> daily) {
    final sunrises = (daily['sunrise'] as List<dynamic>?)?.cast<String>() ?? [];
    if (sunrises.isEmpty) {
      return '--:--';
    }
    return WeatherUtils.formatTimeToHHmm(sunrises[0]);
  }

  /// 解析日落时间
  static String _parseSunset(Map<String, dynamic> daily) {
    final sunsets = (daily['sunset'] as List<dynamic>?)?.cast<String>() ?? [];
    if (sunsets.isEmpty) {
      return '--:--';
    }
    return WeatherUtils.formatTimeToHHmm(sunsets[0]);
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'condition': condition,
      'conditionCode': conditionCode,
      'humidity': humidity,
      'pressure': pressure,
      'visibility': visibility,
      'uvIndex': uvIndex,
      'windSpeed': windSpeed,
      'sunrise': sunrise,
      'sunset': sunset,
      'isDayTime': isDayTime,
      'highTemp': highTemp,
      'lowTemp': lowTemp,
      'hourlyForecast': hourlyForecast.map((e) => e.toJson()).toList(),
      'dailyForecast': dailyForecast.map((e) => e.toJson()).toList(),
    };
  }

  /// 复制并修改
  WeatherData copyWith({
    String? location,
    double? temperature,
    double? feelsLike,
    String? condition,
    int? conditionCode,
    int? humidity,
    int? pressure,
    double? visibility,
    int? uvIndex,
    double? windSpeed,
    String? sunrise,
    String? sunset,
    bool? isDayTime,
    double? highTemp,
    double? lowTemp,
    List<HourlyForecast>? hourlyForecast,
    List<DailyForecast>? dailyForecast,
    AirQualityData? airQuality,
  }) {
    return WeatherData(
      location: location ?? this.location,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      condition: condition ?? this.condition,
      conditionCode: conditionCode ?? this.conditionCode,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      visibility: visibility ?? this.visibility,
      uvIndex: uvIndex ?? this.uvIndex,
      windSpeed: windSpeed ?? this.windSpeed,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      isDayTime: isDayTime ?? this.isDayTime,
      highTemp: highTemp ?? this.highTemp,
      lowTemp: lowTemp ?? this.lowTemp,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      dailyForecast: dailyForecast ?? this.dailyForecast,
      airQuality: airQuality ?? this.airQuality,
    );
  }
}

/// 逐小时预报
class HourlyForecast {
  /// 时间标签 (例如 "Now", "13:00")
  final String time;

  /// 温度 (°C)
  final double temperature;

  /// WMO 天气代码
  final int conditionCode;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.conditionCode,
  });

  /// 从 JSON 解析
  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: json['time'] as String? ?? '',
      temperature: (json['temperature'] ?? 0).toDouble(),
      conditionCode: (json['conditionCode'] ?? 0).toInt(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature': temperature,
      'conditionCode': conditionCode,
    };
  }

  /// 复制并修改
  HourlyForecast copyWith({
    String? time,
    double? temperature,
    int? conditionCode,
  }) {
    return HourlyForecast(
      time: time ?? this.time,
      temperature: temperature ?? this.temperature,
      conditionCode: conditionCode ?? this.conditionCode,
    );
  }
}

/// 逐日预报
class DailyForecast {
  /// 日期标签 (例如 "今天", "周一")
  final String date;

  /// 最高温度 (°C)
  final double highTemp;

  /// 最低温度 (°C)
  final double lowTemp;

  /// WMO 天气代码
  final int conditionCode;

  /// 降水概率 (%)
  final int precipitationChance;

  DailyForecast({
    required this.date,
    required this.highTemp,
    required this.lowTemp,
    required this.conditionCode,
    required this.precipitationChance,
  });

  /// 从 JSON 解析
  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: json['date'] as String? ?? '',
      highTemp: (json['highTemp'] ?? 0).toDouble(),
      lowTemp: (json['lowTemp'] ?? 0).toDouble(),
      conditionCode: (json['conditionCode'] ?? 0).toInt(),
      precipitationChance: (json['precipitationChance'] ?? 0).toInt(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'highTemp': highTemp,
      'lowTemp': lowTemp,
      'conditionCode': conditionCode,
      'precipitationChance': precipitationChance,
    };
  }

  /// 复制并修改
  DailyForecast copyWith({
    String? date,
    double? highTemp,
    double? lowTemp,
    int? conditionCode,
    int? precipitationChance,
  }) {
    return DailyForecast(
      date: date ?? this.date,
      highTemp: highTemp ?? this.highTemp,
      lowTemp: lowTemp ?? this.lowTemp,
      conditionCode: conditionCode ?? this.conditionCode,
      precipitationChance: precipitationChance ?? this.precipitationChance,
    );
  }
}
