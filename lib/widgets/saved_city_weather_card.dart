import 'package:flutter/material.dart';

import '../models/saved_city_weather.dart';
import '../utils/theme_utils.dart';
import '../utils/weather_utils.dart';
import 'air_quality_card.dart';
import 'daily_forecast_widget.dart';
import 'hourly_forecast_widget.dart';
import 'weather_details_grid.dart';

class SavedCityWeatherCard extends StatelessWidget {
  final SavedCityWeather cityWeather;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SavedCityWeatherCard({
    super.key,
    required this.cityWeather,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final weatherData = cityWeather.weatherData;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: isExpanded ? 0.22 : 0.16),
        border: ThemeUtils.glassCardBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onToggle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_city,
                        color: Colors.white70,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '已添加城市',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: isExpanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weatherData.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weatherData.condition,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'H:${weatherData.highTemp.round()}°  L:${weatherData.lowTemp.round()}°',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      WeatherUtils.getWeatherIcon(weatherData.conditionCode),
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${weatherData.temperature.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w200,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          label: '体感',
                          value: '${weatherData.feelsLike.round()}°',
                        ),
                        _InfoChip(
                          label: '湿度',
                          value: '${weatherData.humidity}%',
                        ),
                        _InfoChip(
                          label: '风速',
                          value: WeatherUtils.formatWindSpeed(
                            weatherData.windSpeed,
                          ),
                        ),
                        _InfoChip(
                          label: 'AQI',
                          value: weatherData.airQuality == null
                              ? '--'
                              : '${weatherData.airQuality!.aqiValue}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (weatherData.hourlyForecast.isNotEmpty) ...[
                      HourlyForecastWidget(
                        hourlyForecasts: weatherData.hourlyForecast,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (weatherData.dailyForecast.isNotEmpty) ...[
                      DailyForecastWidget(
                        dailyForecasts: weatherData.dailyForecast,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AirQualityCard(data: weatherData.airQuality),
                    const SizedBox(height: 16),
                    WeatherDetailsGrid(weatherData: weatherData),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
