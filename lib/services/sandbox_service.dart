import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../data/models/sandbox_app.dart';
import '../data/models/security_report.dart';

class SandboxService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.channelSandbox,
  );

  final _behaviorStreamController = StreamController<BehaviorEvent>.broadcast();
  final _networkStreamController =
      StreamController<NetworkActivity>.broadcast();
  final _permissionStreamController =
      StreamController<PermissionAttempt>.broadcast();

  Stream<BehaviorEvent> get behaviorStream => _behaviorStreamController.stream;
  Stream<NetworkActivity> get networkStream => _networkStreamController.stream;
  Stream<PermissionAttempt> get permissionStream =>
      _permissionStreamController.stream;

  SandboxService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onBehaviorEvent':
        final event = BehaviorEvent.fromJson(
          Map<String, dynamic>.from(call.arguments),
        );
        _behaviorStreamController.add(event);
        break;
      case 'onNetworkActivity':
        final activity = NetworkActivity.fromJson(
          Map<String, dynamic>.from(call.arguments),
        );
        _networkStreamController.add(activity);
        break;
      case 'onPermissionAttempt':
        final attempt = PermissionAttempt.fromJson(
          Map<String, dynamic>.from(call.arguments),
        );
        _permissionStreamController.add(attempt);
        break;
    }
  }

  Future<bool> initializeSandbox() async {
    try {
      final result = await _channel.invokeMethod<bool>('initializeSandbox');
      return result ?? false;
    } on PlatformException catch (e) {
      throw SandboxServiceException(
        e.message ?? 'Failed to initialize sandbox',
      );
    }
  }

  Future<SandboxApp> installToSandbox(String apkPath) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'installToSandbox',
        {'apkPath': apkPath},
      );
      if (result == null) {
        throw SandboxServiceException('Failed to install APK in sandbox');
      }
      return SandboxApp.fromJson(result);
    } on PlatformException catch (e) {
      throw SandboxServiceException(
        e.message ?? 'Failed to install to sandbox',
      );
    }
  }

  Future<bool> startSandboxAnalysis(String appId) async {
    try {
      final result = await _channel.invokeMethod<bool>('startAnalysis', {
        'appId': appId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw SandboxServiceException(e.message ?? 'Failed to start analysis');
    }
  }

  Future<void> stopSandbox(String appId) async {
    try {
      await _channel.invokeMethod('stopSandbox', {'appId': appId});
    } on PlatformException catch (e) {
      throw SandboxServiceException(e.message ?? 'Failed to stop sandbox');
    }
  }

  Future<void> terminateSandbox(String appId) async {
    try {
      await _channel.invokeMethod('terminateSandbox', {'appId': appId});
    } on PlatformException catch (e) {
      throw SandboxServiceException(e.message ?? 'Failed to terminate sandbox');
    }
  }

  Future<Map<String, String>> getFakeDataProfile() async {
    try {
      final result = await _channel.invokeMapMethod<String, String>(
        'getFakeDataProfile',
      );
      return result ?? {};
    } on PlatformException catch (e) {
      throw SandboxServiceException(
        e.message ?? 'Failed to get fake data profile',
      );
    }
  }

  Future<List<SandboxApp>> getActiveSandboxApps() async {
    try {
      final result = await _channel.invokeListMethod<dynamic>(
        'getActiveSandboxApps',
      );
      if (result == null) return [];
      return result
          .map((e) => SandboxApp.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (e) {
      throw SandboxServiceException(e.message ?? 'Failed to get sandbox apps');
    }
  }

  void dispose() {
    _behaviorStreamController.close();
    _networkStreamController.close();
    _permissionStreamController.close();
  }
}

class SandboxServiceException implements Exception {
  final String message;
  const SandboxServiceException(this.message);

  @override
  String toString() => 'SandboxServiceException: $message';
}
