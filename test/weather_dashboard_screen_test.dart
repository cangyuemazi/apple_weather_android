import 'package:apple_weather_android/models/air_quality_model.dart';
import 'package:apple_weather_android/models/city_search_result.dart';
import 'package:apple_weather_android/models/saved_city_weather.dart';
import 'package:apple_weather_android/models/weather_model.dart';
import 'package:apple_weather_android/providers/weather_hub_provider.dart';
import 'package:apple_weather_android/screens/weather_dashboard_screen.dart';
import 'package:apple_weather_android/services/local_weather_cache_service.dart';
import 'package:apple_weather_android/services/weather_api_service.dart';
import 'package:apple_weather_android/utils/constants.dart';
import 'package:apple_weather_android/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeWeatherApiService extends WeatherApiService {
  _FakeWeatherApiService({required this.searchResults});

  final List<CitySearchResult> searchResults;

  @override
  Future<List<CitySearchResult>> searchCity(String keyword) async {
    return searchResults
        .where(
          (city) =>
              city.displayName.toLowerCase().contains(keyword.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<WeatherData> getWeatherByLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
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

class _FakeCacheService extends LocalWeatherCacheService {
  @override
  Future<void> saveState({
    required WeatherData? currentLocationWeather,
    required List<SavedCityWeather> savedCities,
    required String? expandedCityId,
    required DateTime? lastUpdated,
    required TemperatureUnit temperatureUnit,
  }) async {}
}

Widget _buildScreen(WeatherProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(
      home: WeatherDashboardScreen(),
    ),
  );
}

void main() {
  group('WeatherDashboardScreen', () {
    testWidgets('reorders saved city cards through the reorder list', (
      WidgetTester tester,
    ) async {
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
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(
          searchResults: [beijing, shanghai],
        ),
        cacheService: _FakeCacheService(),
      );

      await provider.addCity(beijing, showLoading: false);
      await provider.addCity(shanghai, showLoading: false);
      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));

      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorder(1, 0);
      await tester.pumpAndSettle();

      expect(
        provider.savedCities.map((city) => city.city.name).toList(),
        ['Beijing', 'Shanghai'],
      );
    });

    testWidgets('switches temperature unit from celsius to fahrenheit', (
      WidgetTester tester,
    ) async {
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(searchResults: [beijing]),
        cacheService: _FakeCacheService(),
      );

      await provider.addCity(beijing, showLoading: false);
      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(provider.temperatureUnit, TemperatureUnit.celsius);
      expect(find.text('℃'), findsOneWidget);

      await tester.tap(find.text('℃'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('华氏度 ℉'));
      await tester.pumpAndSettle();

      expect(provider.temperatureUnit, TemperatureUnit.fahrenheit);
      expect(find.text('℉'), findsOneWidget);
      expect(find.text('77°F'), findsWidgets);
    });

    testWidgets('marks already saved cities in search results', (
      WidgetTester tester,
    ) async {
      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(searchResults: [beijing]),
        cacheService: _FakeCacheService(),
      );

      await provider.addCity(beijing, showLoading: false);
      await tester.pumpWidget(_buildScreen(provider));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Beijing');
      await tester.pump(AppConstants.searchDebounce);
      await tester.pumpAndSettle();

      expect(find.text('已保存，点击后会刷新并置顶'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('restores a deleted city when undo is tapped', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final beijing = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
        country: 'China',
      );
      final provider = WeatherProvider(
        weatherApiService: _FakeWeatherApiService(searchResults: [beijing]),
        cacheService: _FakeCacheService(),
      );

      await provider.addCity(beijing, showLoading: false);
      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.text('Beijing, China'), findsOneWidget);

      await tester.tap(find.text('Beijing, China'));
      await tester.pumpAndSettle();

      final deleteCityButton = find.widgetWithText(TextButton, '删除城市');
      await tester.scrollUntilVisible(
        deleteCityButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester.widget<TextButton>(deleteCityButton).onPressed!.call();
      await tester.pumpAndSettle();

      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '删除'))
          .onPressed!
          .call();
      await tester.pumpAndSettle();

      expect(find.text('已删除 Beijing, China'), findsOneWidget);
      expect(find.text('撤销'), findsOneWidget);

      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();

      expect(find.text('Beijing, China'), findsOneWidget);
      expect(provider.savedCities, hasLength(1));
    });
  });
}
