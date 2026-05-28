class RideDriver {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String licensePlate;

  const RideDriver({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.licensePlate,
  });

  factory RideDriver.fromJson(Map<String, dynamic> json) {
    return RideDriver(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      licensePlate: json['licensePlate'] as String,
    );
  }
}
