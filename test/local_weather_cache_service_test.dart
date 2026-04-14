import 'package:apple_weather_android/models/air_quality_model.dart';
import 'package:apple_weather_android/models/city_search_result.dart';
import 'package:apple_weather_android/models/saved_city_weather.dart';
import 'package:apple_weather_android/models/weather_model.dart';
import 'package:apple_weather_android/services/local_weather_cache_service.dart';
import 'package:apple_weather_android/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

WeatherData _buildWeather(String location) {
  return WeatherData(
    location: location,
    temperature: 24,
    feelsLike: 25,
    condition: 'Sunny',
    conditionCode: 0,
    humidity: 55,
    pressure: 1012,
    visibility: 10000,
    uvIndex: 5,
    windSpeed: 12,
    sunrise: '06:00',
    sunset: '18:30',
    isDayTime: true,
    highTemp: 28,
    lowTemp: 18,
    hourlyForecast: [
      HourlyForecast(time: 'Now', temperature: 24, conditionCode: 0),
    ],
    dailyForecast: [
      DailyForecast(
        date: 'Today',
        highTemp: 28,
        lowTemp: 18,
        conditionCode: 0,
        precipitationChance: 10,
      ),
    ],
    airQuality: AirQualityData(
      aqiValue: 42,
      aqiStandard: 'US',
      aqiLevelText: 'Good',
      primaryPollutant: 'PM2.5',
      pm25: 10,
      pm10: 18,
      no2: 12,
      o3: 20,
      so2: 2,
      co: 200,
      uvIndex: 5,
      lastUpdated: DateTime.parse('2026-04-14T10:00:00Z'),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalWeatherCacheService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and restores cached dashboard state', () async {
      final service = LocalWeatherCacheService();
      final city = CitySearchResult(
        name: 'Shanghai',
        latitude: 31.2304,
        longitude: 121.4737,
        country: 'China',
        admin1: 'Shanghai',
        timezone: 'Asia/Shanghai',
      );
      final savedCity = SavedCityWeather(
        city: city,
        weatherData: _buildWeather('Shanghai, China'),
        updatedAt: DateTime.parse('2026-04-14T11:00:00Z'),
        sortOrder: 3,
      );

      await service.saveState(
        currentLocationWeather: _buildWeather('Current Location'),
        savedCities: [savedCity],
        expandedCityId: savedCity.id,
        lastUpdated: DateTime.parse('2026-04-14T12:00:00Z'),
        temperatureUnit: TemperatureUnit.fahrenheit,
      );

      final restored = await service.loadState();

      expect(restored, isNotNull);
      expect(restored!.currentLocationWeather!.location, 'Current Location');
      expect(restored.savedCities, hasLength(1));
      expect(
          restored.savedCities.first.displayName, 'Shanghai, Shanghai, China');
      expect(restored.savedCities.first.weatherData.airQuality?.aqiValue, 42);
      expect(restored.savedCities.first.sortOrder, 3);
      expect(restored.expandedCityId, savedCity.id);
      expect(restored.lastUpdated, DateTime.parse('2026-04-14T12:00:00Z'));
      expect(restored.temperatureUnit, TemperatureUnit.fahrenheit);
    });

    test('drops invalid cached payloads', () async {
      SharedPreferences.setMockInitialValues({
        'weather_dashboard_state_v1': '{invalid json',
      });

      final service = LocalWeatherCacheService();
      final restored = await service.loadState();

      expect(restored, isNull);
    });
  });
}
