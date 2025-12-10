// controllers/quick_chat_controller.dart
import 'package:get/get.dart';
import '../models/quick_message.dart';
import '../services/quick_chat_service.dart';

class QuickChatController extends GetxController {
  final QuickChatService _quickChatService = Get.find<QuickChatService>();

  final RxList<QuickMessage> quickMessages = <QuickMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadQuickMessages();
  }

  Future<void> loadQuickMessages() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final messages = await _quickChatService.getQuickChats();
      quickMessages.assignAll(messages);
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error loading quick messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshQuickMessages() async {
    await loadQuickMessages();
  }

  Future<void> sendQuickMessage(QuickMessage message) async {
    try {
      // Increment usage count if needed
      await _quickChatService.incrementUsageCount(message.id);
    } catch (e) {
      print('Error incrementing usage count: $e');
    }
  }

  Future<QuickMessage?> createQuickMessage(String content) async {
    try {
      isCreating.value = true;
      final newMessage = await _quickChatService.createQuickChat(content);
      quickMessages.insert(0, newMessage); // Add to beginning
      return newMessage;
    } catch (e) {
      errorMessage.value = 'Failed to create quick chat: $e';
      print('Error creating quick chat: $e');
      return null;
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> updateQuickMessage(QuickMessage message, String newContent) async {
    try {
      isLoading.value = true;

      // Call API to update the message
      final updatedMessage = await _quickChatService.updateQuickChat(message.id, newContent);

      // Update in local list
      final index = quickMessages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        quickMessages[index] = updatedMessage;
      }

      update(); // Notify listeners
    } catch (e) {
      errorMessage.value = 'Failed to update message: $e';
      print('Error updating quick chat: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteQuickMessage(QuickMessage message) async {
    try {
      isLoading.value = true;

      // Call API to delete the message
      await _quickChatService.deleteQuickChat(message.id);

      // Remove from local list
      quickMessages.removeWhere((m) => m.id == message.id);

      update(); // Notify listeners
    } catch (e) {
      errorMessage.value = 'Failed to delete message: $e';
      print('Error deleting quick chat: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}