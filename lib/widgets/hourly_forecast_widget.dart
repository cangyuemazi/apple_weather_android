import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../utils/date_utils.dart';
import '../utils/theme_utils.dart';
import '../utils/weather_utils.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;
  final TemperatureUnit temperatureUnit;

  const HourlyForecastWidget({
    super.key,
    required this.hourlyForecasts,
    required this.temperatureUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyForecasts.isEmpty) {
      return const SizedBox.shrink();
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
            '逐小时预报',
            style: TextStyle(
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
                return _HourlyItem(
                  forecast: forecast,
                  temperatureUnit: temperatureUnit,
                );
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
  final TemperatureUnit temperatureUnit;

  const _HourlyItem({
    required this.forecast,
    required this.temperatureUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            forecast.time,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              WeatherUtils.getWeatherIcon(forecast.conditionCode),
              color: Colors.white,
              size: 24,
            ),
          ),
          Text(
            TemperatureUtils.formatTemperature(
              forecast.temperature,
              unit: temperatureUnit,
            ),
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
}
