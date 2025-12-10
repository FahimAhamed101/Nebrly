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

    // Parse service requests
    if (responseData['serviceRequests'] != null) {
      final serviceRequestsData = responseData['serviceRequests'];

      if (serviceRequestsData['items'] is List) {
        final List<dynamic> serviceRequests = serviceRequestsData['items'];
        print('📋 Total Service Requests in response: ${serviceRequests.length}');

        if (serviceRequests.isNotEmpty) {
          print('📊 Request Statuses:');
          for (var request in serviceRequests) {
            print('   - ${request['_id']}: ${request['status']}');
          }

          for (var request in serviceRequests) {
            try {
              print('🔍 Processing service request: ${request['_id']} (status: ${request['status']})');
              final serviceRequest = _parseServiceRequest(request);
              allRequests.add(serviceRequest);
              print('✅ Added request: ${serviceRequest.id} with status: ${serviceRequest.status}');
            } catch (e, stackTrace) {
              print('❌ Error parsing service request ${request['_id']}: $e');
              print('📍 Stack trace: $stackTrace');
              // Don't rethrow - continue with other requests
            }
          }
        } else {
          print('ℹ️ No service requests found in items array');
        }
      } else {
        print('⚠️ serviceRequests.items is not an array: ${serviceRequestsData['items']}');
      }
    } else {
      print('ℹ️ No serviceRequests field in response');
    }

    // Parse bundle requests
    if (responseData['bundles'] != null) {
      final bundlesData = responseData['bundles'];

      if (bundlesData['items'] is List) {
        final List<dynamic> bundleRequests = bundlesData['items'];
        print('📦 Total Bundle Requests in response: ${bundleRequests.length}');

        if (bundleRequests.isNotEmpty) {
          print('📊 Bundle Statuses:');
          for (var bundle in bundleRequests) {
            print('   - ${bundle['_id']}: ${bundle['status']}');
          }

          for (var bundle in bundleRequests) {
            try {
              print('🔍 Processing bundle request: ${bundle['_id']} (status: ${bundle['status']})');
              final bundleRequest = _parseBundleRequest(bundle);
              allRequests.add(bundleRequest);
              print('✅ Added bundle: ${bundleRequest.id} with status: ${bundleRequest.status}');
            } catch (e, stackTrace) {
              print('❌ Error parsing bundle request ${bundle['_id']}: $e');
              print('📍 Stack trace: $stackTrace');
              // Don't rethrow - continue with other bundles
            }
          }
        } else {
          print('ℹ️ No bundle requests found in items array');
        }
      } else {
        print('⚠️ bundles.items is not an array: ${bundlesData['items']}');
      }
    } else {
      print('ℹ️ No bundles field in response');
    }

    print('🎯 Total requests parsed: ${allRequests.length}');

    if (allRequests.isNotEmpty) {
      print('📋 Parsed Requests Summary:');
      for (var request in allRequests) {
        print('   - ${request.id}: ${request.serviceName} (${request.status}) - ${request.clientName}');
      }
    }

    return allRequests;
  }

  ServiceRequest _parseServiceRequest(Map<String, dynamic> request) {
    try {
      print('🔧 Parsing service request: ${request['_id']}');

      // Parse service type - FIXED: Handle null safely
      final serviceTypeStr = request['serviceType'];
      final ServiceType serviceType = serviceTypeStr != null
          ? _parseServiceType(serviceTypeStr.toString())
          : ServiceType.electrical;

      // Parse date
      DateTime scheduledDate;
      try {
        if (request['scheduledDate'] != null) {
          scheduledDate = DateTime.parse(request['scheduledDate'].toString());
        } else {
          scheduledDate = DateTime.now();
          print('⚠️ No scheduledDate, using current date');
        }
      } catch (e) {
        scheduledDate = DateTime.now();
        print('⚠️ Error parsing scheduledDate, using current date: $e');
      }

      // Parse customer info - FIXED: Better null handling
      final customer = request['customer'];
      if (customer == null) {
        print('❌ Customer data is null');
        throw Exception('Customer data is null');
      }

      // Ensure customer is a Map
      if (customer is! Map<String, dynamic>) {
        print('❌ Customer data is not a Map: ${customer.runtimeType}');
        throw Exception('Customer data is not a Map');
      }

      // Build address string - FIXED: Better null checks
      String addressStr = 'Unknown Address';
      try {
        final address = customer['address'];
        if (address != null && address is Map<String, dynamic>) {
          final street = address['street']?.toString() ?? '';
          final city = address['city']?.toString() ?? '';
          final state = address['state']?.toString() ?? '';
          final zipCode = address['zipCode']?.toString() ?? '';
          final aptSuite = address['aptSuite']?.toString();

          if (aptSuite != null && aptSuite.isNotEmpty) {
            addressStr = '$aptSuite, $street, $city, $state $zipCode';
          } else {
            addressStr = '$street, $city, $state $zipCode';
          }
        } else {
          // Try locationInfo as fallback
          final locationInfo = request['locationInfo'];
          if (locationInfo != null && locationInfo is Map<String, dynamic>) {
            final customerAddress = locationInfo['customerAddress'];
            if (customerAddress != null && customerAddress is Map<String, dynamic>) {
              final street = customerAddress['street']?.toString() ?? '';
              final city = customerAddress['city']?.toString() ?? '';
              final state = customerAddress['state']?.toString() ?? '';
              final zipCode = customerAddress['zipCode']?.toString() ?? '';
              final aptSuite = customerAddress['aptSuite']?.toString();

              if (aptSuite != null && aptSuite.isNotEmpty) {
                addressStr = '$aptSuite, $street, $city, $state $zipCode';
              } else {
                addressStr = '$street, $city, $state $zipCode';
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Error parsing address: $e');
        addressStr = 'Unknown Address';
      }

      // Get profile image URL - FIXED: Better null handling
      String profileImageUrl = 'assets/images/default_avatar.png';
      try {
        final profileImage = customer['profileImage'];
        if (profileImage != null && profileImage is Map<String, dynamic>) {
          profileImageUrl = profileImage['url']?.toString() ?? 'assets/images/default_avatar.png';
        }
      } catch (e) {
        print('⚠️ Error parsing profile image: $e');
      }

      // Get time
      String timeStr = _formatTimeFromDate(scheduledDate);
      if (timeStr == '00:00') {
        timeStr = '09:00';
      }

      // Parse status
      final statusStr = request['status'];
      final RequestStatus status = statusStr != null
          ? _parseRequestStatus(statusStr.toString())
          : RequestStatus.pending;

      // Get client name - FIXED: Better null handling
      final firstName = customer['firstName']?.toString() ?? '';
      final lastName = customer['lastName']?.toString() ?? '';
      final clientName = firstName.isNotEmpty || lastName.isNotEmpty
          ? '$firstName $lastName'.trim()
          : 'Unknown Customer';

      // Get problem note
      final problemNote = request['problem']?.toString() ??
          request['note']?.toString() ??
          'No description provided';

      // Parse price - FIXED: Better number parsing
      double pricePerHour = 50.0;
      try {
        final price = request['price'];
        if (price != null) {
          pricePerHour = price is num ? price.toDouble() : double.parse(price.toString());
        }
      } catch (e) {
        print('⚠️ Error parsing price: $e');
      }

      final serviceRequest = ServiceRequest(
        id: request['_id']?.toString() ?? 'unknown_id',
        serviceType: serviceType,
        serviceName: _getServiceName(serviceType),
        pricePerHour: pricePerHour,
        clientName: clientName,
        clientImage: profileImageUrl,
        clientRating: 4.5,
        clientReviewCount: 10,
        address: addressStr,
        date: scheduledDate,
        time: timeStr,
        problemNote: problemNote,
        status: status,
        isTeamService: false,
      );

      print('✅ Successfully parsed service request:');
      print('   - ID: ${serviceRequest.id}');
      print('   - Service: ${serviceRequest.serviceName}');
      print('   - Status: ${serviceRequest.status}');
      print('   - Client: ${serviceRequest.clientName}');

      return serviceRequest;
    } catch (e, stackTrace) {
      print('❌ Error in _parseServiceRequest: $e');
      print('📍 Stack trace: $stackTrace');
      print('📍 Request data: ${json.encode(request)}');
      rethrow;
    }
  }

  ServiceRequest _parseBundleRequest(Map<String, dynamic> bundle) {
    try {
      print('🔧 Parsing bundle request: ${bundle['_id']}');

      // Parse service type from category
      final categoryStr = bundle['category']?.toString() ?? 'Interior';
      final ServiceType serviceType = _parseServiceTypeFromCategory(categoryStr);

      // Parse date
      DateTime serviceDate;
      try {
        if (bundle['serviceDate'] != null) {
          serviceDate = DateTime.parse(bundle['serviceDate'].toString());
        } else {
          serviceDate = DateTime.now();
          print('⚠️ No serviceDate, using current date');
        }
      } catch (e) {
        serviceDate = DateTime.now();
        print('⚠️ Error parsing serviceDate, using current date: $e');
      }

      // Helper function to safely extract customer data
      Map<String, dynamic>? _extractCustomerData(dynamic source) {
        if (source == null) return null;
        if (source is Map<String, dynamic>) {
          // If it has a 'customer' field, use that
          if (source.containsKey('customer') && source['customer'] is Map<String, dynamic>) {
            return source['customer'] as Map<String, dynamic>;
          }
          // Otherwise, if it looks like customer data itself, return it
          if (source.containsKey('firstName') || source.containsKey('email')) {
            return source;
          }
        }
        return null;
      }

      // Helper function to safely extract address
      Map<String, dynamic>? _extractAddress(dynamic source) {
        if (source == null) return null;
        if (source is Map<String, dynamic>) {
          // Direct address field
          if (source.containsKey('address') && source['address'] is Map<String, dynamic>) {
            return source['address'] as Map<String, dynamic>;
          }
          // If source itself looks like an address
          if (source.containsKey('street') || source.containsKey('city')) {
            return source;
          }
        }
        return null;
      }

      // Parse participant info - FIXED: Use helper functions
      Map<String, dynamic>? customerData;
      Map<String, dynamic>? addressData;

      try {
        // Try multiple sources for customer data
        final sources = [
          bundle['participantCustomer'],
          bundle['customer'],
          bundle['creator'],
          bundle['participant']?['customer'],
          bundle['participant'],
        ];

        for (var source in sources) {
          customerData = _extractCustomerData(source);
          if (customerData != null) {
            print('✅ Found customer data from source');
            break;
          }
        }

        // Try multiple sources for address
        final addressSources = [
          bundle['participantAddress'],
          bundle['address'],
          customerData,
          bundle['creator'],
        ];

        for (var source in addressSources) {
          addressData = _extractAddress(source);
          if (addressData != null) {
            print('✅ Found address data from source');
            break;
          }
        }
      } catch (e) {
        print('⚠️ Error extracting participant data: $e');
      }

      // Use default data if not found
      if (customerData == null) {
        print('⚠️ Using default customer data');
        customerData = {
          'firstName': 'Unknown',
          'lastName': 'Customer',
          'profileImage': {'url': 'assets/images/default_avatar.png'},
        };
      }

      if (addressData == null) {
        print('⚠️ Using default address data');
        addressData = {
          'street': 'Unknown',
          'city': 'Unknown',
          'state': 'Unknown',
          'zipCode': '00000'
        };
      }

      // Build address string
      String addressStr = 'Unknown Address';
      try {
        final street = addressData['street']?.toString() ?? '';
        final city = addressData['city']?.toString() ?? '';
        final state = addressData['state']?.toString() ?? '';
        final zipCode = addressData['zipCode']?.toString() ?? '';
        final aptSuite = addressData['aptSuite']?.toString();

        if (aptSuite != null && aptSuite.isNotEmpty) {
          addressStr = '$aptSuite, $street, $city, $state $zipCode';
        } else {
          addressStr = '$street, $city, $state $zipCode';
        }

        // Clean up any double spaces
        addressStr = addressStr.replaceAll(RegExp(r'\s+'), ' ').trim();
      } catch (e) {
        print('⚠️ Error building address string: $e');
      }

      // Get profile image
      String profileImageUrl = 'assets/images/default_avatar.png';
      try {
        final profileImage = customerData['profileImage'];
        if (profileImage != null && profileImage is Map<String, dynamic>) {
          profileImageUrl = profileImage['url']?.toString() ?? 'assets/images/default_avatar.png';
        } else if (profileImage is String) {
          profileImageUrl = profileImage;
        }
      } catch (e) {
        print('⚠️ Error parsing profile image: $e');
      }

      // Create team members list
      final List<String> teamMembers = [];
      int participantsCount = 1;
      try {
        if (bundle['currentParticipants'] != null) {
          participantsCount = int.parse(bundle['currentParticipants'].toString());
        } else if (bundle['participants'] is List) {
          participantsCount = (bundle['participants'] as List).length;
        }

        if (participantsCount > 1) {
          for (int i = 1; i <= participantsCount; i++) {
            teamMembers.add('Team Member $i');
          }
        }
      } catch (e) {
        print('⚠️ Error parsing participants count: $e');
      }

      // Parse status
      final statusStr = bundle['status'];
      final RequestStatus status = statusStr != null
          ? _parseRequestStatus(statusStr.toString())
          : RequestStatus.pending;

      // Get client name
      final firstName = customerData['firstName']?.toString() ?? '';
      final lastName = customerData['lastName']?.toString() ?? '';
      final clientName = firstName.isNotEmpty || lastName.isNotEmpty
          ? '$firstName $lastName'.trim()
          : 'Unknown Customer';

      // Get time
      final timeStr = bundle['serviceTimeStart']?.toString() ?? '09:00';

      final bundleRequest = ServiceRequest(
        id: bundle['_id']?.toString() ?? 'unknown_bundle_id',
        serviceType: serviceType,
        serviceName: bundle['title']?.toString() ?? 'Bundle Service',
        pricePerHour: _calculateBundleHourlyRate(bundle),
        clientName: clientName,
        clientImage: profileImageUrl,
        clientRating: 4.5,
        clientReviewCount: 10,
        address: addressStr,
        date: serviceDate,
        time: timeStr,
        problemNote: bundle['categoryTypeName']?.toString() ??
            bundle['description']?.toString() ??
            'Bundle Service',
        status: status,
        isTeamService: participantsCount > 1,
        teamMembers: teamMembers.isNotEmpty ? teamMembers : null,
        bundleType: participantsCount > 1
            ? '$participantsCount-Person Bundle'
            : null,
      );

      print('✅ Successfully parsed bundle request:');
      print('   - ID: ${bundleRequest.id}');
      print('   - Title: ${bundleRequest.serviceName}');
      print('   - Status: ${bundleRequest.status}');
      print('   - Participants: $participantsCount');

      return bundleRequest;
    } catch (e, stackTrace) {
      print('❌ Error in _parseBundleRequest: $e');
      print('📍 Stack trace: $stackTrace');
      print('📍 Bundle data: ${json.encode(bundle)}');
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
      case 'carpet cleaning':
        return ServiceType.cleaning;
      case 'appliance':
        return ServiceType.applianceRepairs;
      case 'window':
        return ServiceType.windowWashing;
      case 'hvac':
        return ServiceType.electrical; // Map HVAC to electrical for now
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
      case 'more services':
        return ServiceType.applianceRepairs;
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
      final services = bundle['services'];
      if (services != null && services is List && services.isNotEmpty) {
        double totalRate = 0;
        int count = 0;
        for (var service in services) {
          if (service is Map<String, dynamic>) {
            final hourlyRate = service['hourlyRate'];
            if (hourlyRate != null) {
              totalRate += hourlyRate is num
                  ? hourlyRate.toDouble()
                  : double.parse(hourlyRate.toString());
              count++;
            }
          }
        }
        if (count > 0) {
          return totalRate / count;
        }
      }
    } catch (e) {
      print('❌ Error calculating bundle rate: $e');
    }
    return 50.0;
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