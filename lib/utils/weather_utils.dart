/// 天气工具类
/// 提供天气代码映射、时间格式化等纯工具函数

import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// 天气工具类
///
/// 提供以下功能:
/// - 天气代码映射为中文文案
/// - 天气类型判断 (雨/雪/多云/晴等)
/// - 时间格式化 (小时、日出日落、日期标签等)
class WeatherUtils {
  /// 根据 WMO 天气代码获取中文天气描述
  ///
  /// [code] WMO 天气代码
  /// 返回对应的中文天气描述
  ///
  /// 映射规则:
  /// - 0: 晴
  /// - 1-3: 多云
  /// - 45, 48: 雾
  /// - 51-55: 毛毛雨
  /// - 61-65: 雨
  /// - 71-75: 雪
  /// - 80-82: 阵雨
  /// - 95-99: 雷暴
  /// - 其他: 未知
  static String getWeatherConditionText(int code) {
    if (code == 0) return '晴';
    if (code >= 1 && code <= 3) return '多云';
    if (code == 45 || code == 48) return '雾';
    if (code >= 51 && code <= 55) return '毛毛雨';
    if (code >= 61 && code <= 65) return '雨';
    if (code >= 71 && code <= 75) return '雪';
    if (code >= 80 && code <= 82) return '阵雨';
    if (code >= 95 && code <= 99) return '雷暴';
    return '未知';
  }

  /// 判断是否为雨天代码
  ///
  /// [code] WMO 天气代码
  /// 返回是否为雨天
  static bool isRainCode(int code) {
    return (code >= 51 && code <= 55) || // 毛毛雨
        (code >= 61 && code <= 65) || // 雨
        (code >= 80 && code <= 82); // 阵雨
  }

  /// 判断是否为雪天代码
  ///
  /// [code] WMO 天气代码
  /// 返回是否为雪天
  static bool isSnowCode(int code) {
    return code >= 71 && code <= 75;
  }

  /// 判断是否为多云代码
  ///
  /// [code] WMO 天气代码
  /// 返回是否为多云
  static bool isCloudyCode(int code) {
    return code >= 1 && code <= 3;
  }

  /// 判断是否为晴天代码
  ///
  /// [code] WMO 天气代码
  /// 返回是否为晴天
  static bool isClearCode(int code) {
    return code == 0;
  }

  /// 判断是否为雾天代码
  ///
  /// [code] WMO 天气代码
  /// 返回是否为雾天
  static bool isFoggyCode(int code) {
    return code == 45 || code == 48;
  }

  /// 判断是否为雷暴代码
  ///
  /// [code] WMO 天气代码
  /// 返回是否为雷暴
  static bool isThunderstormCode(int code) {
    return code >= 95 && code <= 99;
  }

  /// 根据天气代码和是否白天获取背景类型
  ///
  /// [code] WMO 天气代码
  /// [isDayTime] 是否为白天
  /// 返回对应的背景类型
  static WeatherBackgroundType getBackgroundType(int code, bool isDayTime) {
    if (code == 0) {
      return isDayTime ? WeatherBackgroundType.clearDay : WeatherBackgroundType.clearNight;
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

  /// 格式化小时标签
  ///
  /// [dateTimeStr] ISO 8601 格式的时间字符串
  /// [currentIndex] 是否为当前小时 (用于显示 "Now")
  /// 返回格式化后的小时标签
  ///
  /// 格式:
  /// - 当前小时: "Now"
  /// - 其他小时: "HH:mm"
  static String formatHourLabel(String dateTimeStr, {bool currentIndex = false}) {
    if (currentIndex) {
      return 'Now';
    }

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      // 解析失败时返回原始字符串
      return dateTimeStr;
    }
  }

  /// 格式化时间为 HH:mm 格式
  ///
  /// [dateTimeStr] ISO 8601 格式的时间字符串
  /// 返回 HH:mm 格式的时间字符串
  static String formatTimeToHHmm(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      // 解析失败时返回默认值
      return '--:--';
    }
  }

  /// 格式化逐日预报日期标签
  ///
  /// [dateStr] ISO 8601 格式的日期字符串 (例如 "2024-01-15")
  /// [index] 日期索引 (0 表示今天)
  /// 返回格式化后的日期标签
  ///
  /// 格式:
  /// - index == 0: "今天"
  /// - index > 0: 星期几 (例如 "周一", "周二")
  static String formatDailyLabel(String dateStr, {int index = 0}) {
    if (index == 0) {
      return '今天';
    }

    try {
      final dateTime = DateTime.parse(dateStr);
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      // DateTime.weekday: 1 = Monday, 7 = Sunday
      return weekdays[dateTime.weekday - 1];
    } catch (e) {
      // 解析失败时返回原始字符串
      return dateStr;
    }
  }

  /// 获取星期几
  ///
  /// [dateStr] ISO 8601 格式的日期字符串
  /// 返回星期几的中文表示
  static String getWeekday(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[dateTime.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  /// 格式化日期为 MM月dd日
  ///
  /// [dateStr] ISO 8601 格式的日期字符串
  /// 返回格式化后的日期字符串
  static String formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('MM月dd日').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  /// 格式化温度
  ///
  /// [temperature] 温度值 (°C)
  /// 返回带单位的温度字符串
  static String formatTemperature(double temperature) {
    return '${temperature.round()}°';
  }

  /// 格式化温度范围
  ///
  /// [min] 最低温度
  /// [max] 最高温度
  /// 返回温度范围字符串 (例如 "15° / 25°")
  static String formatTemperatureRange(double min, double max) {
    return '${min.round()}° / ${max.round()}°';
  }

  /// 格式化风速
  ///
  /// [windSpeed] 风速值 (km/h)
  /// 返回带单位的风速字符串
  static String formatWindSpeed(double windSpeed) {
    return '${windSpeed.round()} km/h';
  }

  /// 格式化能见度
  ///
  /// [visibility] 能见度值 (米)
  /// 返回格式化后的能见度字符串
  static String formatVisibility(double visibility) {
    if (visibility < 1000) {
      return '${visibility.round()}m';
    } else {
      return '${(visibility / 1000).toStringAsFixed(1)}km';
    }
  }

  /// 湿度描述
  ///
  /// [humidity] 湿度百分比
  /// 返回湿度描述
  static String getHumidityDescription(int humidity) {
    if (humidity < 30) return '干燥';
    if (humidity < 60) return '舒适';
    if (humidity < 80) return '潮湿';
    return '非常潮湿';
  }

  /// 气压描述
  ///
  /// [pressure] 气压值 (hPa)
  /// 返回气压描述
  static String getPressureDescription(int pressure) {
    if (pressure < 1000) return '低气压';
    if (pressure < 1020) return '正常';
    return '高气压';
  }

  /// 风速描述
  ///
  /// [windSpeed] 风速值 (km/h)
  /// 返回风速描述
  static String getWindDescription(double windSpeed) {
    if (windSpeed < 5) return '微风';
    if (windSpeed < 15) return '轻风';
    if (windSpeed < 30) return '中风';
    if (windSpeed < 50) return '强风';
    return '大风';
  }

  /// UV 指数描述
  ///
  /// [uvIndex] UV 指数
  /// 返回 UV 等级描述
  static String getUVDescription(int uvIndex) {
    if (uvIndex <= 2) return '低';
    if (uvIndex <= 5) return '中等';
    if (uvIndex <= 7) return '高';
    if (uvIndex <= 10) return '很高';
    return '极高';
  }

  /// 能见度描述
  ///
  /// [visibility] 能见度值 (米)
  /// 返回能见度描述
  static String getVisibilityDescription(double visibility) {
    if (visibility < 1000) return '能见度极低';
    if (visibility < 5000) return '能见度较低';
    if (visibility < 10000) return '能见度一般';
    return '能见度良好';
  }

  /// 穿衣建议
  ///
  /// [temperature] 温度值 (°C)
  /// 返回穿衣建议
  static String getClothingSuggestion(double temperature) {
    if (temperature < 0) return '极寒天气,请穿羽绒服并注意保暖';
    if (temperature < 10) return '天气较冷,建议穿厚外套或毛衣';
    if (temperature < 20) return '温度适中,建议穿长袖衬衫或薄外套';
    if (temperature < 30) return '天气温暖,适合穿短袖或薄衣物';
    return '天气炎热,请穿轻薄衣物并注意防晒';
  }

  /// 出行建议
  ///
  /// [weatherCode] WMO 天气代码
  /// [windSpeed] 风速值 (km/h)
  /// 返回出行建议
  static String getTravelSuggestion(int weatherCode, double windSpeed) {
    if (isThunderstormCode(weatherCode)) return '雷暴天气,建议减少外出';
    if (isSnowCode(weatherCode)) return '雨雪天气,出行请注意安全';
    if (isRainCode(weatherCode)) return '雨天出行,请携带雨具';
    if (windSpeed > 30) return '风力较大,注意防风';
    return '天气良好,适合出行';
  }
}
