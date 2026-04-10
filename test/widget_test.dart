import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:apple_weather_android/main.dart';
import 'package:apple_weather_android/providers/weather_provider.dart';

void main() {
  testWidgets('App should render without crashing', (WidgetTester tester) async {
    // 构建应用
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WeatherProvider(),
        child: const MyApp(),
      ),
    );

    // 验证应用能够正常渲染
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
