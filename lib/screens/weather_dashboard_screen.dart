import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/city_search_result.dart';
import '../models/saved_city_weather.dart';
import '../models/weather_model.dart';
import '../providers/weather_hub_provider.dart';
import '../utils/date_utils.dart';
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
  final ValueNotifier<bool> _showSearch = ValueNotifier<bool>(false);

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return '刚刚';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    }

    if (difference.inHours < 24 &&
        now.year == lastUpdated.year &&
        now.month == lastUpdated.month &&
        now.day == lastUpdated.day) {
      return '今天 ${DateFormat('HH:mm').format(lastUpdated)}';
    }

    return DateFormat('MM-dd HH:mm').format(lastUpdated);
  }

  Widget _buildRefreshStatus(WeatherProvider provider) {
    if (provider.lastUpdated == null && !provider.isRefreshing) {
      return const SizedBox.shrink();
    }

    final isExpired = provider.isCacheExpired;
    final icon = provider.isRefreshing
        ? Icons.sync
        : isExpired
            ? Icons.history
            : Icons.check_circle_outline;
    final message = provider.isRefreshing
        ? '正在刷新天气数据...'
        : provider.lastUpdated == null
            ? '暂无缓存时间'
            : isExpired
                ? '缓存已过期，当前显示 ${_formatLastUpdated(provider.lastUpdated!)} 的数据'
                : '最后更新 ${_formatLastUpdated(provider.lastUpdated!)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            (isExpired ? Colors.amber : Colors.white).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              (isExpired ? Colors.amber : Colors.white).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _showSearch.dispose();
    super.dispose();
  }

  void _closeSearch(WeatherProvider provider) {
    _showSearch.value = false;
    _searchController.clear();
    provider.clearSearchResults();
  }

  Future<void> _handleSearchSelect(
    WeatherProvider provider,
    CitySearchResult result,
  ) async {
    final isNew = await provider.selectCity(result);
    if (!mounted) {
      return;
    }

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
              ? '已将 ${result.displayName} 添加到首页'
              : '已更新 ${result.displayName} 并置顶显示',
        ),
      ),
    );
  }

  Future<void> _handleDeleteCity(
    WeatherProvider provider,
    String cityId,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除城市'),
          content: Text('确定要从卡片列表中移除 $displayName 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final removedCity = provider.removeCityAndReturn(cityId);
    if (removedCity == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.78),
        action: SnackBarAction(
          label: '撤销',
          textColor: Colors.white,
          onPressed: () => provider.restoreRemovedCity(removedCity),
        ),
        content: Text('已删除 $displayName'),
      ),
    );
  }

  void _handleTogglePin(
    WeatherProvider provider,
    String cityId,
    String displayName,
  ) {
    final pinned = provider.toggleCityPinned(cityId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.78),
        content: Text(pinned ? '已置顶 $displayName' : '已取消置顶 $displayName'),
      ),
    );
  }

  void _handleReorderSavedCities(
    WeatherProvider provider,
    int oldIndex,
    int newIndex,
  ) {
    final normalizedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = provider.reorderSavedCities(oldIndex, normalizedNewIndex);
    if (moved) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.78),
        content: const Text('置顶城市和普通城市分组排序，暂不支持跨组拖动。'),
      ),
    );
  }

  Widget _buildAppBar(WeatherProvider provider) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showSearch,
      builder: (context, showSearch, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!showSearch) ..._buildAppBarDefault(provider)
              else ..._buildAppBarSearch(provider),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAppBarDefault(WeatherProvider provider) {
    return [
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
                        ? '搜索城市后会以卡片形式加入首页'
                        : '已添加 ${provider.savedCities.length} 个城市卡片',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<TemperatureUnit>(
              tooltip: '切换温标',
              icon: Text(
                provider.temperatureUnit.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onSelected: provider.setTemperatureUnit,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TemperatureUnit.celsius,
                  child: Text('摄氏度 ℃'),
                ),
                const PopupMenuItem(
                  value: TemperatureUnit.fahrenheit,
                  child: Text('华氏度 ℉'),
                ),
              ],
            ),
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () => _showSearch.value = true,
      ),
      IconButton(
        icon: const Icon(Icons.my_location, color: Colors.white),
        onPressed: provider.isBusy
            ? null
            : () => provider.loadCurrentLocationWeather(),
      ),
      IconButton(
        icon: Icon(
          Icons.refresh,
          color: Colors.white.withValues(alpha: 0.84),
        ),
        onPressed: provider.isBusy ? null : () => provider.refreshWeather(),
      ),
    ];
  }

  List<Widget> _buildAppBarSearch(WeatherProvider provider) {
    return [
      Expanded(
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '搜索城市并添加到首页...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.84),
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearchResults();
                  },
                );
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
          onChanged: provider.debounceSearch,
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => _closeSearch(provider),
      ),
    ];
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
    return ValueListenableBuilder<bool>(
      valueListenable: _showSearch,
      builder: (context, showSearch, _) {
        final shouldShowPanel = showSearch &&
            (_searchController.text.trim().isNotEmpty ||
                provider.isSearchPending ||
                provider.isSearching ||
                provider.searchResults.isNotEmpty);

        if (!shouldShowPanel) {
          return const SizedBox.shrink();
        }

        return _buildSearchResultsPanel(provider);
      },
    );
  }

  Widget _buildSearchResultsPanel(WeatherProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: provider.isSearchPending || provider.isSearching
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : provider.hasCompletedSearch && provider.searchResults.isEmpty
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
                      _SearchResultTile(
                        key: ValueKey(
                          'search-result-${SavedCityWeather.buildId(result)}',
                        ),
                        result: result,
                        isSaved: provider.hasSavedCity(result),
                        isBusy: provider.isBusy,
                        onTap: () => _handleSearchSelect(provider, result),
                      ),
                  ],
                ),
    );
  }

  List<Widget> _buildLocationSection(
    WeatherData weatherData,
    TemperatureUnit temperatureUnit,
  ) {
    return [
      _buildSectionHeader(
        '我的位置',
        '定位天气固定在最上方，作为主页主卡片展示',
        icon: Icons.near_me,
      ),
      CurrentWeatherCard(
        weatherData: weatherData,
        temperatureUnit: temperatureUnit,
      ),
      const SizedBox(height: 16),
      AirQualityCard(data: weatherData.airQuality),
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
      WeatherDetailsGrid(
        weatherData: weatherData,
        temperatureUnit: temperatureUnit,
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildSavedCitiesSection(WeatherProvider provider) {
    return [
      _buildSectionHeader(
        '城市卡片',
        provider.savedCities.isEmpty
            ? '搜索任意城市后，这里会以折叠卡片形式展示'
            : '轻点卡片即可展开，长按右侧手柄可调整同组顺序',
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
        ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.savedCities.length,
          onReorder: (oldIndex, newIndex) =>
              _handleReorderSavedCities(provider, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final cityWeather = provider.savedCities[index];
            return Padding(
              key: ValueKey('saved-city-${cityWeather.id}'),
              padding: const EdgeInsets.only(bottom: 16),
              child: SavedCityWeatherCard(
                cityWeather: cityWeather,
                isExpanded: provider.expandedCityId == cityWeather.id,
                onToggle: () => provider.toggleCityExpanded(cityWeather.id),
                onTogglePin: () => _handleTogglePin(
                  provider,
                  cityWeather.id,
                  cityWeather.displayName,
                ),
                onDelete: () => _handleDeleteCity(
                  provider,
                  cityWeather.id,
                  cityWeather.displayName,
                ),
                temperatureUnit: provider.temperatureUnit,
                dragHandle: ReorderableDelayedDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: cityWeather.isPinned ? '拖动调整置顶城市顺序' : '拖动调整城市顺序',
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
                              _buildRefreshStatus(provider),
                              if (provider.currentLocationWeather != null)
                                ..._buildLocationSection(
                                  provider.currentLocationWeather!,
                                  provider.temperatureUnit,
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    super.key,
    required this.result,
    required this.isSaved,
    required this.isBusy,
    required this.onTap,
  });

  final CitySearchResult result;
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        isSaved ? Icons.bookmark_added_rounded : Icons.location_on,
        color: isSaved ? Colors.green : Colors.blue,
      ),
      title: Text(
        result.displayName,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isSaved ? '已保存，点击后会刷新并置顶' : (result.country ?? ''),
      ),
      trailing: Icon(
        isSaved ? Icons.refresh_rounded : Icons.add_circle_outline,
        color: isSaved ? Colors.green : Colors.black54,
      ),
      onTap: isBusy ? null : onTap,
    );
  }
}
