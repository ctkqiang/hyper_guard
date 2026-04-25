import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../data/models/security_report.dart';

class MonitorService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.channelMonitor,
  );

  Future<SecurityReport> generateReport(String sandboxAppId) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'generateReport',
        {'sandboxAppId': sandboxAppId},
      );
      if (result == null) {
        throw MonitorServiceException('Failed to generate report');
      }
      return SecurityReport.fromJson(result);
    } on PlatformException catch (e) {
      throw MonitorServiceException(e.message ?? 'Failed to generate report');
    }
  }

  Future<List<SecurityReport>> getReportHistory() async {
    try {
      final result = await _channel.invokeListMethod<dynamic>(
        'getReportHistory',
      );
      if (result == null) return [];
      return result
          .map((e) => SecurityReport.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (e) {
      throw MonitorServiceException(
        e.message ?? 'Failed to get report history',
      );
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteReport', {
        'reportId': reportId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw MonitorServiceException(e.message ?? 'Failed to delete report');
    }
  }

  Future<bool> exportReport(String reportId, String format) async {
    try {
      final result = await _channel.invokeMethod<bool>('exportReport', {
        'reportId': reportId,
        'format': format,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw MonitorServiceException(e.message ?? 'Failed to export report');
    }
  }
}

class MonitorServiceException implements Exception {
  final String message;
  const MonitorServiceException(this.message);

  @override
  String toString() => 'MonitorServiceException: $message';
}
