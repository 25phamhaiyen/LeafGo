import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:leafgo_app/models/auth/userEntity/user_models.dart';
import 'package:image_picker/image_picker.dart';

abstract class UserRemoteDataSource {
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

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  UserRemoteDataSourceImpl({required this.client, required this.baseUrl});

  @override
  Future<UserModel> getProfile(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/Users/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return UserModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to load profile');
  }

  @override
  Future<UserModel> updateProfile(
    String fullName,
    String phoneNumber,
    String token,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/Users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'fullName': fullName, 'phoneNumber': phoneNumber}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return UserModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to update profile');
  }

  @override
  Future<String> uploadAvatar(XFile imageFile, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/Users/avatar'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'png',
      'gif' => 'gif',
      'webp' => 'webp',
      _ => 'jpeg',
    };

    request.files.add(
      http.MultipartFile.fromBytes(
        'File',
        bytes,
        filename: imageFile.name,
        contentType: MediaType('image', mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data']['avatarUrl'];
      }
    } else {
      final body = utf8.decode(response.bodyBytes);
      throw Exception('Failed to upload avatar: ${response.statusCode} $body');
    }

    throw Exception('Failed to upload avatar');
  }

  @override
  Future<Map<String, dynamic>> getRideHistory({
    int page = 1,
    int pageSize = 10,
    String? status,
    required String token,
  }) async {
    String url =
        '$baseUrl/api/Users/ride-history?Page=$page&PageSize=$pageSize';
    if (status != null) url += '&Status=$status';

    final response = await client.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data']; // Returns items, totalItems, totalPages, etc.
      }
    }
    throw Exception('Failed to load ride history');
  }
}
