import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class DeviceService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.channelDevice,
  );

  Future<bool> isXiaomiDevice() async {
    try {
      final result = await _channel.invokeMethod<bool>('isXiaomiDevice');
      return result ?? false;
    } on PlatformException catch (e) {
      throw DeviceServiceException(e.message ?? 'Failed to check device');
    }
  }

  Future<bool> isHyperOS() async {
    try {
      final result = await _channel.invokeMethod<bool>('isHyperOS');
      return result ?? false;
    } on PlatformException catch (e) {
      throw DeviceServiceException(e.message ?? 'Failed to check OS');
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      return result ?? {};
    } on PlatformException catch (e) {
      throw DeviceServiceException(e.message ?? 'Failed to get device info');
    }
  }
}

class DeviceServiceException implements Exception {
  final String message;
  const DeviceServiceException(this.message);

  @override
  String toString() => 'DeviceServiceException: $message';
}
