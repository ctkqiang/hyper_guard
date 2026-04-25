import 'package:equatable/equatable.dart';
import '../../../data/models/security_report.dart';

enum ReportStatus { initial, loading, loaded, exporting, deleting, error }

class ReportState extends Equatable {
  final ReportStatus status;
  final List<SecurityReport> reports;
  final SecurityReport? selectedReport;
  final String? errorMessage;

  const ReportState({
    this.status = ReportStatus.initial,
    this.reports = const [],
    this.selectedReport,
    this.errorMessage,
  });

  ReportState copyWith({
    ReportStatus? status,
    List<SecurityReport>? reports,
    SecurityReport? selectedReport,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      selectedReport: selectedReport ?? this.selectedReport,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, reports, selectedReport, errorMessage];
}
