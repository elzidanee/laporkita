import 'dart:io';
import 'package:dio/dio.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/data/models/report_model.dart';

/// Report Remote Datasource
/// STATUS: VERIFIED — endpoint dari backend/src/modules/reports/reports.controller.ts
class ReportRemoteDatasource {
  final DioClient _dioClient;

  ReportRemoteDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  // ── Get List Reports ───────────────────────────────────────────────────────
  // STATUS: VERIFIED — GET /reports (publik)
  Future<ApiResponse<List<ReportModel>>> getReports({
    int limit = 20,
    String? cursor,
    String? status,
    String? categoryId,
    String? reporterId,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
    String sortBy = 'newest',
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'sort_by': sortBy,
      if (cursor case final c?) 'cursor': c,
      if (status case final s?) 'status': s,
      if (categoryId case final cat?) 'category_id': cat,
      if (reporterId case final r?) 'reporter_id': r,
      if (minLat case final lat?) 'min_lat': lat,
      if (maxLat case final lat?) 'max_lat': lat,
      if (minLng case final lng?) 'min_lng': lng,
      if (maxLng case final lng?) 'max_lng': lng,
    };

    return _dioClient.get<List<ReportModel>>(
      '/reports',
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map((e) => ReportModel.fromJson(e))
              .toList();
        } else if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['reports'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map((e) => ReportModel.fromJson(e))
                .toList();
          }
        }
        return <ReportModel>[];
      },
      queryParameters: queryParams,
    );
  }

  // ── Get Report Detail ──────────────────────────────────────────────────────
  // STATUS: VERIFIED — GET /reports/:id (publik)
  Future<ReportModel> getReportById(String id) async {
    final response = await _dioClient.get<ReportModel>(
      '/reports/$id',
      fromJson: (json) =>
          ReportModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  // ── Submit Report ──────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /reports (auth required)
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
    final Map<String, dynamic> map = {
      'category_id': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      if (addressText case final addr?) 'address_text': addr,
      if (description case final desc?) 'description': desc,
      if (idempotencyKey case final key?) 'idempotency_key': key,
    };

    bool isLocalValid = false;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !photoPath.startsWith('http')) {
      try {
        isLocalValid = File(photoPath).existsSync();
      } catch (_) {
        isLocalValid = false;
      }
    }

    if (isLocalValid && photoPath != null) {
      map['photo'] = await MultipartFile.fromFile(
        photoPath,
        filename: 'report_photo.jpg',
      );
    } else {
      // Foto wajib ada — lempar error agar UI dapat memblokir submit
      // sebelum request dikirim (FE-07 fix: hapus dummy JPEG fallback).
      throw ArgumentError(
        'Foto laporan tidak valid atau tidak ditemukan. '
        'Harap ambil foto terlebih dahulu sebelum mengirim laporan.',
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _dioClient.post<ReportModel>(
      '/reports',
      fromJson: (json) =>
          ReportModel.fromJson(json as Map<String, dynamic>),
      formData: formData,
    );
    final result = response.data!;

    // Pasang photoPath lokal hanya jika result tidak memiliki photoUrl dari backend
    bool isLocalFileValid = false;
    if (photoPath.isNotEmpty &&
        !photoPath.startsWith('http')) {
      try {
        isLocalFileValid = File(photoPath).existsSync();
      } catch (_) {
        isLocalFileValid = false;
      }
    }

    if (isLocalFileValid) {
      final String currentUrl = result.photoUrl ?? '';
      if (currentUrl.isEmpty) {
        return ReportModel(
          id: result.id,
          reportCode: result.reportCode,
          reporterId: result.reporterId,
          categoryId: result.categoryId,
          status: result.status,
          latitude: result.latitude,
          longitude: result.longitude,
          addressText: result.addressText,
          description: result.description,
          directPhotoUrl: photoPath,
          supportCount: result.supportCount,
          viewCount: result.viewCount,
          urgencyScore: result.urgencyScore,
          needsManualReview: result.needsManualReview,
          createdAt: result.createdAt,
          updatedAt: result.updatedAt,
          category: result.category,
          reporter: result.reporter,
          assignedAgency: result.assignedAgency,
          media: result.media,
          statusHistory: result.statusHistory,
          count: result.count,
        );
      }
    }

    return result;
  }

  // ── Support Report (Upvote) ────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /reports/:id/support (auth required)
  Future<Map<String, dynamic>> supportReport(String reportId) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/reports/$reportId/support',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {},
    );
    return response.data!;
  }

  // ── Cancel Support ─────────────────────────────────────────────────────────
  // STATUS: VERIFIED — DELETE /reports/:id/support (auth required, grace 5 menit)
  Future<Map<String, dynamic>> cancelSupport(String reportId) async {
    final response = await _dioClient.delete<Map<String, dynamic>>(
      '/reports/$reportId/support',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response.data!;
  }

  // ── Get Comments ───────────────────────────────────────────────────────────
  // STATUS: VERIFIED — GET /reports/:id/comments (publik)
  Future<ApiResponse<List<Map<String, dynamic>>>> getComments(
    String reportId, {
    int limit = 20,
    String? cursor,
  }) async {
    return _dioClient.get<List<Map<String, dynamic>>>(
      '/reports/$reportId/comments',
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      queryParameters: {
        'limit': limit,
        if (cursor case final c?) 'cursor': c,
      },
    );
  }

  // ── Add Comment ────────────────────────────────────────────────────────────
  // STATUS: VERIFIED — POST /reports/:id/comments (auth required)
  Future<Map<String, dynamic>> addComment(
    String reportId,
    String content,
  ) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/reports/$reportId/comments',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {'content': content},
    );
    return response.data!;
  }

  // ── Validate Report (Citizen) ──────────────────────────────────────────────
  // STATUS: FE-06 — POST /reports/:id/validate (auth required)
  // Warga mengkonfirmasi laporan mereka sudah selesai ditangani.
  Future<Map<String, dynamic>> validateReport(String reportId) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/reports/$reportId/validate',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {},
    );
    return response.data!;
  }

  // ── Update Report Status (Operator) ───────────────────────────────────────
  // STATUS: FE-06 — PATCH /reports/:id/status (auth required, operator role)
  // Operator dinas mengubah status laporan (assigned, in_progress, completed, dll).
  Future<ReportModel> updateReportStatus(
    String reportId,
    String newStatus, {
    String? notes,
    String? assignedAgencyId,
  }) async {
    try {
      final response = await _dioClient.patch<ReportModel>(
        '/reports/$reportId/status',
        fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
        data: {
          'status': newStatus,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (assignedAgencyId != null) 'assigned_agency_id': assignedAgencyId,
        },
      );
      return response.data!;
    } catch (_) {
      try {
        final uppercaseStatus = newStatus.toUpperCase();
        final response = await _dioClient.patch<ReportModel>(
          '/reports/$reportId/status',
          fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
          data: {
            'status': uppercaseStatus,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            if (assignedAgencyId != null) 'assigned_agency_id': assignedAgencyId,
          },
        );
        return response.data!;
      } catch (_) {
        final response = await _dioClient.patch<ReportModel>(
          '/reports/$reportId',
          fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
          data: {
            'status': newStatus,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            if (assignedAgencyId != null) 'assigned_agency_id': assignedAgencyId,
          },
        );
        return response.data!;
      }
    }
  }
}
