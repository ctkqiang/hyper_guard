import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../services/monitor_service.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final MonitorService _monitorService;

  ReportBloc({MonitorService? monitorService})
    : _monitorService = monitorService ?? MonitorService(),
      super(const ReportState()) {
    on<LoadReportHistory>(_onLoad);
    on<DeleteReport>(_onDelete);
    on<ExportReport>(_onExport);
    on<SelectReport>(_onSelect);
    on<ClearSelection>(_onClear);
  }

  Future<void> _onLoad(
    LoadReportHistory event,
    Emitter<ReportState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final reports = await _monitorService.getReportHistory();
      emit(state.copyWith(status: ReportStatus.loaded, reports: reports));
    } catch (e) {
      debugPrint('ReportBloc load error: $e');
      emit(
        state.copyWith(
          status: ReportStatus.error,
          errorMessage: '加载报告历史失败: $e',
        ),
      );
    }
  }

  Future<void> _onDelete(DeleteReport event, Emitter<ReportState> emit) async {
    emit(state.copyWith(status: ReportStatus.deleting));
    try {
      final success = await _monitorService.deleteReport(event.reportId);
      if (success) {
        final updated = state.reports
            .where((r) => r.id != event.reportId)
            .toList();
        emit(
          state.copyWith(
            status: ReportStatus.loaded,
            reports: updated,
            selectedReport: state.selectedReport?.id == event.reportId
                ? null
                : state.selectedReport,
          ),
        );
      }
    } catch (e) {
      debugPrint('ReportBloc delete error: $e');
      emit(
        state.copyWith(status: ReportStatus.error, errorMessage: '删除报告失败: $e'),
      );
    }
  }

  Future<void> _onExport(ExportReport event, Emitter<ReportState> emit) async {
    emit(state.copyWith(status: ReportStatus.exporting));
    try {
      await _monitorService.exportReport(event.reportId, event.format);
      emit(state.copyWith(status: ReportStatus.loaded));
    } catch (e) {
      debugPrint('ReportBloc export error: $e');
      emit(
        state.copyWith(status: ReportStatus.error, errorMessage: '导出报告失败: $e'),
      );
    }
  }

  void _onSelect(SelectReport event, Emitter<ReportState> emit) {
    emit(state.copyWith(selectedReport: event.report));
  }

  void _onClear(ClearSelection event, Emitter<ReportState> emit) {
    emit(state.copyWith(selectedReport: null));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
