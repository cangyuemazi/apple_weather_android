import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/date_utils.dart';
import '../utils/weather_utils.dart';
import '../utils/theme_utils.dart';

/// 逐小时预报组件
class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;

  const HourlyForecastWidget({
    Key? key,
    required this.hourlyForecasts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hourlyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.15),
        border: ThemeUtils.glassCardBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '逐小时预报',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourlyForecasts.length,
              itemBuilder: (context, index) {
                final forecast = hourlyForecasts[index];
                return _HourlyItem(forecast: forecast);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyItem extends StatelessWidget {
  final HourlyForecast forecast;

  const _HourlyItem({
    Key? key,
    required this.forecast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 时间
          Text(
            AppDateUtils.formatHour(forecast.time),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          // 天气图标占位
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(forecast.conditionCode),
              color: Colors.white,
              size: 24,
            ),
          ),
          // 温度
          Text(
            '${forecast.temperature.round()}°',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.cloud;
    if (code >= 51 && code <= 65) return Icons.water_drop;
    if (code >= 71 && code <= 75) return Icons.ac_unit;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.cloud;
  }
}
