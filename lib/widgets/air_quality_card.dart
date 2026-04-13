import 'package:flutter/material.dart';
import '../models/air_quality_model.dart';
import '../utils/theme_utils.dart';

/// 空气质量卡片组件
class AirQualityCard extends StatelessWidget {
  final AirQualityData? data;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AirQualityCard({
    Key? key,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 加载中状态
    if (isLoading && data == null) {
      return _buildLoadingCard();
    }

    // 有数据状态
    if (data != null) {
      return _buildDataCard(data!);
    }

    // 错误状态
    return _buildErrorCard();
  }

  /// 构建数据卡片
  Widget _buildDataCard(AirQualityData data) {
    // 根据 AQI 决定卡片颜色
    final cardColor = _getCardColor(data.aqiValue, data.aqiStandard);

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
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '空气质量',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // AQI 标准标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data.aqiStandard} AQI',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AQI 数值和等级
          Row(
            children: [
              // 大号 AQI 数值
              Text(
                '${data.aqiValue}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: cardColor,
                ),
              ),
              const SizedBox(width: 12),
              // 等级文案
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.aqiLevelText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (data.primaryPollutant != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '主污染物: ${data.primaryPollutant}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 污染物网格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: [
              _PollutantItem(
                label: 'PM2.5',
                value: data.pm25.toStringAsFixed(1),
                unit: 'μg/m³',
              ),
              _PollutantItem(
                label: 'PM10',
                value: data.pm10.toStringAsFixed(1),
                unit: 'μg/m³',
              ),
              _PollutantItem(
                label: 'O₃',
                value: data.o3.toStringAsFixed(1),
                unit: 'μg/m³',
              ),
              _PollutantItem(
                label: 'NO₂',
                value: data.no2.toStringAsFixed(1),
                unit: 'μg/m³',
              ),
              _PollutantItem(
                label: 'SO₂',
                value: data.so2.toStringAsFixed(1),
                unit: 'μg/m³',
              ),
              _PollutantItem(
                label: 'CO',
                value: data.co.toStringAsFixed(1),
                unit: 'μg/m³',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 加载中的卡片
  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.15),
        border: ThemeUtils.glassCardBorder(),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      ),
    );
  }

  /// 错误卡片
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.15),
        border: ThemeUtils.glassCardBorder(),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.air,
            size: 32,
            color: Colors.white54,
          ),
          const SizedBox(height: 8),
          const Text(
            '空气质量数据不可用',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 根据 AQI 获取卡片颜色
  Color _getCardColor(int aqi, String standard) {
    int normalizedAqi = aqi;

    // 如果是 EU AQI,转换到近似 US AQI 范围
    if (standard == 'EU') {
      normalizedAqi = (aqi * 1.5).toInt();
    }

    if (normalizedAqi <= 50) return Colors.green;
    if (normalizedAqi <= 100) return Colors.yellow.shade700;
    if (normalizedAqi <= 150) return Colors.orange;
    if (normalizedAqi <= 200) return Colors.red;
    if (normalizedAqi <= 300) return Colors.purple;
    return Colors.red.shade900;
  }
}

/// 污染物小项
class _PollutantItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _PollutantItem({
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
