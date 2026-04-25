import 'package:equatable/equatable.dart';
import '../../../data/models/security_report.dart';

abstract class SandboxEvent extends Equatable {
  const SandboxEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSandbox extends SandboxEvent {
  const InitializeSandbox();
}

class InstallToSandbox extends SandboxEvent {
  final String apkPath;
  const InstallToSandbox(this.apkPath);

  @override
  List<Object?> get props => [apkPath];
}

class StartAnalysis extends SandboxEvent {
  final String appId;
  const StartAnalysis(this.appId);

  @override
  List<Object?> get props => [appId];
}

class StopSandbox extends SandboxEvent {
  final String appId;
  const StopSandbox(this.appId);

  @override
  List<Object?> get props => [appId];
}

class TerminateSandbox extends SandboxEvent {
  final String appId;
  const TerminateSandbox(this.appId);

  @override
  List<Object?> get props => [appId];
}

class RefreshSandboxApps extends SandboxEvent {
  const RefreshSandboxApps();
}

class GenerateReport extends SandboxEvent {
  final String sandboxAppId;
  const GenerateReport(this.sandboxAppId);

  @override
  List<Object?> get props => [sandboxAppId];
}

class BehaviorEventReceived extends SandboxEvent {
  final BehaviorEvent event;
  const BehaviorEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}

class NetworkActivityReceived extends SandboxEvent {
  final NetworkActivity event;
  const NetworkActivityReceived(this.event);

  @override
  List<Object?> get props => [event];
}

class PermissionAttemptReceived extends SandboxEvent {
  final PermissionAttempt event;
  const PermissionAttemptReceived(this.event);

  @override
  List<Object?> get props => [event];
}
