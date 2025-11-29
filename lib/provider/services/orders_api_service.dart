// services/orders_api_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../utils/tokenService.dart';
import '../models/order.dart';

class OrdersApiService extends GetxService {
  static const String baseUrl = 'https://naibrly-backend.onrender.com/api';

  String? get _token {
    final tokenService = Get.find<TokenService>();
    return tokenService.getToken();
  }

  Future<List<Order>> getOrders() async {
    try {
      print('🔄 Fetching orders from API...');
      print('📝 URL: $baseUrl/service-requests/provider/my-requests');

      final token = _token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      print('🔑 Token length: ${token.length}');

      final response = await http.get(
        Uri.parse('$baseUrl/service-requests/provider/my-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully parsed API response');

        if (data['success'] == true) {
          final orders = _parseApiResponse(data);
          print('✅ Total parsed orders: ${orders.length}');
          return orders;
        } else {
          throw Exception('API returned success: false - ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please check your token');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getOrders: $e');
      rethrow;
    }
  }

  List<Order> _parseApiResponse(Map<String, dynamic> data) {
    print('🔄 Parsing orders API response...');

    final List<Order> allOrders = [];

    if (data['data'] == null) {
      print('❌ No data field in response');
      return allOrders;
    }

    final responseData = data['data'];

    // Parse regular service requests
    final serviceRequestsRaw = responseData['serviceRequests'];
    List<dynamic>? serviceRequests;

    if (serviceRequestsRaw is List) {
      serviceRequests = serviceRequestsRaw;
    } else if (serviceRequestsRaw is int && serviceRequestsRaw == 0) {
      serviceRequests = [];
    }

    print('📋 Total Service Requests: ${serviceRequests?.length ?? 0}');

    if (serviceRequests != null && serviceRequests.isNotEmpty) {
      for (var request in serviceRequests) {
        print('🔍 Processing order: ${request['_id']} - Status: ${request['status']}');
        try {
          final order = _parseServiceRequest(request);
          allOrders.add(order);
          print('✅ Added order: ${order.id}');
        } catch (e) {
          print('❌ Error parsing order ${request['_id']}: $e');
        }
      }
    }

    // Parse bundle requests
    final bundlesRaw = responseData['bundles'];
    List<dynamic>? bundleRequests;

    if (bundlesRaw is Map<String, dynamic>) {
      bundleRequests = bundlesRaw['requests'] as List<dynamic>?;
    } else if (bundlesRaw is int && bundlesRaw == 0) {
      bundleRequests = [];
    }

    print('📦 Total Bundle Requests: ${bundleRequests?.length ?? 0}');

    if (bundleRequests != null && bundleRequests.isNotEmpty) {
      for (var bundle in bundleRequests) {
        print('🔍 Processing bundle order: ${bundle['_id']}');
        try {
          final order = _parseBundleRequest(bundle);
          allOrders.add(order);
          print('✅ Added bundle order: ${order.id}');
        } catch (e) {
          print('❌ Error parsing bundle ${bundle['_id']}: $e');
        }
      }
    }

    print('🎯 Total orders parsed: ${allOrders.length}');
    return allOrders;
  }

  Order _parseServiceRequest(Map<String, dynamic> request) {
    try {
      final customer = request['customer'];
      if (customer == null) throw Exception('Customer data is null');

      final address = customer['address'];
      if (address == null) throw Exception('Address data is null');

      String addressStr = '${address['street']}, ${address['city']}, ${address['state']} ${address['zipCode']}';
      if (address['aptSuite'] != null && address['aptSuite'].toString().isNotEmpty) {
        addressStr = '${address['aptSuite']}, $addressStr';
      }

      final DateTime scheduledDate = DateTime.parse(request['scheduledDate']);
      final profileImageUrl = customer['profileImage']?['url'] ?? 'assets/images/default_avatar.png';

      String timeStr = _formatTimeFromDate(scheduledDate);
      if (timeStr == '00:00') {
        timeStr = '09:00';
      }

      return Order(
        id: request['_id'],
        serviceName: _getServiceName(request['serviceType']),
        averagePrice: (request['price'] ?? 0.0).toDouble(),
        date: scheduledDate,
        time: timeStr,
        imagePath: _getServiceImage(request['serviceType']),
        status: _parseOrderStatus(request['status']),
        problemDescription: request['problem'] ?? request['note'],
        clientName: '${customer['firstName']} ${customer['lastName']}',
        clientImage: profileImageUrl,
        clientRating: 4.5,
        clientReviewCount: 10,
        address: addressStr,
        isTeamService: false,
      );
    } catch (e) {
      print('❌ Error in _parseServiceRequest: $e');
      rethrow;
    }
  }

  Order _parseBundleRequest(Map<String, dynamic> bundle) {
    try {
      final participant = bundle['participant'];
      if (participant == null) throw Exception('Participant data is null');

      final address = participant['address'];
      if (address == null) throw Exception('Address data is null');

      final addressStr = '${address['street']}, ${address['city']}, ${address['state']} ${address['zipCode']}';
      final DateTime serviceDate = DateTime.parse(bundle['serviceDate']);
      final profileImageUrl = participant['profileImage']?['url'] ?? 'assets/images/default_avatar.png';

      final List<String> teamMembers = [];
      final participantsCount = bundle['participantsCount'] ?? 1;
      if (participantsCount > 1) {
        for (int i = 1; i <= participantsCount; i++) {
          teamMembers.add('Team Member $i');
        }
      }

      return Order(
        id: bundle['_id'],
        serviceName: bundle['title'] ?? 'Bundle Service',
        averagePrice: _calculateBundleRate(bundle),
        date: serviceDate,
        time: bundle['serviceTimeStart'] ?? '09:00',
        imagePath: 'assets/images/cleaning.png',
        status: _parseOrderStatus(bundle['status']),
        problemDescription: bundle['categoryTypeName'],
        clientName: '${participant['firstName']} ${participant['lastName']}',
        clientImage: profileImageUrl,
        clientRating: 4.5,
        clientReviewCount: 10,
        address: addressStr,
        isTeamService: participantsCount > 1,
        teamMembers: teamMembers.isNotEmpty ? teamMembers : null,
        bundleType: '$participantsCount-Person Bundle',
      );
    } catch (e) {
      print('❌ Error in _parseBundleRequest: $e');
      rethrow;
    }
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String _getServiceName(String type) {
    switch (type.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'cleaning':
        return 'House Cleaning';
      case 'appliance':
        return 'Appliance Repairs';
      case 'window':
        return 'Window Washing';
      default:
        return 'Service';
    }
  }

  String _getServiceImage(String type) {
    switch (type.toLowerCase()) {
      case 'cleaning':
      case 'window':
        return 'assets/images/cleaning.png';
      case 'electrical':
      case 'plumbing':
      case 'appliance':
        return 'assets/images/repares.png';
      default:
        return 'assets/images/cleaning.png';
    }
  }

  String _formatTimeFromDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calculateBundleRate(Map<String, dynamic> bundle) {
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
    return 50.0;
  }
}