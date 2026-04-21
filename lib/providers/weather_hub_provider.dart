library weather_hub_provider;

import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../models/city_search_result.dart';
import '../models/saved_city_weather.dart';
import '../models/weather_model.dart';
import '../repositories/weather_repository.dart';
import '../services/local_weather_cache_service.dart';
import '../services/location_service.dart';
import '../services/weather_api_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class WeatherProvider extends ChangeNotifier {
  static const Duration _cacheRefreshInterval = Duration(minutes: 30);
  static const Duration _cacheRetentionWindow = Duration(hours: 6);

  WeatherProvider({
    WeatherRepository? repository,
    WeatherApiService? weatherApiService,
    LocalWeatherCacheService? cacheService,
  }) : _repository = repository ??
            WeatherRepository(
              weatherApiService: weatherApiService,
              cacheService: cacheService,
            );

  final WeatherRepository _repository;

  WeatherData? _currentLocationWeather;
  final List<SavedCityWeather> _savedCities = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  List<CitySearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchPending = false;
  bool _hasCompletedSearch = false;
  String _currentQuery = '';
  String? _currentLocationName;
  DateTime? _lastUpdated;
  String? _expandedCityId;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;

  Timer? _searchDebounceTimer;
  int _searchRequestId = 0;

  List<SavedCityWeather>? _savedCitiesView;
  List<CitySearchResult>? _searchResultsView;
  SavedCityWeather? _expandedCityCache;
  String? _expandedCityCacheForId;

  void _invalidateSavedCityCaches() {
    _savedCitiesView = null;
    _expandedCityCacheForId = null;
    _expandedCityCache = null;
  }

  void _invalidateSearchResultsCache() {
    _searchResultsView = null;
  }

  WeatherData? get weatherData =>
      _currentLocationWeather ??
      expandedCity?.weatherData ??
      (_savedCities.isNotEmpty ? _savedCities.first.weatherData : null);

  WeatherData? get currentLocationWeather => _currentLocationWeather;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isBusy => _isLoading || _isRefreshing;
  String? get errorMessage => _errorMessage;
  List<CitySearchResult> get searchResults =>
      _searchResultsView ??= List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  bool get isSearchPending => _isSearchPending;
  bool get hasCompletedSearch => _hasCompletedSearch;
  String get currentQuery => _currentQuery;
  String? get currentLocationName => _currentLocationName;
  bool get isUsingCurrentLocation => _currentLocationWeather != null;
  DateTime? get lastUpdated => _lastUpdated;
  TemperatureUnit get temperatureUnit => _temperatureUnit;
  bool get isCacheExpired {
    if (!hasData) {
      return false;
    }
    final now = DateTime.now();
    if (_currentLocationWeather != null) {
      if (_lastUpdated == null ||
          now.difference(_lastUpdated!) > _cacheRefreshInterval) {
        return true;
      }
    }
    for (final city in _savedCities) {
      if (now.difference(city.updatedAt) > _cacheRefreshInterval) {
        return true;
      }
    }
    return false;
  }
  bool get hasData =>
      _currentLocationWeather != null || _savedCities.isNotEmpty;
  bool get hasError => _errorMessage != null;
  List<SavedCityWeather> get savedCities =>
      _savedCitiesView ??= List.unmodifiable(_savedCities);
  String? get expandedCityId => _expandedCityId;

  SavedCityWeather? get expandedCity {
    final id = _expandedCityId;
    if (id == null) {
      return null;
    }
    if (_expandedCityCacheForId == id) {
      return _expandedCityCache;
    }
    SavedCityWeather? found;
    for (final city in _savedCities) {
      if (city.id == id) {
        found = city;
        break;
      }
    }
    _expandedCityCache = found;
    _expandedCityCacheForId = id;
    return found;
  }

  Future<SavedCityWeather> _refreshSavedCity(
      SavedCityWeather cityWeather) async {
    try {
      final weatherData =
          await _repository.fetchWeatherForCity(cityWeather.city);

      return cityWeather.copyWith(
        weatherData: weatherData,
        updatedAt: DateTime.now(),
      );
    } catch (error) {
      debugPrint('WeatherProvider: failed to refresh city - $error');
      return cityWeather;
    }
  }

  void _sortSavedCities() {
    _savedCities.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderCompare != 0) {
        return sortOrderCompare;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void _normalizeSavedCityOrder() {
    for (var index = 0; index < _savedCities.length; index++) {
      _savedCities[index] = _savedCities[index].copyWith(sortOrder: index);
    }
  }

  int get _firstUnpinnedIndex {
    final index = _savedCities.indexWhere((item) => !item.isPinned);
    return index == -1 ? _savedCities.length : index;
  }

  void _upsertSavedCity(
    SavedCityWeather cityWeather, {
    bool moveToGroupFront = true,
  }) {
    final existingIndex =
        _savedCities.indexWhere((item) => item.id == cityWeather.id);

    if (existingIndex >= 0) {
      final existingCity = _savedCities.removeAt(existingIndex);
      cityWeather = cityWeather.copyWith(
        isPinned: existingCity.isPinned,
        sortOrder: existingCity.sortOrder,
      );
    }

    if (moveToGroupFront) {
      final insertIndex = cityWeather.isPinned ? 0 : _firstUnpinnedIndex;
      _savedCities.insert(insertIndex, cityWeather);
    } else {
      _savedCities.add(cityWeather);
      _sortSavedCities();
    }
    _normalizeSavedCityOrder();
    _expandedCityId = cityWeather.id;
    _invalidateSavedCityCaches();
  }

  void _persistState() {
    unawaited(
      _repository.saveCachedState(
        currentLocationWeather: _currentLocationWeather,
        savedCities: _savedCities,
        expandedCityId: _expandedCityId,
        lastUpdated: _lastUpdated,
        temperatureUnit: _temperatureUnit,
      ),
    );
  }

  Future<void> _restoreCachedState() async {
    final cachedState = await _repository.loadCachedState();
    if (cachedState == null) {
      return;
    }

    if (cachedState.lastUpdated != null &&
        DateTime.now().difference(cachedState.lastUpdated!) >
            _cacheRetentionWindow) {
      await _repository.clearCachedState();
      return;
    }

    _currentLocationWeather = cachedState.currentLocationWeather;
    _savedCities
      ..clear()
      ..addAll(cachedState.savedCities);
    _sortSavedCities();
    _normalizeSavedCityOrder();
    _invalidateSavedCityCaches();
    _expandedCityId = cachedState.expandedCityId;
    _lastUpdated = cachedState.lastUpdated;
    _temperatureUnit = cachedState.temperatureUnit;
    _currentLocationName = cachedState.currentLocationWeather?.location;

    if (_expandedCityId != null &&
        !_savedCities.any((item) => item.id == _expandedCityId)) {
      _expandedCityId = _savedCities.isEmpty ? null : _savedCities.first.id;
    }

    if (hasData) {
      notifyListeners();
    }
  }

  String _mapErrorToMessage(Object error) {
    debugPrint('WeatherProvider: caught error - ${error.runtimeType}: $error');

    if (error is LocationServiceDisabledException) {
      return 'Location services are disabled.';
    }

    if (error is LocationPermissionPermanentlyDeniedException) {
      return 'Location permission is permanently denied.';
    }

    if (error is LocationPermissionDeniedException) {
      return 'Location permission is required to load local weather.';
    }

    if (error is LocationServiceException) {
      return error.message;
    }

    if (error is CityNotFoundException) {
      return 'No city found for "${error.keyword}".';
    }

    if (error is InvalidResponseException) {
      return 'The weather response format was invalid.';
    }

    if (error is WeatherApiException) {
      final message = error.message.toLowerCase();
      if (message.contains('socket') ||
          message.contains('network') ||
          message.contains('connection')) {
        return 'Network connection failed.';
      }
      if (message.contains('timeout')) {
        return 'The request timed out.';
      }
      return error.message;
    }

    return 'Failed to load weather: $error';
  }

  Future<void> init() async {
    await _restoreCachedState();
    if (hasData) {
      if (isCacheExpired) {
        unawaited(refreshWeather());
      }
      return;
    }
    await loadCurrentLocationWeather();
  }

  Future<void> loadCurrentLocationWeather({bool showLoading = true}) async {
    if (isBusy) {
      return;
    }

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final weatherData = await _repository.fetchCurrentLocationWeather();
      _currentLocationWeather = weatherData;
      _currentLocationName = weatherData.location;
      _lastUpdated = DateTime.now();
      _persistState();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadWeatherByCity(String city, {bool showLoading = true}) async {
    if (isBusy) {
      _errorMessage = 'A weather update is already in progress.';
      notifyListeners();
      return;
    }

    if (city.trim().isEmpty) {
      _errorMessage = 'City name cannot be empty.';
      notifyListeners();
      return;
    }

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final results = await _repository.searchCity(city.trim());
      if (results.isEmpty) {
        throw CityNotFoundException(city.trim());
      }

      final cityResult = results.first;
      final weatherData = await _repository.fetchWeatherForCity(cityResult);

      _upsertSavedCity(
        SavedCityWeather(
          city: cityResult,
          weatherData: weatherData,
          updatedAt: DateTime.now(),
        ),
      );
      _lastUpdated = DateTime.now();
      _persistState();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> addCity(
    CitySearchResult city, {
    bool showLoading = true,
  }) async {
    if (isBusy) {
      _errorMessage = 'A weather update is already in progress.';
      notifyListeners();
      return false;
    }

    final isNewCity =
        !_savedCities.any((item) => item.id == SavedCityWeather.buildId(city));

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = null;
    }

    try {
      final weatherData = await _repository.fetchWeatherForCity(city);

      _upsertSavedCity(
        SavedCityWeather(
          city: city,
          weatherData: weatherData,
          updatedAt: DateTime.now(),
        ),
      );
      _searchResults = [];
    _invalidateSearchResultsCache();
      _currentQuery = '';
      _isSearching = false;
      _isSearchPending = false;
      _hasCompletedSearch = false;
      _lastUpdated = DateTime.now();
      _persistState();
      return isNewCity;
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
      return false;
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> selectCity(CitySearchResult city) {
    return addCity(city);
  }

  bool hasSavedCity(CitySearchResult city) {
    final cityId = SavedCityWeather.buildId(city);
    return _savedCities.any((item) => item.id == cityId);
  }

  void setTemperatureUnit(TemperatureUnit temperatureUnit) {
    if (_temperatureUnit == temperatureUnit) {
      return;
    }

    _temperatureUnit = temperatureUnit;
    _persistState();
    notifyListeners();
  }

  void toggleCityExpanded(String cityId) {
    _expandedCityId = _expandedCityId == cityId ? null : cityId;
    _persistState();
    notifyListeners();
  }

  bool toggleCityPinned(String cityId) {
    final index = _savedCities.indexWhere((item) => item.id == cityId);
    if (index < 0) {
      return false;
    }

    final cityWeather = _savedCities.removeAt(index);
    final updatedCity = cityWeather.copyWith(
      isPinned: !cityWeather.isPinned,
      updatedAt: DateTime.now(),
    );
    final insertIndex = updatedCity.isPinned ? 0 : _firstUnpinnedIndex;
    _savedCities.insert(insertIndex, updatedCity);
    _normalizeSavedCityOrder();
    _expandedCityId = cityId;
    _invalidateSavedCityCaches();
    _persistState();
    notifyListeners();
    return updatedCity.isPinned;
  }

  bool reorderSavedCities(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _savedCities.length ||
        newIndex < 0 ||
        newIndex >= _savedCities.length) {
      return false;
    }

    final movingCity = _savedCities[oldIndex];
    if (oldIndex == newIndex) {
      return false;
    }

    final targetCity = _savedCities[newIndex];
    if (movingCity.isPinned != targetCity.isPinned) {
      return false;
    }

    final item = _savedCities.removeAt(oldIndex);
    _savedCities.insert(newIndex, item);
    _normalizeSavedCityOrder();
    _invalidateSavedCityCaches();
    _persistState();
    notifyListeners();
    return true;
  }

  bool removeCity(String cityId) {
    final index = _savedCities.indexWhere((item) => item.id == cityId);
    if (index < 0) {
      return false;
    }

    _savedCities.removeAt(index);

    if (_expandedCityId == cityId) {
      _expandedCityId = _savedCities.isEmpty ? null : _savedCities.first.id;
    }

    if (!hasData) {
      _lastUpdated = null;
    }
    _invalidateSavedCityCaches();
    _persistState();
    notifyListeners();
    return true;
  }

  SavedCityWeather? removeCityAndReturn(String cityId) {
    final index = _savedCities.indexWhere((item) => item.id == cityId);
    if (index < 0) {
      return null;
    }

    final removedCity = _savedCities.removeAt(index);

    if (_expandedCityId == cityId) {
      _expandedCityId = _savedCities.isEmpty ? null : _savedCities.first.id;
    }

    if (!hasData) {
      _lastUpdated = null;
    }
    _invalidateSavedCityCaches();
    _persistState();
    notifyListeners();
    return removedCity;
  }

  void restoreRemovedCity(SavedCityWeather cityWeather) {
    _upsertSavedCity(cityWeather, moveToGroupFront: false);
    _lastUpdated ??= cityWeather.updatedAt;
    _persistState();
    notifyListeners();
  }

  Future<void> refreshWeather() async {
    if (_isRefreshing || _isLoading) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    Object? currentLocationError;

    try {
      final currentLocationTask = _currentLocationWeather == null
          ? Future<WeatherData?>.value(null)
          : () async {
              try {
                return await _repository.fetchCurrentLocationWeather();
              } catch (error) {
                currentLocationError = error;
                return null;
              }
            }();

      final savedCitiesTask = Future.wait(_savedCities.map(_refreshSavedCity));

      final refreshedCurrentLocation = await currentLocationTask;
      final refreshedCities = await savedCitiesTask;

      if (refreshedCurrentLocation != null) {
        _currentLocationWeather = refreshedCurrentLocation;
        _currentLocationName = refreshedCurrentLocation.location;
      }

      _savedCities
        ..clear()
        ..addAll(refreshedCities);
      _invalidateSavedCityCaches();

      if (currentLocationError != null) {
        _errorMessage = _mapErrorToMessage(currentLocationError!);
      }

      _lastUpdated = DateTime.now();
      _persistState();
    } catch (error) {
      _errorMessage = _mapErrorToMessage(error);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> searchCity(String keyword) async {
    final requestId = ++_searchRequestId;
    _searchResults = [];
    _invalidateSearchResultsCache();

    if (keyword.trim().isEmpty) {
      _currentQuery = '';
      _isSearching = false;
      _isSearchPending = false;
      _hasCompletedSearch = false;
      notifyListeners();
      return;
    }

    _isSearchPending = false;
    _isSearching = true;
    _hasCompletedSearch = false;
    _currentQuery = keyword;
    notifyListeners();

    try {
      final results = await _repository.searchCity(keyword.trim());
      if (requestId != _searchRequestId || keyword != _currentQuery) {
        return;
      }
      _searchResults = results;
      _invalidateSearchResultsCache();
    } catch (_) {
      if (requestId == _searchRequestId) {
        _searchResults = [];
        _invalidateSearchResultsCache();
      }
    } finally {
      if (requestId == _searchRequestId) {
        _isSearching = false;
        _hasCompletedSearch = true;
        notifyListeners();
      }
    }
  }

  void debounceSearch(String keyword) {
    _currentQuery = keyword;
    _searchDebounceTimer?.cancel();

    if (keyword.trim().isEmpty) {
      _searchRequestId++;
      _searchResults = [];
      _invalidateSearchResultsCache();
      _isSearching = false;
      _isSearchPending = false;
      _hasCompletedSearch = false;
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _searchResults = [];
    _invalidateSearchResultsCache();
    _isSearching = false;
    _isSearchPending = true;
    _hasCompletedSearch = false;
    notifyListeners();

    _searchDebounceTimer = Timer(
      AppConstants.searchDebounce,
      () => searchCity(keyword),
    );
  }

  void clearSearchResults() {
    _searchDebounceTimer?.cancel();
    _searchRequestId++;
    _searchResults = [];
    _invalidateSearchResultsCache();
    _isSearching = false;
    _isSearchPending = false;
    _hasCompletedSearch = false;
    _currentQuery = '';
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchRequestId++;
    _repository.dispose();
    super.dispose();
  }
}
