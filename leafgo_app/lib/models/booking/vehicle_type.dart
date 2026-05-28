class VehicleType {
  final String id;
  final String name;
  final int availableDrivers;
  final double basePrice;
  final double pricePerKm;
  final String? description;

  VehicleType({
    required this.id,
    required this.name,
    required this.availableDrivers,
    required this.basePrice,
    required this.pricePerKm,
    this.description,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'],
      name: json['name'],
      availableDrivers: json['availableDrivers'] ?? 0,
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      pricePerKm: (json['pricePerKm'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}
