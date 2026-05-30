import 'dart:io';

import 'package:leafgo_app/models/auth/userEntity/user_models.dart';
import 'package:leafgo_app/services/datasources/user_remote_datasource.dart';

import 'package:image_picker/image_picker.dart';

abstract class UserRepository {
  Future<UserModel> getProfile(String token);
  Future<UserModel> updateProfile(
    String fullName,
    String phoneNumber,
    String token,
  );
  Future<String> uploadAvatar(XFile imageFile, String token);
  Future<Map<String, dynamic>> getRideHistory({
    int page = 1,
    int pageSize = 10,
    String? status,
    required String token,
  });
}

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remote;

  UserRepositoryImpl({required this.remote});

  @override
  Future<UserModel> getProfile(String token) => remote.getProfile(token);

  @override
  Future<UserModel> updateProfile(
    String fullName,
    String phoneNumber,
    String token,
  ) => remote.updateProfile(fullName, phoneNumber, token);

  @override
  Future<String> uploadAvatar(XFile imageFile, String token) =>
      remote.uploadAvatar(imageFile, token);

  @override
  Future<Map<String, dynamic>> getRideHistory({
    int page = 1,
    int pageSize = 10,
    String? status,
    required String token,
  }) => remote.getRideHistory(
    page: page,
    pageSize: pageSize,
    status: status,
    token: token,
  );
}
