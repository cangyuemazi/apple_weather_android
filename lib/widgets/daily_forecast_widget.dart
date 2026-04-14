import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../utils/date_utils.dart';
import '../utils/theme_utils.dart';
import '../utils/weather_utils.dart';

class DailyForecastWidget extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;
  final TemperatureUnit temperatureUnit;

  const DailyForecastWidget({
    super.key,
    required this.dailyForecasts,
    required this.temperatureUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

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
                temperatureUnit: temperatureUnit,
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
  final TemperatureUnit temperatureUnit;

  const _DailyItem({
    required this.forecast,
    required this.globalMin,
    required this.globalMax,
    required this.temperatureUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
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
          Icon(
            WeatherUtils.getWeatherIcon(forecast.conditionCode),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              TemperatureUtils.formatTemperature(
                forecast.lowTemp,
                unit: temperatureUnit,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TemperatureBar(
              min: forecast.lowTemp,
              max: forecast.highTemp,
              globalMin: globalMin,
              globalMax: globalMax,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              TemperatureUtils.formatTemperature(
                forecast.highTemp,
                unit: temperatureUnit,
              ),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
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
