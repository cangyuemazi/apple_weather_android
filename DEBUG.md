# 页面空白问题排查与修复

## 🔍 问题现象
运行 `flutter run -d edge` 后页面显示一片空白。

---

## ✅ 已修复的问题

### 1. `_loadDefaultCity` 缺少 `notifyListeners()`
**问题**: 定位失败后降级加载默认城市,但成功后没有通知 UI 更新,导致页面状态卡住。

**修复**: 在 `_loadDefaultCity` 的 try/catch 块中都添加了 `notifyListeners()`。

### 2. Web 平台不支持 SystemChrome
**问题**: `main.dart` 中调用 `SystemChrome.setSystemUIOverlayStyle()` 在 Web 平台可能抛异常。

**修复**: 添加平台检测 `if (!kIsWeb) { ... }`。

### 3. Web 平台不支持 geolocator 定位
**问题**: 浏览器中 `geolocator` 插件可能无法正常工作,导致定位一直失败。

**修复**: 在 `loadCurrentLocationWeather()` 中添加 Web 平台检测:
```dart
if (kIsWeb) {
  debugPrint('WeatherProvider: Web 平台,跳过定位,直接加载默认城市');
  await _loadDefaultCity();
  return;
}
```

### 4. 缺少调试日志
**问题**: 无法追踪数据加载流程。

**修复**: 添加关键节点的 `debugPrint` 输出:
- 初始化开始
- 位置获取成功/失败
- 天气数据获取成功/失败
- 最终状态 (hasData / hasError)

---

## 🧪 如何验证修复

### 1. 运行应用
```bash
cd d:\Code_project_2026\apple_weather_android
flutter run -d edge
```

### 2. 查看控制台输出
正常情况应该看到以下日志:
```
WeatherProvider: 初始化,开始加载天气数据...
WeatherProvider: Web 平台,跳过定位,直接加载默认城市
WeatherProvider: 成功获取天气数据 - 北京
WeatherProvider: 加载完成,hasData=true,hasError=false
```

### 3. 预期页面显示
- ✅ 蓝色渐变背景
- ✅ 顶部显示 "北京" 城市名称
- ✅ 大温度显示 (例如 "25°")
- ✅ 天气状况 (例如 "晴")
- ✅ 高低温 (例如 "15° / 28°")
- ✅ 8 小时逐时预报 (横向滚动)
- ✅ 7 天逐日预报
- ✅ 天气详情网格 (湿度、气压、能见度等)

---

## 🐛 如果仍然空白,请检查

### 检查 1: 控制台是否有错误
打开浏览器开发者工具 (F12),查看 Console 标签页是否有红色错误信息。

### 检查 2: API 请求是否成功
在开发者工具的 Network 标签页查看:
- `https://api.open-meteo.com/v1/forecast?...` 请求是否返回 200
- Response 中是否有完整的天气数据

### 检查 3: 网络问题
确认你的网络可以访问 `api.open-meteo.com`:
```bash
curl https://api.open-meteo.com/v1/forecast?latitude=39.9&longitude=116.4&current=temperature_2m&timezone=auto
```

### 检查 4: 手动触发刷新
点击页面右上角的刷新按钮,或下拉刷新,看是否能加载数据。

### 检查 5: 搜索城市
1. 点击顶部城市名称 "天气"
2. 输入 "Beijing"
3. 从搜索结果中选择
4. 看是否能显示天气数据

---

## 📊 状态流程图

```
应用启动
  ↓
WeatherProvider.init()
  ↓
kIsWeb? ─Yes─→ _loadDefaultCity() ─→ 显示北京天气
  ↓ No
尝试 GPS 定位
  ↓ 成功
getWeatherByLocation(lat, lon)
  ↓ 失败
_loadDefaultCity() ─→ 显示北京天气
  ↓ 失败
errorMessage = "错误信息"
  ↓
显示 ErrorView + 重试按钮
```

---

## 🎯 关键代码修改点

| 文件 | 修改内容 |
|------|---------|
| `lib/providers/weather_provider.dart` | 添加 kIsWeb 检测、notifyListeners、debugPrint |
| `lib/main.dart` | 添加 kIsWeb 检测保护 SystemChrome |

---

## 📝 调试技巧

### 1. 强制显示调试信息
在 `home_screen.dart` 的 `_buildBody` 方法顶部添加:
```dart
debugPrint('HomeScreen: isLoading=${provider.isLoading}, hasData=${provider.hasData}, hasError=${provider.hasError}');
```

### 2. 测试 API 是否可用
```dart
// 在 main.dart 的 main() 中添加
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 测试 API
  try {
    final response = await http.get(Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=39.9&longitude=116.4&current=temperature_2m&timezone=auto'
    ));
    debugPrint('API 测试: ${response.statusCode}');
    debugPrint('API 响应: ${response.body.substring(0, 100)}');
  } catch (e) {
    debugPrint('API 测试失败: $e');
  }
  
  runApp(const MyApp());
}
```

---

**修复完成时间**: 2026年4月10日  
**状态**: 已修复,等待验证
