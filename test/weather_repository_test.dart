import 'package:apple_weather_android/models/air_quality_model.dart';
import 'package:apple_weather_android/models/city_search_result.dart';
import 'package:apple_weather_android/models/saved_city_weather.dart';
import 'package:apple_weather_android/models/weather_model.dart';
import 'package:apple_weather_android/repositories/weather_repository.dart';
import 'package:apple_weather_android/services/local_weather_cache_service.dart';
import 'package:apple_weather_android/services/weather_api_service.dart';
import 'package:apple_weather_android/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWeatherApiService extends WeatherApiService {
  @override
  Future<WeatherData> getWeatherByLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    return WeatherData(
      location: locationName ?? 'Test City',
      temperature: 26,
      feelsLike: 27,
      condition: 'Sunny',
      conditionCode: 0,
      humidity: 58,
      pressure: 1011,
      visibility: 10000,
      uvIndex: 6,
      windSpeed: 9,
      sunrise: '06:00',
      sunset: '18:00',
      isDayTime: true,
      highTemp: 30,
      lowTemp: 22,
      hourlyForecast: const [],
      dailyForecast: const [],
    );
  }

  @override
  Future<AirQualityData> getAirQualityByLocation(
    double latitude,
    double longitude,
  ) async {
    return AirQualityData(
      aqiValue: 35,
      aqiStandard: 'US',
      aqiLevelText: 'Good',
      primaryPollutant: 'PM2.5',
      pm25: 8,
      pm10: 14,
      no2: 7,
      o3: 12,
      so2: 2,
      co: 180,
      uvIndex: 5,
      lastUpdated: DateTime.parse('2026-04-14T10:00:00Z'),
    );
  }
}

class _FakeCacheService extends LocalWeatherCacheService {
  CachedWeatherState? cachedState;

  @override
  Future<CachedWeatherState?> loadState() async => cachedState;

  @override
  Future<void> saveState({
    required WeatherData? currentLocationWeather,
    required List<SavedCityWeather> savedCities,
    required String? expandedCityId,
    required DateTime? lastUpdated,
    required TemperatureUnit temperatureUnit,
  }) async {
    cachedState = CachedWeatherState(
      currentLocationWeather: currentLocationWeather,
      savedCities: List<SavedCityWeather>.from(savedCities),
      expandedCityId: expandedCityId,
      lastUpdated: lastUpdated,
      temperatureUnit: temperatureUnit,
    );
  }
}

void main() {
  group('WeatherRepository', () {
    test('fetches weather bundle with air quality', () async {
      final repository = WeatherRepository(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: _FakeCacheService(),
      );
      final city = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );

      final weather = await repository.fetchWeatherForCity(city);

      expect(weather.location, 'Shanghai, China');
      expect(weather.airQuality, isNotNull);
      expect(weather.airQuality!.aqiValue, 35);
    });

    test('persists cached dashboard state through cache service', () async {
      final cacheService = _FakeCacheService();
      final repository = WeatherRepository(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );
      final city = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );
      final savedCity = SavedCityWeather(
        city: city,
        weatherData: await repository.fetchWeatherForCity(city),
        updatedAt: DateTime.parse('2026-04-14T11:00:00Z'),
        isPinned: true,
        sortOrder: 2,
      );

      await repository.saveCachedState(
        currentLocationWeather: null,
        savedCities: [savedCity],
        expandedCityId: savedCity.id,
        lastUpdated: DateTime.parse('2026-04-14T12:00:00Z'),
        temperatureUnit: TemperatureUnit.fahrenheit,
      );

      final restored = await repository.loadCachedState();

      expect(restored, isNotNull);
      expect(restored!.savedCities, hasLength(1));
      expect(restored.savedCities.first.isPinned, isTrue);
      expect(restored.savedCities.first.sortOrder, 2);
      expect(restored.expandedCityId, savedCity.id);
      expect(restored.lastUpdated, DateTime.parse('2026-04-14T12:00:00Z'));
      expect(restored.temperatureUnit, TemperatureUnit.fahrenheit);
    });
  });
}
