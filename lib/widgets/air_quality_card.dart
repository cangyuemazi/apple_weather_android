import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/air_quality_model.dart';
import '../utils/theme_utils.dart';

class AirQualityCard extends StatefulWidget {
  final AirQualityData? data;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AirQualityCard({
    super.key,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<AirQualityCard> createState() => _AirQualityCardState();
}

class _AirQualityCardState extends State<AirQualityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.data == null) {
      return _buildLoadingCard();
    }

    if (widget.data != null) {
      return _buildDataCard(widget.data!);
    }

    return _buildErrorCard();
  }

  Widget _buildDataCard(AirQualityData data) {
    final cardColor = _getCardColor(data.aqiValue, data.aqiStandard);

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
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '空气质量',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor.withValues(alpha: 0.3),
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
                            Row(
                              children: [
                                Text(
                                  '${data.aqiValue}',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w300,
                                    color: cardColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.aqiLevelText,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _buildSummaryLine(data),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.76,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 220),
                        turns: _isExpanded ? 0.5 : 0,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildAdvice(data),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  if (data.lastUpdated != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '更新于 ${DateFormat('HH:mm').format(data.lastUpdated!.toLocal())}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: !_isExpanded
                ? const SizedBox.shrink(key: ValueKey('aqi-collapsed'))
                : Padding(
                    key: const ValueKey('aqi-expanded'),
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              label: '主要污染物',
                              value: data.primaryPollutant ?? '暂无',
                            ),
                            _InfoChip(
                              label: '紫外线',
                              value: '${data.uvIndex}',
                            ),
                            _InfoChip(
                              label: '建议',
                              value: _buildRiskTag(data),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                              label: 'O3',
                              value: data.o3.toStringAsFixed(1),
                              unit: 'μg/m³',
                            ),
                            _PollutantItem(
                              label: 'NO2',
                              value: data.no2.toStringAsFixed(1),
                              unit: 'μg/m³',
                            ),
                            _PollutantItem(
                              label: 'SO2',
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.15),
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

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.15),
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
          Text(
            widget.errorMessage ?? '空气质量数据暂时不可用',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onRetry,
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

  String _buildSummaryLine(AirQualityData data) {
    final pollutant = data.primaryPollutant == null
        ? '污染物数据完整'
        : '主要污染物 ${data.primaryPollutant}';
    return '$pollutant，轻点展开查看分项浓度';
  }

  String _buildAdvice(AirQualityData data) {
    final normalizedAqi = _normalizeAqi(data.aqiValue, data.aqiStandard);
    if (normalizedAqi <= 50) {
      return '空气状态稳定，户外活动基本不受影响。';
    }
    if (normalizedAqi <= 100) {
      return '空气略有污染，敏感人群外出时建议适当减少停留时间。';
    }
    if (normalizedAqi <= 150) {
      return '敏感人群尽量减少长时间户外活动，必要时佩戴口罩。';
    }
    if (normalizedAqi <= 200) {
      return '空气污染明显，建议减少户外运动并关闭门窗。';
    }
    if (normalizedAqi <= 300) {
      return '空气质量较差，外出建议佩戴防护口罩，老人儿童尽量留在室内。';
    }
    return '空气污染严重，建议避免外出并开启室内净化设备。';
  }

  String _buildRiskTag(AirQualityData data) {
    final normalizedAqi = _normalizeAqi(data.aqiValue, data.aqiStandard);
    if (normalizedAqi <= 50) {
      return '适宜外出';
    }
    if (normalizedAqi <= 100) {
      return '敏感人群留意';
    }
    if (normalizedAqi <= 150) {
      return '减少久留';
    }
    if (normalizedAqi <= 200) {
      return '减少外出';
    }
    if (normalizedAqi <= 300) {
      return '建议防护';
    }
    return '尽量居家';
  }

  int _normalizeAqi(int aqi, String standard) {
    if (standard == 'EU') {
      return (aqi * 1.5).toInt();
    }
    return aqi;
  }

  Color _getCardColor(int aqi, String standard) {
    final normalizedAqi = _normalizeAqi(aqi, standard);

    if (normalizedAqi <= 50) return Colors.green;
    if (normalizedAqi <= 100) return Colors.yellow.shade700;
    if (normalizedAqi <= 150) return Colors.orange;
    if (normalizedAqi <= 200) return Colors.red;
    if (normalizedAqi <= 300) return Colors.purple;
    return Colors.red.shade900;
  }
}

class _PollutantItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _PollutantItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
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
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
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
