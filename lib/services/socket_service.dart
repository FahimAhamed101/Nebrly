// lib/services/socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/tokenService.dart';

class SocketService extends GetxService {
  static SocketService get instance => Get.find<SocketService>();

  IO.Socket? _socket;
  final RxBool isConnected = false.obs;
  final RxString socketId = ''.obs;
  final RxString connectionStatus = 'disconnected'.obs;

  // Stream controllers
  final _connectionController = StreamController<bool>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _quickChatController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationHistoryController = StreamController<Map<String, dynamic>>.broadcast();
  final _allConversationsController = StreamController<List<dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get quickChatStream => _quickChatController.stream;
  Stream<Map<String, dynamic>> get conversationHistoryStream => _conversationHistoryController.stream;
  Stream<List<dynamic>> get allConversationsStream => _allConversationsController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get deliveryStream => _deliveryController.stream;
  Stream<String> get errorStream => _errorController.stream;

  final TokenService _tokenService = Get.find<TokenService>();
  Completer<void>? _initializationCompleter;
  bool _isInitialized = false;

  Future<void> initializeSocket() async {
    try {
      // Prevent multiple initializations
      if (_isInitialized && _socket != null && isConnected.value) {
        if (kDebugMode) {
          print('✅ Socket already initialized and connected');
        }
        return;
      }

      final token = _tokenService.getToken();

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('❌ No token available for socket connection');
        }
        _errorController.add('Authentication token not found');
        return;
      }

      if (kDebugMode) {
        print('🔗 Initializing socket with token...');
      }

      // Clean up existing socket if any
      if (_socket != null) {
        try {
          _socket!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error disposing old socket: $e');
          }
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Create new completer
      _initializationCompleter = Completer<void>();

      _socket = IO.io(
        'https://naibrly-backend.onrender.com',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setTimeout(30000)
            .setExtraHeaders({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        })
            .build(),
      );

      _setupSocketListeners();

      // Manual connection
      _socket!.connect();

      // Wait for connection
      await _waitForConnection();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Socket initialized successfully');
      }

      if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete();
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Socket initialization error: $e');
        print('Stack trace: $stackTrace');
      }
      _errorController.add('Socket initialization failed: $e');

      if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.completeError(e);
      }
    }
  }

  Future<void> _waitForConnection() async {
    int attempts = 0;
    const maxAttempts = 10;

    while (!isConnected.value && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    if (!isConnected.value) {
      throw Exception('Socket connection timeout');
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      isConnected.value = true;
      socketId.value = _socket?.id ?? '';
      connectionStatus.value = 'connected';
      _connectionController.add(true);

      if (kDebugMode) {
        print('✅ Socket connected with ID: ${_socket?.id}');
      }
    });

    _socket!.onConnectError((data) {
      connectionStatus.value = 'error';
      _errorController.add('Connection error: $data');

      if (kDebugMode) {
        print('❌ Socket connection error: $data');
      }
    });

    _socket!.onDisconnect((reason) {
      isConnected.value = false;
      connectionStatus.value = 'disconnected';
      _connectionController.add(false);

      if (kDebugMode) {
        print('📴 Socket disconnected: $reason');
      }
    });

    _socket!.onError((data) {
      _errorController.add('Socket error: $data');

      if (kDebugMode) {
        print('⚠️ Socket error: $data');
      }
    });

    // Message events - Unified handler
    _socket!.on('message', (data) {
      _handleSocketMessage(data);
    });

    // Direct event handlers
    _socket!.on('new_message', (data) {
      if (kDebugMode) {
        print('📨 Direct new_message event: $data');
      }
      _handleDirectMessage('new_message', data);
    });

    _socket!.on('new_quick_message', (data) {
      if (kDebugMode) {
        print('💬 Direct new_quick_message event: $data');
      }
      _handleDirectMessage('new_quick_message', data);
    });

    _socket!.on('conversation_history', (data) {
      if (kDebugMode) {
        print('📜 Direct conversation_history event: $data');
      }
      _handleDirectMessage('conversation_history', data);
    });

    _socket!.on('conversations_list', (data) {
      if (kDebugMode) {
        print('📋 Direct conversations_list event: $data');
      }
      _handleDirectMessage('conversations_list', data);
    });

    _socket!.on('typing', (data) {
      _handleDirectMessage('typing', data);
    });

    _socket!.on('stop_typing', (data) {
      _handleDirectMessage('stop_typing', data);
    });

    _socket!.on('message_delivered', (data) {
      _handleDirectMessage('message_delivered', data);
    });

    _socket!.on('message_read', (data) {
      _handleDirectMessage('message_read', data);
    });

    _socket!.on('error', (data) {
      final errorMsg = data is String ? data : data.toString();
      _errorController.add(errorMsg);

      if (kDebugMode) {
        print('❌ Server error: $errorMsg');
      }
    });
  }

  void _handleSocketMessage(dynamic data) {
    try {
      if (kDebugMode) {
        print('📨 Raw socket message: $data');
      }

      if (data is Map<String, dynamic>) {
        final type = data['type']?.toString() ?? 'unknown';
        final eventData = data['data'] ?? data;

        if (kDebugMode) {
          print('📋 Message type: $type');
        }

        switch (type) {
          case 'new_message':
            _messageController.add({'type': 'new_message', 'data': eventData});
            break;
          case 'new_quick_message':
            _quickChatController.add({'type': 'new_quick_message', 'data': eventData});
            break;
          case 'conversation_history':
            _conversationHistoryController.add({'type': 'history', 'data': eventData});
            break;
          case 'conversations_list':
          case 'customer_conversations':
            _processConversationsList(eventData);
            break;
          case 'typing':
            _typingController.add({'type': 'typing', 'data': eventData});
            break;
          case 'stop_typing':
            _typingController.add({'type': 'stop_typing', 'data': eventData});
            break;
          case 'message_delivered':
            _deliveryController.add({'type': 'delivered', 'data': eventData});
            break;
          case 'message_read':
            _deliveryController.add({'type': 'read', 'data': eventData});
            break;
          default:
            _messageController.add({'type': type, 'data': eventData});
        }
      } else if (data is List) {
        _processConversationsList({'conversations': data});
      } else {
        _messageController.add({'type': 'raw', 'data': data});
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error processing socket message: $e');
        print('Stack trace: $stackTrace');
      }
      _errorController.add('Message processing error: $e');
    }
  }

  void _handleDirectMessage(String event, dynamic data) {
    try {
      if (kDebugMode) {
        print('📨 Direct event: $event, Data: $data');
      }

      final messageData = {'type': event, 'data': data};

      switch (event) {
        case 'new_message':
          _messageController.add(messageData);
          break;
        case 'new_quick_message':
          _quickChatController.add(messageData);
          break;
        case 'conversation_history':
          _conversationHistoryController.add(messageData);
          break;
        case 'conversations_list':
          _processConversationsList(data);
          break;
        case 'typing':
          _typingController.add(messageData);
          break;
        case 'stop_typing':
          _typingController.add(messageData);
          break;
        case 'message_delivered':
          _deliveryController.add(messageData);
          break;
        case 'message_read':
          _deliveryController.add(messageData);
          break;
        default:
          _messageController.add(messageData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing direct message: $e');
      }
    }
  }

  void _processConversationsList(dynamic data) {
    try {
      List<dynamic> conversations = [];

      if (data is Map<String, dynamic>) {
        conversations = data['conversations'] ?? [];
      } else if (data is List) {
        conversations = data;
      }

      _allConversationsController.add(conversations);

      if (kDebugMode) {
        print('✅ Loaded ${conversations.length} conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing conversations list: $e');
      }
    }
  }

  // Helper method to ensure socket is ready
  Future<void> _ensureConnection() async {
    if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
      await _initializationCompleter!.future;
    }

    if (!isConnected.value) {
      throw Exception('Socket not connected');
    }
  }

  // Join conversation
  Future<void> joinConversation({String? requestId, String? bundleId, String? customerId}) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{};

      // Priority: If requestId exists, use ONLY requestId
      // Otherwise, use bundleId and customerId together
      if (requestId != null && requestId.isNotEmpty) {
        data['requestId'] = requestId;
        if (kDebugMode) {
          print('🤝 Joining conversation by requestId: $requestId');
        }
      } else if ((bundleId != null && bundleId.isNotEmpty) ||
          (customerId != null && customerId.isNotEmpty)) {
        if (bundleId != null && bundleId.isNotEmpty) data['bundleId'] = bundleId;
        if (customerId != null && customerId.isNotEmpty) data['customerId'] = customerId;
        if (kDebugMode) {
          print('🤝 Joining conversation by bundleId: $bundleId, customerId: $customerId');
        }
      } else {
        throw Exception('At least one identifier is required (requestId OR bundleId+customerId)');
      }

      _socket!.emit('message', {
        'type': 'join_conversation',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('🤝 Joining conversation: ${jsonEncode(data)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error joining conversation: $e');
      }
      rethrow;
    }
  }

  // Get conversation history
  Future<void> getConversation({String? requestId, String? bundleId, String? customerId}) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{};

      // Priority: If requestId exists, use ONLY requestId
      // Otherwise, use bundleId and customerId together
      if (requestId != null && requestId.isNotEmpty) {
        data['requestId'] = requestId;
        if (kDebugMode) {
          print('📥 Getting conversation by requestId: $requestId');
        }
      } else if ((bundleId != null && bundleId.isNotEmpty) ||
          (customerId != null && customerId.isNotEmpty)) {
        if (bundleId != null && bundleId.isNotEmpty) data['bundleId'] = bundleId;
        if (customerId != null && customerId.isNotEmpty) data['customerId'] = customerId;
        if (kDebugMode) {
          print('📥 Getting conversation by bundleId: $bundleId, customerId: $customerId');
        }
      } else {
        throw Exception('At least one identifier is required (requestId OR bundleId+customerId)');
      }

      _socket!.emit('message', {
        'type': 'get_conversation',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('📥 Requesting conversation: ${jsonEncode(data)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversation: $e');
      }
      rethrow;
    }
  }

  // Send quick chat
  Future<void> sendQuickChat({
    required String quickChatId,
    String? requestId,
    String? bundleId,
    String? customerId,
  }) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{
        'quickChatId': quickChatId,
      };

      // Priority: If requestId exists, use ONLY requestId
      // Otherwise, use bundleId and customerId together
      if (requestId != null && requestId.isNotEmpty) {
        data['requestId'] = requestId;
        if (kDebugMode) {
          print('💬 Sending quick chat to requestId: $requestId');
        }
      } else {
        if (bundleId != null && bundleId.isNotEmpty) data['bundleId'] = bundleId;
        if (customerId != null && customerId.isNotEmpty) data['customerId'] = customerId;
        if (kDebugMode) {
          print('💬 Sending quick chat to bundleId: $bundleId, customerId: $customerId');
        }
      }

      _socket!.emit('message', {
        'type': 'send_quick_chat',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('💬 Sending quick chat: ${jsonEncode(data)}');
      }

      // Wait a bit for server to process and emit the message back
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending quick chat: $e');
      }
      rethrow;
    }
  }

  // Send message
  Future<void> sendMessage({
    required String content,
    String? requestId,
    String? bundleId,
    String? customerId,
    String? messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{
        'content': content,
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      // Priority: If requestId exists, use ONLY requestId
      // Otherwise, use bundleId and customerId together
      if (requestId != null && requestId.isNotEmpty) {
        data['requestId'] = requestId;
        if (kDebugMode) {
          print('📤 Sending message to requestId: $requestId');
        }
      } else {
        if (bundleId != null && bundleId.isNotEmpty) data['bundleId'] = bundleId;
        if (customerId != null && customerId.isNotEmpty) data['customerId'] = customerId;
        if (kDebugMode) {
          print('📤 Sending message to bundleId: $bundleId, customerId: $customerId');
        }
      }

      _socket!.emit('message', {
        'type': 'send_message',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('📤 Sending message: ${jsonEncode(data)}');
      }

      // Wait a bit for server to process and emit the message back
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      rethrow;
    }
  }

  // Get all conversations
  Future<void> getAllConversations() async {
    try {
      await _ensureConnection();

      _socket!.emit('message', {
        'type': 'get_customer_conversations',
        'data': {},
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('📋 Requesting all conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversations: $e');
      }
      rethrow;
    }
  }

  // Typing indicators
  Future<void> startTyping({
    String? requestId,
    String? bundleId,
    String? customerId,
  }) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{};
      if (requestId != null && requestId.isNotEmpty) data['requestId'] = requestId;
      if (bundleId != null && bundleId.isNotEmpty) data['bundleId'] = bundleId;
      if (customerId != null && customerId.isNotEmpty) data['customerId'] = customerId;

      _socket!.emit('message', {
        'type': 'typing',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending typing indicator: $e');
      }
    }
  }

  Future<void> stopTyping({
    String? requestId,
    String? bundleId,
    String? customerId,
  }) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{};
      if (requestId != null && requestId.isNotEmpty) data['requestId'] = requestId;
      if (bundleId != null && bundleId.isNotEmpty) data['bundleId'] = bundleId;
      if (customerId != null && customerId.isNotEmpty) data['customerId'] = customerId;

      _socket!.emit('message', {
        'type': 'stop_typing',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping typing indicator: $e');
      }
    }
  }

  // Mark message as read
  Future<void> markAsRead(String messageId, {String? conversationId}) async {
    try {
      await _ensureConnection();

      final data = <String, dynamic>{
        'messageId': messageId,
        if (conversationId != null) 'conversationId': conversationId,
      };

      _socket!.emit('message', {
        'type': 'mark_read',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking message as read: $e');
      }
    }
  }

  // Disconnect socket
  Future<void> disconnect() async {
    try {
      if (isConnected.value && _socket != null) {
        _socket!.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      isConnected.value = false;
      socketId.value = '';
      connectionStatus.value = 'disconnected';
      _isInitialized = false;

      if (kDebugMode) {
        print('🔌 Socket disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting socket: $e');
      }
    }
  }

  // Reconnect socket
  Future<void> reconnect() async {
    try {
      if (isConnected.value) {
        if (kDebugMode) {
          print('⚠️ Socket already connected');
        }
        return;
      }

      connectionStatus.value = 'reconnecting';

      if (kDebugMode) {
        print('🔄 Reconnecting socket...');
      }

      await disconnect();
      await initializeSocket();

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reconnecting socket: $e');
      }
      _errorController.add('Reconnection failed: $e');
    }
  }

  // Clean up
  @override
  void onClose() {
    disconnect();

    // Close all stream controllers
    _connectionController.close();
    _messageController.close();
    _quickChatController.close();
    _conversationHistoryController.close();
    _allConversationsController.close();
    _typingController.close();
    _deliveryController.close();
    _errorController.close();

    super.onClose();
  }
}