import 'package:intl/intl.dart';

/// 日期工具类
class AppDateUtils {
  /// 格式化日期为年月日
  static String formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MM月dd日').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 获取星期几
  static String getWeekday(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
      return weekdays[dateTime.weekday % 7];
    } catch (e) {
      return '';
    }
  }

  /// 格式化时间为小时分钟
  static String formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 格式化时间为小时
  static String formatHour(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:00').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 获取相对时间描述
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
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 格式化日出时间
  static String formatSunrise(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 格式化日落时间
  static String formatSunset(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
}

/// 温度工具类
class TemperatureUtils {
  /// 格式化温度
  static String formatTemperature(double temperature) {
    return '${temperature.round()}°';
  }

  /// 格式化温度范围
  static String formatTemperatureRange(double min, double max) {
    return '${min.round()}° / ${max.round()}°';
  }

  /// 摄氏度转华氏度
  static double celsiusToFahrenheit(double celsius) {
    return celsius * 9 / 5 + 32;
  }
}

/// 风速工具类
class WindUtils {
  /// 格式化风速
  static String formatWindSpeed(double windSpeed) {
    return '${windSpeed.round()} km/h';
  }

  /// 风力等级
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

/// 能见度工具类
class VisibilityUtils {
  /// 格式化能见度
  static String formatVisibility(double visibility) {
    // visibility 单位为米
    if (visibility < 1000) {
      return '${visibility.round()}m';
    } else {
      return '${(visibility / 1000).toStringAsFixed(1)}km';
    }
  }
}
