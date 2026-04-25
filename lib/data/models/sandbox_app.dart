import 'package:equatable/equatable.dart';

enum SandboxAppStatus { pending, running, analyzing, completed, failed }

enum ThreatLevel { safe, suspicious, dangerous, malicious }

class SandboxApp extends Equatable {
  final String id;
  final String packageName;
  final String appName;
  final String? iconPath;
  final int sizeBytes;
  final SandboxAppStatus status;
  final ThreatLevel threatLevel;
  final DateTime createdTime;
  final DateTime? completedTime;
  final int permissionRequests;
  final int networkRequests;
  final int blockedActions;
  final List<String> detectedBehaviors;

  const SandboxApp({
    required this.id,
    required this.packageName,
    required this.appName,
    this.iconPath,
    required this.sizeBytes,
    this.status = SandboxAppStatus.pending,
    this.threatLevel = ThreatLevel.safe,
    required this.createdTime,
    this.completedTime,
    this.permissionRequests = 0,
    this.networkRequests = 0,
    this.blockedActions = 0,
    this.detectedBehaviors = const [],
  });

  SandboxApp copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? iconPath,
    int? sizeBytes,
    SandboxAppStatus? status,
    ThreatLevel? threatLevel,
    DateTime? createdTime,
    DateTime? completedTime,
    int? permissionRequests,
    int? networkRequests,
    int? blockedActions,
    List<String>? detectedBehaviors,
  }) {
    return SandboxApp(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      threatLevel: threatLevel ?? this.threatLevel,
      createdTime: createdTime ?? this.createdTime,
      completedTime: completedTime ?? this.completedTime,
      permissionRequests: permissionRequests ?? this.permissionRequests,
      networkRequests: networkRequests ?? this.networkRequests,
      blockedActions: blockedActions ?? this.blockedActions,
      detectedBehaviors: detectedBehaviors ?? this.detectedBehaviors,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'packageName': packageName,
    'appName': appName,
    'iconPath': iconPath,
    'sizeBytes': sizeBytes,
    'status': status.index,
    'threatLevel': threatLevel.index,
    'createdTime': createdTime.toIso8601String(),
    'completedTime': completedTime?.toIso8601String(),
    'permissionRequests': permissionRequests,
    'networkRequests': networkRequests,
    'blockedActions': blockedActions,
    'detectedBehaviors': detectedBehaviors,
  };

  factory SandboxApp.fromJson(Map<String, dynamic> json) {
    return SandboxApp(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      iconPath: json['iconPath'] as String?,
      sizeBytes: json['sizeBytes'] as int,
      status: SandboxAppStatus.values[json['status'] as int],
      threatLevel: ThreatLevel.values[json['threatLevel'] as int],
      createdTime: DateTime.parse(json['createdTime'] as String),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
      permissionRequests: json['permissionRequests'] as int? ?? 0,
      networkRequests: json['networkRequests'] as int? ?? 0,
      blockedActions: json['blockedActions'] as int? ?? 0,
      detectedBehaviors: List<String>.from(json['detectedBehaviors'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    id,
    packageName,
    appName,
    iconPath,
    sizeBytes,
    status,
    threatLevel,
    createdTime,
    completedTime,
    permissionRequests,
    networkRequests,
    blockedActions,
    detectedBehaviors,
  ];
}
