export 'report_event.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../core/network/api_exception.dart';
import 'report_event.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;
  String? _currentCursor;

  ReportBloc({ReportRepository? reportRepository})
      : _reportRepository = reportRepository ?? ReportRepository(),
        super(const ReportInitial()) {
    on<ReportLoadRequested>(_onLoadRequested);
    on<ReportLoadMoreRequested>(_onLoadMoreRequested);
    on<ReportDetailRequested>(_onDetailRequested);
    on<ReportSubmitRequested>(_onSubmitRequested);
    on<ReportSupportRequested>(_onSupportRequested);
    on<ReportUpdateStatusRequested>(_onUpdateStatusRequested);
  }

  Future<void> _onLoadRequested(
    ReportLoadRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    _currentCursor = null;
    try {
      final response = await _reportRepository.getReports(
        categoryId: event.categoryId,
        status: event.status,
        sortBy: event.sortBy,
      );
      final data = response.data ?? [];
      _currentCursor = response.meta?.nextCursor;
      emit(ReportListLoaded(
        reports: data,
        nextCursor: _currentCursor,
        hasMore: _currentCursor != null,
        total: response.meta?.total ?? data.length,
      ));
    } on ApiException catch (e) {
      emit(ReportError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(ReportError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(ReportError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    ReportLoadMoreRequested event,
    Emitter<ReportState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ReportListLoaded || !currentState.hasMore) return;

    try {
      final response = await _reportRepository.getReports(
        cursor: _currentCursor,
      );
      final newData = response.data ?? [];
      _currentCursor = response.meta?.nextCursor;
      emit(ReportListLoaded(
        reports: [...currentState.reports, ...newData],
        nextCursor: _currentCursor,
        hasMore: _currentCursor != null,
        total: response.meta?.total ?? currentState.total,
      ));
    } catch (_) {
      // Gagal load more — tetap tampilkan data yang ada
    }
  }

  Future<void> _onDetailRequested(
    ReportDetailRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    try {
      final report = await _reportRepository.getReportById(event.reportId);
      emit(ReportDetailLoaded(report));
    } on ApiException catch (e) {
      emit(ReportError(code: e.code, message: e.userMessage));
    } catch (e) {
      emit(ReportError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  Future<void> _onSubmitRequested(
    ReportSubmitRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportSubmitting());
    try {
      final report = await _reportRepository.submitReport(
        categoryId: event.categoryId,
        latitude: event.latitude,
        longitude: event.longitude,
        addressText: event.addressText,
        description: event.description,
        photoPath: event.photoPath,
        photoUrl: event.photoUrl,
        idempotencyKey: event.idempotencyKey,
      );
      emit(ReportSubmitSuccess(report));
    } on ApiException catch (e) {
      emit(ReportError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(ReportError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(ReportError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  Future<void> _onSupportRequested(
    ReportSupportRequested event,
    Emitter<ReportState> emit,
  ) async {
    try {
      await _reportRepository.supportReport(event.reportId);
      // Refresh detail jika sedang di detail screen
      if (state is ReportDetailLoaded) {
        add(ReportDetailRequested(event.reportId));
      } else if (state is ReportListLoaded) {
        final current = state as ReportListLoaded;
        final updatedReports = current.reports.map((r) {
          if (r.id == event.reportId) {
            return r.copyWith(supportCount: r.supportCount + 1);
          }
          return r;
        }).toList();
        emit(ReportListLoaded(
          reports: updatedReports,
          nextCursor: current.nextCursor,
          hasMore: current.hasMore,
          total: current.total,
        ));
      }
    } on ApiException catch (e) {
      emit(ReportError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(ReportError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(ReportError(code: 'UNKNOWN', message: e.toString()));
    }
  }

  Future<void> _onUpdateStatusRequested(
    ReportUpdateStatusRequested event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final updated = await _reportRepository.updateReportStatus(
        event.reportId,
        event.newStatus,
        notes: event.notes,
      );
      if (state is ReportDetailLoaded) {
        emit(ReportDetailLoaded(updated));
      } else if (state is ReportListLoaded) {
        final current = state as ReportListLoaded;
        final updatedReports = current.reports.map((r) {
          if (r.id == event.reportId) {
            return updated;
          }
          return r;
        }).toList();
        emit(ReportListLoaded(
          reports: updatedReports,
          nextCursor: current.nextCursor,
          hasMore: current.hasMore,
          total: current.total,
        ));
      } else {
        add(const ReportLoadRequested());
      }
    } on ApiException catch (e) {
      emit(ReportError(code: e.code, message: e.userMessage));
    } on NetworkException catch (e) {
      emit(ReportError(code: 'NETWORK_ERROR', message: e.message));
    } catch (e) {
      emit(ReportError(code: 'STATUS_UPDATE_FAILED', message: e.toString()));
    }
  }
}

// ─── Category BLoC ────────────────────────────────────────────────────────────

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryBloc({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(const CategoryInitial()) {
    on<CategoryLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    CategoryLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final categories = await _categoryRepository.getCategories();
      emit(CategoryLoaded(categories));
    } on ApiException catch (e) {
      emit(CategoryError(e.userMessage));
    } on NetworkException catch (e) {
      emit(CategoryError(e.message));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
