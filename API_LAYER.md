# Open-Meteo 接口层交付文档

## 📦 交付内容

本次只生成接口层和数据模型层代码,不包含 UI、Provider 或页面逻辑。

---

## 📁 文件清单

### 1. lib/models/weather_model.dart
**天气数据模型**,包含:
- `WeatherData` - 完整天气数据(当前天气 + 逐小时 + 逐日预报)
- `HourlyForecast` - 逐小时预报
- `DailyForecast` - 逐日预报

**特性:**
- ✅ 完整 fromJson/toJson 序列化
- ✅ copyWith 方法支持不可变更新
- ✅ 空值保护,所有字段有默认值
- ✅ 自动解析 Open-Meteo API 响应
- ✅ 自动截取未来 8 小时逐时预报
- ✅ 自动截取未来 7 天逐日预报
- ✅ 自动格式化时间标签(Now, HH:mm, 今天, 周几)

### 2. lib/models/city_search_result.dart
**城市搜索结果模型**,包含:
- `CitySearchResult` - 城市地理信息

**特性:**
- ✅ 完整 fromJson/toJson 序列化
- ✅ copyWith 方法
- ✅ displayName getter 自动拼接城市名+行政区+国家
- ✅ 实现 == 和 hashCode (基于 name+latitude+longitude)
- ✅ 空值保护

### 3. lib/services/weather_api_service.dart
**天气 API 服务层**,包含:
- `WeatherApiService` 类
  - `searchCity(String keyword)` - 搜索城市
  - `getWeatherByCity(String cityName)` - 通过城市名获取天气
  - `getWeatherByLocation(double lat, double lon, {String? locationName})` - 通过经纬度获取天气

**自定义异常:**
- `WeatherApiException` - API 异常基类
- `CityNotFoundException` - 城市未找到
- `InvalidResponseException` - 响应数据格式错误

**特性:**
- ✅ 支持依赖注入 (http.Client)
- ✅ 可配置超时时间
- ✅ 统一异常处理
- ✅ 参数校验
- ✅ HTTP 状态码检查
- ✅ JSON 响应验证
- ✅ 不在方法中写死不可配置逻辑
- ✅ 不与 UI 提示文案强耦合

**私有辅助方法:**
- `_buildGeocodingUri()` - 构建地理编码请求 URI
- `_buildForecastUri()` - 构建天气预报请求 URI
- `_decodeJson()` - 解析 JSON 字符串
- `_validateWeatherResponse()` - 验证天气响应数据

### 4. lib/utils/weather_utils.dart
**天气工具类**,包含:

**天气代码映射:**
- `getWeatherConditionText(int code)` - WMO 代码转中文
- `isRainCode(int code)` - 是否雨天
- `isSnowCode(int code)` - 是否雪天
- `isCloudyCode(int code)` - 是否多云
- `isClearCode(int code)` - 是否晴天
- `isFoggyCode(int code)` - 是否雾天
- `isThunderstormCode(int code)` - 是否雷暴

**时间格式化:**
- `formatHourLabel(String dateTimeStr, {bool currentIndex})` - 格式化小时标签 (Now / HH:mm)
- `formatTimeToHHmm(String dateTimeStr)` - 格式化时间为 HH:mm
- `formatDailyLabel(String dateStr, {int index})` - 格式化日期标签 (今天 / 周几)
- `getWeekday(String dateStr)` - 获取星期几
- `formatDate(String dateStr)` - 格式化日期为 MM月dd日

**数据格式化:**
- `formatTemperature(double temperature)` - 格式化温度
- `formatTemperatureRange(double min, double max)` - 格式化温度范围
- `formatWindSpeed(double windSpeed)` - 格式化风速
- `formatVisibility(double visibility)` - 格式化能见度

**描述文本:**
- `getHumidityDescription(int humidity)` - 湿度描述
- `getPressureDescription(int pressure)` - 气压描述
- `getWindDescription(double windSpeed)` - 风速描述
- `getUVDescription(int uvIndex)` - UV 描述
- `getVisibilityDescription(double visibility)` - 能见度描述
- `getClothingSuggestion(double temperature)` - 穿衣建议
- `getTravelSuggestion(int weatherCode, double windSpeed)` - 出行建议

---

## 🎯 字段映射规则

### WeatherData 映射

| 字段 | 来源 | 说明 |
|------|------|------|
| location | 传入的 locationName | 优先使用传入值,降级为 "Unknown Location" |
| temperature | current.temperature_2m | 当前温度 |
| feelsLike | current.apparent_temperature | 体感温度 |
| conditionCode | current.weather_code | WMO 天气代码 |
| condition | WeatherUtils.getWeatherConditionText() | 中文天气描述 |
| humidity | current.relative_humidity_2m | 湿度 |
| pressure | current.surface_pressure | 气压 |
| windSpeed | current.wind_speed_10m | 风速 |
| isDayTime | current.is_day == 1 | 是否白天 |
| visibility | hourly.visibility[当前小时索引] | 能见度,降级取第一个值 |
| uvIndex | daily.uv_index_max[0].toInt() | UV 指数 |
| sunrise | daily.sunrise[0] 格式化为 HH:mm | 日出时间 |
| sunset | daily.sunset[0] 格式化为 HH:mm | 日落时间 |
| highTemp | daily.temperature_2m_max[0] | 当日最高温 |
| lowTemp | daily.temperature_2m_min[0] | 当日最低温 |
| hourlyForecast | 解析 hourly 数组 | 未来 8 小时 |
| dailyForecast | 解析 daily 数组 | 未来 7 天 |

### HourlyForecast 映射

| 字段 | 来源 | 说明 |
|------|------|------|
| time | hourly.time 格式化为 "Now" 或 "HH:mm" | 时间标签 |
| temperature | hourly.temperature_2m | 温度 |
| conditionCode | hourly.weather_code | 天气代码 |

### DailyForecast 映射

| 字段 | 来源 | 说明 |
|------|------|------|
| date | daily.time 格式化为 "今天" 或 "周几" | 日期标签 |
| highTemp | daily.temperature_2m_max | 最高温 |
| lowTemp | daily.temperature_2m_min | 最低温 |
| conditionCode | daily.weather_code | 天气代码 |
| precipitationChance | daily.precipitation_probability_max | 降水概率 |

### CitySearchResult 映射

| 字段 | 来源 | 说明 |
|------|------|------|
| name | results[].name | 城市名称 |
| latitude | results[].latitude | 纬度 |
| longitude | results[].longitude | 经度 |
| country | results[].country | 国家 |
| admin1 | results[].admin1 | 行政区 |
| timezone | results[].timezone | 时区 |

---

## 🔧 API 调用示例

### 1. 搜索城市

```dart
final apiService = WeatherApiService();

try {
  final cities = await apiService.searchCity('Beijing');
  print('找到 ${cities.length} 个城市');
  for (final city in cities) {
    print('${city.displayName}: ${city.latitude}, ${city.longitude}');
  }
} on CityNotFoundException catch (e) {
  print('城市未找到: $e');
} on WeatherApiException catch (e) {
  print('API 错误: $e');
}
```

### 2. 通过城市名获取天气

```dart
final apiService = WeatherApiService();

try {
  final weather = await apiService.getWeatherByCity('Beijing');
  print('当前温度: ${weather.temperature}°C');
  print('天气状况: ${weather.condition}');
  print('未来 8 小时: ${weather.hourlyForecast.length} 条');
  print('未来 7 天: ${weather.dailyForecast.length} 条');
} on CityNotFoundException catch (e) {
  print('城市未找到');
} on WeatherApiException catch (e) {
  print('获取天气失败: $e');
}
```

### 3. 通过经纬度获取天气

```dart
final apiService = WeatherApiService();

try {
  final weather = await apiService.getWeatherByLocation(
    39.9042,
    116.4074,
    locationName: '北京',
  );
  print('位置: ${weather.location}');
  print('温度: ${weather.temperature}°C');
  print('体感温度: ${weather.feelsLike}°C');
  print('湿度: ${weather.humidity}%');
  print('日出: ${weather.sunrise}');
  print('日落: ${weather.sunset}');
} on WeatherApiException catch (e) {
  print('获取天气失败: $e');
}
```

---

## 🛡️ 异常处理

### 已处理的异常情况

| 异常类型 | 触发条件 | 异常消息 |
|---------|---------|---------|
| WeatherApiException | 关键词为空 | "搜索关键词不能为空" |
| WeatherApiException | 城市名为空 | "城市名称不能为空" |
| WeatherApiException | HTTP 非 200 | "搜索城市失败: HTTP xxx" |
| WeatherApiException | 网络错误 | "搜索城市时发生错误: xxx" |
| CityNotFoundException | 搜索无结果 | "未找到城市: xxx" |
| InvalidResponseException | JSON 解析失败 | "JSON 解析失败: xxx" |
| InvalidResponseException | 缺少关键字段 | "响应数据缺少 xxx 字段" |
| InvalidResponseException | 数组为空 | "逐小时预报时间列表为空" |

### 异常处理策略

1. **参数校验** - 方法入口处检查必填参数
2. **HTTP 状态检查** - 检查响应码是否为 200
3. **JSON 验证** - 解析后验证数据结构完整性
4. **统一异常包装** - 所有异常继承 WeatherApiException
5. **异常透传** - WeatherApiException 直接 rethrow,其他异常包装后抛出

---

## ⏰ 时间格式化规则

### 逐小时预报时间标签

```dart
// 当前小时
formatHourLabel('2024-01-01T10:00', currentIndex: true)
// 返回: "Now"

// 其他小时
formatHourLabel('2024-01-01T13:00', currentIndex: false)
// 返回: "13:00"
```

### 日出日落时间

```dart
formatTimeToHHmm('2024-01-01T06:30:00')
// 返回: "06:30"
```

### 逐日预报日期标签

```dart
// 第一天 (index = 0)
formatDailyLabel('2024-01-15', index: 0)
// 返回: "今天"

// 后续天数 (index > 0)
formatDailyLabel('2024-01-16', index: 1)
// 返回: "周二" (根据实际日期计算)
```

---

## 📊 WMO 天气代码映射

| 代码范围 | 中文描述 | 判断函数 |
|---------|---------|---------|
| 0 | 晴 | isClearCode(0) |
| 1-3 | 多云 | isCloudyCode(1-3) |
| 45, 48 | 雾 | isFoggyCode(45,48) |
| 51-55 | 毛毛雨 | isRainCode(51-55) |
| 61-65 | 雨 | isRainCode(61-65) |
| 71-75 | 雪 | isSnowCode(71-75) |
| 80-82 | 阵雨 | isRainCode(80-82) |
| 95-99 | 雷暴 | isThunderstormCode(95-99) |
| 其他 | 未知 | - |

---

## ✅ 测试覆盖

**测试文件:** `test/weather_model_test.dart`

**测试用例: 25 个 (全部通过 ✅)**

### 测试分组

1. **WeatherData Model Tests** (4 个)
   - JSON 解析正确性
   - 空值处理
   - 序列化
   - copyWith

2. **HourlyForecast Model Tests** (3 个)
   - 创建实例
   - 序列化
   - copyWith

3. **DailyForecast Model Tests** (3 个)
   - 创建实例
   - 序列化
   - copyWith

4. **CitySearchResult Model Tests** (5 个)
   - JSON 解析
   - 缺失字段处理
   - 序列化
   - copyWith
   - 相等性判断

5. **WeatherUtils Tests** (10 个)
   - 天气代码映射
   - 天气类型判断
   - 时间格式化
   - 日期标签格式化
   - 描述文本生成
   - 温度格式化
   - 风速格式化
   - 能见度格式化
   - 穿衣建议
   - 出行建议

---

## 🎓 设计原则

### 1. 单一职责
- 模型只负责数据映射
- Service 只负责 API 调用
- Utils 只负责工具函数

### 2. 不可变性
- 所有模型字段为 final
- 通过 copyWith 创建新实例
- 避免副作用

### 3. 依赖注入
- WeatherApiService 支持注入 http.Client
- 便于测试和扩展

### 4. 空值安全
- 所有 fromJson 都有默认值保护
- 不会因为 JSON 字段缺失而崩溃

### 5. 类型安全
- 避免使用 dynamic
- 明确的类型声明
- 编译时类型检查

---

## 📝 代码规范

- ✅ 所有类和方法都有注释
- ✅ 命名清晰,符合 Dart 规范
- ✅ 类型明确,避免 dynamic 传播
- ✅ JSON 解析封装在模型内部
- ✅ 异常信息可读且明确
- ✅ 适合后续接 Provider 和 UI

---

## 🚀 后续集成指南

### 接入 Provider

```dart
class WeatherProvider extends ChangeNotifier {
  final WeatherApiService _apiService = WeatherApiService();
  WeatherData? _weatherData;
  
  Future<void> loadWeather(String city) async {
    try {
      _weatherData = await _apiService.getWeatherByCity(city);
      notifyListeners();
    } on WeatherApiException catch (e) {
      // 处理错误
      print('加载天气失败: $e');
    }
  }
}
```

### 接入 UI

```dart
// 显示当前温度
Text('${weatherData.temperature.round()}°')

// 显示天气状况
Text(weatherData.condition)

// 显示逐小时预报
ListView.builder(
  itemCount: weatherData.hourlyForecast.length,
  itemBuilder: (context, index) {
    final hour = weatherData.hourlyForecast[index];
    return Text('${hour.time}: ${hour.temperature}°');
  },
)
```

---

## 📦 依赖清单

```yaml
dependencies:
  http: ^1.1.0        # 网络请求
  intl: ^0.18.1       # 时间格式化
```

---

## ✨ 亮点特性

1. **完整异常处理** - 覆盖所有可能的异常情况
2. **空值保护** - 不会因为 JSON 字段缺失而崩溃
3. **自动截取** - 自动截取未来 8 小时和 7 天数据
4. **智能格式化** - 自动格式化时间标签为可读文本
5. **依赖注入** - 支持测试和扩展
6. **不可变模型** - 通过 copyWith 实现不可变更新
7. **类型安全** - 明确的类型声明,避免 dynamic 传播

---

**交付完成时间**: 2026年4月10日  
**测试状态**: ✅ 25/25 全部通过  
**代码分析**: ✅ 0 errors  
**可运行状态**: ✅ 可直接使用
