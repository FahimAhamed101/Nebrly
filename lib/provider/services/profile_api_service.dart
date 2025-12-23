import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<bool> updateProviderProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String businessNameRegistered,
    required String description,
    required String experience,
    required String maxBundleCapacity,
    List<Map<String, dynamic>>? servicesToRemove,
    List<Map<String, dynamic>>? servicesToUpdate,
    List<Map<String, dynamic>>? servicesToAdd,
    File? businessLogo,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/users/provider/update-profile'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phone'] = phone;
      request.fields['businessNameRegistered'] = businessNameRegistered;
      request.fields['description'] = description;
      request.fields['experience'] = experience;
      request.fields['maxBundleCapacity'] = maxBundleCapacity;

      // Add services as JSON strings (as per API documentation)
      if (servicesToAdd != null && servicesToAdd.isNotEmpty) {
        request.fields['servicesToAdd'] = jsonEncode(servicesToAdd);
      }

      if (servicesToUpdate != null && servicesToUpdate.isNotEmpty) {
        request.fields['servicesToUpdate'] = jsonEncode(servicesToUpdate);
      }

      if (servicesToRemove != null && servicesToRemove.isNotEmpty) {
        request.fields['servicesToRemove'] = jsonEncode(servicesToRemove);
      }

      // Add business logo if provided
      if (businessLogo != null && await businessLogo.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'businessLogo',
            businessLogo.path,
            filename: 'business_logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        print('Update profile failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}