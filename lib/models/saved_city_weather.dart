library saved_city_weather;

import 'city_search_result.dart';
import 'weather_model.dart';

class SavedCityWeather {
  final CitySearchResult city;
  final WeatherData weatherData;
  final DateTime updatedAt;
  final bool isPinned;
  final int sortOrder;

  const SavedCityWeather({
    required this.city,
    required this.weatherData,
    required this.updatedAt,
    this.isPinned = false,
    this.sortOrder = 0,
  });

  String get id => buildId(city);

  String get displayName => city.displayName;

  static String buildId(CitySearchResult city) {
    return '${city.name}_${city.latitude}_${city.longitude}';
  }

  factory SavedCityWeather.fromJson(Map<String, dynamic> json) {
    return SavedCityWeather(
      city: CitySearchResult.fromJson(json['city'] as Map<String, dynamic>),
      weatherData: WeatherData.fromStorageJson(
          json['weatherData'] as Map<String, dynamic>),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isPinned: json['isPinned'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city.toJson(),
      'weatherData': weatherData.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'sortOrder': sortOrder,
    };
  }

  SavedCityWeather copyWith({
    CitySearchResult? city,
    WeatherData? weatherData,
    DateTime? updatedAt,
    bool? isPinned,
    int? sortOrder,
  }) {
    return SavedCityWeather(
      city: city ?? this.city,
      weatherData: weatherData ?? this.weatherData,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
