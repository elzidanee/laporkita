import '../../core/network/api_response.dart';
import '../datasources/remote/report_remote_datasource.dart';
import '../models/report_model.dart';

class ReportRepository {
  final ReportRemoteDatasource _datasource;
  final List<ReportModel> _submittedReports = [];

  ReportRepository({ReportRemoteDatasource? datasource})
      : _datasource = datasource ?? ReportRemoteDatasource();

  List<ReportModel> get localSubmittedReports =>
      List.unmodifiable(_submittedReports);

  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    String sortBy = 'newest',
  }) async {
    final response = await _datasource.getReports(
      limit: limit,
      cursor: cursor,
      status: status,
      categoryId: categoryId,
      reporterId: reporterId,
      sortBy: sortBy,
    );

    final remoteData = response.data ?? [];
    final merged = <ReportModel>[];
    final seenIds = <String>{};

    for (final r in _submittedReports) {
      if (!seenIds.contains(r.id)) {
        seenIds.add(r.id);
        merged.add(r);
      }
    }

    for (final r in remoteData) {
      if (!seenIds.contains(r.id)) {
        seenIds.add(r.id);
        merged.add(r);
      } else {
        final idx = merged.indexWhere((item) => item.id == r.id);
        if (idx != -1) {
          final localItem = merged[idx];
          if (localItem.directPhotoUrl != null &&
              localItem.directPhotoUrl!.isNotEmpty) {
            merged[idx] = ReportModel(
              id: r.id,
              reportCode: r.reportCode,
              reporterId: r.reporterId,
              categoryId: r.categoryId,
              status: r.status,
              latitude: r.latitude,
              longitude: r.longitude,
              addressText: r.addressText,
              description: r.description,
              directPhotoUrl: localItem.directPhotoUrl,
              supportCount: r.supportCount,
              viewCount: r.viewCount,
              urgencyScore: r.urgencyScore,
              needsManualReview: r.needsManualReview,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
              category: r.category,
              reporter: r.reporter,
              assignedAgency: r.assignedAgency,
              media: r.media,
              statusHistory: r.statusHistory,
              count: r.count,
            );
          }
        }
      }
    }

    return ApiResponse(
      success: response.success,
      data: merged,
      error: response.error,
      meta: response.meta,
    );
  }

  Future<ReportModel> getReportById(String id) =>
      _datasource.getReportById(id);

  Future<ReportModel> submitReport({
    required String categoryId,
    required double latitude,
    required double longitude,
    String? addressText,
    String? description,
    String? photoPath,
    String? photoUrl,
    String? idempotencyKey,
  }) async {
    final result = await _datasource.submitReport(
      categoryId: categoryId,
      latitude: latitude,
      longitude: longitude,
      addressText: addressText,
      description: description,
      photoPath: photoPath,
      photoUrl: photoUrl,
      idempotencyKey: idempotencyKey,
    );

    _submittedReports.removeWhere((item) => item.id == result.id);
    _submittedReports.insert(0, result);
    return result;
  }

  Future<Map<String, dynamic>> supportReport(String reportId) =>
      _datasource.supportReport(reportId);

  Future<Map<String, dynamic>> cancelSupport(String reportId) =>
      _datasource.cancelSupport(reportId);

  Future<ApiResponse<List<Map<String, dynamic>>>> getComments(
    String reportId, {
    int limit = 20,
    String? cursor,
  }) {
    return _datasource.getComments(reportId, limit: limit, cursor: cursor);
  }

  Future<Map<String, dynamic>> addComment(
    String reportId,
    String content,
  ) {
    return _datasource.addComment(reportId, content);
  }

  /// Check whether there are nearby/similar active reports at lat/lng
  Future<List<ReportModel>> checkSimilarReports({
    required double latitude,
    required double longitude,
    double radiusDegree = 0.005,
  }) async {
    try {
      final response = await _datasource.getReports(
        minLat: latitude - radiusDegree,
        maxLat: latitude + radiusDegree,
        minLng: longitude - radiusDegree,
        maxLng: longitude + radiusDegree,
        limit: 5,
      );
      return response.data ?? [];
    } catch (_) {
      return [];
    }
  }
}
