# Apple Weather Android

A Flutter weather app inspired by Apple Weather, using the Open-Meteo forecast, geocoding, and air-quality APIs.

## Features

- Current-location weather as the primary dashboard card
- City search with debounce and add-to-dashboard flow
- Saved city cards with expand/collapse interactions
- Pinning and drag reordering inside pinned and unpinned groups
- Air quality, hourly forecast, daily forecast, and weather detail panels
- Pull-to-refresh and manual refresh actions
- Local cache for dashboard state, expanded card, and temperature unit
- Automatic refresh of stale cached data on startup
- Delete with undo for saved city cards

## Tech Stack

- Flutter 3.x
- Dart 3.x
- Provider
- `http`
- `geolocator`
- `permission_handler`
- `shared_preferences`
- Open-Meteo APIs

## Project Structure

```text
lib/
|-- main.dart
|-- models/
|   |-- air_quality_model.dart
|   |-- city_search_result.dart
|   |-- saved_city_weather.dart
|   `-- weather_model.dart
|-- providers/
|   `-- weather_hub_provider.dart
|-- repositories/
|   `-- weather_repository.dart
|-- screens/
|   `-- weather_dashboard_screen.dart
|-- services/
|   |-- local_weather_cache_service.dart
|   |-- location_service.dart
|   `-- weather_api_service.dart
|-- utils/
|   |-- constants.dart
|   |-- date_utils.dart
|   |-- theme_utils.dart
|   `-- weather_utils.dart
`-- widgets/
    |-- air_quality_card.dart
    |-- current_weather_card.dart
    |-- daily_forecast_widget.dart
    |-- error_view.dart
    |-- hourly_forecast_widget.dart
    |-- loading_view.dart
    |-- saved_city_weather_card.dart
    |-- search_bar_widget.dart
    |-- weather_background.dart
    `-- weather_details_grid.dart
```

## Getting Started

```bash
flutter pub get
flutter run
```

## Validation

```bash
flutter analyze
flutter test
```

Current test coverage includes repository behavior, provider state transitions, cache persistence, widget rendering, and air-quality card presentation.

## Android Permissions

The app requests:

- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

## Architecture Notes

- `WeatherDashboardScreen` is the active entry screen.
- `WeatherProvider` in `weather_hub_provider.dart` owns dashboard state and user interactions.
- `WeatherRepository` coordinates Open-Meteo requests, current-location lookup, and cached state persistence.
- Weather and air-quality requests are fetched as a bundle, with AQI failure falling back to weather-only data.
- Cached state is restored on startup and refreshed automatically when it becomes stale.
