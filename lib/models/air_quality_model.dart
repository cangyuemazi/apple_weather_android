/// 空气质量数据模型
/// 基于 Open-Meteo Air Quality API 返回结构映射

/// 空气质量数据
library air_quality_model;

class AirQualityData {
  /// AQI 数值
  final int aqiValue;

  /// AQI 标准 ("US" 或 "EU")
  final String aqiStandard;

  /// AQI 等级文案
  final String aqiLevelText;

  /// 主污染物
  final String? primaryPollutant;

  /// PM2.5 (μg/m³)
  final double pm25;

  /// PM10 (μg/m³)
  final double pm10;

  /// NO2 (μg/m³)
  final double no2;

  /// O3 (μg/m³)
  final double o3;

  /// SO2 (μg/m³)
  final double so2;

  /// CO (μg/m³)
  final double co;

  /// UV 指数
  final int uvIndex;

  /// 最后更新时间
  final DateTime? lastUpdated;

  AirQualityData({
    required this.aqiValue,
    required this.aqiStandard,
    required this.aqiLevelText,
    this.primaryPollutant,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.co,
    required this.uvIndex,
    this.lastUpdated,
  });

  /// 从 Open-Meteo Air Quality API 返回的 JSON 解析
  ///
  /// [json] Air Quality API 响应数据
  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};

    // 解析各污染物浓度
    final pm25 = (current['pm2_5'] ?? 0).toDouble();
    final pm10 = (current['pm10'] ?? 0).toDouble();
    final no2 = (current['nitrogen_dioxide'] ?? 0).toDouble();
    final o3 = (current['ozone'] ?? 0).toDouble();
    final so2 = (current['sulphur_dioxide'] ?? 0).toDouble();
    final co = (current['carbon_monoxide'] ?? 0).toDouble();

    // 解析 UV 指数
    final uvIndex = (current['uv_index'] ?? 0).toDouble().toInt();

    // 解析 AQI - 优先使用 US AQI,降级到 EU AQI
    int aqiValue;
    String aqiStandard;

    final usAqi = current['us_aqi'];
    final euAqi = current['european_aqi'];

    if (usAqi != null && usAqi >= 0) {
      aqiValue = usAqi.toDouble().toInt();
      aqiStandard = 'US';
    } else if (euAqi != null && euAqi >= 0) {
      aqiValue = euAqi.toDouble().toInt();
      aqiStandard = 'EU';
    } else {
      // 都缺失,默认 0
      aqiValue = 0;
      aqiStandard = 'US';
    }

    return AirQualityData(
      aqiValue: aqiValue,
      aqiStandard: aqiStandard,
      aqiLevelText: _getAqiLevelText(aqiValue, aqiStandard),
      primaryPollutant: _resolvePrimaryPollutant(pm25, pm10, no2, o3, so2, co),
      pm25: pm25,
      pm10: pm10,
      no2: no2,
      o3: o3,
      so2: so2,
      co: co,
      uvIndex: uvIndex,
      lastUpdated: DateTime.now(),
    );
  }

  /// 获取 AQI 等级文案
  static String _getAqiLevelText(int value, String standard) {
    if (standard == 'EU') {
      return _getEuAqiLevel(value);
    }
    return _getUsAqiLevel(value);
  }

  /// US AQI 等级映射
  static String _getUsAqiLevel(int value) {
    if (value <= 50) return '良';
    if (value <= 100) return '中等';
    if (value <= 150) return '对敏感人群不健康';
    if (value <= 200) return '不健康';
    if (value <= 300) return '非常不健康';
    return '危险';
  }

  /// European AQI 等级映射
  static String _getEuAqiLevel(int value) {
    if (value <= 20) return '良';
    if (value <= 40) return '一般';
    if (value <= 60) return '中等';
    if (value <= 80) return '较差';
    if (value <= 100) return '很差';
    return '极差';
  }

  /// 解析主污染物
  ///
  /// 使用相对风险优先策略:
  /// PM2.5 > PM10 > O3 > NO2 > SO2 > CO
  static String? _resolvePrimaryPollutant(
    double pm25,
    double pm10,
    double no2,
    double o3,
    double so2,
    double co,
  ) {
    // 简单策略: 找浓度最高的污染物
    final pollutants = {
      'PM2.5': pm25,
      'PM10': pm10,
      'O3': o3,
      'NO2': no2,
      'SO2': so2,
      'CO': co / 1000, // CO 单位不同,换算后比较
    };

    String? primary;
    double maxConcentration = -1;

    for (final entry in pollutants.entries) {
      if (entry.value > maxConcentration) {
        maxConcentration = entry.value;
        primary = entry.key;
      }
    }

    return primary;
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'aqiValue': aqiValue,
      'aqiStandard': aqiStandard,
      'aqiLevelText': aqiLevelText,
      'primaryPollutant': primaryPollutant,
      'pm25': pm25,
      'pm10': pm10,
      'no2': no2,
      'o3': o3,
      'so2': so2,
      'co': co,
      'uvIndex': uvIndex,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// 复制并修改
  AirQualityData copyWith({
    int? aqiValue,
    String? aqiStandard,
    String? aqiLevelText,
    String? primaryPollutant,
    double? pm25,
    double? pm10,
    double? no2,
    double? o3,
    double? so2,
    double? co,
    int? uvIndex,
    DateTime? lastUpdated,
  }) {
    return AirQualityData(
      aqiValue: aqiValue ?? this.aqiValue,
      aqiStandard: aqiStandard ?? this.aqiStandard,
      aqiLevelText: aqiLevelText ?? this.aqiLevelText,
      primaryPollutant: primaryPollutant ?? this.primaryPollutant,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      no2: no2 ?? this.no2,
      o3: o3 ?? this.o3,
      so2: so2 ?? this.so2,
      co: co ?? this.co,
      uvIndex: uvIndex ?? this.uvIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
