import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Fixed import path
import '../../utils/tokenService.dart';
import '../models/client_feedback.dart';

class FeedbackService extends GetxService {
  static FeedbackService get to => Get.find();

  TokenService get _tokenService => Get.find<TokenService>();

  String? get _token {
    return _tokenService.getToken();
  }

  Future<ReviewsResponse> getMyReviews({int page = 1, int limit = 10}) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    // FIXED: Use actual base URL instead of placeholder
    final response = await http.get(
      Uri.parse('https://naibrly-backend.onrender.com/api/providers/reviews/my?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('=== API Response Details ===');
    print('URL: https://naibrly-backend.onrender.com/api/providers/reviews/my?page=$page&limit=$limit');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('============================');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Print detailed response information
      _printResponseDetails(jsonResponse);

      return ReviewsResponse.fromJson(jsonResponse['data']);
    } else {
      final errorBody = json.decode(response.body);
      print('API Error: ${errorBody['message']}');
      throw Exception('Failed to load reviews: ${errorBody['message']}');
    }
  }

  void _printResponseDetails(Map<String, dynamic> jsonResponse) {
    print('\n=== REVIEWS API RESPONSE ANALYSIS ===');

    final data = jsonResponse['data'];
    final provider = data['provider'];
    final reviews = data['reviews'];
    final statistics = reviews['statistics'];
    final pagination = reviews['pagination'];
    final reviewList = reviews['list'] as List;

    // Print provider information
    print('👤 PROVIDER INFO:');
    print('   Business Name: ${provider['businessName']}');
    print('   Overall Rating: ${provider['rating']}');
    print('   Total Reviews: ${provider['totalReviews']}');

    // Print statistics
    print('\n📊 REVIEW STATISTICS:');
    print('   Average Rating: ${statistics['averageRating']}');
    print('   Total Reviews: ${statistics['totalReviews']}');
    print('   Rating Distribution:');
    final distribution = statistics['ratingDistribution'] as Map<String, dynamic>;
    distribution.forEach((key, value) {
      print('     $key star: $value reviews');
    });

    // Print pagination info
    print('\n📄 PAGINATION:');
    print('   Current Page: ${pagination['current']}');
    print('   Total Pages: ${pagination['pages']}');
    print('   Total Items: ${pagination['total']}');
    print('   Limit per page: ${pagination['limit']}');

    // Print individual reviews
    print('\n🗣️ INDIVIDUAL REVIEWS (${reviewList.length}):');
    for (int i = 0; i < reviewList.length; i++) {
      final review = reviewList[i];
      final customer = review['customer'];
      print('   Review ${i + 1}:');
      print('     ID: ${review['id']}');
      print('     Rating: ${review['rating']} ⭐');
      print('     Comment: "${review['comment']}"');
      print('     Service: ${review['serviceName']}');
      print('     Date: ${review['createdAt']}');
      print('     Customer: ${customer['firstName']} ${customer['lastName']}');
      print('     Customer ID: ${customer['id']}');
      print('     Profile Image: ${customer['profileImage']['url']}');
      print('     ---');
    }

    print('=== END OF ANALYSIS ===\n');
  }
}