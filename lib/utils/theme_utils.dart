import 'package:flutter/material.dart';
import 'constants.dart';

/// 主题工具类
class ThemeUtils {
  /// 获取天气背景渐变
  static List<Color> getWeatherGradient(WeatherBackgroundType type) {
    switch (type) {
      case WeatherBackgroundType.clearDay:
        // 晴天白天：蓝色渐变
        return const [
          Color(0xFF4A90D9),
          Color(0xFF87CEEB),
          Color(0xFF5DADE2),
        ];
      case WeatherBackgroundType.clearNight:
        // 晴天夜间：深紫渐变
        return const [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
          Color(0xFF0F3460),
        ];
      case WeatherBackgroundType.cloudy:
        // 多云：灰蓝渐变
        return const [
          Color(0xFF6B8E9B),
          Color(0xFF8BA3B0),
          Color(0xFF9BB5C4),
        ];
      case WeatherBackgroundType.rainy:
        // 雨天：深蓝灰渐变
        return const [
          Color(0xFF3A4A5A),
          Color(0xFF4B5D6E),
          Color(0xFF5D6F7F),
        ];
      case WeatherBackgroundType.snowy:
        // 雪天：浅蓝白渐变
        return const [
          Color(0xFFA8C8E8),
          Color(0xFFC8D8E8),
          Color(0xFFE8F0F8),
        ];
      case WeatherBackgroundType.foggy:
        // 雾天：灰色渐变
        return const [
          Color(0xFF8B9DAF),
          Color(0xFFA3B5C5),
          Color(0xFFB8C8D5),
        ];
      case WeatherBackgroundType.thunderstorm:
        // 雷暴：深灰渐变
        return const [
          Color(0xFF2C3E50),
          Color(0xFF34495E),
          Color(0xFF3D566E),
        ];
      case WeatherBackgroundType.unknown:
        // 默认蓝色渐变
        return const [
          Color(0xFF4A90D9),
          Color(0xFF87CEEB),
          Color(0xFF5DADE2),
        ];
    }
  }

  /// 玻璃拟态卡片样式
  static BoxDecoration glassCardDecoration({
    double borderRadius = 16,
    double blur = 10,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: Colors.white.withValues(alpha: 0.15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 玻璃拟态边框
  static BoxBorder glassCardBorder() {
    return Border.all(
      color: Colors.white.withValues(alpha: 0.3),
      width: 1.5,
    );
  }

  /// 主文字颜色（基于背景亮度）
  static Color getPrimaryTextColor(WeatherBackgroundType type) {
    switch (type) {
      case WeatherBackgroundType.clearNight:
      case WeatherBackgroundType.rainy:
      case WeatherBackgroundType.thunderstorm:
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  /// 次要文字颜色
  static Color getSecondaryTextColor(WeatherBackgroundType type) {
    switch (type) {
      case WeatherBackgroundType.clearNight:
      case WeatherBackgroundType.rainy:
      case WeatherBackgroundType.thunderstorm:
        return Colors.white.withValues(alpha: 0.8);
      default:
        return Colors.white.withValues(alpha: 0.85);
    }
  }

  /// 获取图标颜色
  static Color getIconColor(WeatherBackgroundType type) {
    return Colors.white.withValues(alpha: 0.9);
  }
}
