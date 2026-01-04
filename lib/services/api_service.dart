import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../utils/tokenService.dart';

class MainApiService extends GetxService {
  static const String baseUrl = "https://naibrly-backend-main.onrender.com/api/";
  final TokenService _tokenService = Get.find<TokenService>();

  // Static method for provider service details
  static Future<Map<String, dynamic>> getProviderServiceDetails(
      String providerId,
      String serviceName,
      ) async {
    try {
      final url = '${baseUrl}providers/$providerId/services/$serviceName';
      print('Fetching provider data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load provider data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Static method to fetch multiple providers in parallel
  static Future<Map<String, Map<String, dynamic>>> getMultipleProvidersServiceDetails(
      List<String> providerIds,
      String serviceName,
      ) async {
    final results = <String, Map<String, dynamic>>{};

    // Fetch all providers in parallel
    final futures = providerIds.map((providerId) async {
      try {
        final data = await getProviderServiceDetails(providerId, serviceName);
        if (data['success'] == true && data['data'] != null) {
          results[providerId] = data['data'];
        }
      } catch (e) {
        print('Error fetching provider $providerId: $e');
        // Continue with other providers even if one fails
      }
    });

    await Future.wait(futures);
    return results;
  }

  // Alternative: Fetch providers one by one with error handling
  static Future<List<Map<String, dynamic>>> getProvidersDataSequential(
      List<String> providerIds,
      String serviceName,
      ) async {
    final results = <Map<String, dynamic>>[];

    for (final providerId in providerIds) {
      try {
        final response = await getProviderServiceDetails(providerId, serviceName);
        if (response['success'] == true && response['data'] != null) {
          results.add({
            'providerId': providerId,
            'data': response['data'],
          });
        }
      } catch (e) {
        print('Error fetching provider $providerId: $e');
        // Add placeholder for failed providers
        results.add({
          'providerId': providerId,
          'data': null,
          'error': e.toString(),
        });
      }
    }

    return results;
  }

  // Headers for API requests
  Map<String, String> getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = _tokenService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic GET request
  Future<dynamic> get(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        bool includeAuth = true,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST request
  Future<dynamic> post(
      String endpoint,
      dynamic data, {
        bool includeAuth = true,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: getHeaders(includeAuth: includeAuth),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT request
  Future<dynamic> put(
      String endpoint,
      dynamic data, {
        bool includeAuth = true,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: getHeaders(includeAuth: includeAuth),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PATCH request
  Future<dynamic> patch(
      String endpoint,
      dynamic data, {
        bool includeAuth = true,
      }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: getHeaders(includeAuth: includeAuth),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(
      String endpoint, {
        bool includeAuth = true,
      }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Multipart request for file uploads
  Future<dynamic> multipartRequest(
      String endpoint,
      String method,
      Map<String, dynamic> data, {
        List<http.MultipartFile>? files,
        bool includeAuth = true,
      }) async {
    try {
      final request = http.MultipartRequest(
        method,
        Uri.parse('$baseUrl$endpoint'),
      );

      // Add headers
      request.headers.addAll(getHeaders(includeAuth: includeAuth));

      // Add fields
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    try {
      final jsonResponse = jsonDecode(responseBody);

      if (statusCode >= 200 && statusCode < 300) {
        return jsonResponse;
      } else {
        final errorMessage = jsonResponse['message'] ??
            jsonResponse['error'] ??
            'Request failed with status: $statusCode';
        throw ApiException(message: errorMessage, statusCode: statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Invalid response format', statusCode: statusCode);
    }
  }

  // Handle errors
  dynamic _handleError(dynamic error) {
    if (error is ApiException) {
      throw error;
    } else if (error is http.ClientException) {
      throw ApiException(message: 'Network error: ${error.message}');
    } else {
      throw ApiException(message: 'Unexpected error: $error');
    }
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}