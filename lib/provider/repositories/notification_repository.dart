// repositories/notification_repository.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import '../../utils/tokenService.dart';
import '../models/notification.dart';

class NotificationRepository {
  final String baseUrl = 'https://naibrly-backend-main.onrender.com/api';
  String? get _token {
    final tokenService = Get.find<TokenService>();
    return tokenService.getToken();
  }



  Future<NotificationResponse> getNotifications() async {

    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }


    final response = await http.get(
      Uri.parse('$baseUrl/notifications/me'),




      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // Add your auth token
      },


    );

    if (response.statusCode == 200) {
      return NotificationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<Map<String, dynamic>> markAsRead(String notificationId) async {

    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),



      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }


    final response = await http.put(
      Uri.parse('$baseUrl/notifications/mark-all-read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN_HERE',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {

    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/$notificationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete notification');
    }
  }
}