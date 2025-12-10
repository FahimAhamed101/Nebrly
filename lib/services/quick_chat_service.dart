// services/quick_chat_service.dart
import 'package:get/get.dart';
import '../models/quick_message.dart';
import './api_service.dart';

class QuickChatService extends GetxService {
  final MainApiService _apiService = Get.find<MainApiService>(); // Changed to ApiService

  Future<List<QuickMessage>> getQuickChats() async {
    try {
      final response = await _apiService.get('quick-chats');

      if (response['success'] == true) {
        final List<dynamic> quickChatsData = response['data']['quickChats'] ?? [];
        final List<QuickMessage> quickMessages = [];

        for (var chatData in quickChatsData) {
          final quickMessage = QuickMessage(
            id: chatData['_id']?.toString() ?? '',
            message: chatData['content']?.toString() ?? '',
            usageCount: chatData['usageCount'] != null ? int.tryParse(chatData['usageCount'].toString()) ?? 0 : 0,
            createdAt: chatData['createdAt'] != null
                ? DateTime.parse(chatData['createdAt'].toString())
                : DateTime.now(),
            updatedAt: chatData['updatedAt'] != null
                ? DateTime.parse(chatData['updatedAt'].toString())
                : DateTime.now(),
          );
          quickMessages.add(quickMessage);
        }

        return quickMessages;
      } else {
        throw Exception(response['message']?.toString() ?? 'Failed to load quick chats');
      }
    } catch (e) {
      throw Exception('Error fetching quick chats: $e');
    }
  }

  Future<void> incrementUsageCount(String chatId) async {
    try {
      final response = await _apiService.put('quick-chats/$chatId/increment-usage', {});

      if (response['success'] != true) {
        throw Exception(response['message']?.toString() ?? 'Failed to increment usage count');
      }
    } catch (e) {
      throw Exception('Error incrementing usage count: $e');
    }
  }

  Future<QuickMessage> createQuickChat(String content) async {
    try {
      final response = await _apiService.post('quick-chats', {
        'content': content,
      });

      if (response['success'] == true && response['data'] != null) {
        final chatData = response['data'];
        return QuickMessage(
          id: chatData['_id']?.toString() ?? '',
          message: chatData['content']?.toString() ?? '',
          usageCount: chatData['usageCount'] != null ? int.tryParse(chatData['usageCount'].toString()) ?? 0 : 0,
          createdAt: chatData['createdAt'] != null
              ? DateTime.parse(chatData['createdAt'].toString())
              : DateTime.now(),
          updatedAt: chatData['updatedAt'] != null
              ? DateTime.parse(chatData['updatedAt'].toString())
              : DateTime.now(),
        );
      } else {
        throw Exception(response['message']?.toString() ?? 'Failed to create quick chat');
      }
    } catch (e) {
      throw Exception('Error creating quick chat: $e');
    }
  }

  Future<QuickMessage> updateQuickChat(String chatId, String newContent) async {
    try {
      final response = await _apiService.put('quick-chats/$chatId', {
        'content': newContent,
      });

      if (response['success'] == true && response['data'] != null) {
        final chatData = response['data'];
        return QuickMessage(
          id: chatData['_id']?.toString() ?? '',
          message: chatData['content']?.toString() ?? '',
          usageCount: chatData['usageCount'] != null ? int.tryParse(chatData['usageCount'].toString()) ?? 0 : 0,
          createdAt: chatData['createdAt'] != null
              ? DateTime.parse(chatData['createdAt'].toString())
              : DateTime.now(),
          updatedAt: chatData['updatedAt'] != null
              ? DateTime.parse(chatData['updatedAt'].toString())
              : DateTime.now(),
        );
      } else {
        throw Exception(response['message']?.toString() ?? 'Failed to update quick chat');
      }
    } catch (e) {
      throw Exception('Error updating quick chat: $e');
    }
  }

  Future<void> deleteQuickChat(String chatId) async {
    try {
      final response = await _apiService.delete('quick-chats/$chatId');

      if (response['success'] != true) {
        throw Exception(response['message']?.toString() ?? 'Failed to delete quick chat');
      }
    } catch (e) {
      throw Exception('Error deleting quick chat: $e');
    }
  }
}