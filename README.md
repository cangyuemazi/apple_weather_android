# Apple Weather Android

[English](#english) · [中文](#中文) · [日本語](#日本語)

A Flutter weather application inspired by Apple Weather, powered by the free Open-Meteo forecast, geocoding, and air-quality APIs. No API keys required.

---

## English

### Overview

Apple Weather Android is a cross-platform Flutter client that reproduces the information architecture of Apple's stock Weather app. It centers on a **current-location card** at the top of the dashboard, followed by a **stack of user-added city cards** that can be expanded, pinned, reordered, and deleted. All state is persisted locally so the app restores the last-seen dashboard instantly on relaunch.

### Features

| Category | Capability |
| --- | --- |
| **Location** | GPS-based current location with permission handling; graceful fallback to a default city on web |
| **Search** | Debounced geocoding search (Open-Meteo Geocoding API), with duplicate detection for already-saved cities |
| **Dashboard** | Current weather, hourly forecast, daily forecast, air quality, and six-tile weather detail grid |
| **City cards** | Expand/collapse, pin to top group, drag-to-reorder within same pin group, delete with undo snackbar |
| **Persistence** | `SharedPreferences`-backed cache for weather data, expanded card, temperature unit, and last-update time |
| **Refresh** | Pull-to-refresh, manual refresh button, and auto-refresh of stale data (> 30 min) on startup |
| **Units** | Toggle between Celsius and Fahrenheit from the AppBar popup menu |
| **Error handling** | Inline error banners for partial failures, full-screen error view with retry for total failures |

### Tech Stack

- **Framework**: Flutter 3.x (Dart 3.x)
- **State management**: `provider` (`ChangeNotifier` + `Selector`/`Consumer`)
- **HTTP**: `http` package
- **Location**: `geolocator` + `permission_handler`
- **Persistence**: `shared_preferences`
- **i18n**: `intl` for date formatting
- **APIs** (all free, no key required):
  - Forecast: `https://api.open-meteo.com/v1`
  - Geocoding: `https://geocoding-api.open-meteo.com/v1`
  - Air Quality: `https://air-quality-api.open-meteo.com/v1`

### Project Structure

```text
lib/
├── main.dart                          # App entry, Provider wiring
├── models/
│   ├── air_quality_model.dart         # AQI + pollutant levels
│   ├── city_search_result.dart        # Geocoding response item
│   ├── saved_city_weather.dart        # Saved city + weather bundle
│   └── weather_model.dart             # Core weather data models
├── providers/
│   └── weather_hub_provider.dart      # Dashboard state owner
├── repositories/
│   └── weather_repository.dart        # API + cache coordinator
├── screens/
│   └── weather_dashboard_screen.dart  # Main dashboard UI
├── services/
│   ├── local_weather_cache_service.dart  # SharedPreferences wrapper
│   ├── location_service.dart             # Geolocator + permissions
│   └── weather_api_service.dart          # Open-Meteo HTTP client
├── utils/
│   ├── constants.dart                 # App-wide constants
│   ├── date_utils.dart                # Temperature unit, date helpers
│   ├── theme_utils.dart               # Weather-based theming
│   └── weather_utils.dart             # Unit conversion, code mapping
└── widgets/
    ├── air_quality_card.dart
    ├── current_weather_card.dart
    ├── daily_forecast_widget.dart
    ├── error_view.dart
    ├── hourly_forecast_widget.dart
    ├── loading_view.dart
    ├── saved_city_weather_card.dart
    ├── search_bar_widget.dart
    ├── weather_background.dart
    └── weather_details_grid.dart
```

### Getting Started

#### Prerequisites

- Flutter SDK **>= 3.10** (Dart **>= 3.0**)
- Android Studio / Xcode for device emulation
- `flutter doctor` passing for your target platform

#### Install & Run

```bash
flutter pub get
flutter run
```

Select a target from `flutter devices` (Android emulator, physical device, Chrome, Windows desktop, etc.).

#### Validation

```bash
flutter analyze
flutter test
```

Current test suite (47 tests) covers:

- `weather_model_test.dart` — JSON parsing and unit conversion
- `weather_repository_test.dart` — API/cache coordination, AQI fallback
- `weather_hub_provider_test.dart` — state transitions, pin/reorder/undo flows
- `local_weather_cache_service_test.dart` — round-trip persistence
- `weather_dashboard_screen_test.dart` — widget interactions (reorder, search, pin, delete-undo)
- `air_quality_card_test.dart` — AQI presentation
- `widget_test.dart` — smoke test

> **Note for local proxies (common in mainland China):** if you have a global `HTTP_PROXY` set, `flutter test` may fail with `Invalid WebSocket upgrade request`. Fix by exempting the loopback address:
>
> ```powershell
> $env:NO_PROXY = "127.0.0.1,localhost,::1"
> flutter test
> ```

### Android Permissions

Declared in `android/app/src/main/AndroidManifest.xml`:

- `INTERNET` — API calls
- `ACCESS_NETWORK_STATE` — network reachability
- `ACCESS_FINE_LOCATION` — GPS location
- `ACCESS_COARSE_LOCATION` — network-based location fallback

### Architecture Notes

- `WeatherDashboardScreen` is the single active screen; older `HomeScreen` code has been removed.
- `WeatherProvider` (in `weather_hub_provider.dart`) owns:
  - Current-location weather
  - List of saved cities (pinned-first, index-sorted)
  - Search state (debounced, request-id guarded)
  - Expanded card id, temperature unit, last-updated timestamp
- `WeatherRepository` bundles weather + air-quality requests in parallel; AQI failures are logged and fall back to weather-only data.
- State cache has a **6-hour retention window** and a **30-minute refresh interval** for auto-refresh triggers.
- `isCacheExpired` checks per-city `updatedAt` so a freshly added city does not mask stale ones.
- Search is debounced via `Timer` with a request-id pattern that invalidates stale responses; `dispose()` bumps the id so in-flight responses never call `notifyListeners` on a disposed provider.
- The dashboard uses `ValueNotifier<bool>` for the search-mode toggle so that opening the search box does not rebuild the entire saved-city list.

### Performance Optimizations

Recent passes applied:

1. Removed redundant `setState(() {})` calls in the search text field.
2. Scoped the search toggle to `ValueListenableBuilder` regions instead of a screen-wide `setState`.
3. Cached `savedCities` / `searchResults` / `expandedCity` getters to avoid per-build allocations.
4. Deduplicated `indexWhere` calls in pin/reorder hot paths.
5. Dropped redundant sort/normalize during refresh (order is preserved by `_refreshSavedCity`).
6. Made `isCacheExpired` per-city aware.
7. `AQI` request failures are now logged rather than silently swallowed.
8. Search-result list uses `ValueKey`s so Flutter can reuse widgets across queries.

### License

This project is provided as-is for educational and personal use.

---

## 中文

### 项目简介

Apple Weather Android 是一个使用 Flutter 开发的跨平台天气客户端,复刻了苹果系统自带"天气"App 的信息架构。顶部展示**当前定位卡片**,下方是**用户添加的城市卡片列表**,支持展开/折叠、置顶、同组内拖动排序、删除后撤销等操作。所有状态本地持久化,重启后瞬间还原上次的看板视图。

### 功能特性

| 分类 | 能力 |
| --- | --- |
| **定位** | 基于 GPS 获取当前位置并处理权限;Web 平台降级到默认城市 |
| **搜索** | 基于 Open-Meteo 地理编码 API 的防抖搜索,识别并标记已保存城市 |
| **看板** | 当前天气、24 小时预报、7 天预报、空气质量、6 宫格天气详情 |
| **城市卡片** | 展开/折叠、置顶到顶部分组、同组内拖动排序、删除后 Snackbar 撤销 |
| **持久化** | 基于 `SharedPreferences` 缓存天气数据、展开状态、温标、最后更新时间 |
| **刷新** | 下拉刷新、手动刷新按钮、启动时检测到过期(> 30 分钟)自动刷新 |
| **单位** | AppBar 弹出菜单中切换摄氏/华氏 |
| **错误处理** | 部分失败时顶部错误条、完全失败时全屏错误页并提供重试 |

### 技术栈

- **框架**: Flutter 3.x(Dart 3.x)
- **状态管理**: `provider`(`ChangeNotifier` + `Selector`/`Consumer`)
- **HTTP**: `http`
- **定位**: `geolocator` + `permission_handler`
- **持久化**: `shared_preferences`
- **国际化**: `intl`(日期格式化)
- **API**(全部免费,无需申请 Key):
  - 天气预报: `https://api.open-meteo.com/v1`
  - 地理编码: `https://geocoding-api.open-meteo.com/v1`
  - 空气质量: `https://air-quality-api.open-meteo.com/v1`

### 项目结构

```text
lib/
├── main.dart                          # 应用入口、Provider 装配
├── models/
│   ├── air_quality_model.dart         # AQI 和污染物模型
│   ├── city_search_result.dart        # 地理编码结果
│   ├── saved_city_weather.dart        # 保存的城市 + 天气组合
│   └── weather_model.dart             # 核心天气数据模型
├── providers/
│   └── weather_hub_provider.dart      # 看板状态核心
├── repositories/
│   └── weather_repository.dart        # API 和缓存协调层
├── screens/
│   └── weather_dashboard_screen.dart  # 主看板界面
├── services/
│   ├── local_weather_cache_service.dart  # SharedPreferences 封装
│   ├── location_service.dart             # 定位和权限封装
│   └── weather_api_service.dart          # Open-Meteo HTTP 客户端
├── utils/
│   ├── constants.dart                 # 应用常量
│   ├── date_utils.dart                # 温标、日期工具
│   ├── theme_utils.dart               # 基于天气的主题
│   └── weather_utils.dart             # 单位换算、天气码映射
└── widgets/
    ├── air_quality_card.dart
    ├── current_weather_card.dart
    ├── daily_forecast_widget.dart
    ├── error_view.dart
    ├── hourly_forecast_widget.dart
    ├── loading_view.dart
    ├── saved_city_weather_card.dart
    ├── search_bar_widget.dart
    ├── weather_background.dart
    └── weather_details_grid.dart
```

### 快速开始

#### 环境要求

- Flutter SDK **>= 3.10**(Dart **>= 3.0**)
- Android Studio / Xcode 模拟器
- `flutter doctor` 在目标平台无报错

#### 安装与运行

```bash
flutter pub get
flutter run
```

用 `flutter devices` 查看可用目标(Android 模拟器、真机、Chrome、Windows 桌面等)。

#### 验证

```bash
flutter analyze
flutter test
```

当前测试套件(47 个用例)覆盖:

- `weather_model_test.dart` — JSON 解析、单位换算
- `weather_repository_test.dart` — API/缓存协同、AQI 降级
- `weather_hub_provider_test.dart` — 状态迁移、置顶/排序/撤销流程
- `local_weather_cache_service_test.dart` — 持久化往返
- `weather_dashboard_screen_test.dart` — 组件交互(排序、搜索、置顶、删除-撤销)
- `air_quality_card_test.dart` — AQI 展示
- `widget_test.dart` — 冒烟测试

> **国内代理用户注意**:如果你设置了全局 `HTTP_PROXY`(常见于翻墙场景),`flutter test` 会报 `Invalid WebSocket upgrade request`。给本地回环地址加例外即可:
>
> ```powershell
> $env:NO_PROXY = "127.0.0.1,localhost,::1"
> flutter test
> ```

### Android 权限

在 `android/app/src/main/AndroidManifest.xml` 中声明:

- `INTERNET` — API 调用
- `ACCESS_NETWORK_STATE` — 网络可达性
- `ACCESS_FINE_LOCATION` — 精确定位
- `ACCESS_COARSE_LOCATION` — 粗略定位降级

### 架构说明

- `WeatherDashboardScreen` 是唯一的活跃界面,旧的 `HomeScreen` 代码已移除。
- `WeatherProvider`(在 `weather_hub_provider.dart` 中)持有:
  - 当前定位的天气数据
  - 保存的城市列表(置顶优先、按索引排序)
  - 搜索状态(防抖、请求 id 保护)
  - 展开的卡片 id、温标、最后更新时间
- `WeatherRepository` 并发请求天气和空气质量;AQI 请求失败时打日志并降级为仅天气数据。
- 状态缓存有 **6 小时保留窗口**,**30 分钟刷新间隔**触发自动刷新。
- `isCacheExpired` 基于每个城市的 `updatedAt` 判断,不会因为刚添加的新城市掩盖其他过期城市。
- 搜索通过 `Timer` 防抖 + 请求 id 模式丢弃过期响应;`dispose()` 会自增请求 id,保证销毁后进行中的响应不会再调用 `notifyListeners`。
- 看板用 `ValueNotifier<bool>` 控制搜索模式切换,打开搜索框时不会重建整个城市列表。

### 性能优化记录

最近一轮改进:

1. 移除搜索框中多余的 `setState(() {})`。
2. 搜索切换收窄到 `ValueListenableBuilder`,不再触发整屏 `setState`。
3. 缓存 `savedCities` / `searchResults` / `expandedCity` 的 getter,避免每帧重新分配。
4. 置顶/排序热路径去掉重复的 `indexWhere` 调用。
5. 刷新时去掉多余的 sort/normalize(`_refreshSavedCity` 已保留顺序)。
6. `isCacheExpired` 改为按城市各自判断。
7. AQI 请求失败改为打日志,不再静默吞异常。
8. 搜索结果列表使用 `ValueKey`,Flutter 可跨查询复用 widget。

### 许可

本项目按"原样"提供,仅供学习和个人使用。

---

## 日本語

### プロジェクト概要

Apple Weather Android は、Apple 純正「天気」アプリの情報構成を参考に Flutter で構築したクロスプラットフォームの天気クライアントです。ダッシュボード上部に**現在地カード**、下部にユーザーが追加した**都市カードの一覧**を配置し、展開/折りたたみ、ピン留め、同グループ内での並び替え、スナックバー付きの削除取り消しに対応しています。すべての状態はローカルに永続化されており、再起動時に直前のダッシュボードを即座に復元します。

### 主な機能

| カテゴリ | 機能 |
| --- | --- |
| **位置情報** | GPS ベースの現在地取得と権限ハンドリング。Web ではデフォルト都市にフォールバック |
| **検索** | Open-Meteo Geocoding API を用いたデバウンス検索。保存済み都市を識別表示 |
| **ダッシュボード** | 現在の天気、1 時間ごとの予報、7 日間予報、大気質、6 分割の天気詳細 |
| **都市カード** | 展開/折りたたみ、上部へのピン留め、同グループ内並び替え、スナックバーでの取り消し削除 |
| **永続化** | `SharedPreferences` を用いた天気データ・展開状態・温度単位・最終更新時刻のキャッシュ |
| **更新** | プルトゥリフレッシュ、手動更新ボタン、起動時に古い(> 30 分)データを自動更新 |
| **単位** | AppBar のポップアップメニューから摂氏/華氏を切り替え |
| **エラー処理** | 部分的失敗時は上部バナー、完全失敗時はフルスクリーンのエラー画面(再試行可) |

### 技術スタック

- **フレームワーク**: Flutter 3.x(Dart 3.x)
- **状態管理**: `provider`(`ChangeNotifier` + `Selector` / `Consumer`)
- **HTTP**: `http`
- **位置情報**: `geolocator` + `permission_handler`
- **永続化**: `shared_preferences`
- **国際化**: `intl`(日付フォーマット)
- **API**(すべて無料・APIキー不要):
  - 天気予報: `https://api.open-meteo.com/v1`
  - ジオコーディング: `https://geocoding-api.open-meteo.com/v1`
  - 大気質: `https://air-quality-api.open-meteo.com/v1`

### プロジェクト構成

```text
lib/
├── main.dart                          # アプリのエントリ、Provider の組み立て
├── models/
│   ├── air_quality_model.dart         # AQI と汚染物質モデル
│   ├── city_search_result.dart        # ジオコーディング結果
│   ├── saved_city_weather.dart        # 保存都市 + 天気の組み合わせ
│   └── weather_model.dart             # 天気データのコアモデル
├── providers/
│   └── weather_hub_provider.dart      # ダッシュボード状態の管理者
├── repositories/
│   └── weather_repository.dart        # API とキャッシュの調整層
├── screens/
│   └── weather_dashboard_screen.dart  # メインダッシュボード UI
├── services/
│   ├── local_weather_cache_service.dart  # SharedPreferences ラッパー
│   ├── location_service.dart             # 位置情報と権限ラッパー
│   └── weather_api_service.dart          # Open-Meteo HTTP クライアント
├── utils/
│   ├── constants.dart                 # アプリ定数
│   ├── date_utils.dart                # 温度単位・日付ユーティリティ
│   ├── theme_utils.dart               # 天気ベースのテーマ
│   └── weather_utils.dart             # 単位変換・天気コードマッピング
└── widgets/
    ├── air_quality_card.dart
    ├── current_weather_card.dart
    ├── daily_forecast_widget.dart
    ├── error_view.dart
    ├── hourly_forecast_widget.dart
    ├── loading_view.dart
    ├── saved_city_weather_card.dart
    ├── search_bar_widget.dart
    ├── weather_background.dart
    └── weather_details_grid.dart
```

### はじめに

#### 前提条件

- Flutter SDK **>= 3.10**(Dart **>= 3.0**)
- Android Studio / Xcode(エミュレータ用)
- ターゲットプラットフォームで `flutter doctor` が通ること

#### インストールと実行

```bash
flutter pub get
flutter run
```

`flutter devices` で利用可能なターゲット(Android エミュレータ、実機、Chrome、Windows デスクトップ等)を確認してください。

#### 検証

```bash
flutter analyze
flutter test
```

現行テストスイート(47 件)のカバー範囲:

- `weather_model_test.dart` — JSON パースと単位変換
- `weather_repository_test.dart` — API/キャッシュ連携、AQI フォールバック
- `weather_hub_provider_test.dart` — 状態遷移、ピン留め/並び替え/取り消しフロー
- `local_weather_cache_service_test.dart` — 永続化の往復
- `weather_dashboard_screen_test.dart` — ウィジェット操作(並び替え、検索、ピン留め、削除取り消し)
- `air_quality_card_test.dart` — AQI 表示
- `widget_test.dart` — スモークテスト

> **ローカルプロキシ使用時の注意**(中国本土で一般的):グローバルな `HTTP_PROXY` が設定されていると、`flutter test` が `Invalid WebSocket upgrade request` で失敗することがあります。ループバックアドレスを例外に追加してください:
>
> ```powershell
> $env:NO_PROXY = "127.0.0.1,localhost,::1"
> flutter test
> ```

### Android 権限

`android/app/src/main/AndroidManifest.xml` で宣言:

- `INTERNET` — API 呼び出し
- `ACCESS_NETWORK_STATE` — ネットワーク到達性
- `ACCESS_FINE_LOCATION` — 高精度 GPS 位置情報
- `ACCESS_COARSE_LOCATION` — ネットワークベースの位置情報フォールバック

### アーキテクチャノート

- `WeatherDashboardScreen` が唯一のアクティブな画面で、旧 `HomeScreen` のコードは削除済みです。
- `WeatherProvider`(`weather_hub_provider.dart`)が保持するもの:
  - 現在地の天気データ
  - 保存された都市のリスト(ピン留め優先、インデックス順)
  - 検索状態(デバウンス、リクエスト ID で保護)
  - 展開されたカードの ID、温度単位、最終更新時刻
- `WeatherRepository` は天気と大気質を並列リクエストします。AQI の失敗はログに記録され、天気のみのデータにフォールバックします。
- 状態キャッシュには **6 時間の保持ウィンドウ**と **30 分の更新インターバル**があり、後者は自動更新のトリガーとなります。
- `isCacheExpired` は都市ごとの `updatedAt` を確認するため、新しく追加された都市が他の古い都市のステータスを隠すことはありません。
- 検索は `Timer` によるデバウンスとリクエスト ID パターンで古いレスポンスを破棄します。`dispose()` では ID をインクリメントし、破棄後のレスポンスが `notifyListeners` を呼ばないように保証します。
- ダッシュボードは検索モード切替に `ValueNotifier<bool>` を用いており、検索ボックスを開いても保存都市リスト全体を再構築しません。

### パフォーマンス最適化の記録

直近の改善点:

1. 検索テキストフィールドの不要な `setState(() {})` を削除。
2. 検索切替を `ValueListenableBuilder` の範囲に限定し、画面全体の `setState` を回避。
3. `savedCities` / `searchResults` / `expandedCity` の getter をキャッシュし、ビルドごとの再割当を削減。
4. ピン留め/並び替えのホットパスで重複する `indexWhere` を排除。
5. 更新時の冗長な sort/normalize を削除(`_refreshSavedCity` が順序を保持)。
6. `isCacheExpired` を都市ごとの判定に変更。
7. AQI リクエストの失敗を静かに握り潰さず、ログ出力。
8. 検索結果リストで `ValueKey` を使用し、クエリ間で Flutter がウィジェットを再利用可能に。

### ライセンス

本プロジェクトは「現状のまま」提供され、学習および個人利用を想定しています。
