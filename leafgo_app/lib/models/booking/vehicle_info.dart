class VehicleInfo {
  final String licensePlate;
  final String brand;
  final String model;
  final String color;

  VehicleInfo({
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      licensePlate: json['licensePlate'] ?? 'N/A',
      brand: json['vehicleBrand'] ?? json['brand'] ?? 'N/A',
      model: json['vehicleModel'] ?? json['model'] ?? 'N/A',
      color: json['vehicleColor'] ?? json['color'] ?? 'N/A',
    );
  }
}
