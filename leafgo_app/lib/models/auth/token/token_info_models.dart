class TokenInfoModel {
  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String createdByIp;
  final bool isActive;

  const TokenInfoModel({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.createdByIp,
    required this.isActive,
  });

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) {
    return TokenInfoModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdByIp: json['createdByIp'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}
