import 'package:apple_weather_android/models/air_quality_model.dart';
import 'package:apple_weather_android/widgets/air_quality_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AirQualityCard', () {
    testWidgets('expands to show pollutant details', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final data = AirQualityData(
        aqiValue: 118,
        aqiStandard: 'US',
        aqiLevelText: 'Moderate',
        primaryPollutant: 'PM2.5',
        pm25: 35.2,
        pm10: 56.8,
        no2: 14.3,
        o3: 41.6,
        so2: 3.2,
        co: 220,
        uvIndex: 5,
        lastUpdated: DateTime.parse('2026-04-14T10:00:00Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [AirQualityCard(data: data)],
            ),
          ),
        ),
      );

      expect(find.text('空气质量'), findsOneWidget);
      expect(find.text('主要污染物 PM2.5，轻点展开查看分项浓度'), findsOneWidget);
      expect(find.text('μg/m³'), findsNothing);

      await tester.tap(find.text('空气质量'));
      await tester.pumpAndSettle();

      expect(find.text('PM2.5'), findsWidgets);
      expect(find.text('35.2'), findsOneWidget);
      expect(find.text('220.0'), findsOneWidget);
      expect(find.text('μg/m³'), findsNWidgets(6));
    });
  });
}
