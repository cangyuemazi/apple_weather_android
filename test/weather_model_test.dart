import 'package:flutter_test/flutter_test.dart';
import 'package:apple_weather_android/models/weather_model.dart';
import 'package:apple_weather_android/models/city_search_result.dart';
import 'package:apple_weather_android/utils/weather_utils.dart';

void main() {
  group('WeatherData Model Tests', () {
    test('should parse Open-Meteo JSON correctly', () {
      final json = {
        'current': {
          'temperature_2m': 25.5,
          'relative_humidity_2m': 60,
          'apparent_temperature': 26.0,
          'is_day': 1,
          'weather_code': 0,
          'surface_pressure': 1013,
          'wind_speed_10m': 3.5,
        },
        'hourly': {
          'time': [
            '2024-01-01T10:00',
            '2024-01-01T11:00',
            '2024-01-01T12:00',
          ],
          'temperature_2m': [25.0, 26.0, 27.0],
          'weather_code': [0, 1, 2],
          'visibility': [10000, 9500, 9000],
        },
        'daily': {
          'time': ['2024-01-01', '2024-01-02'],
          'temperature_2m_max': [28.0, 27.0],
          'temperature_2m_min': [18.0, 17.0],
          'weather_code': [0, 1],
          'sunrise': ['2024-01-01T06:00', '2024-01-02T06:00'],
          'sunset': ['2024-01-01T18:00', '2024-01-02T18:00'],
          'uv_index_max': [5.0, 4.5],
          'precipitation_probability_max': [10, 20],
          'wind_speed_10m_max': [15, 18],
        },
      };

      final weather = WeatherData.fromJson(json, 'Beijing');

      expect(weather.location, 'Beijing');
      expect(weather.temperature, 25.5);
      expect(weather.feelsLike, 26.0);
      expect(weather.humidity, 60);
      expect(weather.pressure, 1013);
      expect(weather.windSpeed, 3.5);
      expect(weather.conditionCode, 0);
      expect(weather.condition, '晴');
      expect(weather.isDayTime, true);
      expect(weather.highTemp, 28.0);
      expect(weather.lowTemp, 18.0);
      expect(weather.uvIndex, 5);
      expect(weather.hourlyForecast.isNotEmpty, true);
      expect(weather.dailyForecast.isNotEmpty, true);
    });

    test('should handle null values gracefully', () {
      final json = <String, dynamic>{};

      // Should not throw exception
      expect(() => WeatherData.fromJson(json, 'Test'), returnsNormally);
    });

    test('should serialize to JSON correctly', () {
      final json = {
        'current': {
          'temperature_2m': 20.0,
          'relative_humidity_2m': 50,
          'apparent_temperature': 21.0,
          'is_day': 1,
          'weather_code': 0,
          'surface_pressure': 1013,
          'wind_speed_10m': 5.0,
        },
        'hourly': {
          'time': ['2024-01-01T10:00'],
          'temperature_2m': [20.0],
          'weather_code': [0],
          'visibility': [10000],
        },
        'daily': {
          'time': ['2024-01-01'],
          'temperature_2m_max': [25.0],
          'temperature_2m_min': [15.0],
          'weather_code': [0],
          'sunrise': ['2024-01-01T06:00'],
          'sunset': ['2024-01-01T18:00'],
          'uv_index_max': [5.0],
          'precipitation_probability_max': [10],
          'wind_speed_10m_max': [15],
        },
      };

      final weather = WeatherData.fromJson(json, 'Test');
      final serialized = weather.toJson();

      expect(serialized['location'], 'Test');
      expect(serialized['temperature'], 20.0);
      expect(serialized['condition'], '晴');
    });

    test('copyWith should create new instance with updated values', () {
      final json = {
        'current': {
          'temperature_2m': 20.0,
          'relative_humidity_2m': 50,
          'apparent_temperature': 21.0,
          'is_day': 1,
          'weather_code': 0,
          'surface_pressure': 1013,
          'wind_speed_10m': 5.0,
        },
        'hourly': {
          'time': ['2024-01-01T10:00'],
          'temperature_2m': [20.0],
          'weather_code': [0],
          'visibility': [10000],
        },
        'daily': {
          'time': ['2024-01-01'],
          'temperature_2m_max': [25.0],
          'temperature_2m_min': [15.0],
          'weather_code': [0],
          'sunrise': ['2024-01-01T06:00'],
          'sunset': ['2024-01-01T18:00'],
          'uv_index_max': [5.0],
          'precipitation_probability_max': [10],
          'wind_speed_10m_max': [15],
        },
      };

      final weather = WeatherData.fromJson(json, 'Beijing');
      final updated = weather.copyWith(temperature: 25.0, humidity: 65);

      expect(updated.temperature, 25.0);
      expect(updated.humidity, 65);
      expect(updated.location, 'Beijing'); // unchanged
    });
  });

  group('HourlyForecast Model Tests', () {
    test('should create hourly forecast correctly', () {
      final hourly = HourlyForecast(
        time: '13:00',
        temperature: 22.5,
        conditionCode: 0,
      );

      expect(hourly.temperature, 22.5);
      expect(hourly.conditionCode, 0);
      expect(hourly.time, '13:00');
    });

    test('should serialize to JSON correctly', () {
      final hourly = HourlyForecast(
        time: '14:00',
        temperature: 25.0,
        conditionCode: 1,
      );

      final json = hourly.toJson();
      expect(json['time'], '14:00');
      expect(json['temperature'], 25.0);
      expect(json['conditionCode'], 1);
    });

    test('copyWith should work correctly', () {
      final hourly = HourlyForecast(
        time: '10:00',
        temperature: 20.0,
        conditionCode: 0,
      );

      final updated = hourly.copyWith(temperature: 22.0);
      expect(updated.temperature, 22.0);
      expect(updated.time, '10:00'); // unchanged
    });
  });

  group('DailyForecast Model Tests', () {
    test('should create daily forecast correctly', () {
      final daily = DailyForecast(
        date: '今天',
        highTemp: 25.0,
        lowTemp: 15.0,
        conditionCode: 0,
        precipitationChance: 10,
      );

      expect(daily.lowTemp, 15.0);
      expect(daily.highTemp, 25.0);
      expect(daily.conditionCode, 0);
      expect(daily.precipitationChance, 10);
      expect(daily.date, '今天');
    });

    test('should serialize to JSON correctly', () {
      final daily = DailyForecast(
        date: '周一',
        highTemp: 28.0,
        lowTemp: 18.0,
        conditionCode: 1,
        precipitationChance: 20,
      );

      final json = daily.toJson();
      expect(json['date'], '周一');
      expect(json['highTemp'], 28.0);
      expect(json['lowTemp'], 18.0);
    });

    test('copyWith should work correctly', () {
      final daily = DailyForecast(
        date: '今天',
        highTemp: 25.0,
        lowTemp: 15.0,
        conditionCode: 0,
        precipitationChance: 10,
      );

      final updated = daily.copyWith(highTemp: 27.0);
      expect(updated.highTemp, 27.0);
      expect(daily.highTemp, 25.0); // original unchanged
    });
  });

  group('CitySearchResult Model Tests', () {
    test('should parse city search result correctly', () {
      final json = {
        'name': 'Beijing',
        'latitude': 39.9042,
        'longitude': 116.4074,
        'country': 'China',
        'admin1': 'Beijing',
        'timezone': 'Asia/Shanghai',
      };

      final result = CitySearchResult.fromJson(json);

      expect(result.name, 'Beijing');
      expect(result.latitude, 39.9042);
      expect(result.longitude, 116.4074);
      expect(result.country, 'China');
      expect(result.displayName, 'Beijing, Beijing, China');
    });

    test('should handle missing admin1', () {
      final json = {
        'name': 'Shanghai',
        'latitude': 31.2304,
        'longitude': 121.4737,
        'country': 'China',
      };

      final result = CitySearchResult.fromJson(json);

      expect(result.name, 'Shanghai');
      expect(result.displayName, 'Shanghai, China');
    });

    test('should serialize to JSON correctly', () {
      final result = CitySearchResult(
        name: 'Guangzhou',
        latitude: 23.1291,
        longitude: 113.2644,
        country: 'China',
        admin1: 'Guangdong',
      );

      final json = result.toJson();
      expect(json['name'], 'Guangzhou');
      expect(json['latitude'], 23.1291);
      expect(json['country'], 'China');
    });

    test('copyWith should work correctly', () {
      final result = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
      );

      final updated = result.copyWith(country: 'China');
      expect(updated.country, 'China');
      expect(updated.name, 'Beijing'); // unchanged
    });

    test('equality should work', () {
      final result1 = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
      );

      final result2 = CitySearchResult(
        name: 'Beijing',
        latitude: 39.9042,
        longitude: 116.4074,
      );

      expect(result1 == result2, true);
      expect(result1.hashCode == result2.hashCode, true);
    });
  });

  group('WeatherUtils Tests', () {
    test('should map weather codes correctly', () {
      expect(WeatherUtils.getWeatherConditionText(0), '晴');
      expect(WeatherUtils.getWeatherConditionText(1), '多云');
      expect(WeatherUtils.getWeatherConditionText(2), '多云');
      expect(WeatherUtils.getWeatherConditionText(3), '多云');
      expect(WeatherUtils.getWeatherConditionText(45), '雾');
      expect(WeatherUtils.getWeatherConditionText(51), '毛毛雨');
      expect(WeatherUtils.getWeatherConditionText(61), '雨');
      expect(WeatherUtils.getWeatherConditionText(71), '雪');
      expect(WeatherUtils.getWeatherConditionText(80), '阵雨');
      expect(WeatherUtils.getWeatherConditionText(95), '雷暴');
      expect(WeatherUtils.getWeatherConditionText(-1), '未知');
      expect(WeatherUtils.getWeatherConditionText(100), '未知');
    });

    test('should check weather types correctly', () {
      expect(WeatherUtils.isClearCode(0), true);
      expect(WeatherUtils.isClearCode(1), false);

      expect(WeatherUtils.isCloudyCode(1), true);
      expect(WeatherUtils.isCloudyCode(0), false);

      expect(WeatherUtils.isRainCode(61), true);
      expect(WeatherUtils.isRainCode(0), false);

      expect(WeatherUtils.isSnowCode(71), true);
      expect(WeatherUtils.isSnowCode(0), false);

      expect(WeatherUtils.isThunderstormCode(95), true);
      expect(WeatherUtils.isThunderstormCode(0), false);

      expect(WeatherUtils.isFoggyCode(45), true);
      expect(WeatherUtils.isFoggyCode(0), false);
    });

    test('should format time correctly', () {
      expect(WeatherUtils.formatHourLabel('2024-01-01T13:00', currentIndex: false), '13:00');
      expect(WeatherUtils.formatHourLabel('2024-01-01T10:00', currentIndex: true), 'Now');
      expect(WeatherUtils.formatTimeToHHmm('2024-01-01T06:30'), '06:30');
    });

    test('should format daily label correctly', () {
      expect(WeatherUtils.formatDailyLabel('2024-01-01', index: 0), '今天');
      // Index > 0 should return weekday
      final result = WeatherUtils.formatDailyLabel('2024-01-15', index: 1);
      expect(result.isNotEmpty, true);
    });

    test('should return correct descriptions', () {
      expect(WeatherUtils.getHumidityDescription(20), '干燥');
      expect(WeatherUtils.getHumidityDescription(50), '舒适');
      expect(WeatherUtils.getPressureDescription(1013), '正常');
      expect(WeatherUtils.getWindDescription(3), '微风');
      expect(WeatherUtils.getUVDescription(1), '低');
      expect(WeatherUtils.getVisibilityDescription(10000), '能见度良好');
    });

    test('should format temperature correctly', () {
      expect(WeatherUtils.formatTemperature(25.5), '26°');
      expect(WeatherUtils.formatTemperatureRange(15.0, 25.0), '15° / 25°');
    });

    test('should format wind speed correctly', () {
      expect(WeatherUtils.formatWindSpeed(15.5), '16 km/h');
    });

    test('should format visibility correctly', () {
      expect(WeatherUtils.formatVisibility(500), '500m');
      expect(WeatherUtils.formatVisibility(10000), '10.0km');
    });

    test('should return clothing suggestions', () {
      expect(WeatherUtils.getClothingSuggestion(-5), contains('羽绒服'));
      expect(WeatherUtils.getClothingSuggestion(25), contains('短袖'));
    });

    test('should return travel suggestions', () {
      expect(WeatherUtils.getTravelSuggestion(95, 10), contains('雷暴'));
      expect(WeatherUtils.getTravelSuggestion(61, 10), contains('雨具'));
      expect(WeatherUtils.getTravelSuggestion(0, 10), contains('良好'));
    });
  });
}
