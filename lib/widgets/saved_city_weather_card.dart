import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/saved_city_weather.dart';
import '../utils/date_utils.dart';
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
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final TemperatureUnit temperatureUnit;
  final Widget? dragHandle;

  const SavedCityWeatherCard({
    super.key,
    required this.cityWeather,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onTogglePin,
    required this.temperatureUnit,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final weatherData = cityWeather.weatherData;
    final now = DateTime.now();
    final isSameDay = now.year == cityWeather.updatedAt.year &&
        now.month == cityWeather.updatedAt.month &&
        now.day == cityWeather.updatedAt.day;
    final updatedAtLabel = DateFormat(
      isSameDay ? 'HH:mm' : 'MM-dd HH:mm',
    ).format(cityWeather.updatedAt);

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
                if (cityWeather.isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.push_pin,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '已置顶',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (dragHandle != null) ...[
                  dragHandle!,
                  const SizedBox(width: 8),
                ],
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
                        '更新于 $updatedAtLabel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'H:${TemperatureUtils.formatTemperature(weatherData.highTemp, unit: temperatureUnit)}  L:${TemperatureUtils.formatTemperature(weatherData.lowTemp, unit: temperatureUnit)}',
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
                      TemperatureUtils.formatTemperature(
                        weatherData.temperature,
                        unit: temperatureUnit,
                      ),
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
                          value: TemperatureUtils.formatTemperature(
                            weatherData.feelsLike,
                            unit: temperatureUnit,
                          ),
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
                        temperatureUnit: temperatureUnit,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (weatherData.dailyForecast.isNotEmpty) ...[
                      DailyForecastWidget(
                        dailyForecasts: weatherData.dailyForecast,
                        temperatureUnit: temperatureUnit,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AirQualityCard(data: weatherData.airQuality),
                    const SizedBox(height: 16),
                    WeatherDetailsGrid(
                      weatherData: weatherData,
                      temperatureUnit: temperatureUnit,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onTogglePin,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          cityWeather.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                        ),
                        label: Text(cityWeather.isPinned ? '取消置顶' : '置顶城市'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.withValues(alpha: 0.22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('删除城市'),
                      ),
                    ),
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
