import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_city_weather.dart';
import '../models/weather_model.dart';
import '../utils/date_utils.dart';

class CachedWeatherState {
  final WeatherData? currentLocationWeather;
  final List<SavedCityWeather> savedCities;
  final String? expandedCityId;
  final DateTime? lastUpdated;
  final TemperatureUnit temperatureUnit;

  const CachedWeatherState({
    required this.currentLocationWeather,
    required this.savedCities,
    required this.expandedCityId,
    required this.lastUpdated,
    required this.temperatureUnit,
  });
}

class LocalWeatherCacheService {
  static const String _stateKey = 'weather_dashboard_state_v1';

  Future<CachedWeatherState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CachedWeatherState(
        currentLocationWeather:
            json['currentLocationWeather'] is Map<String, dynamic>
                ? WeatherData.fromStorageJson(
                    json['currentLocationWeather'] as Map<String, dynamic>,
                  )
                : null,
        savedCities: ((json['savedCities'] as List<dynamic>?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SavedCityWeather.fromJson)
            .toList(),
        expandedCityId: json['expandedCityId'] as String?,
        lastUpdated: json['lastUpdated'] == null
            ? null
            : DateTime.tryParse(json['lastUpdated'] as String),
        temperatureUnit: TemperatureUnit.fromCacheValue(
          json['temperatureUnit'] as String?,
        ),
      );
    } catch (_) {
      await prefs.remove(_stateKey);
      return null;
    }
  }

  Future<void> saveState({
    required WeatherData? currentLocationWeather,
    required List<SavedCityWeather> savedCities,
    required String? expandedCityId,
    required DateTime? lastUpdated,
    required TemperatureUnit temperatureUnit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'currentLocationWeather': currentLocationWeather?.toJson(),
      'savedCities': savedCities.map((city) => city.toJson()).toList(),
      'expandedCityId': expandedCityId,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'temperatureUnit': temperatureUnit.cacheValue,
    });
    await prefs.setString(_stateKey, payload);
  }

  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }
}
