library saved_city_weather;

import 'city_search_result.dart';
import 'weather_model.dart';

class SavedCityWeather {
  final CitySearchResult city;
  final WeatherData weatherData;
  final DateTime updatedAt;

  const SavedCityWeather({
    required this.city,
    required this.weatherData,
    required this.updatedAt,
  });

  String get id => buildId(city);

  String get displayName => city.displayName;

  static String buildId(CitySearchResult city) {
    return '${city.name}_${city.latitude}_${city.longitude}';
  }

  SavedCityWeather copyWith({
    CitySearchResult? city,
    WeatherData? weatherData,
    DateTime? updatedAt,
  }) {
    return SavedCityWeather(
      city: city ?? this.city,
      weatherData: weatherData ?? this.weatherData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
