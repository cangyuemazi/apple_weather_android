import 'package:intl/intl.dart';

enum TemperatureUnit {
  celsius,
  fahrenheit;

  String get cacheValue => name;
  String get label => this == TemperatureUnit.celsius ? '℃' : '℉';

  static TemperatureUnit fromCacheValue(String? value) {
    return TemperatureUnit.values.firstWhere(
      (unit) => unit.cacheValue == value,
      orElse: () => TemperatureUnit.celsius,
    );
  }
}

class AppDateUtils {
  static String formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MM月dd日').format(dateTime);
    } catch (_) {
      return dateTimeStr;
    }
  }

  static String getWeekday(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[dateTime.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  static String formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return '--:--';
    }
  }

  static String formatHour(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:00').format(dateTime);
    } catch (_) {
      return dateTimeStr;
    }
  }

  static String formatDailyLabel(String dateStr, {int index = 0}) {
    if (index == 0) {
      return '今天';
    }

    try {
      final dateTime = DateTime.parse(dateStr);
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[dateTime.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  static String getRelativeTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.inHours == 0) {
        return '现在';
      } else if (difference.inHours == 1) {
        return '1小时后';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时后';
      } else if (difference.inDays == 1) {
        return '明天';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天后';
      } else {
        return formatDate(dateTimeStr);
      }
    } catch (_) {
      return dateTimeStr;
    }
  }

  static String formatHourLabel(
    String dateTimeStr, {
    bool currentIndex = false,
  }) {
    if (currentIndex) {
      return 'Now';
    }

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return dateTimeStr;
    }
  }

  static String formatSunrise(String dateTimeStr) {
    return formatTime(dateTimeStr);
  }

  static String formatSunset(String dateTimeStr) {
    return formatTime(dateTimeStr);
  }
}

class TemperatureUtils {
  static double convertTemperature(
    double temperature,
    TemperatureUnit unit,
  ) {
    if (unit == TemperatureUnit.fahrenheit) {
      return celsiusToFahrenheit(temperature);
    }
    return temperature;
  }

  static String formatTemperature(
    double temperature, {
    TemperatureUnit unit = TemperatureUnit.celsius,
  }) {
    final converted = convertTemperature(temperature, unit).round();
    return unit == TemperatureUnit.celsius
        ? '$converted°'
        : '$converted°F';
  }

  static String formatTemperatureRange(
    double min,
    double max, {
    TemperatureUnit unit = TemperatureUnit.celsius,
  }) {
    final formattedMin = formatTemperature(min, unit: unit);
    final formattedMax = formatTemperature(max, unit: unit);
    return '$formattedMin / $formattedMax';
  }

  static double celsiusToFahrenheit(double celsius) {
    return celsius * 9 / 5 + 32;
  }
}

class WindUtils {
  static String formatWindSpeed(double windSpeed) {
    return '${windSpeed.round()} km/h';
  }

  static String getWindLevel(double windSpeed) {
    if (windSpeed < 5) {
      return '0级';
    } else if (windSpeed < 15) {
      return '1-2级';
    } else if (windSpeed < 30) {
      return '3-4级';
    } else if (windSpeed < 50) {
      return '5-6级';
    } else {
      return '7级以上';
    }
  }
}

class VisibilityUtils {
  static String formatVisibility(double visibility) {
    if (visibility < 1000) {
      return '${visibility.round()}m';
    } else {
      return '${(visibility / 1000).toStringAsFixed(1)}km';
    }
  }
}
