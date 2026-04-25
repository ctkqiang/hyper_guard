import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../services/sandbox_service.dart';
import '../../../services/monitor_service.dart';
import '../../../data/models/sandbox_app.dart';
import '../../../data/models/security_report.dart';
import 'sandbox_event.dart';
import 'sandbox_state.dart';

class SandboxBloc extends Bloc<SandboxEvent, SandboxState> {
  final SandboxService _sandboxService;
  final MonitorService _monitorService;
  StreamSubscription<BehaviorEvent>? _behaviorSub;
  StreamSubscription<NetworkActivity>? _networkSub;
  StreamSubscription<PermissionAttempt>? _permissionSub;

  SandboxBloc({SandboxService? sandboxService, MonitorService? monitorService})
    : _sandboxService = sandboxService ?? SandboxService(),
      _monitorService = monitorService ?? MonitorService(),
      super(const SandboxState()) {
    on<InitializeSandbox>(_onInitialize);
    on<InstallToSandbox>(_onInstall);
    on<StartAnalysis>(_onStartAnalysis);
    on<StopSandbox>(_onStop);
    on<TerminateSandbox>(_onTerminate);
    on<RefreshSandboxApps>(_onRefresh);
    on<GenerateReport>(_onGenerateReport);
    on<BehaviorEventReceived>(_onBehavior);
    on<NetworkActivityReceived>(_onNetwork);
    on<PermissionAttemptReceived>(_onPermission);
  }

  void _subscribeToStreams() {
    _behaviorSub = _sandboxService.behaviorStream.listen((event) {
      if (!isClosed) add(BehaviorEventReceived(event));
    });
    _networkSub = _sandboxService.networkStream.listen((event) {
      if (!isClosed) add(NetworkActivityReceived(event));
    });
    _permissionSub = _sandboxService.permissionStream.listen((event) {
      if (!isClosed) add(PermissionAttemptReceived(event));
    });
  }

  Future<void> _onInitialize(
    InitializeSandbox event,
    Emitter<SandboxState> emit,
  ) async {
    emit(state.copyWith(status: SandboxStatus.initializing));
    try {
      final success = await _sandboxService.initializeSandbox();
      if (success) {
        _subscribeToStreams();
        final apps = await _sandboxService.getActiveSandboxApps();
        emit(state.copyWith(status: SandboxStatus.ready, activeApps: apps));
      } else {
        emit(
          state.copyWith(status: SandboxStatus.error, errorMessage: '沙盒初始化失败'),
        );
      }
    } catch (e) {
      debugPrint('SandboxBloc init error: $e');
      emit(
        state.copyWith(
          status: SandboxStatus.error,
          errorMessage: '沙盒初始化异常: $e',
        ),
      );
    }
  }

  Future<void> _onInstall(
    InstallToSandbox event,
    Emitter<SandboxState> emit,
  ) async {
    emit(state.copyWith(status: SandboxStatus.installing));
    try {
      final app = await _sandboxService.installToSandbox(event.apkPath);
      final updatedApps = List<SandboxApp>.from(state.activeApps)..add(app);
      emit(
        state.copyWith(status: SandboxStatus.ready, activeApps: updatedApps),
      );
    } catch (e) {
      debugPrint('SandboxBloc install error: $e');
      emit(
        state.copyWith(status: SandboxStatus.error, errorMessage: '蜜罐安装失败: $e'),
      );
    }
  }

  Future<void> _onStartAnalysis(
    StartAnalysis event,
    Emitter<SandboxState> emit,
  ) async {
    emit(state.copyWith(status: SandboxStatus.running));
    try {
      await _sandboxService.startSandboxAnalysis(event.appId);
    } catch (e) {
      debugPrint('SandboxBloc analysis error: $e');
      emit(
        state.copyWith(
          status: SandboxStatus.error,
          errorMessage: '沙盒分析启动失败: $e',
        ),
      );
    }
  }

  Future<void> _onStop(StopSandbox event, Emitter<SandboxState> emit) async {
    emit(state.copyWith(status: SandboxStatus.stopping));
    try {
      await _sandboxService.stopSandbox(event.appId);
      final apps = await _sandboxService.getActiveSandboxApps();
      emit(state.copyWith(status: SandboxStatus.ready, activeApps: apps));
    } catch (e) {
      emit(
        state.copyWith(status: SandboxStatus.error, errorMessage: '停止沙盒失败: $e'),
      );
    }
  }

  Future<void> _onTerminate(
    TerminateSandbox event,
    Emitter<SandboxState> emit,
  ) async {
    try {
      await _sandboxService.terminateSandbox(event.appId);
      final apps = state.activeApps
          .map(
            (a) => a.id == event.appId
                ? a.copyWith(status: SandboxAppStatus.completed)
                : a,
          )
          .toList();
      emit(state.copyWith(activeApps: apps));
    } catch (e) {
      emit(
        state.copyWith(status: SandboxStatus.error, errorMessage: '终止沙盒失败: $e'),
      );
    }
  }

  Future<void> _onRefresh(
    RefreshSandboxApps event,
    Emitter<SandboxState> emit,
  ) async {
    try {
      final apps = await _sandboxService.getActiveSandboxApps();
      emit(state.copyWith(activeApps: apps));
    } catch (e) {
      debugPrint('SandboxBloc refresh error: $e');
    }
  }

  Future<void> _onGenerateReport(
    GenerateReport event,
    Emitter<SandboxState> emit,
  ) async {
    try {
      final report = await _monitorService.generateReport(event.sandboxAppId);
      emit(state.copyWith(currentReport: report));
    } catch (e) {
      debugPrint('SandboxBloc report error: $e');
    }
  }

  void _onBehavior(BehaviorEventReceived event, Emitter<SandboxState> emit) {
    final updated = List<BehaviorEvent>.from(state.liveBehaviorEvents)
      ..add(event.event);
    emit(state.copyWith(liveBehaviorEvents: updated));
  }

  void _onNetwork(NetworkActivityReceived event, Emitter<SandboxState> emit) {
    final updated = List<NetworkActivity>.from(state.liveNetworkActivities)
      ..add(event.event);
    emit(state.copyWith(liveNetworkActivities: updated));
  }

  void _onPermission(
    PermissionAttemptReceived event,
    Emitter<SandboxState> emit,
  ) {
    final updated = List<PermissionAttempt>.from(state.livePermissionAttempts)
      ..add(event.event);
    emit(state.copyWith(livePermissionAttempts: updated));
  }

  @override
  Future<void> close() {
    _behaviorSub?.cancel();
    _networkSub?.cancel();
    _permissionSub?.cancel();
    return super.close();
  }
}
