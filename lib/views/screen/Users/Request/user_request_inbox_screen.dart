// views/screen/Users/Request/user_request_inbox_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/models/user_request1.dart';
import 'package:naibrly/models/quick_message.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/widgets/payment_confirmation_bottom_sheet.dart';
import 'package:naibrly/widgets/naibrly_now_bottom_sheet.dart';

import '../../../../controller/quick_chat_controller.dart';
import '../../../../controller/socket_controller.dart';
import 'QuickChatPage.dart';

class UserRequestInboxScreen extends StatefulWidget {
  final UserRequest request;
  final String? bundleId;
  final String? requestId;
  final String? customerId;

  const UserRequestInboxScreen({
    super.key,
    required this.request,
    this.bundleId,
    this.requestId,
    this.customerId,
  });

  @override
  State<UserRequestInboxScreen> createState() => _UserRequestInboxScreenState();
}

class _UserRequestInboxScreenState extends State<UserRequestInboxScreen> {
  final ScrollController _scrollController = ScrollController();
  final QuickChatController _quickChatController = Get.find<QuickChatController>();
  final SocketController _socketController = Get.find<SocketController>();

  bool _isWaitingForAcceptance = false;
  bool _showFeedback = false;
  bool _isCancelled = false;
  String? _cancellationReason;
  DateTime? _cancellationTime;

  StreamSubscription? _messagesSubscription;

  List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();

    // Check if request is cancelled
    _isCancelled = widget.request.status.toLowerCase() == 'cancelled';

    if (_isCancelled) {
      _cancellationReason = widget.request.cancellationReason ??
          'The service was no longer required due to unforeseen circumstances.';
      _cancellationTime = widget.request.cancellationTime ?? DateTime.now();
    }

    // Check if request is done
    if (widget.request.status.toLowerCase() == 'completed' ||
        widget.request.status.toLowerCase() == 'done') {
      _showFeedback = true;
    }

    // Load quick messages
    _loadQuickMessages();

    // Initialize socket connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketConnection();
    });
  }

  void _initializeSocketConnection() async {
    try {
      if (kDebugMode) {
        print('🔗 Initializing socket connection...');
        print('Request ID: ${widget.requestId}');
        print('Bundle ID: ${widget.bundleId}');
        print('Customer ID: ${widget.customerId}');
      }

      // Ensure socket is connected
      if (!_socketController.isConnected) {
        if (kDebugMode) {
          print('🔄 Socket not connected, reconnecting...');
        }
        await _socketController.reconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      // Join conversation and load history
      await _socketController.joinConversation(
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      // Wait for history to load
      await Future.delayed(const Duration(milliseconds: 1500));

      // Load existing messages
      _loadExistingMessages();

      // Setup real-time message listener
      _setupMessageListener();

      setState(() {
        _isLoadingHistory = false;
      });

      if (kDebugMode) {
        print('✅ Socket connection initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing socket connection: $e');
      }

      setState(() {
        _isLoadingHistory = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _loadExistingMessages() {
    try {
      final existingMessages = _socketController.getMessagesForConversation(
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      if (kDebugMode) {
        print('📜 UI: Loading ${existingMessages.length} existing messages from controller');
        if (existingMessages.isNotEmpty) {
          print('📜 UI: First message: ${existingMessages.first}');
          print('📜 UI: Last message: ${existingMessages.last}');
        }
      }

      if (existingMessages.isNotEmpty) {
        final newMessages = existingMessages
            .map((msg) => ChatMessage.fromSocketData(msg))
            .toList();

        // Always update to get latest messages
        if (mounted) {
          setState(() {
            _messages = newMessages;
          });

          if (kDebugMode) {
            print('✅ UI: Updated UI with ${_messages.length} messages');
          }

          // Scroll to bottom to show latest message
          _scrollToBottom();
        }
      } else if (_messages.isEmpty) {
        // Add initial welcome messages if no history
        if (mounted) {
          setState(() {
            _messages = [
              ChatMessage(
                text: "Your service request has been confirmed!",
                isFromUser: false,
                isFromProvider: true,
                timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
              ),
            ];
          });
        }

        if (kDebugMode) {
          print('ℹ️ UI: No existing messages, using default welcome message');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UI: Error loading existing messages: $e');
      }
    }
  }

  void _setupMessageListener() {
    // Cancel existing subscription
    _messagesSubscription?.cancel();

    // Listen to message changes via the stream controller
    _messagesSubscription = _socketController.messagesChangeStream.listen((_) {
      if (mounted) {
        _loadExistingMessages();
      }
    });

    if (kDebugMode) {
      print('✅ Message listener set up');
    }
  }

  Future<void> _loadQuickMessages() async {
    try {
      await _quickChatController.loadQuickMessages();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading quick messages: $e');
      }
    }
  }

  void _sendQuickMessage(QuickMessage message) async {
    try {
      if (kDebugMode) {
        print('📤 UI: Sending quick message: ${message.message}');
      }

      // Send via socket first
      await _socketController.sendQuickChat(
        quickChatId: message.id ?? '',
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      // Track usage in API
      _quickChatController.sendQuickMessage(message);

      if (kDebugMode) {
        print('✅ UI: Quick message sent, reloading messages...');
      }

      // Force reload messages after a delay
      await Future.delayed(const Duration(milliseconds: 800));
      _loadExistingMessages();

    } catch (e) {
      if (kDebugMode) {
        print('❌ UI: Error sending quick message: $e');
      }

      // Show error message in UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToQuickChatPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuickChatPage(
          requestId: widget.requestId,
          bundleId: widget.bundleId,
          customerId: widget.customerId,
          serviceName: widget.request.serviceName,
          providerName: widget.request.provider?.fullName ?? widget.request.providerName ?? 'Provider',
        ),
      ),
    );
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messagesSubscription?.cancel();

    // Mark conversation as read when leaving
    _socketController.markConversationAsRead(
      requestId: widget.requestId,
      bundleId: widget.bundleId,
      customerId: widget.customerId,
    );

    super.dispose();
  }

  void _handleCopyToClipboard(String text, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $text'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCancelRequestDialog() {
    final providerName = widget.request.provider?.fullName ?? widget.request.providerName ?? 'Provider';

    showCancelRequestBottomSheet(
      context,
      onNaibrlyNow: () {
        showNaibrlyNowBottomSheet(
          context,
          serviceName: widget.request.serviceName,
          providerName: providerName,
        );
      },
      onCancelConfirmed: (reason) {
        setState(() {
          _isCancelled = true;
          _cancellationReason = reason;
          _cancellationTime = DateTime.now();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerName = widget.request.provider?.fullName ?? widget.request.providerName ?? 'Provider';
    final providerImage = widget.request.providerImage ?? widget.request.provider?.businessLogo?.url ?? widget.request.imagePath ?? 'assets/images/default_avatar.png';
    final providerRating = widget.request.providerRating ?? widget.request.provider?.rating ?? 0.0;
    final providerReviewCount = widget.request.providerReviewCount ?? 0;
    final isCompleted = widget.request.status.toLowerCase() == 'completed' ||
        widget.request.status.toLowerCase() == 'done';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText(
          _isCancelled ? 'Cancelled' : 'Request Inbox',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.Black,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: (_isWaitingForAcceptance || _showFeedback || _isCancelled || isCompleted) ? null : () {
                _showCancelRequestDialog();
              },
              style: TextButton.styleFrom(
                backgroundColor: (_isWaitingForAcceptance || _showFeedback || _isCancelled || isCompleted)
                    ? Colors.grey[300]
                    : const Color(0xFFFEEEEE),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: AppText(
                _isCancelled ? 'Cancelled' : (isCompleted ? 'Completed' : 'Cancel'),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (_isWaitingForAcceptance || _showFeedback || _isCancelled || isCompleted)
                    ? Colors.grey[600]
                    : const Color(0xFFF34F4F),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.bundleId != null || widget.requestId != null || widget.customerId != null)
                      _buildIdSection(),

                    _buildRequestDetailsCard(),

                    if (_isLoadingHistory)
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            AppText(
                              'Loading conversation...',
                              fontSize: 14,
                              color: AppColors.DarkGray,
                            ),
                          ],
                        ),
                      )
                    else
                      _showFeedback
                          ? Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: _buildChatMessages(),
                          ),
                          _buildFeedbackMessage(),
                        ],
                      )
                          : SizedBox(
                        height: 200,
                        child: _buildChatMessages(),
                      ),

                    if (_isWaitingForAcceptance)
                      _buildWaitingMessage(providerName),

                    if (_isCancelled) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: AppText(
                          _cancellationReason ?? 'The service was no longer required due to unforeseen circumstances.',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.DarkGray,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else if (!_isWaitingForAcceptance && !_showFeedback && !_isLoadingHistory) ...[
                      _buildQuickReplies(),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isWaitingForAcceptance || _showFeedback || _isCancelled || _isLoadingHistory
          ? null
          : FloatingActionButton(
        onPressed: _navigateToQuickChatPage,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMessageInputDialog() {
    final TextEditingController messageController = TextEditingController();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: AppText(
        'New Message',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.Black,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: messageController,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: AppText(
            'Cancel',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.DarkGray,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final message = messageController.text.trim();
            if (message.isNotEmpty) {
              Navigator.of(context).pop(message);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: AppText(
            'Send',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildIdSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.bundleId != null) ...[
            _buildClickableId(
              label: 'Bundle ID',
              id: widget.bundleId!,
              icon: Icons.inventory,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.requestId != null) ...[
            _buildClickableId(
              label: 'Request ID',
              id: widget.requestId!,
              icon: Icons.request_page,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.customerId != null) ...[
            _buildClickableId(
              label: 'Customer ID',
              id: widget.customerId!,
              icon: Icons.person,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClickableId({
    required String label,
    required String id,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            AppText(
              label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _handleCopyToClipboard(id, label),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    id,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.content_copy,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDetailsCard() {
    final providerName = widget.request.provider?.fullName ?? widget.request.providerName ?? 'Provider';
    final providerImage = widget.request.providerImage ?? widget.request.provider?.businessLogo?.url ?? widget.request.imagePath ?? 'assets/images/default_avatar.png';
    final providerRating = widget.request.providerRating ?? widget.request.provider?.rating ?? 0.0;
    final providerReviewCount = widget.request.providerReviewCount ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                '${widget.request.serviceName}: ',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
              AppText(
                '\$${widget.request.averagePrice.toInt()}/hr',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: providerImage.startsWith('http')
                    ? NetworkImage(providerImage)
                    : AssetImage(providerImage) as ImageProvider,
                onBackgroundImageError: (exception, stackTrace) {},
                child: providerImage.startsWith('http')
                    ? null
                    : const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    providerName,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.Black,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      AppText(
                        '$providerRating ($providerReviewCount reviews)',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.DarkGray,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Address: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.Black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: widget.request.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.DarkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              AppText(
                'Date: ${widget.request.formattedDate} Time: ${widget.request.time}',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.DarkGray,
              ),
            ],
          ),
          if (widget.request.problemDescription != null && widget.request.problemDescription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppText(
              'Problem Note for ${widget.request.serviceName}',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.Black,
            ),
            const SizedBox(height: 4),
            AppText(
              widget.request.problemDescription!,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    final providerImage = widget.request.providerImage ??
        widget.request.provider?.businessLogo?.url ??
        widget.request.imagePath ??
        'assets/images/default_avatar.png';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText(
              'Today',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.DarkGray,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: AppText(
                'No messages yet',
                fontSize: 14,
                color: AppColors.DarkGray,
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, providerImage);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String providerImage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: providerImage.startsWith('http')
                  ? NetworkImage(providerImage)
                  : AssetImage(providerImage) as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) {},
              child: providerImage.startsWith('http')
                  ? null
                  : const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isFromUser
                    ? AppColors.primary.withOpacity(message.isPending ? 0.6 : 1.0)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    message.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: message.isFromUser ? Colors.white : AppColors.Black,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        _formatTime(message.timestamp),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: message.isFromUser ? Colors.white70 : AppColors.DarkGray,
                      ),
                      if (message.isPending) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              message.isFromUser ? Colors.white70 : AppColors.DarkGray,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Obx(() {
      if (_quickChatController.isLoading.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_quickChatController.errorMessage.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              AppText(
                _quickChatController.errorMessage.value,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.red,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _loadQuickMessages(),
                child: AppText(
                  'Retry',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }

      if (_quickChatController.quickMessages.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message_outlined, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        'No quick questions available.',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.DarkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  'Quick Questions',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.DarkGray,
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _loadQuickMessages(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: _quickChatController.quickMessages.length,
                itemBuilder: (context, index) {
                  final message = _quickChatController.quickMessages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => _sendQuickMessage(message),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7D6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1C400), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              message.message,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8B4513),
                              maxLines: 2,
                            ),
                            if (message.usageCount != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.thumb_up,
                                    size: 10,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  AppText(
                                    '${message.usageCount} uses',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWaitingMessage(String providerName) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(
              Icons.access_time,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Please wait for acceptance from $providerName',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                AppText(
                  'Your request is pending approval.',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.DarkGray,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.feedback, size: 50, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          AppText(
            'Received feedback from the provider',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.Black,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText(
            'Thank you for your order! It was a pleasure working on your request.',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.DarkGray,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (index) => const Icon(
                Icons.star,
                color: Colors.amber,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showFeedback = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                elevation: 0,
              ),
              child: AppText(
                'Done',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final bool isFromProvider;
  final DateTime timestamp;
  final String? senderId;
  final bool isQuickChat;
  final bool isPending;

  ChatMessage({
    required this.text,
    this.isFromUser = false,
    this.isFromProvider = false,
    required this.timestamp,
    this.senderId,
    this.isQuickChat = false,
    this.isPending = false,
  });

  factory ChatMessage.fromSocketData(Map<String, dynamic> data) {
    return ChatMessage(
      text: data['content']?.toString() ?? '',
      isFromUser: data['senderRole'] == 'customer',
      isFromProvider: data['senderRole'] == 'provider',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      senderId: data['senderId']?.toString(),
      isQuickChat: data['isQuickChat'] == true || data['quickChatId'] != null,
      isPending: false,
    );
  }

  ChatMessage copyWith({
    String? text,
    bool? isFromUser,
    bool? isFromProvider,
    DateTime? timestamp,
    String? senderId,
    bool? isQuickChat,
    bool? isPending,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isFromUser: isFromUser ?? this.isFromUser,
      isFromProvider: isFromProvider ?? this.isFromProvider,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      isQuickChat: isQuickChat ?? this.isQuickChat,
      isPending: isPending ?? this.isPending,
    );
  }
}