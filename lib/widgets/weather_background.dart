import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/constants.dart';
import '../utils/theme_utils.dart';
import '../utils/weather_utils.dart' as weather_utils;

/// 天气背景组件
class WeatherBackground extends StatelessWidget {
  final WeatherData? weatherData;
  final Widget child;

  const WeatherBackground({
    Key? key,
    required this.weatherData,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据天气数据获取背景类型
    final backgroundType = weatherData != null
        ? weather_utils.WeatherUtils.getBackgroundType(
            weatherData!.conditionCode,
            weatherData!.isDayTime,
          )
        : WeatherBackgroundType.clearDay;

    // 获取渐变颜色
    final gradient = ThemeUtils.getWeatherGradient(backgroundType);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
