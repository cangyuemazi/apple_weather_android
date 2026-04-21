library weather_repository;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import '../models/city_search_result.dart';
import '../models/saved_city_weather.dart';
import '../models/weather_model.dart';
import '../services/local_weather_cache_service.dart';
import '../services/location_service.dart';
import '../services/weather_api_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class WeatherRepository {
  WeatherRepository({
    WeatherApiService? weatherApiService,
    LocalWeatherCacheService? cacheService,
  })  : _weatherApiService = weatherApiService ?? WeatherApiService(),
        _cacheService = cacheService ?? LocalWeatherCacheService();

  final WeatherApiService _weatherApiService;
  final LocalWeatherCacheService _cacheService;

  Future<List<CitySearchResult>> searchCity(String keyword) {
    return _weatherApiService.searchCity(keyword);
  }

  Future<WeatherData> fetchWeatherForCity(CitySearchResult city) {
    return fetchWeatherBundle(
      latitude: city.latitude,
      longitude: city.longitude,
      locationName: city.displayName,
    );
  }

  Future<WeatherData> fetchCurrentLocationWeather() async {
    if (kIsWeb) {
      return fetchWeatherBundle(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        locationName: AppConstants.defaultCity,
      );
    }

    final position = await LocationService.getCurrentPosition();
    return fetchWeatherBundle(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: 'Current Location',
    );
  }

  Future<WeatherData> fetchWeatherBundle({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    final weatherFuture = _weatherApiService.getWeatherByLocation(
      latitude,
      longitude,
      locationName: locationName,
    );
    final airQualityFuture = _weatherApiService.getAirQualityByLocation(
      latitude,
      longitude,
    );

    final weatherData = await weatherFuture;

    try {
      final airQuality = await airQualityFuture;
      return weatherData.copyWith(airQuality: airQuality);
    } catch (error) {
      debugPrint('WeatherRepository: air quality fetch failed - $error');
      return weatherData;
    }
  }

  Future<CachedWeatherState?> loadCachedState() {
    return _cacheService.loadState();
  }

  Future<void> saveCachedState({
    required WeatherData? currentLocationWeather,
    required List<SavedCityWeather> savedCities,
    required String? expandedCityId,
    required DateTime? lastUpdated,
    required TemperatureUnit temperatureUnit,
  }) {
    return _cacheService.saveState(
      currentLocationWeather: currentLocationWeather,
      savedCities: savedCities,
      expandedCityId: expandedCityId,
      lastUpdated: lastUpdated,
      temperatureUnit: temperatureUnit,
    );
  }

  Future<void> clearCachedState() {
    return _cacheService.clearState();
  }

  void dispose() {
    _weatherApiService.dispose();
  }
}
