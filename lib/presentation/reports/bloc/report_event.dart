import 'package:equatable/equatable.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/category_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class ReportLoadRequested extends ReportEvent {
  final String? categoryId;
  final String? status;
  final String sortBy;

  const ReportLoadRequested({
    this.categoryId,
    this.status,
    this.sortBy = 'newest',
  });

  @override
  List<Object?> get props => [categoryId, status, sortBy];
}

class ReportLoadMoreRequested extends ReportEvent {
  const ReportLoadMoreRequested();
}

class ReportDetailRequested extends ReportEvent {
  final String reportId;
  const ReportDetailRequested(this.reportId);
  @override
  List<Object?> get props => [reportId];
}

class ReportSubmitRequested extends ReportEvent {
  final String categoryId;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? description;
  final String? photoPath;
  final String? photoUrl;
  final String? idempotencyKey;

  const ReportSubmitRequested({
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    this.addressText,
    this.description,
    this.photoPath,
    this.photoUrl,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [categoryId, latitude, longitude];
}

class ReportSupportRequested extends ReportEvent {
  final String reportId;
  const ReportSupportRequested(this.reportId);
  @override
  List<Object?> get props => [reportId];
}

class ReportUpdateStatusRequested extends ReportEvent {
  final String reportId;
  final String newStatus;
  final String? notes;

  const ReportUpdateStatusRequested({
    required this.reportId,
    required this.newStatus,
    this.notes,
  });

  @override
  List<Object?> get props => [reportId, newStatus, notes];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportListLoaded extends ReportState {
  final List<ReportModel> reports;
  final String? nextCursor;
  final bool hasMore;
  final int total;

  const ReportListLoaded({
    required this.reports,
    this.nextCursor,
    required this.hasMore,
    required this.total,
  });

  @override
  List<Object?> get props => [reports, nextCursor, hasMore, total];
}

class ReportDetailLoaded extends ReportState {
  final ReportModel report;
  const ReportDetailLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class ReportSubmitSuccess extends ReportState {
  final ReportModel report;
  const ReportSubmitSuccess(this.report);
  @override
  List<Object?> get props => [report];
}

class ReportSubmitting extends ReportState {
  const ReportSubmitting();
}

class ReportError extends ReportState {
  final String code;
  final String message;
  const ReportError({required this.code, required this.message});
  @override
  List<Object?> get props => [code, message];
}

// ─── Category Events & States ─────────────────────────────────────────────────

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class CategoryLoadRequested extends CategoryEvent {
  const CategoryLoadRequested();
}

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  const CategoryLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}
