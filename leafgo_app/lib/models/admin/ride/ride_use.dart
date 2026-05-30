class RideUser {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;

  const RideUser({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
  });

  factory RideUser.fromJson(Map<String, dynamic> json) {
    return RideUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
    );
  }
}
