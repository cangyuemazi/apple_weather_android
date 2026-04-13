import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/date_utils.dart';
import '../utils/weather_utils.dart';
import '../utils/theme_utils.dart';

/// 天气详情网格
class WeatherDetailsGrid extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherDetailsGrid({
    Key? key,
    required this.weatherData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            '天气详情',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _DetailItem(
                icon: Icons.water_drop,
                label: '湿度',
                value: '${weatherData.humidity}%',
                description:
                    WeatherUtils.getHumidityDescription(weatherData.humidity),
              ),
              _DetailItem(
                icon: Icons.air,
                label: '气压',
                value: '${weatherData.pressure} hPa',
                description:
                    WeatherUtils.getPressureDescription(weatherData.pressure),
              ),
              _DetailItem(
                icon: Icons.visibility,
                label: '能见度',
                value: VisibilityUtils.formatVisibility(weatherData.visibility),
                description: WeatherUtils.getVisibilityDescription(
                    weatherData.visibility),
              ),
              _DetailItem(
                icon: Icons.wb_sunny,
                label: 'UV指数',
                value: '${weatherData.uvIndex}',
                description: WeatherUtils.getUVDescription(weatherData.uvIndex),
              ),
              _DetailItem(
                icon: Icons.air,
                label: '风速',
                value: WindUtils.formatWindSpeed(weatherData.windSpeed),
                description:
                    WeatherUtils.getWindDescription(weatherData.windSpeed),
              ),
              _DetailItem(
                icon: Icons.thermostat,
                label: '体感温度',
                value:
                    TemperatureUtils.formatTemperature(weatherData.feelsLike),
                description: '实际感受温度',
              ),
              _DetailItem(
                icon: Icons.wb_sunny_outlined,
                label: '日出',
                value: AppDateUtils.formatSunrise(weatherData.sunrise),
                description: '今日日出',
              ),
              _DetailItem(
                icon: Icons.nights_stay,
                label: '日落',
                value: AppDateUtils.formatSunset(weatherData.sunset),
                description: '今日日落',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String description;

  const _DetailItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
