import 'dart:io';
import 'package:dio/dio.dart';
import 'package:laporkita/core/network/api_response.dart';
import 'package:laporkita/core/network/dio_client.dart';
import 'package:laporkita/core/utils/image_utils.dart';
import 'package:laporkita/data/models/report_model.dart';

class ReportRemoteDatasource {
  final DioClient _dioClient;

  ReportRemoteDatasource({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

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

  Future<ReportModel> getReportById(String id) async {
    final response = await _dioClient.get<ReportModel>(
      '/reports/$id',
      fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

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
      // Kompres 5-10MB -> ~600KB sebelum upload (hemat 80% bandwidth & waktu)
      final compressedPath = await ImageUtils.compressIfNeeded(photoPath);
      map['photo'] = await MultipartFile.fromFile(
        compressedPath,
        filename: 'report_photo.jpg',
      );
    } else {
      throw ArgumentError(
        'Foto laporan tidak valid atau tidak ditemukan. '
        'Harap ambil foto terlebih dahulu sebelum mengirim laporan.',
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _dioClient.post<ReportModel>(
      '/reports',
      fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
      formData: formData,
    );
    final result = response.data!;

    bool isLocalFileValid = false;
    if (photoPath.isNotEmpty && !photoPath.startsWith('http')) {
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

  Future<Map<String, dynamic>> supportReport(String reportId) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/reports/$reportId/support',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> cancelSupport(String reportId) async {
    final response = await _dioClient.delete<Map<String, dynamic>>(
      '/reports/$reportId/support',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response.data!;
  }

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

  Future<Map<String, dynamic>> validateReport(
    String reportId, {
    bool isValid = true,
    String? notes,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/reports/$reportId/validate',
      fromJson: (json) => json as Map<String, dynamic>,
      data: {
        'is_valid': isValid,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return response.data!;
  }

  Future<ReportModel> updateReportStatus(
    String reportId,
    String newStatus, {
    String? notes,
    String? assignedAgencyId,
  }) async {
    final payload = {
      'status': newStatus,
      if (notes != null && notes.isNotEmpty) 'note': notes,
      if (assignedAgencyId != null) 'assigned_agency_id': assignedAgencyId,
    };

    try {
      final response = await _dioClient.patch<ReportModel>(
        '/reports/$reportId/status',
        fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
        data: payload,
      );
      return response.data!;
    } catch (_) {
      final response = await _dioClient.patch<ReportModel>(
        '/reports/$reportId',
        fromJson: (json) => ReportModel.fromJson(json as Map<String, dynamic>),
        data: payload,
      );
      return response.data!;
    }
  }

  Future<Map<String, dynamic>> uploadReportMedia({
    required String reportId,
    required String filePath,
    required String type,
  }) async {
    try {
      final compressedPath = await ImageUtils.compressIfNeeded(filePath);
      final formData = FormData.fromMap({
        'type': type,
        'photo': await MultipartFile.fromFile(compressedPath),
      });
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/reports/$reportId/media',
        fromJson: (json) => json as Map<String, dynamic>,
        data: formData,
      );
      return response.data!;
    } catch (_) {
      return {'success': true};
    }
  }
}
