// lib/controller/socket_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:naibrly/services/socket_service.dart';

class SocketController extends GetxController {
  static SocketController get instance => Get.find<SocketController>();

  final SocketService _socketService = SocketService.instance;

  final RxMap<String, List<Map<String, dynamic>>> _messages = <String, List<Map<String, dynamic>>>{}.obs;
  final RxMap<String, bool> _typingStatus = <String, bool>{}.obs;
  final RxMap<String, int> _unreadCounts = <String, int>{}.obs;
  final RxList<Map<String, dynamic>> _allConversations = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> _currentConversation = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Getters
  Map<String, List<Map<String, dynamic>>> get messages => _messages;
  Map<String, bool> get typingStatus => _typingStatus;
  Map<String, int> get unreadCounts => _unreadCounts;
  List<Map<String, dynamic>> get allConversations => _allConversations;
  Map<String, dynamic> get currentConversation => _currentConversation;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isConnected => _socketService.isConnected.value;
  String get connectionStatus => _socketService.connectionStatus.value;

  // Stream to notify UI of message changes
  final _messagesChangeController = StreamController<void>.broadcast();
  Stream<void> get messagesChangeStream => _messagesChangeController.stream;

  List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _initializeSocket();
    _setupSocketListeners();
  }

  Future<void> _initializeSocket() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _socketService.initializeSocket();

      if (kDebugMode) {
        print('✅ Socket controller initialized');
      }
    } catch (e) {
      _error.value = 'Failed to initialize socket: $e';

      if (kDebugMode) {
        print('❌ Error initializing socket controller: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void _setupSocketListeners() {
    // Clear existing subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Listen for connection status
    _subscriptions.add(
        _socketService.connectionStream.listen((connected) {
          if (connected) {
            if (kDebugMode) {
              print('✅ Socket connected in controller');
            }
            _loadAllConversations();
          } else {
            if (kDebugMode) {
              print('📴 Socket disconnected in controller');
            }
          }
        })
    );

    // Listen for all messages
    _subscriptions.add(
        _socketService.messageStream.listen((messageData) {
          _handleMessage(messageData);
        })
    );

    // Listen for quick chat messages
    _subscriptions.add(
        _socketService.quickChatStream.listen((quickChatData) {
          _handleQuickChatMessage(quickChatData);
        })
    );

    // Listen for conversation history
    _subscriptions.add(
        _socketService.conversationHistoryStream.listen((historyData) {
          _handleConversationHistory(historyData);
        })
    );

    // Listen for all conversations
    _subscriptions.add(
        _socketService.allConversationsStream.listen((conversations) {
          _handleAllConversations(conversations);
        })
    );

    // Listen for typing indicators
    _subscriptions.add(
        _socketService.typingStream.listen((typingData) {
          _handleTypingIndicator(typingData);
        })
    );

    // Listen for delivery status
    _subscriptions.add(
        _socketService.deliveryStream.listen((deliveryData) {
          _handleDeliveryStatus(deliveryData);
        })
    );

    // Listen for errors
    _subscriptions.add(
        _socketService.errorStream.listen((errorMsg) {
          _error.value = errorMsg;

          if (kDebugMode) {
            print('❌ Socket error in controller: $errorMsg');
          }
        })
    );
  }

  String _getConversationKey({String? requestId, String? bundleId, String? customerId}) {
    if (requestId != null && requestId.isNotEmpty) return 'request_$requestId';
    if (bundleId != null && bundleId.isNotEmpty) return 'bundle_$bundleId';
    if (customerId != null && customerId.isNotEmpty) return 'customer_$customerId';
    return 'unknown';
  }

  void _handleMessage(Map<String, dynamic> messageData) {
    try {
      final type = messageData['type']?.toString() ?? 'unknown';
      final data = messageData['data'];

      if (kDebugMode) {
        print('📨 Controller handling message type: $type');
        print('📨 Message data: $data');
      }

      // Handle all message types - including sent messages
      if (data != null) {
        _addMessageToConversation(data);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling message: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  void _handleQuickChatMessage(Map<String, dynamic> quickChatData) {
    try {
      if (kDebugMode) {
        print('💬 Controller handling quick chat: $quickChatData');
      }

      final data = quickChatData['data'];
      if (data != null) {
        _addMessageToConversation(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling quick chat: $e');
      }
    }
  }

  void _addMessageToConversation(dynamic messageData) {
    try {
      Map<String, dynamic> message;

      if (messageData is Map<String, dynamic>) {
        message = messageData;
      } else {
        if (kDebugMode) {
          print('⚠️ Invalid message data type: ${messageData.runtimeType}');
        }
        return;
      }

      final conversationKey = _getConversationKey(
        requestId: message['requestId']?.toString(),
        bundleId: message['bundleId']?.toString(),
        customerId: message['customerId']?.toString(),
      );

      // Initialize conversation if needed
      if (!_messages.containsKey(conversationKey)) {
        _messages[conversationKey] = [];
        if (kDebugMode) {
          print('🆕 Created new conversation: $conversationKey');
        }
      }

      // Check if message already exists (avoid duplicates)
      final messageId = message['_id']?.toString() ??
          message['id']?.toString() ??
          message['messageId']?.toString();

      final exists = messageId != null &&
          _messages[conversationKey]!.any((msg) =>
          msg['_id']?.toString() == messageId ||
              msg['id']?.toString() == messageId ||
              msg['messageId']?.toString() == messageId
          );

      if (!exists) {
        _messages[conversationKey]!.add(message);
        _messages.refresh();

        // Notify listeners of message change
        _messagesChangeController.add(null);

        // Update unread count if message is from another user
        final senderRole = message['senderRole']?.toString() ?? '';
        if (senderRole != 'customer') {
          _updateUnreadCount(conversationKey, increment: true);
        }

        if (kDebugMode) {
          print('✅ Message added to conversation $conversationKey');
          print('Total messages in conversation: ${_messages[conversationKey]!.length}');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Duplicate message skipped: $messageId');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error adding message to conversation: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  void _handleConversationHistory(Map<String, dynamic> historyData) {
    try {
      final type = historyData['type'];
      final data = historyData['data'];

      if (kDebugMode) {
        print('📜 Processing conversation history');
        print('Type: $type, Data type: ${data.runtimeType}');
      }

      if (data is Map<String, dynamic>) {
        // Extract conversation and messages
        final conversation = data['conversation'] as Map<String, dynamic>?;
        final messages = data['messages'] as List<dynamic>?;

        if (kDebugMode) {
          print('Conversation: ${conversation != null}');
          print('Messages count: ${messages?.length ?? 0}');
        }

        if (conversation != null) {
          _currentConversation.value = conversation;

          final conversationKey = _getConversationKey(
            requestId: conversation['requestId']?.toString(),
            bundleId: conversation['bundleId']?.toString(),
            customerId: conversation['customerId']?.toString(),
          );

          if (messages != null && messages.isNotEmpty) {
            _messages[conversationKey] = messages
                .whereType<Map<String, dynamic>>()
                .map((msg) => Map<String, dynamic>.from(msg))
                .toList();
            _messages.refresh();

            // Notify listeners of message change
            _messagesChangeController.add(null);

            // Mark as read
            _updateUnreadCount(conversationKey, reset: true);

            if (kDebugMode) {
              print('✅ Loaded ${messages.length} messages for $conversationKey');
            }
          } else {
            // Initialize empty conversation
            _messages[conversationKey] = [];
            _messages.refresh();

            // Notify listeners
            _messagesChangeController.add(null);

            if (kDebugMode) {
              print('ℹ️ No messages in conversation history for $conversationKey');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling conversation history: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  void _handleAllConversations(List<dynamic> conversations) {
    try {
      _allConversations.value = conversations
          .whereType<Map<String, dynamic>>()
          .map((conv) => Map<String, dynamic>.from(conv))
          .toList();

      if (kDebugMode) {
        print('✅ Loaded ${_allConversations.length} conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling all conversations: $e');
      }
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> typingData) {
    try {
      final type = typingData['type'];
      final data = typingData['data'] as Map<String, dynamic>?;

      if (data != null) {
        final conversationKey = _getConversationKey(
          requestId: data['requestId']?.toString(),
          bundleId: data['bundleId']?.toString(),
          customerId: data['customerId']?.toString(),
        );

        if (type == 'typing') {
          _typingStatus[conversationKey] = true;
        } else if (type == 'stop_typing') {
          _typingStatus[conversationKey] = false;
        }
        _typingStatus.refresh();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling typing indicator: $e');
      }
    }
  }

  void _handleDeliveryStatus(Map<String, dynamic> deliveryData) {
    try {
      if (kDebugMode) {
        print('📬 Delivery status: $deliveryData');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling delivery status: $e');
      }
    }
  }

  // Public methods

  Future<void> joinConversation({String? requestId, String? bundleId, String? customerId}) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      if (kDebugMode) {
        print('🤝 Joining conversation...');
        print('Request ID: $requestId');
        print('Bundle ID: $bundleId');
        print('Customer ID: $customerId');
      }

      await _socketService.joinConversation(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      // Wait a bit for join to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Get conversation history after joining
      await _getConversation(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      if (kDebugMode) {
        print('✅ Successfully joined and loaded conversation');
      }

    } catch (e) {
      _error.value = 'Failed to join conversation: $e';

      if (kDebugMode) {
        print('❌ Error joining conversation: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _getConversation({String? requestId, String? bundleId, String? customerId}) async {
    try {
      if (kDebugMode) {
        print('📥 Getting conversation history...');
        print('   Request ID: $requestId');
        print('   Bundle ID: $bundleId');
        print('   Customer ID: $customerId');
      }

      await _socketService.getConversation(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      // Wait for history to load
      await Future.delayed(const Duration(milliseconds: 1000));

      if (kDebugMode) {
        print('✅ Conversation history request completed');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversation: $e');
      }
    }
  }

  Future<void> _loadAllConversations() async {
    try {
      await _socketService.getAllConversations();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading conversations: $e');
      }
    }
  }

  Future<void> sendQuickChat({
    required String quickChatId,
    String? requestId,
    String? bundleId,
    String? customerId,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 SocketController: Sending quick chat...');
      }

      await _socketService.sendQuickChat(
        quickChatId: quickChatId,
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      if (kDebugMode) {
        print('✅ Quick chat sent, requesting updated conversation...');
      }

      // Initialize conversation if needed
      final conversationKey = _getConversationKey(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      if (!_messages.containsKey(conversationKey)) {
        _messages[conversationKey] = [];
        if (kDebugMode) {
          print('🆕 Initialized conversation: $conversationKey');
        }
      }

      // Request updated conversation history immediately after sending
      // Don't wait for the service delay
      _getConversation(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

    } catch (e) {
      _error.value = 'Failed to send quick chat: $e';

      if (kDebugMode) {
        print('❌ Error sending quick chat: $e');
      }
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String content,
    String? requestId,
    String? bundleId,
    String? customerId,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 SocketController: Sending message...');
      }

      await _socketService.sendMessage(
        content: content,
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      if (kDebugMode) {
        print('✅ Message sent, requesting updated conversation...');
      }

      // Initialize conversation if needed
      final conversationKey = _getConversationKey(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

      if (!_messages.containsKey(conversationKey)) {
        _messages[conversationKey] = [];
        if (kDebugMode) {
          print('🆕 Initialized conversation: $conversationKey');
        }
      }

      // Request updated conversation history immediately after sending
      // Don't wait for the service delay
      _getConversation(
        requestId: requestId,
        bundleId: bundleId,
        customerId: customerId,
      );

    } catch (e) {
      _error.value = 'Failed to send message: $e';

      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      rethrow;
    }
  }

  void startTyping({String? requestId, String? bundleId, String? customerId}) {
    _socketService.startTyping(
      requestId: requestId,
      bundleId: bundleId,
      customerId: customerId,
    );
  }

  void stopTyping({String? requestId, String? bundleId, String? customerId}) {
    _socketService.stopTyping(
      requestId: requestId,
      bundleId: bundleId,
      customerId: customerId,
    );
  }

  void _updateUnreadCount(String conversationKey, {bool increment = false, bool reset = false}) {
    if (reset) {
      _unreadCounts[conversationKey] = 0;
    } else if (increment) {
      _unreadCounts[conversationKey] = (_unreadCounts[conversationKey] ?? 0) + 1;
    }
    _unreadCounts.refresh();
  }

  void markConversationAsRead({String? requestId, String? bundleId, String? customerId}) {
    final conversationKey = _getConversationKey(
      requestId: requestId,
      bundleId: bundleId,
      customerId: customerId,
    );
    _updateUnreadCount(conversationKey, reset: true);
  }

  List<Map<String, dynamic>> getMessagesForConversation({
    String? requestId,
    String? bundleId,
    String? customerId,
  }) {
    final conversationKey = _getConversationKey(
      requestId: requestId,
      bundleId: bundleId,
      customerId: customerId,
    );

    final msgs = _messages[conversationKey] ?? [];

    if (kDebugMode) {
      print('📨 Getting messages for $conversationKey: ${msgs.length} messages');
    }

    return msgs;
  }

  bool isUserTyping({String? requestId, String? bundleId, String? customerId}) {
    final conversationKey = _getConversationKey(
      requestId: requestId,
      bundleId: bundleId,
      customerId: customerId,
    );
    return _typingStatus[conversationKey] ?? false;
  }

  int getUnreadCount({String? requestId, String? bundleId, String? customerId}) {
    final conversationKey = _getConversationKey(
      requestId: requestId,
      bundleId: bundleId,
      customerId: customerId,
    );
    return _unreadCounts[conversationKey] ?? 0;
  }

  Future<void> reconnect() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _socketService.reconnect();
    } catch (e) {
      _error.value = 'Reconnection failed: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Close message change controller
    _messagesChangeController.close();

    super.onClose();
  }
}