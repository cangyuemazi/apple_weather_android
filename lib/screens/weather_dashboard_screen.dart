import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/city_search_result.dart';
import '../models/weather_model.dart';
import '../providers/weather_hub_provider.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/daily_forecast_widget.dart';
import '../widgets/error_view.dart';
import '../widgets/hourly_forecast_widget.dart';
import '../widgets/loading_view.dart';
import '../widgets/saved_city_weather_card.dart';
import '../widgets/weather_background.dart';
import '../widgets/weather_details_grid.dart';

class WeatherDashboardScreen extends StatefulWidget {
  const WeatherDashboardScreen({super.key});

  @override
  State<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends State<WeatherDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeSearch(WeatherProvider provider) {
    setState(() {
      _showSearch = false;
    });
    _searchController.clear();
    provider.clearSearchResults();
  }

  Future<void> _handleSearchSelect(
    WeatherProvider provider,
    CitySearchResult result,
  ) async {
    final isNew = await provider.selectCity(result);
    if (!mounted) return;

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.withValues(alpha: 0.82),
          content: Text(provider.errorMessage!),
        ),
      );
      return;
    }

    _closeSearch(provider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.78),
        content: Text(
          isNew
              ? '已将 ${result.displayName} 添加到前台'
              : '已更新 ${result.displayName} 并置顶显示',
        ),
      ),
    );
  }

  Widget _buildAppBar(WeatherProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!_showSearch) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '天气',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.savedCities.isEmpty
                        ? '搜索城市后会像苹果天气一样以卡片加入首页'
                        : '已添加 ${provider.savedCities.length} 个城市卡片',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSearch = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () => provider.loadCurrentLocationWeather(),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white.withValues(alpha: 0.84),
              ),
              onPressed: provider.isRefreshing
                  ? null
                  : () => provider.refreshWeather(),
            ),
          ] else ...[
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '搜索城市并添加到前台...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            provider.clearSearchResults();
                            setState(() {});
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.44),
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  provider.debounceSearch(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => _closeSearch(provider),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(WeatherProvider provider) {
    final shouldShowPanel = _showSearch &&
        (_searchController.text.trim().isNotEmpty ||
            provider.isSearching ||
            provider.searchResults.isNotEmpty);

    if (!shouldShowPanel) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: provider.isSearching
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : provider.searchResults.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '没有找到匹配城市，请换个名称再试试。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final result in provider.searchResults)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                        title: Text(
                          result.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(result.country ?? ''),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.black54,
                        ),
                        onTap: () => _handleSearchSelect(provider, result),
                      ),
                  ],
                ),
    );
  }

  List<Widget> _buildLocationSection(WeatherData weatherData) {
    return [
      _buildSectionHeader(
        '我的位置',
        '定位天气固定在最上方，作为主页主卡片展示',
        icon: Icons.near_me,
      ),
      CurrentWeatherCard(weatherData: weatherData),
      const SizedBox(height: 16),
      AirQualityCard(data: weatherData.airQuality),
      const SizedBox(height: 16),
      if (weatherData.hourlyForecast.isNotEmpty) ...[
        HourlyForecastWidget(hourlyForecasts: weatherData.hourlyForecast),
        const SizedBox(height: 16),
      ],
      if (weatherData.dailyForecast.isNotEmpty) ...[
        DailyForecastWidget(dailyForecasts: weatherData.dailyForecast),
        const SizedBox(height: 16),
      ],
      WeatherDetailsGrid(weatherData: weatherData),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildSavedCitiesSection(WeatherProvider provider) {
    return [
      _buildSectionHeader(
        '城市卡片',
        provider.savedCities.isEmpty
            ? '搜索任意城市后，这里会以折叠卡片形式展示'
            : '轻点卡片即可展开，查看更完整的天气细节',
        icon: Icons.view_carousel_outlined,
      ),
      if (provider.savedCities.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.add_location_alt_outlined,
                color: Colors.white70,
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                '还没有添加城市',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '点右上角搜索，输入城市名后就会把天气卡片加入首页。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        )
      else
        ...provider.savedCities.map(
          (cityWeather) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SavedCityWeatherCard(
              cityWeather: cityWeather,
              isExpanded: provider.expandedCityId == cityWeather.id,
              onToggle: () => provider.toggleCityExpanded(cityWeather.id),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Selector<WeatherProvider, WeatherData?>(
        selector: (_, provider) => provider.weatherData,
        builder: (context, weatherData, child) {
          return WeatherBackground(
            weatherData: weatherData,
            child: SafeArea(
              child: Consumer<WeatherProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && !provider.isRefreshing) {
                    return Column(
                      children: [
                        _buildAppBar(provider),
                        const Expanded(
                          child: LoadingView(message: '正在整理天气卡片...'),
                        ),
                      ],
                    );
                  }

                  if (provider.hasError && !provider.hasData) {
                    return Column(
                      children: [
                        _buildAppBar(provider),
                        Expanded(
                          child: ErrorView(
                            message: provider.errorMessage ?? '加载天气失败',
                            onRetry: () =>
                                provider.loadCurrentLocationWeather(),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildAppBar(provider),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: provider.refreshWeather,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (provider.hasError && provider.hasData) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          provider.errorMessage ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              _buildSearchResults(provider),
                              if (provider.currentLocationWeather != null)
                                ..._buildLocationSection(
                                  provider.currentLocationWeather!,
                                ),
                              ..._buildSavedCitiesSection(provider),
                              if (!provider.hasData) ...[
                                const SizedBox(height: 100),
                                const EmptyView(message: '暂无天气数据'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
