import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../utils/date_utils.dart';
import '../utils/theme_utils.dart';
import '../utils/weather_utils.dart' as weather_utils;

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weatherData;
  final TemperatureUnit temperatureUnit;

  const CurrentWeatherCard({
    super.key,
    required this.weatherData,
    required this.temperatureUnit,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundType = weather_utils.WeatherUtils.getBackgroundType(
      weatherData.conditionCode,
      weatherData.isDayTime,
    );
    final textColor = ThemeUtils.getPrimaryTextColor(backgroundType);
    final secondaryColor = ThemeUtils.getSecondaryTextColor(backgroundType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.15),
        border: ThemeUtils.glassCardBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weatherData.location,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weatherData.condition,
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TemperatureUtils.formatTemperature(
                  weatherData.temperature,
                  unit: temperatureUnit,
                ),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: textColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  TemperatureUtils.formatTemperatureRange(
                    weatherData.lowTemp,
                    weatherData.highTemp,
                    unit: temperatureUnit,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    color: secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '体感温度 ${TemperatureUtils.formatTemperature(weatherData.feelsLike, unit: temperatureUnit)}',
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
