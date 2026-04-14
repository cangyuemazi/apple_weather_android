import 'dart:async';

import 'package:apple_weather_android/models/air_quality_model.dart';
import 'package:apple_weather_android/models/city_search_result.dart';
import 'package:apple_weather_android/models/saved_city_weather.dart';
import 'package:apple_weather_android/models/weather_model.dart';
import 'package:apple_weather_android/providers/weather_hub_provider.dart';
import 'package:apple_weather_android/services/local_weather_cache_service.dart';
import 'package:apple_weather_android/services/weather_api_service.dart';
import 'package:apple_weather_android/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWeatherApiService extends WeatherApiService {
  int weatherFetchCount = 0;

  @override
  Future<WeatherData> getWeatherByLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    weatherFetchCount++;
    return WeatherData(
      location: locationName ?? 'Test City',
      temperature: 25,
      feelsLike: 26,
      condition: 'Sunny',
      conditionCode: 0,
      humidity: 60,
      pressure: 1012,
      visibility: 10000,
      uvIndex: 5,
      windSpeed: 10,
      sunrise: '06:00',
      sunset: '18:00',
      isDayTime: true,
      highTemp: 30,
      lowTemp: 20,
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
      aqiValue: 40,
      aqiStandard: 'US',
      aqiLevelText: 'Good',
      primaryPollutant: 'PM2.5',
      pm25: 10,
      pm10: 20,
      no2: 8,
      o3: 15,
      so2: 2,
      co: 200,
      uvIndex: 4,
      lastUpdated: DateTime.parse('2026-04-14T10:00:00Z'),
    );
  }
}

class _DelayedWeatherApiService extends _FakeWeatherApiService {
  _DelayedWeatherApiService(this.gate);

  final Completer<void> gate;

  @override
  Future<WeatherData> getWeatherByLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    await gate.future;
    return super.getWeatherByLocation(
      latitude,
      longitude,
      locationName: locationName,
    );
  }
}

class _FakeCacheService extends LocalWeatherCacheService {
  List<SavedCityWeather> savedCities = const [];
  String? expandedCityId;
  CachedWeatherState? restoredState;
  bool didClearState = false;

  @override
  Future<CachedWeatherState?> loadState() async => restoredState;

  @override
  Future<void> saveState({
    required WeatherData? currentLocationWeather,
    required List<SavedCityWeather> savedCities,
    required String? expandedCityId,
    required DateTime? lastUpdated,
    required TemperatureUnit temperatureUnit,
  }) async {
    this.savedCities = List<SavedCityWeather>.from(savedCities);
    this.expandedCityId = expandedCityId;
  }

  @override
  Future<void> clearState() async {
    didClearState = true;
    restoredState = null;
  }
}

WeatherData _buildCachedWeather(String location) {
  return WeatherData(
    location: location,
    temperature: 22,
    feelsLike: 23,
    condition: 'Cloudy',
    conditionCode: 1,
    humidity: 55,
    pressure: 1012,
    visibility: 10000,
    uvIndex: 3,
    windSpeed: 8,
    sunrise: '06:00',
    sunset: '18:00',
    isDayTime: true,
    highTemp: 26,
    lowTemp: 18,
    hourlyForecast: const [],
    dailyForecast: const [],
  );
}

void main() {
  group('WeatherProvider city management', () {
    test('removes city and moves expanded state to the next item', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );

      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final shanghai = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);
      await provider.addCity(shanghai, showLoading: false);

      expect(provider.savedCities, hasLength(2));
      expect(provider.expandedCityId, provider.savedCities.first.id);

      final removed = provider.removeCity(provider.savedCities.first.id);

      expect(removed, isTrue);
      expect(provider.savedCities, hasLength(1));
      expect(provider.savedCities.first.city.name, 'Beijing');
      expect(provider.expandedCityId, provider.savedCities.first.id);
      expect(cacheService.savedCities, hasLength(1));
      expect(cacheService.expandedCityId, provider.savedCities.first.id);
    });

    test('pins city to the top and persists pinned state', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );

      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final shanghai = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);
      await provider.addCity(shanghai, showLoading: false);

      final pinned =
          provider.toggleCityPinned(SavedCityWeather.buildId(beijing));

      expect(pinned, isTrue);
      expect(provider.savedCities.first.city.name, 'Beijing');
      expect(provider.savedCities.first.isPinned, isTrue);
      expect(cacheService.savedCities.first.isPinned, isTrue);
    });

    test('reorders cities within the same group and persists order', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );

      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final shanghai = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );
      final shenzhen = CitySearchResult(
        name: 'Shenzhen',
        latitude: 22.5431,
        longitude: 114.0579,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);
      await provider.addCity(shanghai, showLoading: false);
      await provider.addCity(shenzhen, showLoading: false);

      final reordered = provider.reorderSavedCities(2, 0);

      expect(reordered, isTrue);
      expect(
        provider.savedCities.map((city) => city.city.name).toList(),
        ['Beijing', 'Shenzhen', 'Shanghai'],
      );
      expect(
        cacheService.savedCities.map((city) => city.sortOrder).toList(),
        [0, 1, 2],
      );
    });

    test('blocks reordering across pinned and unpinned groups', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );

      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final shanghai = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);
      await provider.addCity(shanghai, showLoading: false);
      provider.toggleCityPinned(SavedCityWeather.buildId(beijing));

      final reordered = provider.reorderSavedCities(1, 0);

      expect(reordered, isFalse);
      expect(
        provider.savedCities.map((city) => city.city.name).toList(),
        ['Beijing', 'Shanghai'],
      );
    });

    test('detects whether a city is already saved', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final shanghai = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);

      expect(provider.hasSavedCity(beijing), isTrue);
      expect(provider.hasSavedCity(shanghai), isFalse);
    });

    test('pinning city does not change weather freshness timestamp', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);
      final lastUpdatedBeforePin = provider.lastUpdated;

      final pinned =
          provider.toggleCityPinned(SavedCityWeather.buildId(beijing));

      expect(pinned, isTrue);
      expect(provider.lastUpdated, lastUpdatedBeforePin);
    });

    test('removing the final city clears freshness timestamp', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);

      final removed = provider.removeCity(SavedCityWeather.buildId(beijing));

      expect(removed, isTrue);
      expect(provider.savedCities, isEmpty);
      expect(provider.lastUpdated, isNull);
    });

    test('restores deleted city without refetching weather', () async {
      final cacheService = _FakeCacheService();
      final apiService = _FakeWeatherApiService();
      final provider = WeatherProvider(
        weatherApiService: apiService,
        cacheService: cacheService,
      );
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );

      await provider.addCity(beijing, showLoading: false);
      final fetchCountBeforeDelete = apiService.weatherFetchCount;

      final removedCity =
          provider.removeCityAndReturn(SavedCityWeather.buildId(beijing));

      expect(removedCity, isNotNull);
      expect(provider.savedCities, isEmpty);

      provider.restoreRemovedCity(removedCity!);

      expect(provider.savedCities, hasLength(1));
      expect(provider.savedCities.first.city.name, 'Beijing');
      expect(provider.expandedCityId, provider.savedCities.first.id);
      expect(apiService.weatherFetchCount, fetchCountBeforeDelete);
    });

    test('blocks adding another city while a request is in progress', () async {
      final cacheService = _FakeCacheService();
      final gate = Completer<void>();
      final apiService = _DelayedWeatherApiService(gate);
      final provider = WeatherProvider(
        weatherApiService: apiService,
        cacheService: cacheService,
      );
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final shanghai = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
      );

      final firstAddFuture = provider.addCity(beijing);
      final secondAddResult = await provider.addCity(shanghai);

      expect(secondAddResult, isFalse);
      expect(
        provider.errorMessage,
        'A weather update is already in progress.',
      );

      gate.complete();
      final firstAddResult = await firstAddFuture;

      expect(firstAddResult, isTrue);
      expect(provider.savedCities, hasLength(1));
      expect(provider.savedCities.first.city.name, 'Beijing');
    });

    test('restores fresh cache without triggering immediate refresh', () async {
      final cacheService = _FakeCacheService()
        ..restoredState = CachedWeatherState(
          currentLocationWeather: null,
          savedCities: [
            SavedCityWeather(
              city: CitySearchResult(
                name: 'Shanghai',
                latitude: 31.2304,
                longitude: 121.4737,
                country: 'China',
              ),
              weatherData: _buildCachedWeather('Shanghai, China'),
              updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
            ),
          ],
          expandedCityId: SavedCityWeather.buildId(
            CitySearchResult(
              name: 'Shanghai',
              latitude: 31.2304,
              longitude: 121.4737,
              country: 'China',
            ),
          ),
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
          temperatureUnit: TemperatureUnit.fahrenheit,
        );
      final apiService = _FakeWeatherApiService();
      final provider = WeatherProvider(
        weatherApiService: apiService,
        cacheService: cacheService,
      );

      await provider.init();
      await Future<void>.delayed(Duration.zero);

      expect(provider.savedCities, hasLength(1));
      expect(provider.savedCities.first.city.name, 'Shanghai');
      expect(provider.isCacheExpired, isFalse);
      expect(provider.temperatureUnit, TemperatureUnit.fahrenheit);
      expect(apiService.weatherFetchCount, 0);
    });

    test('refreshes expired cache for saved cities only', () async {
      final cacheService = _FakeCacheService()
        ..restoredState = CachedWeatherState(
          currentLocationWeather: null,
          savedCities: [
            SavedCityWeather(
              city: CitySearchResult(
                name: 'Shanghai',
                latitude: 31.2304,
                longitude: 121.4737,
                country: 'China',
              ),
              weatherData: _buildCachedWeather('Stale Shanghai'),
              updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ],
          expandedCityId: SavedCityWeather.buildId(
            CitySearchResult(
              name: 'Shanghai',
              latitude: 31.2304,
              longitude: 121.4737,
              country: 'China',
            ),
          ),
          lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
          temperatureUnit: TemperatureUnit.celsius,
        );
      final apiService = _FakeWeatherApiService();
      final provider = WeatherProvider(
        weatherApiService: apiService,
        cacheService: cacheService,
      );

      await provider.init();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(apiService.weatherFetchCount, 1);
      expect(provider.savedCities, hasLength(1));
      expect(
          provider.savedCities.first.weatherData.location, 'Shanghai, China');
      expect(provider.errorMessage, isNull);
      expect(provider.isCacheExpired, isFalse);
    });

    test('persists temperature unit changes', () async {
      final cacheService = _FakeCacheService();
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(),
        cacheService: cacheService,
      );

      provider.setTemperatureUnit(TemperatureUnit.fahrenheit);

      expect(provider.temperatureUnit, TemperatureUnit.fahrenheit);
    });
  });
}
