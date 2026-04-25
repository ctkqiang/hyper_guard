import 'package:equatable/equatable.dart';
import '../../../data/models/sandbox_app.dart';
import '../../../data/models/security_report.dart';

enum SandboxStatus {
  idle,
  initializing,
  ready,
  installing,
  running,
  stopping,
  error,
}

class SandboxState extends Equatable {
  final SandboxStatus status;
  final List<SandboxApp> activeApps;
  final List<BehaviorEvent> liveBehaviorEvents;
  final List<NetworkActivity> liveNetworkActivities;
  final List<PermissionAttempt> livePermissionAttempts;
  final SecurityReport? currentReport;
  final String? errorMessage;

  const SandboxState({
    this.status = SandboxStatus.idle,
    this.activeApps = const [],
    this.liveBehaviorEvents = const [],
    this.liveNetworkActivities = const [],
    this.livePermissionAttempts = const [],
    this.currentReport,
    this.errorMessage,
  });

  SandboxState copyWith({
    SandboxStatus? status,
    List<SandboxApp>? activeApps,
    List<BehaviorEvent>? liveBehaviorEvents,
    List<NetworkActivity>? liveNetworkActivities,
    List<PermissionAttempt>? livePermissionAttempts,
    SecurityReport? currentReport,
    String? errorMessage,
  }) {
    return SandboxState(
      status: status ?? this.status,
      activeApps: activeApps ?? this.activeApps,
      liveBehaviorEvents: liveBehaviorEvents ?? this.liveBehaviorEvents,
      liveNetworkActivities:
          liveNetworkActivities ?? this.liveNetworkActivities,
      livePermissionAttempts:
          livePermissionAttempts ?? this.livePermissionAttempts,
      currentReport: currentReport ?? this.currentReport,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeApps,
    liveBehaviorEvents,
    liveNetworkActivities,
    livePermissionAttempts,
    currentReport,
    errorMessage,
  ];
}
