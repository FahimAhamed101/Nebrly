// services/analytics_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../utils/tokenService.dart';
import '../models/analytics.dart';


class AnalyticsService extends GetxService {
  static const String baseUrl = 'https://naibrly-backend.onrender.com/api';

  String? get _token {
    final tokenService = Get.find<TokenService>();
    return tokenService.getToken();
  }

  Future<Analytics> getProviderAnalytics() async {
    try {
      print('🔄 Fetching provider analytics from API...');
      print('📝 URL: $baseUrl/providers/analytics/my');

      final token = _token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      print('🔑 Token available: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/providers/analytics/my'),
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

        if (data['success'] == true && data['data'] != null) {
          final analytics = Analytics.fromApiResponse(data['data']);

          print('📊 Analytics parsed:');
          print('   - Today Orders: ${analytics.todayOrders}');
          print('   - Today Earnings: \$${analytics.todayEarnings}');
          print('   - Monthly Orders: ${analytics.monthlyOrders}');
          print('   - Monthly Earnings: \$${analytics.monthlyEarnings}');

          return analytics;
        } else {
          throw Exception('API returned success: false - ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Analytics endpoint not found');
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getProviderAnalytics: $e');
      rethrow;
    }
  }
}