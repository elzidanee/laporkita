// STATUS: VERIFIED — dari backend/src/modules/categories/categories.repository.ts (CategoryWithAgency type)
// CategoryWithAgency = Category & { default_agency: { id, name, type } | null }

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final String? defaultAgencyId;
  final Map<String, dynamic>? defaultAgency;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.isActive,
    this.defaultAgencyId,
    this.defaultAgency,
    required this.createdAt,
  });

  // STATUS: VERIFIED — field dari Prisma Category model
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      defaultAgencyId: json['default_agency_id'] as String?,
      defaultAgency: json['default_agency'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Nama dinas terkait
  String get agencyName =>
      defaultAgency?['name'] as String? ?? 'Dinas Terkait';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          (id == other.id || name == other.name);

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
