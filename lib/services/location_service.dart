/// 定位服务
/// 封装 geolocator 和 permission_handler,提供统一的定位权限与位置获取接口

library location_service;

import 'package:geolocator/geolocator.dart';

/// 定位权限状态
enum LocationPermissionStatus {
  /// 权限未确定
  unknown,

  /// 已授予
  granted,

  /// 已拒绝(可再次请求)
  denied,

  /// 永久拒绝(需手动在设置中开启)
  permanentlyDenied,

  /// 定位服务未启用
  serviceDisabled,
}

/// 定位服务异常基类
class LocationServiceException implements Exception {
  /// 异常消息
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

/// 定位权限被拒绝异常
class LocationPermissionDeniedException extends LocationServiceException {
  LocationPermissionDeniedException([String? message])
      : super(message ?? '定位权限被拒绝,请允许定位权限以获取当前位置');
}

/// 定位权限被永久拒绝异常
class LocationPermissionPermanentlyDeniedException
    extends LocationServiceException {
  LocationPermissionPermanentlyDeniedException([String? message])
      : super(message ?? '定位权限被永久拒绝,请在系统设置中手动开启此应用的定位权限');
}

/// 定位服务未启用异常
class LocationServiceDisabledException extends LocationServiceException {
  LocationServiceDisabledException([String? message])
      : super(message ?? '定位服务未启用,请在系统设置中开启定位服务');
}

/// 定位服务类
///
/// 负责:
/// - 定位权限检查与申请
/// - 位置服务状态检查
/// - 获取当前位置
class LocationService {
  /// 检查定位权限状态
  ///
  /// 返回当前权限状态枚举
  /// 不会主动请求权限,仅检查当前状态
  static Future<LocationPermissionStatus> checkPermissionStatus() async {
    try {
      // 首先检查定位服务是否启用
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      // 检查权限状态
      final LocationPermission permission = await Geolocator.checkPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.granted;

        case LocationPermission.denied:
          return LocationPermissionStatus.denied;

        case LocationPermission.deniedForever:
          return LocationPermissionStatus.permanentlyDenied;

        case LocationPermission.unableToDetermine:
          return LocationPermissionStatus.unknown;
      }
    } catch (e) {
      return LocationPermissionStatus.unknown;
    }
  }

  /// 检查定位服务是否启用
  ///
  /// 返回 true 表示定位服务已开启
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// 请求定位权限
  ///
  /// 完整的权限申请流程:
  /// 1. 检查定位服务是否启用
  /// 2. 检查当前权限状态
  /// 3. 如果需要,请求权限
  /// 4. 处理各种权限状态
  ///
  /// 返回 true 表示权限已授予
  ///
  /// 抛出异常:
  /// - LocationServiceDisabledException: 定位服务未启用
  /// - LocationPermissionDeniedException: 权限被拒绝
  /// - LocationPermissionPermanentlyDeniedException: 权限被永久拒绝
  static Future<bool> requestLocationPermission() async {
    try {
      // 1. 检查定位服务是否启用
      final bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // 2. 检查当前权限状态
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. 如果权限被授予,直接返回
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }

      // 4. 如果权限被永久拒绝,抛出明确异常
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionPermanentlyDeniedException();
      }

      // 5. 请求权限
      permission = await Geolocator.requestPermission();

      // 6. 处理请求结果
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      } else if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionPermanentlyDeniedException();
      } else {
        // denied 或其他状态
        throw LocationPermissionDeniedException();
      }
    } on LocationServiceException {
      rethrow;
    } catch (e) {
      throw LocationServiceException('请求定位权限失败: $e');
    }
  }

  /// 获取当前位置
  ///
  /// 在获取位置前会自动:
  /// 1. 检查定位服务状态
  /// 2. 请求定位权限
  /// 3. 获取位置信息
  ///
  /// 使用高精度模式,超时 15 秒
  ///
  /// 返回 Position 对象,包含经纬度等信息
  ///
  /// 抛出异常:
  /// - LocationServiceException: 定位服务异常
  /// - LocationPermissionDeniedException: 权限被拒绝
  /// - LocationPermissionPermanentlyDeniedException: 权限被永久拒绝
  /// - LocationServiceDisabledException: 定位服务未启用
  static Future<Position> getCurrentPosition() async {
    try {
      // 1. 请求权限(内部会检查服务状态)
      await requestLocationPermission();

      // 2. 获取当前位置
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } on LocationServiceException {
      rethrow;
    } catch (e) {
      throw LocationServiceException('获取当前位置失败: $e');
    }
  }

  /// 打开系统设置页
  ///
  /// 用于引导用户手动开启定位权限
  /// 返回 true 表示成功打开设置页
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// 打开定位服务设置页
  ///
  /// 用于引导用户开启定位服务
  /// 返回 true 表示成功打开设置页
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      return false;
    }
  }
}
