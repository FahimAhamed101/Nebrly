import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../utils/tokenService.dart';
import '../models/provider_model.dart';
// Import TokenService

class ApiService extends GetxService {
  static const String baseUrl = 'https://naibrly-backend.onrender.com';

  // Get TokenService instance
  TokenService get _tokenService => Get.find<TokenService>();

  // Add this method for verify information
  Future<VerifyInformationResponse> verifyInformation(
      VerifyInformationRequest request, {
        required String insuranceDocumentPath,
        required String idCardFrontPath,
        required String idCardBackPath,
      }) async {
    try {
      // Get the token
      final String? token = _tokenService.getToken();

      if (token == null || token.isEmpty) {
        return VerifyInformationResponse(
          success: false,
          message: 'Authentication token not found. Please login again.',
        );
      }

      var uri = Uri.parse('$baseUrl/api/verify-information/submit');
      var requestMultipart = http.MultipartRequest('POST', uri);

      // Add authorization header with token
      requestMultipart.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      requestMultipart.fields['einNumber'] = request.einNumber;
      requestMultipart.fields['firstName'] = request.firstName;
      requestMultipart.fields['lastName'] = request.lastName;
      requestMultipart.fields['businessRegisteredState'] = request.businessRegisteredState;

      // Add files
      await _addMultipartFile(
        requestMultipart,
        'insuranceDocument',
        insuranceDocumentPath,
      );

      await _addMultipartFile(
        requestMultipart,
        'idCardFront',
        idCardFrontPath,
      );

      await _addMultipartFile(
        requestMultipart,
        'idCardBack',
        idCardBackPath,
      );

      // Print request details for debugging
      print('Sending verify information request with token');
      print('Fields: ${requestMultipart.fields.keys}');
      print('Files: ${requestMultipart.files.map((f) => f.field).toList()}');

      // Send request
      var streamedResponse = await requestMultipart.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleVerifyInformationResponse(response);
    } catch (e) {
      print('Exception in verifyInformation: $e');
      return VerifyInformationResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  VerifyInformationResponse _handleVerifyInformationResponse(http.Response response) {
    try {
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VerifyInformationResponse.fromJson(jsonResponse);
      } else {
        print('Error Response: $jsonResponse');
        return VerifyInformationResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Verification failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return VerifyInformationResponse(
        success: false,
        message: 'Failed to parse response: $e',
      );
    }
  }

  // Your existing methods remain the same...
  Future<ProviderRegisterResponse> registerProvider(
      ProviderRegisterRequest request, {
        required String businessLogoPath,
      }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/auth/register/provider');
      var requestMultipart = http.MultipartRequest('POST', uri);

      // Add text fields
      _addTextFields(requestMultipart, request);

      // Add business logo file only (profileImage removed)
      if (businessLogoPath.isNotEmpty && await File(businessLogoPath).exists()) {
        await _addMultipartFile(
          requestMultipart,
          'businessLogo',
          businessLogoPath,
        );
      }

      // Print request details for debugging
      print('Sending multipart request with fields: ${requestMultipart.fields.keys}');
      print('Files: ${requestMultipart.files.map((f) => f.field).toList()}');

      // Send request
      var streamedResponse = await requestMultipart.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Exception in registerProvider: $e');
      return ProviderRegisterResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  void _addTextFields(http.MultipartRequest requestMultipart, ProviderRegisterRequest request) {
    final fields = {
      'firstName': request.firstName,
      'lastName': request.lastName,
      'email': request.email,
      'password': request.password,
      'confirmPassword': request.confirmPassword,
      'phone': request.phone,
      'businessNameRegistered': request.businessNameRegistered,
      'businessNameDBA': request.businessNameDBA,
      'providerRole': request.providerRole,
      'businessPhone': request.businessPhone,
      'website': request.website,
      'servicesProvided': request.servicesProvided,
      'businessServiceStart': request.businessServiceStart,
      'businessServiceEnd': request.businessServiceEnd,
      'businessHoursStart': request.businessHoursStart,
      'businessHoursEnd': request.businessHoursEnd,
      'hourlyRate': request.hourlyRate,
      'businessAddressStreet': request.businessAddressStreet,
      'businessAddressCity': request.businessAddressCity,
      'businessAddressState': request.businessAddressState,
      'businessAddressZipCode': request.businessAddressZipCode,
      'experience': request.experience,
    };

    fields.forEach((key, value) {
      if (value.isNotEmpty) {
        requestMultipart.fields[key] = value;
      }
    });
  }

  Future<void> _addMultipartFile(
      http.MultipartRequest requestMultipart,
      String fieldName,
      String filePath,
      ) async {
    if (filePath.isNotEmpty && await File(filePath).exists()) {
      final file = File(filePath);
      final fileName = basename(filePath);
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Determine content type based on file extension
      final MediaType contentType = _getMediaType(fileExtension);

      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        contentType: contentType,
        filename: fileName,
      );

      requestMultipart.files.add(multipartFile);
    }
  }

  MediaType _getMediaType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  ProviderRegisterResponse _handleResponse(http.Response response) {
    try {
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProviderRegisterResponse.fromJson(jsonResponse);
      } else {
        print('Error Response: $jsonResponse');
        return ProviderRegisterResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Registration failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return ProviderRegisterResponse(
        success: false,
        message: 'Failed to parse response: $e',
      );
    }
  }

  Future<ApiService> init() async {
    return this;
  }
}