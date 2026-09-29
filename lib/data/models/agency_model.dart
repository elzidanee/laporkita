// STATUS: NOT YET VERIFIED — skema dari Postman (POST /agencies body:
// {name, type, contact_email}) — CreateAgencyDto kosong di Swagger.
// Parse defensif: field tak dikenal diabaikan, fallback aman.
class AgencyModel {
  final String id;
  final String name;
  final String? type;
  final String? contactEmail;
  final DateTime? createdAt;

  const AgencyModel({
    required this.id,
    required this.name,
    this.type,
    this.contactEmail,
    this.createdAt,
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Dinas Terkait',
      type: json['type']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
