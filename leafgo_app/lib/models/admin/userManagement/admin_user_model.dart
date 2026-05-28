import 'package:leafgo_app/models/admin/userManagement/user_stats_model.dart';
import 'package:leafgo_app/models/admin/userManagement/vehicle_info_model.dart';

class AdminUserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? avatar;
  final bool isActive;
  final bool isOnline;
  final DateTime createdAt;
  final VehicleInfo? vehicle;
  final UserStats? stats;

  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.avatar,
    required this.isActive,
    required this.isOnline,
    required this.createdAt,
    this.vehicle,
    this.stats,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      isActive: json['isActive'] as bool,
      isOnline: json['isOnline'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'])
          : null,
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
    );
  }
}
