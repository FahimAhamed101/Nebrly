// lib/services/payment_service.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:naibrly/utils/app_contants.dart';
import 'package:naibrly/utils/tokenService.dart';

class PaymentService extends GetxService {
  final TokenService _tokenService = TokenService();

  // Check money requests for provider by bundleId and customerId
  Future<List<dynamic>> checkMoneyRequestByBundleIdForProvider({
    required String bundleId,
    required String customerId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/provider?bundleId=$bundleId&customerId=$customerId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return responseData['data']?['moneyRequests'] ?? [];
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Check money requests for provider by serviceRequestId
  Future<List<dynamic>> checkMoneyRequestByServiceRequestId({
    required String serviceRequestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/provider?serviceRequestId=$serviceRequestId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return responseData['data']?['moneyRequests'] ?? [];
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Check money requests for customer by bundleId
  Future<List<dynamic>> checkMoneyRequestByBundleId({
    required String bundleId,
    required String customerId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/customer?bundleId=$bundleId&customerId=$customerId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return responseData['data']?['moneyRequests'] ?? [];
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Check money requests for customer by serviceRequestId
  Future<List<dynamic>> checkMoneyRequestByServiceRequestIdForCustomer({
    required String serviceRequestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/customer?serviceRequestId=$serviceRequestId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return responseData['data']?['moneyRequests'] ?? [];
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Check money requests by requestId
  Future<List<dynamic>> checkMoneyRequestByRequestId({
    required String requestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/request/$requestId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return responseData['data']?['moneyRequests'] ?? [];
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Load money request details
  Future<Map<String, dynamic>?> loadMoneyRequestDetails({
    required String serviceRequestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) return null;

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/customer?serviceRequestId=$serviceRequestId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            final moneyRequest = moneyRequests[0];

            return {
              '_id': moneyRequest['_id']?.toString(),
              'amount': moneyRequest['amount'] is int
                  ? moneyRequest['amount']
                  : (moneyRequest['amount'] is num
                  ? (moneyRequest['amount'] as num).toInt()
                  : 0),
              'status': moneyRequest['status']?.toString() ?? 'pending',
              'totalAmount': moneyRequest['totalAmount'] is int
                  ? moneyRequest['totalAmount']
                  : (moneyRequest['totalAmount'] is num
                  ? (moneyRequest['totalAmount'] as num).toInt()
                  : 0),
              'tipAmount': moneyRequest['tipAmount'] is int
                  ? moneyRequest['tipAmount']
                  : (moneyRequest['tipAmount'] is num
                  ? (moneyRequest['tipAmount'] as num).toInt()
                  : 0),
              'description': moneyRequest['description']?.toString() ?? 'Payment for service',
              'createdAt': moneyRequest['createdAt']?.toString(),
              'dueDate': moneyRequest['dueDate']?.toString(),
              'commission': moneyRequest['commission'] is Map
                  ? Map<String, dynamic>.from(moneyRequest['commission'])
                  : null,
              'paymentDetails': moneyRequest['paymentDetails'] is Map
                  ? Map<String, dynamic>.from(moneyRequest['paymentDetails'])
                  : null,
              'statusHistory': moneyRequest['statusHistory'] is List
                  ? List<Map<String, dynamic>>.from(moneyRequest['statusHistory'])
                  : [],
              'provider': moneyRequest['provider'] is Map
                  ? Map<String, dynamic>.from(moneyRequest['provider'])
                  : null,
              'serviceRequest': moneyRequest['serviceRequest'] is Map
                  ? Map<String, dynamic>.from(moneyRequest['serviceRequest'])
                  : null,
            };
          }
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Create money request
  Future<Map<String, dynamic>> createMoneyRequest({
    double? amount,
    String? bundleId,
    String? serviceRequestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final apiUrl = '${AppConstants.BASE_URL}/api/money-requests/create';
      final Map<String, dynamic> requestBody = {};

      if (amount != null) {
        requestBody['amount'] = amount;
      }

      if (bundleId != null && bundleId.isNotEmpty) {
        requestBody['bundleId'] = bundleId;
      }

      if (serviceRequestId != null && serviceRequestId.isNotEmpty) {
        requestBody['serviceRequestId'] = serviceRequestId;
      }

      if (requestBody.isEmpty) {
        throw Exception('No valid parameters available for creating money request');
      }

      final url = Uri.parse(apiUrl);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Money request created successfully',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create money request');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create money request');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cancel service request
  Future<Map<String, dynamic>> cancelServiceRequest({
    required String requestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/service-requests/$requestId/status');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': 'cancelled',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return {
            'success': true,
            'message': 'Request cancelled successfully',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to cancel request');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel request');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cancel bundle
  Future<Map<String, dynamic>> cancelBundle({
    required String bundleId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/bundles/$bundleId/status');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': 'cancelled',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return {
            'success': true,
            'message': 'Bundle cancelled successfully',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to cancel bundle');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel bundle');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Complete service request
  Future<Map<String, dynamic>> completeServiceRequest({
    required String requestId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/service-requests/$requestId/status');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': 'completed',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return {
            'success': true,
            'message': 'Request marked as completed successfully',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to complete request');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to complete request');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Complete bundle
  Future<Map<String, dynamic>> completeBundle({
    required String bundleId,
  }) async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${AppConstants.BASE_URL}/api/bundles/$bundleId/status');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': 'completed',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          return {
            'success': true,
            'message': 'Bundle marked as completed successfully',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to complete bundle');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to complete bundle');
      }
    } catch (e) {
      rethrow;
    }
  }
}