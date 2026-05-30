class RideUserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final double? rating;
  final int? totalRides;

  RideUserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.rating,
    this.totalRides,
  });

  factory RideUserModel.fromJson(Map<String, dynamic> json) {
    return RideUserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'Hành khách',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      totalRides: json['totalRides'] as int?,
    );
  }
}
