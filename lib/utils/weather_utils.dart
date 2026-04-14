import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/date_utils.dart';

class WeatherUtils {
  static String getWeatherConditionText(int code) {
    if (code == 0) return '晴';
    if (code >= 1 && code <= 3) return '多云';
    if (code == 45 || code == 48) return '雾';
    if (code >= 51 && code <= 55) return '毛毛雨';
    if (code >= 56 && code <= 57) return '冻毛毛雨';
    if (code >= 61 && code <= 65) return '雨';
    if (code >= 66 && code <= 67) return '冻雨';
    if (code >= 71 && code <= 75) return '雪';
    if (code >= 80 && code <= 82) return '阵雨';
    if (code >= 85 && code <= 86) return '阵雪';
    if (code >= 95 && code <= 99) return '雷暴';
    return '未知';
  }

  static IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 57) return Icons.water_drop;
    if (code >= 61 && code <= 67) return Icons.water_drop;
    if (code >= 71 && code <= 75) return Icons.ac_unit;
    if (code >= 80 && code <= 86) return Icons.grain;
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.cloud;
  }

  static bool isRainCode(int code) {
    return (code >= 51 && code <= 55) ||
        (code >= 61 && code <= 65) ||
        (code >= 80 && code <= 82);
  }

  static bool isSnowCode(int code) {
    return (code >= 71 && code <= 75) || (code >= 85 && code <= 86);
  }

  static bool isCloudyCode(int code) {
    return code >= 1 && code <= 3;
  }

  static bool isClearCode(int code) {
    return code == 0;
  }

  static bool isFoggyCode(int code) {
    return code == 45 || code == 48;
  }

  static bool isThunderstormCode(int code) {
    return code >= 95 && code <= 99;
  }

  static WeatherBackgroundType getBackgroundType(int code, bool isDayTime) {
    if (code == 0) {
      return isDayTime
          ? WeatherBackgroundType.clearDay
          : WeatherBackgroundType.clearNight;
    }
    if (code >= 1 && code <= 3) {
      return WeatherBackgroundType.cloudy;
    }
    if (code == 45 || code == 48) {
      return WeatherBackgroundType.foggy;
    }
    if (isRainCode(code)) {
      return WeatherBackgroundType.rainy;
    }
    if (isSnowCode(code)) {
      return WeatherBackgroundType.snowy;
    }
    if (isThunderstormCode(code)) {
      return WeatherBackgroundType.thunderstorm;
    }
    return WeatherBackgroundType.unknown;
  }

  static String formatTimeToHHmm(String dateTimeStr) {
    return AppDateUtils.formatTime(dateTimeStr);
  }

  static String formatHourLabel(
    String dateTimeStr, {
    bool currentIndex = false,
  }) {
    return AppDateUtils.formatHourLabel(
      dateTimeStr,
      currentIndex: currentIndex,
    );
  }

  static String formatDailyLabel(String dateStr, {int index = 0}) {
    return AppDateUtils.formatDailyLabel(dateStr, index: index);
  }

  static String formatTemperature(double temperature) {
    return TemperatureUtils.formatTemperature(temperature);
  }

  static String formatTemperatureRange(double min, double max) {
    return TemperatureUtils.formatTemperatureRange(min, max);
  }

  static String formatWindSpeed(double windSpeed) {
    return WindUtils.formatWindSpeed(windSpeed);
  }

  static String formatVisibility(double visibility) {
    return VisibilityUtils.formatVisibility(visibility);
  }

  static String getHumidityDescription(int humidity) {
    if (humidity < 30) return '干燥';
    if (humidity < 60) return '舒适';
    if (humidity < 80) return '潮湿';
    return '非常潮湿';
  }

  static String getPressureDescription(int pressure) {
    if (pressure < 1000) return '低气压';
    if (pressure < 1020) return '正常';
    return '高气压';
  }

  static String getWindDescription(double windSpeed) {
    if (windSpeed < 5) return '微风';
    if (windSpeed < 15) return '轻风';
    if (windSpeed < 30) return '中风';
    if (windSpeed < 50) return '强风';
    return '大风';
  }

  static String getUVDescription(int uvIndex) {
    if (uvIndex <= 2) return '低';
    if (uvIndex <= 5) return '中等';
    if (uvIndex <= 7) return '高';
    if (uvIndex <= 10) return '很高';
    return '极高';
  }

  static String getVisibilityDescription(double visibility) {
    if (visibility < 1000) return '能见度极低';
    if (visibility < 5000) return '能见度较低';
    if (visibility < 10000) return '能见度一般';
    return '能见度良好';
  }

  static String getClothingSuggestion(double temperature) {
    if (temperature < 0) return '极寒天气，请穿羽绒服并注意保暖';
    if (temperature < 10) return '天气较冷，建议穿厚外套或毛衣';
    if (temperature < 20) return '温度适中，建议穿长袖衬衫或薄外套';
    if (temperature < 30) return '天气温暖，适合穿短袖或薄衣物';
    return '天气炎热，请穿轻薄衣物并注意防晒';
  }

  static String getTravelSuggestion(int weatherCode, double windSpeed) {
    if (isThunderstormCode(weatherCode)) return '雷暴天气，建议减少外出';
    if (isSnowCode(weatherCode)) return '雨雪天气，出行请注意安全';
    if (isRainCode(weatherCode)) return '雨天出行，请携带雨具';
    if (windSpeed > 30) return '风力较大，注意防风';
    return '天气良好，适合出行';
  }
}
