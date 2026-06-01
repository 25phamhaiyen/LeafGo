class RideUserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? avatar;
  final double? rating;
  final int? totalRides;

  RideUserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.avatar,
    this.rating,
    this.totalRides,
  });

  factory RideUserModel.fromJson(Map<String, dynamic> json) {
    String? parseAvatar() {
      return json['avatar'] as String? ??
          json['Avatar'] as String? ??
          json['avatarUrl'] as String? ??
          json['AvatarUrl'] as String?;
    }

    return RideUserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'Hành khách',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      avatar: parseAvatar(),
      totalRides: json['totalRides'] as int?,
    );
  }
}
