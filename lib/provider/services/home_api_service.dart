// services/home_api_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../utils/tokenService.dart';
import '../models/service_request.dart';

class HomeApiService extends GetxService {
  static const String baseUrl = 'https://naibrly-backend.onrender.com/api';

  String? get _token {
    final tokenService = Get.find<TokenService>();
    return tokenService.getToken();
  }

  Future<List<ServiceRequest>> getServiceRequests() async {
    try {
      print('🔄 Fetching service requests from API...');
      print('📝 URL: $baseUrl/service-requests/provider/my-requests');

      final token = _token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      print('🔑 Token available: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/service-requests/provider/my-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully parsed API response');

        if (data['success'] == true) {
          final requests = _parseApiResponse(data);
          print('✅ Total parsed requests: ${requests.length}');

          // Log the status breakdown
          final pending = requests.where((r) => r.status == RequestStatus.pending).length;
          final accepted = requests.where((r) => r.status == RequestStatus.accepted).length;
          final completed = requests.where((r) => r.status == RequestStatus.completed).length;
          print('📊 Status breakdown: $pending pending, $accepted accepted, $completed completed');

          return requests;
        } else {
          throw Exception('API returned success: false - ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found');
      } else {
        throw Exception('Failed to load service requests: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getServiceRequests: $e');
      rethrow;
    }
  }

  List<ServiceRequest> _parseApiResponse(Map<String, dynamic> data) {
    print('🔄 Parsing API response...');

    final List<ServiceRequest> allRequests = [];

    if (data['data'] == null) {
      print('❌ No data field in response');
      return allRequests;
    }

    final responseData = data['data'];

    // Parse regular service requests - ALL STATUSES
    final serviceRequestsRaw = responseData['serviceRequests'];
    List<dynamic>? serviceRequests;

    if (serviceRequestsRaw is List) {
      serviceRequests = serviceRequestsRaw;
    } else if (serviceRequestsRaw is int && serviceRequestsRaw == 0) {
      serviceRequests = [];
      print('ℹ️ serviceRequests is 0 (number), treating as empty array');
    } else {
      serviceRequests = null;
    }

    print('📋 Total Service Requests in response: ${serviceRequests?.length ?? 0}');

    if (serviceRequests != null && serviceRequests.isNotEmpty) {
      // Log all statuses
      print('📊 Request Statuses:');
      for (var request in serviceRequests) {
        print('   - ${request['_id']}: ${request['status']}');
      }

      // Parse ALL requests regardless of status
      for (var request in serviceRequests) {
        print('🔍 Processing service request: ${request['_id']} (status: ${request['status']})');

        try {
          final serviceRequest = _parseServiceRequest(request);
          allRequests.add(serviceRequest);
          print('✅ Added request: ${serviceRequest.id} with status: ${serviceRequest.status}');
        } catch (e) {
          print('❌ Error parsing service request ${request['_id']}: $e');
        }
      }
    } else {
      print('ℹ️ No service requests found in response');
    }

    // Parse bundle requests - ALL STATUSES
    final bundlesRaw = responseData['bundles'];
    List<dynamic>? bundleRequests;

    if (bundlesRaw is Map<String, dynamic>) {
      bundleRequests = bundlesRaw['requests'] as List<dynamic>?;
    } else if (bundlesRaw is int && bundlesRaw == 0) {
      bundleRequests = [];
      print('ℹ️ bundles is 0 (number), treating as empty array');
    } else {
      bundleRequests = null;
    }

    print('📦 Total Bundle Requests in response: ${bundleRequests?.length ?? 0}');

    if (bundleRequests != null && bundleRequests.isNotEmpty) {
      // Log all statuses
      print('📊 Bundle Statuses:');
      for (var bundle in bundleRequests) {
        print('   - ${bundle['_id']}: ${bundle['status']}');
      }

      // Parse ALL bundles regardless of status
      for (var bundle in bundleRequests) {
        print('🔍 Processing bundle request: ${bundle['_id']} (status: ${bundle['status']})');

        try {
          final bundleRequest = _parseBundleRequest(bundle);
          allRequests.add(bundleRequest);
          print('✅ Added bundle: ${bundleRequest.id} with status: ${bundleRequest.status}');
        } catch (e) {
          print('❌ Error parsing bundle request ${bundle['_id']}: $e');
        }
      }
    } else {
      print('ℹ️ No bundle requests found in response');
    }

    print('🎯 Total requests parsed: ${allRequests.length}');
    return allRequests;
  }

  ServiceRequest _parseServiceRequest(Map<String, dynamic> request) {
    try {
      print('🔧 Parsing service request: ${request['_id']}');

      // Parse service type
      final ServiceType serviceType = _parseServiceType(request['serviceType']);

      // Parse date
      final DateTime scheduledDate = DateTime.parse(request['scheduledDate']);

      // Parse customer info
      final customer = request['customer'];
      if (customer == null) {
        print('❌ Customer data is null');
        throw Exception('Customer data is null');
      }

      final address = customer['address'];
      if (address == null) {
        print('❌ Address data is null');
        throw Exception('Address data is null');
      }

      // Build address string - handle optional aptSuite
      String addressStr = '${address['street']}, ${address['city']}, ${address['state']} ${address['zipCode']}';
      if (address['aptSuite'] != null && address['aptSuite'].toString().isNotEmpty) {
        addressStr = '${address['aptSuite']}, $addressStr';
      }

      // Get profile image URL or use default
      final profileImageUrl = customer['profileImage']?['url'] ?? 'assets/images/default_avatar.png';

      // Get time - use a default time if scheduledDate only has date
      String timeStr = _formatTimeFromDate(scheduledDate);
      if (timeStr == '00:00') {
        timeStr = '09:00'; // Default to 9 AM if no time is specified
      }

      // Parse status from API
      final RequestStatus status = _parseRequestStatus(request['status']);

      final serviceRequest = ServiceRequest(
        id: request['_id'],
        serviceType: serviceType,
        serviceName: _getServiceName(serviceType),
        pricePerHour: (request['price'] ?? 0.0).toDouble(),
        clientName: '${customer['firstName']} ${customer['lastName']}',
        clientImage: profileImageUrl,
        clientRating: 4.5, // Default rating since API doesn't provide
        clientReviewCount: 10, // Default count since API doesn't provide
        address: addressStr,
        date: scheduledDate,
        time: timeStr,
        problemNote: request['problem'] ?? request['note'],
        status: status, // Use the parsed status from API
        isTeamService: false,
      );

      print('✅ Successfully parsed service request: ${serviceRequest.id} (status: ${serviceRequest.status})');
      return serviceRequest;
    } catch (e, stackTrace) {
      print('❌ Error in _parseServiceRequest: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  ServiceRequest _parseBundleRequest(Map<String, dynamic> bundle) {
    try {
      print('🔧 Parsing bundle request: ${bundle['_id']}');

      // Parse service type from category or first service
      final ServiceType serviceType = _parseServiceTypeFromCategory(bundle['category'] ?? 'Cleaning');

      // Parse date
      final DateTime serviceDate = DateTime.parse(bundle['serviceDate']);

      // Parse participant info
      final participant = bundle['participant'];
      if (participant == null) {
        throw Exception('Participant data is null');
      }

      final address = participant['address'];
      if (address == null) {
        throw Exception('Address data is null');
      }

      // Build address string
      final addressStr = '${address['street']}, ${address['city']}, ${address['state']} ${address['zipCode']}';

      // Get profile image URL or use default
      final profileImageUrl = participant['profileImage']?['url'] ?? 'assets/images/default_avatar.png';

      // Create team members list
      final List<String> teamMembers = [];
      final participantsCount = bundle['participantsCount'] ?? 1;
      if (participantsCount > 1) {
        for (int i = 1; i <= participantsCount; i++) {
          teamMembers.add('Team Member $i');
        }
      }

      // Parse status from API
      final RequestStatus status = _parseRequestStatus(bundle['status']);

      return ServiceRequest(
        id: bundle['_id'],
        serviceType: serviceType,
        serviceName: bundle['title'] ?? 'Bundle Service',
        pricePerHour: _calculateBundleHourlyRate(bundle),
        clientName: '${participant['firstName']} ${participant['lastName']}',
        clientImage: profileImageUrl,
        clientRating: 4.5, // Default rating
        clientReviewCount: 10, // Default count
        address: addressStr,
        date: serviceDate,
        time: bundle['serviceTimeStart'] ?? '09:00',
        problemNote: bundle['categoryTypeName'],
        status: status, // Use the parsed status from API
        isTeamService: participantsCount > 1,
        teamMembers: teamMembers.isNotEmpty ? teamMembers : null,
        bundleType: '$participantsCount-Person Bundle',
      );
    } catch (e) {
      print('❌ Error in _parseBundleRequest: $e');
      rethrow;
    }
  }

  ServiceType _parseServiceType(String type) {
    switch (type.toLowerCase()) {
      case 'electrical':
        return ServiceType.electrical;
      case 'plumbing':
        return ServiceType.plumbing;
      case 'cleaning':
        return ServiceType.cleaning;
      case 'appliance':
        return ServiceType.applianceRepairs;
      case 'window':
        return ServiceType.windowWashing;
      default:
        print('⚠️ Unknown service type: $type, defaulting to electrical');
        return ServiceType.electrical;
    }
  }

  ServiceType _parseServiceTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior':
        return ServiceType.cleaning;
      case 'electrical':
        return ServiceType.electrical;
      case 'plumbing':
        return ServiceType.plumbing;
      default:
        print('⚠️ Unknown category: $category, defaulting to cleaning');
        return ServiceType.cleaning;
    }
  }

  String _getServiceName(ServiceType type) {
    switch (type) {
      case ServiceType.applianceRepairs:
        return 'Appliance Repairs';
      case ServiceType.windowWashing:
        return 'Window Washing';
      case ServiceType.plumbing:
        return 'Plumbing';
      case ServiceType.electrical:
        return 'Electrical';
      case ServiceType.cleaning:
        return 'Cleaning';
    }
  }

  RequestStatus _parseRequestStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RequestStatus.pending;
      case 'accepted':
        return RequestStatus.accepted;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        print('⚠️ Unknown status: $status, defaulting to pending');
        return RequestStatus.pending;
    }
  }

  String _formatTimeFromDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calculateBundleHourlyRate(Map<String, dynamic> bundle) {
    try {
      final services = bundle['services'] as List<dynamic>?;
      if (services != null && services.isNotEmpty) {
        double totalRate = 0;
        for (var service in services) {
          totalRate += (service['hourlyRate'] ?? 0).toDouble();
        }
        return totalRate / services.length;
      }
    } catch (e) {
      print('❌ Error calculating bundle rate: $e');
    }
    return 50.0; // Default rate
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      print('🔄 Accepting request: $requestId');

      final token = _token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final requestBody = json.encode({
        'status': 'accepted'
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/service-requests/$requestId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('📡 Accept Response Status: ${response.statusCode}');
      print('📡 Accept Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to accept request: ${response.statusCode} - ${response.body}');
      }

      print('✅ Request accepted successfully');
    } catch (e) {
      print('❌ Error in acceptRequest: $e');
      rethrow;
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      print('🔄 Cancelling request: $requestId');

      final token = _token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/service-requests/$requestId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Cancel Response Status: ${response.statusCode}');
      print('📡 Cancel Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel request: ${response.statusCode} - ${response.body}');
      }

      print('✅ Request cancelled successfully');
    } catch (e) {
      print('❌ Error in cancelRequest: $e');
      rethrow;
    }
  }
}