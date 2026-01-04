import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/controller/quick_chat_controller.dart';
import 'package:naibrly/controller/socket_controller.dart';
import 'package:naibrly/models/quick_message.dart';
import 'package:naibrly/utils/app_colors.dart';
import '../../../base/AppText/appText.dart';

class QuickChatPage extends StatefulWidget {
  final String? requestId;
  final String? bundleId;
  final String? customerId;
  final String serviceName;
  final String providerName;

  const QuickChatPage({
    super.key,
    required this.requestId,
    required this.bundleId,
    required this.customerId,
    required this.serviceName,
    required this.providerName,
  });

  @override
  State<QuickChatPage> createState() => _QuickChatPageState();
}

class _QuickChatPageState extends State<QuickChatPage> {
  final QuickChatController _quickChatController = Get.find<QuickChatController>();
  final SocketController _socketController = Get.find<SocketController>();
  final TextEditingController _customMessageController = TextEditingController();
  final TextEditingController _editMessageController = TextEditingController();
  QuickMessage? _editingMessage;

  bool _isLoading = false;
  String _errorMessage = '';
  List<QuickMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuickMessages();
    });
  }

  Future<void> _loadQuickMessages() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _quickChatController.loadQuickMessages();
      // Get the latest messages from controller
      setState(() {
        _messages = _quickChatController.quickMessages.toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
      });
      if (kDebugMode) {
        print('❌ Error loading quick messages: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendQuickMessage(QuickMessage message) async {
    try {
      await _socketController.sendQuickChat(
        quickChatId: message.id ?? '',
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      // Also update in controller
      _quickChatController.sendQuickMessage(message);

      Get.back();
      Get.snackbar(
        'Success',
        'Message sent successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _sendCustomMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      await _socketController.sendMessage(
        content: message,
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      Get.back();
      Get.snackbar(
        'Success',
        'Message sent successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showCustomMessageDialog() {
    _customMessageController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                'Custom Message',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customMessageController,
                autofocus: true,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const AppText(
                        'Cancel',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.DarkGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final message = _customMessageController.text.trim();
                        if (message.isNotEmpty) {
                          Navigator.pop(context);
                          _sendCustomMessage(message);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const AppText(
                        'Send',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditMessageDialog(QuickMessage message) {
    _editingMessage = message;
    _editMessageController.text = message.message;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                'Edit Message',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _editMessageController,
                autofocus: true,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Edit your message...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const AppText(
                        'Cancel',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.DarkGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newMessage = _editMessageController.text.trim();
                        if (newMessage.isNotEmpty && _editingMessage != null) {
                          Navigator.pop(context);
                          _updateQuickMessage(_editingMessage!, newMessage);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const AppText(
                        'Update',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateQuickMessage(QuickMessage message, String newText) async {
    try {
      // Call update API through service
      await _quickChatController.updateQuickMessage(message, newText);

      // Refresh messages after update
      await _loadQuickMessages();

      Get.snackbar(
        'Success',
        'Message updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update message: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteQuickMessage(QuickMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Delete Message',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        content: const AppText(
          'Are you sure you want to delete this message?',
          fontSize: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const AppText(
              'Delete',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Call delete API through controller
        await _quickChatController.deleteQuickMessage(message);

        // Refresh messages after delete
        await _loadQuickMessages();

        Get.snackbar(
          'Success',
          'Message deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete message: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Widget _buildMessageTile(QuickMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          onTap: () => _sendQuickMessage(message),
          onLongPress: () => _showEditOptions(message),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        message.message,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.Black,
                      ),
                    ),
                    if (message.usageCount != null && message.usageCount! > 0) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: AppText(
                          '${message.usageCount} uses',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        labelPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 4),
                    AppText(
                      'Tap to send',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    Spacer(),
                    AppText(
                      'Long press to edit',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditOptions(QuickMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const AppText(
                'Edit Message',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditMessageDialog(message);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const AppText(
                'Delete Message',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteQuickMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading messages...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          AppText(
            _errorMessage,
            fontSize: 14,
            color: Colors.red,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadQuickMessages,
            child: const AppText('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          AppText(
            'No quick messages available',
            fontSize: 14,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          AppText(
            'Tap the + button to add a message',
            fontSize: 12,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  AppText(
                    'Quick Messages',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppText(
                'Tap any message to send it instantly. Long press to edit or delete.',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppText(
          'Available Messages (${_messages.length})',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.Black,
        ),
        const SizedBox(height: 12),
        ..._messages.map(_buildMessageTile),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AppText(
          'Quick Messages',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.Black,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadQuickMessages,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _messages.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomMessageDialog,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    _editMessageController.dispose();
    super.dispose();
  }
}