import 'package:equatable/equatable.dart';

class SecurityReport extends Equatable {
  final String id;
  final String sandboxAppId;
  final String packageName;
  final String appName;
  final String threatLevel;
  final int threatScore;
  final DateTime generatedTime;
  final List<PermissionAttempt> permissionAttempts;
  final List<NetworkActivity> networkActivities;
  final List<BehaviorEvent> behaviorEvents;
  final String summary;
  final List<String> recommendations;

  const SecurityReport({
    required this.id,
    required this.sandboxAppId,
    required this.packageName,
    required this.appName,
    required this.threatLevel,
    required this.threatScore,
    required this.generatedTime,
    this.permissionAttempts = const [],
    this.networkActivities = const [],
    this.behaviorEvents = const [],
    this.summary = '',
    this.recommendations = const [],
  });

  SecurityReport copyWith({
    String? id,
    String? sandboxAppId,
    String? packageName,
    String? appName,
    String? threatLevel,
    int? threatScore,
    DateTime? generatedTime,
    List<PermissionAttempt>? permissionAttempts,
    List<NetworkActivity>? networkActivities,
    List<BehaviorEvent>? behaviorEvents,
    String? summary,
    List<String>? recommendations,
  }) {
    return SecurityReport(
      id: id ?? this.id,
      sandboxAppId: sandboxAppId ?? this.sandboxAppId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      threatLevel: threatLevel ?? this.threatLevel,
      threatScore: threatScore ?? this.threatScore,
      generatedTime: generatedTime ?? this.generatedTime,
      permissionAttempts: permissionAttempts ?? this.permissionAttempts,
      networkActivities: networkActivities ?? this.networkActivities,
      behaviorEvents: behaviorEvents ?? this.behaviorEvents,
      summary: summary ?? this.summary,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sandboxAppId': sandboxAppId,
    'packageName': packageName,
    'appName': appName,
    'threatLevel': threatLevel,
    'threatScore': threatScore,
    'generatedTime': generatedTime.toIso8601String(),
    'permissionAttempts': permissionAttempts.map((e) => e.toJson()).toList(),
    'networkActivities': networkActivities.map((e) => e.toJson()).toList(),
    'behaviorEvents': behaviorEvents.map((e) => e.toJson()).toList(),
    'summary': summary,
    'recommendations': recommendations,
  };

  factory SecurityReport.fromJson(Map<String, dynamic> json) {
    return SecurityReport(
      id: json['id'] as String,
      sandboxAppId: json['sandboxAppId'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      threatLevel: json['threatLevel'] as String,
      threatScore: json['threatScore'] as int,
      generatedTime: _parseReportTime(json['generatedTime']),
      permissionAttempts: _parseList(
        json['permissionAttempts'],
        PermissionAttempt.fromJson,
      ),
      networkActivities: _parseList(
        json['networkActivities'],
        NetworkActivity.fromJson,
      ),
      behaviorEvents: _parseList(
        json['behaviorEvents'],
        BehaviorEvent.fromJson,
      ),
      summary: json['summary'] as String? ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    id,
    sandboxAppId,
    packageName,
    appName,
    threatLevel,
    threatScore,
    generatedTime,
  ];
}

class PermissionAttempt extends Equatable {
  final String permission;
  final bool granted;
  final DateTime timestamp;
  final String risk;
  final Map<String, dynamic> details;

  const PermissionAttempt({
    required this.permission,
    required this.granted,
    required this.timestamp,
    this.risk = 'low',
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
    'permission': permission,
    'granted': granted,
    'timestamp': timestamp.toIso8601String(),
    'risk': risk,
    'details': details,
  };

  factory PermissionAttempt.fromJson(Map<String, dynamic> json) {
    return PermissionAttempt(
      permission: json['permission'] as String,
      granted: json['granted'] as bool,
      timestamp: _parseReportTime(json['timestamp']),
      risk: json['risk'] as String? ?? 'low',
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [permission, granted, timestamp, risk];
}

class NetworkActivity extends Equatable {
  final String url;
  final String method;
  final int statusCode;
  final DateTime timestamp;
  final bool encrypted;
  final String? ipAddress;
  final Map<String, dynamic> details;

  const NetworkActivity({
    required this.url,
    required this.method,
    required this.statusCode,
    required this.timestamp,
    this.encrypted = false,
    this.ipAddress,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': method,
    'statusCode': statusCode,
    'timestamp': timestamp.toIso8601String(),
    'encrypted': encrypted,
    'ipAddress': ipAddress,
    'details': details,
  };

  factory NetworkActivity.fromJson(Map<String, dynamic> json) {
    return NetworkActivity(
      url: json['url'] as String,
      method: json['method'] as String,
      statusCode: json['statusCode'] as int,
      timestamp: _parseReportTime(json['timestamp']),
      encrypted: json['encrypted'] as bool? ?? false,
      ipAddress: json['ipAddress'] as String?,
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    url,
    method,
    statusCode,
    timestamp,
    encrypted,
    ipAddress,
  ];
}

class BehaviorEvent extends Equatable {
  final String eventType;
  final String description;
  final String severity;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  const BehaviorEvent({
    required this.eventType,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'description': description,
    'severity': severity,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  factory BehaviorEvent.fromJson(Map<String, dynamic> json) {
    return BehaviorEvent(
      eventType: json['eventType'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      timestamp: _parseReportTime(json['timestamp']),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [eventType, description, severity, timestamp];
}

DateTime _parseReportTime(dynamic value) {
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final ms = int.tryParse(value);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}

List<T> _parseList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) return [];
  return value.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
}
