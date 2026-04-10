/// 城市搜索结果模型
/// 基于 Open-Meteo Geocoding API 返回结构映射

/// 城市搜索结果
class CitySearchResult {
  /// 城市名称
  final String name;

  /// 纬度
  final double latitude;

  /// 经度
  final double longitude;

  /// 国家名称
  final String? country;

  /// 一级行政区 (省/州)
  final String? admin1;

  /// 时区
  final String? timezone;

  CitySearchResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
    this.timezone,
  });

  /// 从 Open-Meteo Geocoding API 返回的 JSON 解析
  ///
  /// [json] Geocoding API 单个结果项
  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'admin1': admin1,
      'timezone': timezone,
    };
  }

  /// 复制并修改
  CitySearchResult copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? country,
    String? admin1,
    String? timezone,
  }) {
    return CitySearchResult(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
      timezone: timezone ?? this.timezone,
    );
  }

  /// 获取完整显示名称
  ///
  /// 优先级: 城市名 + admin1 + country
  String get displayName {
    final parts = <String>[name];

    if (admin1 != null && admin1!.isNotEmpty) {
      parts.add(admin1!);
    }

    if (country != null && country!.isNotEmpty) {
      parts.add(country!);
    }

    return parts.join(', ');
  }

  @override
  String toString() {
    return 'CitySearchResult(name: $name, lat: $latitude, lon: $longitude, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CitySearchResult &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(name, latitude, longitude);
  }
}
