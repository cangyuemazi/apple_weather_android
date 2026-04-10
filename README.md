# Apple Weather Android - Open-Meteo 天气应用

一款基于 Flutter 3.x + Provider 架构的苹果风格天气应用，接入 Open-Meteo 官方 API。

## 功能特性

✅ GPS 获取当前位置天气  
✅ 手动搜索城市天气  
✅ 当前天气展示  
✅ 未来 8 小时逐时预报  
✅ 未来 7 天逐日预报  
✅ 天气详情卡片（湿度、气压、能见度、UV、风速、日出、日落）  
✅ 动态天气背景（根据天气类型和昼夜自动切换）  
✅ 下拉刷新  
✅ 加载态 / 错误态 / 空态  
✅ 搜索防抖  
✅ 完善的异常处理  

## 技术栈

- **Flutter**: 3.x
- **Dart**: 3.x
- **状态管理**: Provider
- **网络请求**: http
- **定位服务**: geolocator + permission_handler
- **日期格式化**: intl
- **API**: Open-Meteo (免费，无需 API Key)

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── models/
│   └── weather_model.dart            # 数据模型
├── services/
│   ├── weather_api_service.dart      # Open-Meteo API 服务
│   └── location_service.dart         # 定位服务
├── providers/
│   └── weather_provider.dart         # 状态管理
├── screens/
│   └── home_screen.dart              # 主屏幕
├── widgets/
│   ├── weather_background.dart       # 动态天气背景
│   ├── current_weather_card.dart     # 当前天气卡片
│   ├── hourly_forecast_widget.dart   # 逐小时预报
│   ├── daily_forecast_widget.dart    # 逐日预报
│   ├── weather_details_grid.dart     # 天气详情网格
│   ├── loading_view.dart             # 加载视图
│   ├── error_view.dart               # 错误视图
│   └── search_bar_widget.dart        # 搜索栏
└── utils/
    ├── constants.dart                # 常量配置
    ├── weather_utils.dart            # 天气工具
    ├── theme_utils.dart              # 主题工具
    └── date_utils.dart               # 日期工具
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android SDK (Android 5.0+)
- 已配置 Android 开发环境

### 安装依赖

```bash
cd apple_weather_android
flutter pub get
```

### 运行应用

```bash
# 连接设备或启动模拟器后运行
flutter run
```

### 构建发布版本

```bash
# 构建 APK
flutter build apk --release

# 构建 App Bundle (用于 Google Play)
flutter build appbundle --release
```

## Android 权限配置

应用已在 `android/app/src/main/AndroidManifest.xml` 中配置以下权限：

- `INTERNET` - 网络访问
- `ACCESS_FINE_LOCATION` - 精确定位
- `ACCESS_COARSE_LOCATION` - 粗略定位
- `ACCESS_NETWORK_STATE` - 网络状态

首次运行时会自动请求定位权限。

## API 说明

本应用使用 **Open-Meteo API**，这是一个免费的开源天气 API，**无需 API Key**。

### 使用的 API

1. **地理编码 API** (城市搜索)
   - URL: `https://geocoding-api.open-meteo.com/v1/search`
   - 用途：根据城市名称搜索获取经纬度

2. **天气预报 API**
   - URL: `https://api.open-meteo.com/v1/forecast`
   - 用途：获取当前天气、逐小时预报、逐日预报

### 天气代码映射

应用基于 Open-Meteo 的 WMO 天气代码实现了完整的中文映射：

| 代码 | 天气状况 |
|------|---------|
| 0 | 晴 |
| 1-3 | 多云 |
| 45, 48 | 雾 |
| 51-55 | 毛毛雨 |
| 61-65 | 雨 |
| 71-75 | 雪 |
| 80-82 | 阵雨 |
| 95-99 | 雷暴 |

## 设计特色

### 玻璃拟态 UI
- 半透明卡片背景
- 柔和白色边框
- 渐变动态背景

### 主题自适应
根据天气类型和时间自动切换背景渐变：

- ☀️ 晴天白天：蓝色渐变
- 🌙 晴天夜间：深紫渐变
- ☁️ 多云：灰蓝渐变
- 🌧️ 雨天：深蓝灰渐变
- ❄️ 雪天：浅蓝白渐变
- ⛈️ 雷暴：深灰渐变

## 异常处理

应用已处理以下异常情况：

- ✅ 网络连接失败
- ✅ 请求超时
- ✅ 城市搜索为空
- ✅ 搜索无结果
- ✅ 定位失败
- ✅ 权限拒绝
- ✅ JSON 字段缺失
- ✅ API 返回异常

## 开发说明

### 修改默认城市

编辑 `lib/utils/constants.dart`：

```dart
class AppConstants {
  static const String defaultCity = '北京';
  static const double defaultLatitude = 39.9042;
  static const double defaultLongitude = 116.4074;
}
```

### 调整搜索防抖时间

```dart
static const Duration searchDebounce = Duration(milliseconds: 500);
```

### 修改预报小时数

```dart
static const int hourlyForecastCount = 8;  // 修改为你需要的小时数
```

## 常见问题

### Q: 定位失败怎么办？

A: 请确保：
1. 已在手机设置中为应用开启定位权限
2. 手机的 GPS/定位服务已开启
3. 网络连接正常

### Q: 如何切换城市？

A: 点击顶部城市名称进入搜索模式，输入城市名称后从搜索结果中选择即可。

### Q: 天气数据不准确？

A: Open-Meteo 数据来源于全球气象模型，可能存在一定偏差。建议对比多个天气源。

## 开源协议

MIT License

## 致谢

- [Open-Meteo](https://open-meteo.com/) - 提供免费天气 API
- [Flutter](https://flutter.dev/) - UI 框架
- [Provider](https://pub.dev/packages/provider) - 状态管理
