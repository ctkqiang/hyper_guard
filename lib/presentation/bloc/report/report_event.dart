import 'package:equatable/equatable.dart';
import '../../../data/models/security_report.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportHistory extends ReportEvent {
  const LoadReportHistory();
}

class DeleteReport extends ReportEvent {
  final String reportId;
  const DeleteReport(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

class ExportReport extends ReportEvent {
  final String reportId;
  final String format;
  const ExportReport(this.reportId, this.format);

  @override
  List<Object?> get props => [reportId, format];
}

class SelectReport extends ReportEvent {
  final SecurityReport report;
  const SelectReport(this.report);

  @override
  List<Object?> get props => [report];
}

class ClearSelection extends ReportEvent {
  const ClearSelection();
}
