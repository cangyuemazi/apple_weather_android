import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../models/city_search_result.dart';
import '../widgets/weather_background.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/hourly_forecast_widget.dart';
import '../widgets/daily_forecast_widget.dart';
import '../widgets/weather_details_grid.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/search_bar_widget.dart';

/// 主屏幕
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Selector<WeatherProvider, WeatherData?>(
        selector: (_, provider) => provider.weatherData,
        builder: (context, weatherData, child) {
          return WeatherBackground(
            weatherData: weatherData,
            child: SafeArea(
              child: Column(
                children: [
                  // 顶部栏 - 只监听搜索状态
                  Selector<WeatherProvider, bool>(
                    selector: (_, provider) =>
                        provider.isSearching || _showSearch,
                    builder: (context, isSearching, child) {
                      return _buildAppBar(context);
                    },
                  ),
                  // 主内容区域
                  Expanded(
                    child: _buildBody(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 顶部栏
  Widget _buildAppBar(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!_showSearch) ...[
            // 定位按钮
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                provider.loadCurrentLocationWeather();
              },
            ),
            const SizedBox(width: 8),
            // 城市名称
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showSearch = true;
                  });
                },
                child: Text(
                  provider.weatherData?.location ?? '天气',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // 刷新按钮
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white.withOpacity(0.8),
              ),
              onPressed: provider.isRefreshing
                  ? null
                  : () {
                      provider.refreshWeather();
                    },
            ),
          ] else ...[
            // 搜索模式
            Expanded(
              child: SearchBarWidget(
                onSearch: (keyword) {
                  provider.debounceSearch(keyword);
                },
                onSelect: (CitySearchResult result) {
                  provider.selectCity(result);
                  setState(() {
                    _showSearch = false;
                  });
                },
                searchResults: provider.searchResults,
                isSearching: provider.isSearching,
              ),
            ),
            const SizedBox(width: 8),
            // 关闭搜索
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSearch = false;
                });
                provider.clearSearchResults();
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 主内容
  Widget _buildBody(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        // 加载中状态
        if (provider.isLoading && !provider.isRefreshing) {
          return const LoadingView(message: '正在获取天气数据...');
        }

        // 错误状态（无数据时）
        if (provider.hasError && !provider.hasData) {
          return ErrorView(
            message: provider.errorMessage ?? '加载失败',
            onRetry: () {
              provider.loadCurrentLocationWeather();
            },
          );
        }

        // 有数据或正在刷新
        return RefreshIndicator(
          onRefresh: () => provider.refreshWeather(),
          color: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 错误提示（有数据时显示）
              if (provider.hasError && provider.hasData) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 当前天气卡片
              if (provider.weatherData != null) ...[
                CurrentWeatherCard(weatherData: provider.weatherData!),
                const SizedBox(height: 16),

                // 空气质量卡片
                AirQualityCard(
                  data: provider.weatherData!.airQuality,
                  isLoading: provider.isRefreshing,
                ),
                const SizedBox(height: 16),

                // 逐小时预报
                if (provider.weatherData!.hourlyForecast.isNotEmpty) ...[
                  HourlyForecastWidget(
                    hourlyForecasts: provider.weatherData!.hourlyForecast,
                  ),
                  const SizedBox(height: 16),
                ],

                // 逐日预报
                if (provider.weatherData!.dailyForecast.isNotEmpty) ...[
                  DailyForecastWidget(
                    dailyForecasts: provider.weatherData!.dailyForecast,
                  ),
                  const SizedBox(height: 16),
                ],

                // 天气详情
                WeatherDetailsGrid(weatherData: provider.weatherData!),
                const SizedBox(height: 16),
              ],

              // 空状态
              if (!provider.hasData) ...[
                const SizedBox(height: 100),
                const EmptyView(message: '暂无天气数据'),
              ],
            ],
          ),
        );
      },
    );
  }
}
