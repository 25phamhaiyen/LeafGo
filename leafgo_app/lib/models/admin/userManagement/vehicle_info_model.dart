class VehicleInfo {
  final String licensePlate;
  final String vehicleTypeName;
  final String vehicleBrand;

  const VehicleInfo({
    required this.licensePlate,
    required this.vehicleTypeName,
    required this.vehicleBrand,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      licensePlate: json['licensePlate'] as String,
      vehicleTypeName: json['vehicleTypeName'] as String,
      vehicleBrand: json['vehicleBrand'] as String,
    );
  }
}
