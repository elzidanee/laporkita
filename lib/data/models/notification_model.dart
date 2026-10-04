/// Notification Model — matching GET /notifications & POST /route-alerts
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? data;
  final String? referenceReportId;
  final Map<String, dynamic>? referenceReport;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.isRead = false,
    this.type,
    this.data,
    this.referenceReportId,
    this.referenceReport,
    required this.createdAt,
  });

  String? get reportId =>
      referenceReportId ??
      (data?['report_id'] as String?) ??
      (data?['id'] as String?);

  String? get reportCode =>
      referenceReport?['report_code'] as String? ??
      (data?['report_code'] as String?) ??
      (data?['reportCode'] as String?);

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final refReportId = json['reference_report_id'] as String?;
    final refReport = json['reference_report'] as Map<String, dynamic>?;
    final Map<String, dynamic> mergedData = {};
    if (json['data'] is Map<String, dynamic>) {
      mergedData.addAll(json['data'] as Map<String, dynamic>);
    }
    if (refReportId != null && refReportId.isNotEmpty) {
      mergedData['report_id'] = refReportId;
      mergedData['id'] = refReportId;
    }
    if (refReport != null) {
      if (refReport['id'] != null) mergedData['report_id'] = refReport['id'];
      if (refReport['report_code'] != null) {
        mergedData['report_code'] = refReport['report_code'];
        mergedData['reportCode'] = refReport['report_code'];
      }
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? json['type'] as String? ?? 'Notifikasi',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      type: json['type'] as String?,
      data: mergedData.isNotEmpty ? mergedData : (json['data'] as Map<String, dynamic>?),
      referenceReportId: refReportId,
      referenceReport: refReport,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': isRead,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0 && now.day == createdAt.day) {
      final h = createdAt.hour.toString().padLeft(2, '0');
      final m = createdAt.minute.toString().padLeft(2, '0');
      return '$h.$m';
    } else if (diff.inDays <= 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
