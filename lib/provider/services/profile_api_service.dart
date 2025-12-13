// services/profile_api_service.dart
import 'dart:convert';
import 'package:get/get.dart';

import '../../models/user_model_provider.dart' show UserModel;
import '../../utils/tokenService.dart';


class ProfileApiService extends GetxService {
  final String baseUrl = "https://naibrly-backend.onrender.com";
  final TokenService _tokenService = Get.find<TokenService>();

  Future<UserModel?> getProfile() async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await GetConnect().get(
        '$baseUrl/api/users/profile',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.body;
        if (responseData['success'] == true) {
          return UserModel.fromJson(responseData['data']['user']);
        } else {
          throw Exception('Failed to load profile: ${responseData['message']}');
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await _tokenService.removeToken();
        Get.offAllNamed('/login');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await GetConnect().put(
        '$baseUrl/api/users/profile',
        data,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.body;
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}