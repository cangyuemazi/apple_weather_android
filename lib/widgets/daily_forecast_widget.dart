import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/weather_utils.dart';
import '../utils/theme_utils.dart';

/// 逐日预报组件
class DailyForecastWidget extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;

  const DailyForecastWidget({
    super.key,
    required this.dailyForecasts,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 计算温度范围用于温度条
    double globalMin = dailyForecasts.first.lowTemp;
    double globalMax = dailyForecasts.first.highTemp;
    for (final forecast in dailyForecasts) {
      if (forecast.lowTemp < globalMin) globalMin = forecast.lowTemp;
      if (forecast.highTemp > globalMax) globalMax = forecast.highTemp;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.15),
        border: ThemeUtils.glassCardBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7日预报',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyForecasts.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white24,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final forecast = dailyForecasts[index];
              return _DailyItem(
                forecast: forecast,
                globalMin: globalMin,
                globalMax: globalMax,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DailyItem extends StatelessWidget {
  final DailyForecast forecast;
  final double globalMin;
  final double globalMax;

  const _DailyItem({
    required this.forecast,
    required this.globalMin,
    required this.globalMax,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 日期
          SizedBox(
            width: 80,
            child: Text(
              forecast.date,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          // 天气图标
          Icon(
            WeatherUtils.getWeatherIcon(forecast.conditionCode),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          // 低温
          SizedBox(
            width: 40,
            child: Text(
              '${forecast.lowTemp.round()}°',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 温度条
          Expanded(
            child: _TemperatureBar(
              min: forecast.lowTemp,
              max: forecast.highTemp,
              globalMin: globalMin,
              globalMax: globalMax,
            ),
          ),
          const SizedBox(width: 8),
          // 高温
          SizedBox(
            width: 40,
            child: Text(
              '${forecast.highTemp.round()}°',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 温度条
class _TemperatureBar extends StatelessWidget {
  final double min;
  final double max;
  final double globalMin;
  final double globalMax;

  const _TemperatureBar({
    required this.min,
    required this.max,
    required this.globalMin,
    required this.globalMax,
  });

  @override
  Widget build(BuildContext context) {
    final totalRange = globalMax - globalMin;
    if (totalRange == 0) {
      return Container(
        height: 6,
        width: 20,
        decoration: BoxDecoration(
          color: Colors.blue.shade300,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final leftPadding = (min - globalMin) / totalRange;
    final width = (max - min) / totalRange;

    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          // 背景条
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // 温度范围条
          Positioned(
            left: leftPadding.clamp(0.0, 1.0) * 100,
            right: (1.0 - width.clamp(0.0, 1.0) - leftPadding.clamp(0.0, 1.0)) *
                100,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade300,
                    Colors.orange.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
