class DriverVehicleModel {
  final String id;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final double basePrice;
  final double pricePerKm;
  final String licensePlate;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final bool isActive;

  DriverVehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.basePrice,
    required this.pricePerKm,
    required this.licensePlate,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.isActive,
  });

  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    final vt = json['vehicleType'] ?? {};
    return DriverVehicleModel(
      id: json['id'] ?? '',
      vehicleTypeId: vt['id'] ?? '',
      vehicleTypeName: vt['name'] ?? '',
      basePrice: (vt['basePrice'] ?? 0).toDouble(),
      pricePerKm: (vt['pricePerKm'] ?? 0).toDouble(),
      licensePlate: json['licensePlate'] ?? '',
      vehicleBrand: json['vehicleBrand'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleColor: json['vehicleColor'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}
