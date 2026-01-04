import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../models/user_model_provider.dart' show UserModel;
import '../../utils/tokenService.dart';

class ProfileApiService extends GetxService {
  final String baseUrl = "https://naibrly-backend-main.onrender.com";
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
      // Debug: Print where we're sending the request
      print('=== UPDATE PROFILE REQUEST ===');
      print('Base URL: $baseUrl');
      print('Full URL: $baseUrl/api/users/provider/app/update-profile');
      print('Method: PUT');

      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create multipart request
      final fullUrl = '$baseUrl/api/users/provider/app/update-profile';
      print('Request URL: $fullUrl');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(fullUrl),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      print('Using token: ${token.substring(0, 20)}...');

      // Add text fields
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phone'] = phone;
      request.fields['businessNameRegistered'] = businessNameRegistered;
      request.fields['description'] = description;
      request.fields['experience'] = experience;
      request.fields['maxBundleCapacity'] = maxBundleCapacity;

      // Debug print fields
      print('Fields being sent:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });

      // Add services as JSON strings
      if (servicesToAdd != null && servicesToAdd.isNotEmpty) {
        final servicesJson = jsonEncode(servicesToAdd);
        request.fields['serviceToAdd'] = servicesJson; // SINGULAR 'serviceToAdd'
        print('serviceToAdd: $servicesJson');
      }

      if (servicesToUpdate != null && servicesToUpdate.isNotEmpty) {
        final servicesJson = jsonEncode(servicesToUpdate);
        request.fields['serviceToUpdate'] = servicesJson; // SINGULAR
        print('serviceToUpdate: $servicesJson');
      }

      if (servicesToRemove != null && servicesToRemove.isNotEmpty) {
        final servicesJson = jsonEncode(servicesToRemove);
        request.fields['serviceToRemove'] = servicesJson; // SINGULAR
        print('serviceToRemove: $servicesJson');
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
        print('Adding business logo: ${businessLogo.path}');
      }

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - backend not responding');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] == true;
        print('Update successful: $success');
        print('Message: ${responseData['message']}');
        return success;
      } else {
        print('Update failed with status: ${response.statusCode}');
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}