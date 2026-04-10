# WeatherProvider + LocationService 交付文档

## 📦 交付内容

本次只生成 WeatherProvider 和定位服务代码,不包含 UI、页面或修改现有 widgets/screens。

---

## 📁 文件清单

### 1. lib/services/location_service.dart
**定位服务层**,提供完整的定位权限管理与位置获取功能。

**包含内容:**

#### 枚举
- `LocationPermissionStatus` - 定位权限状态
  - `unknown` - 未确定
  - `granted` - 已授予
  - `denied` - 已拒绝(可再次请求)
  - `permanentlyDenied` - 永久拒绝(需手动设置)
  - `serviceDisabled` - 定位服务未启用

#### 自定义异常
- `LocationServiceException` - 定位服务异常基类
- `LocationPermissionDeniedException` - 权限被拒绝
- `LocationPermissionPermanentlyDeniedException` - 权限被永久拒绝
- `LocationServiceDisabledException` - 定位服务未启用

#### LocationService 类(静态方法)
| 方法 | 说明 | 返回值 |
|------|------|--------|
| `checkPermissionStatus()` | 检查当前权限状态(不主动请求) | `Future<LocationPermissionStatus>` |
| `isLocationServiceEnabled()` | 检查定位服务是否启用 | `Future<bool>` |
| `requestLocationPermission()` | 完整权限申请流程 | `Future<bool>` |
| `getCurrentPosition()` | 获取当前位置(自动校验权限) | `Future<Position>` |
| `openAppSettings()` | 打开系统设置页 | `Future<bool>` |
| `openLocationSettings()` | 打开定位服务设置页 | `Future<bool>` |

**设计特点:**
- ✅ 所有方法为静态,无需实例化
- ✅ `getCurrentPosition()` 自动完成权限校验
- ✅ 完整的异常分类体系
- ✅ 异常信息适合 UI 层直接展示
- ✅ 不泄漏平台细节给上层

---

### 2. lib/providers/weather_provider.dart
**天气状态管理**,使用 ChangeNotifier 管理所有天气相关状态。

**包含内容:**

#### 公开状态字段 (Getters)
| 字段 | 类型 | 说明 |
|------|------|------|
| `weatherData` | `WeatherData?` | 当前天气数据 |
| `isLoading` | `bool` | 是否首次加载中 |
| `isRefreshing` | `bool` | 是否下拉刷新中 |
| `errorMessage` | `String?` | 错误信息 |
| `searchResults` | `List<CitySearchResult>` | 搜索结果列表 |
| `isSearching` | `bool` | 是否搜索中 |
| `currentQuery` | `String` | 当前搜索查询词 |
| `currentLocationName` | `String?` | 当前位置/城市名称 |
| `isUsingCurrentLocation` | `bool` | 是否使用定位模式(区分城市模式) |
| `lastUpdated` | `DateTime?` | 最后更新时间 |
| `hasData` | `bool` | 是否有数据(计算属性) |
| `hasError` | `bool` | 是否有错误(计算属性) |

#### 私有状态字段
| 字段 | 类型 | 说明 |
|------|------|------|
| `_weatherApiService` | `WeatherApiService` | API 服务实例 |
| `_searchDebounceTimer` | `Timer?` | 搜索防抖定时器 |
| `_lastSearchedCity` | `String?` | 上次搜索的城市 |
| `_lastLatitude` | `double?` | 上次定位纬度 |
| `_lastLongitude` | `double?` | 上次定位经度 |

#### 公开方法
| 方法 | 说明 |
|------|------|
| `init()` | 初始化(兼容旧版 main.dart 调用) |
| `loadCurrentLocationWeather()` | 加载当前位置天气 |
| `loadWeatherByCity(String city)` | 加载城市天气 |
| `refreshWeather()` | 刷新天气(根据当前模式) |
| `searchCity(String keyword)` | 立即搜索城市 |
| `debounceSearch(String keyword)` | 带防抖的搜索(500ms) |
| `selectCity(CitySearchResult city)` | 选择搜索结果 |
| `clearSearchResults()` | 清空搜索结果 |
| `clearError()` | 清空错误 |
| `dispose()` | 释放资源 |

#### 私有辅助方法
| 方法 | 说明 |
|------|------|
| `_loadDefaultCity()` | 加载默认城市(北京),用于 Web 平台或降级 |
| `_setLoading(bool)` | 设置加载状态 |
| `_setRefreshing(bool)` | 设置刷新状态 |
| `_setSearching(bool)` | 设置搜索状态 |
| `_setError(String?)` | 设置错误信息 |
| `_updateWeather(WeatherData, {isUsingLocation})` | 更新天气数据 |
| `_mapErrorToMessage(Object)` | 异常映射为用户可读文本 |

---

## 🎯 状态行为说明

### 首次加载行为
```
应用启动
  ↓
provider.init()
  ↓
loadCurrentLocationWeather()
  ↓
Web 平台? ─Yes─→ 提示"Web 不支持定位,请搜索城市"
  ↓ No
isLoading = true
  ↓
获取定位权限 → 失败 ─→ errorMessage,不清空旧数据
  ↓ 成功
获取天气数据 → 成功 ─→ weatherData,isLoading=false
                  ↓ 失败
                  errorMessage,保留旧数据
```

### 定位模式 vs 城市模式

| 特性 | 定位模式 | 城市模式 |
|------|---------|---------|
| `isUsingCurrentLocation` | `true` | `false` |
| 记录字段 | `_lastLatitude/_lastLongitude` | `_lastSearchedCity` |
| 刷新行为 | 重新获取定位 | 重新搜索城市 |
| 切换方式 | 调用 `loadWeatherByCity()` 切换 | 调用 `loadCurrentLocationWeather()` 切换 |

### 刷新行为
```
refreshWeather()
  ↓
检查是否正在加载/刷新 → 是 ─→ 跳过
  ↓ 否
isRefreshing = true
  ↓
isUsingCurrentLocation? ─Yes─→ loadCurrentLocationWeather()
  ↓ No
_lastSearchedCity 存在? ─Yes─→ loadWeatherByCity(_lastSearchedCity)
  ↓ No
loadCurrentLocationWeather() (默认)
  ↓
isRefreshing = false
```

### 搜索防抖机制
```
UI 输入 "Bei"
  ↓
debounceSearch("Bei")
  ↓
取消旧定时器
  ↓
启动 500ms 定时器
  ↓ (500ms 后)
searchCity("Bei")
  ↓
isSearching = true
  ↓
调用 API 搜索
  ↓
searchResults = 结果列表
  ↓
isSearching = false
  ↓
notifyListeners()
```

---

## 🛡️ 异常处理

### Provider 内部异常映射

| 底层异常 | 映射后的用户消息 |
|---------|----------------|
| `LocationServiceDisabledException` | "定位服务未启用,请在设置中开启定位服务" |
| `LocationPermissionPermanentlyDeniedException` | "定位权限被永久拒绝,请在系统设置中手动开启此应用的定位权限" |
| `LocationPermissionDeniedException` | "定位权限被拒绝,请允许定位权限以获取当前位置" |
| `LocationServiceException` | 原始 message |
| `CityNotFoundException` | "未找到城市: {keyword}" |
| `InvalidResponseException` | "数据格式错误,请稍后重试" |
| 网络异常(socket/network/connection) | "网络连接失败,请检查网络设置" |
| 超时异常(timeout) | "请求超时,请稍后重试" |
| 其他未知异常 | "加载失败: {error}" |

### 错误保留策略

| 场景 | 行为 |
|------|------|
| 首次加载失败 | 写入 errorMessage,weatherData 为 null |
| 刷新失败 | 写入 errorMessage,**不清空**旧 weatherData |
| 搜索失败 | searchResults 置空,**不影响** weatherData |
| 城市选择失败 | 写入 errorMessage,**保留**已有数据 |

---

## 📝 使用示例

### 在 main.dart 中初始化
```dart
ChangeNotifierProvider(
  create: (context) {
    final provider = WeatherProvider();
    provider.init(); // 自动加载当前位置
    return provider;
  },
  child: MaterialApp(...),
)
```

### 在 UI 中读取状态
```dart
Consumer<WeatherProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return LoadingView();
    }
    
    if (provider.hasError && !provider.hasData) {
      return ErrorView(message: provider.errorMessage!);
    }
    
    if (provider.hasData) {
      return WeatherView(weather: provider.weatherData!);
    }
    
    return EmptyView();
  },
)
```

### 调用方法
```dart
// 定位
provider.loadCurrentLocationWeather();

// 城市
provider.loadWeatherByCity('Beijing');

// 刷新
provider.refreshWeather();

// 搜索防抖
TextField(
  onChanged: (text) => provider.debounceSearch(text),
)

// 选择城市
provider.selectCity(searchResults[0]);

// 清空搜索
provider.clearSearchResults();
```

---

## ✅ 验证结果

### 代码分析
```bash
dart analyze lib/services/location_service.dart lib/providers/weather_provider.dart
```
**结果**: 0 errors (仅 5 warnings + 6 infos,不影响编译)

### 测试
```bash
flutter test
```
**结果**: ✅ 26/26 tests passed

---

## 🎓 设计原则

1. **单一职责**: Provider 只管状态,Service 只管定位
2. **异常隔离**: 底层异常不泄漏到 UI 层
3. **状态保留**: 失败时不清空已有数据
4. **模式区分**: 定位模式和城市模式独立管理
5. **防抖优化**: 搜索输入自动防抖 500ms
6. **Web 兼容**: Web 平台自动降级处理
7. **资源释放**: dispose 正确清理定时器和 HTTP Client

---

**交付完成时间**: 2026年4月10日  
**测试状态**: ✅ 26/26 全部通过  
**代码分析**: ✅ 0 errors  
**可运行状态**: ✅ 可直接使用
