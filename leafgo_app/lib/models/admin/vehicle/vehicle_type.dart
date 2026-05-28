class VehicleTypeModel {
  final String id;
  final String name;
  final double basePrice;
  final double pricePerKm;
  final String? description;
  final bool isActive;
  final int totalDrivers;
  final int totalRides;

  const VehicleTypeModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.pricePerKm,
    this.description,
    required this.isActive,
    required this.totalDrivers,
    required this.totalRides,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      basePrice: (json['basePrice'] as num).toDouble(),
      pricePerKm: (json['pricePerKm'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['isActive'] as bool,
      totalDrivers: json['totalDrivers'] as int,
      totalRides: json['totalRides'] as int,
    );
  }
}
