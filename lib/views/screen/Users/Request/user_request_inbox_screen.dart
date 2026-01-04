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
import 'package:naibrly/widgets/naibrly_now_bottom_sheetold.dart';
import 'package:naibrly/views/screen/Users/Request/review_confirm_screen.dart';
import 'package:naibrly/utils/tokenService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:naibrly/utils/app_contants.dart';
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
  final QuickChatController _quickChatController = Get.find<
      QuickChatController>();
  final SocketController _socketController = Get.find<SocketController>();
  final TokenService _tokenService = TokenService();

  bool _isWaitingForAcceptance = false;
  bool _showFeedback = false;
  bool _isCancelled = false;
  String? _cancellationReason;
  DateTime? _cancellationTime;

  bool _showCompletionRequest = false;
  int _timerCountdown = 10;
  Timer? _timer;

  bool _showTaskCompletionOverlay = false;
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;

  String? _userRole;
  bool _hasMoneyRequest = false;
  bool _isCheckingMoneyRequest = true;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _specificMessageSubscription;
  List<ChatMessage> _messages = [];
  bool _isLoadingChatHistory = true;
  bool _isLoadingQuickMessages = false;
  List<QuickMessage> _quickMessages = [];

  // Money request details
  Map<String, dynamic>? _moneyRequestDetails;
  bool _isLoadingMoneyDetails = false;

  @override
  void initState() {
    super.initState();

    _userRole = _tokenService.getUserRole();
    if (kDebugMode) {
      print('👤 User role: $_userRole');
    }

    _isCancelled = widget.request.status.toLowerCase() == 'cancelled';
    if (_isCancelled) {
      _cancellationReason = widget.request.cancellationReason ??
          'The service was no longer required due to unforeseen circumstances.';
      _cancellationTime = widget.request.cancellationTime ?? DateTime.now();
    }

    if (widget.request.status.toLowerCase() == 'completed' ||
        widget.request.status.toLowerCase() == 'done') {
      _showFeedback = true;
    }

    // FIXED: Only start completion timer if status is 'accepted' AND user is customer
    if (widget.request.status.toLowerCase() == 'completed' &&
        _userRole?.toLowerCase() == 'customer') {
      _startCompletionTimer();
    }

    // Initialize in the right order
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadQuickMessages(); // Load quick messages first
      await _initializeSocketConnection(); // Then initialize socket
    });

    _checkMoneyRequests().then((_) {
      // Load money request details if exists
      if (_hasMoneyRequest) {
        _loadMoneyRequestDetails();
      }
    });
  }

  // Add this new method for customer checking with serviceRequestId
  Future<bool> _checkMoneyRequestByServiceRequestIdForCustomer() async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ No authentication token found');
        }
        return false;
      }

      final url = Uri.parse('${AppConstants
          .BASE_URL}/api/money-requests/customer?serviceRequestId=${widget
          .requestId}');

      if (kDebugMode) {
        print('🔍 Customer ServiceRequestId API URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('🔍 Response status: ${response.statusCode}');
        print('🔍 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Found ${moneyRequests
                  .length} money request(s) for serviceRequestId (customer)');

              // Log payment status if available
              for (var request in moneyRequests) {
                final status = request['status'] ?? 'unknown';
                final amount = request['amount'] ?? 0;
                final providerAmount = request['commission']?['providerAmount'] ??
                    0;
                final paymentMethod = request['paymentDetails']?['paymentMethod'] ??
                    'N/A';
                final paidAt = request['paymentDetails']?['paidAt'] ??
                    'Not paid';

                print('💰 Money Request Status: $status');
                print('💰 Amount: \$$amount');
                print('💰 Provider Amount: \$$providerAmount');
                print('💰 Payment Method: $paymentMethod');
                print('💰 Paid At: $paidAt');
              }
            }
            return true;
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print(
              'ℹ️ No money request found for this serviceRequestId (customer)');
        }
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ Error checking money request by serviceRequestId for customer: $e');
      }
      return false;
    }
  }

  // Add this method to load money request details
  // Add this method to load money request details
  Future<void> _loadMoneyRequestDetails() async {
    try {
      if (widget.requestId == null) return;

      setState(() {
        _isLoadingMoneyDetails = true;
      });

      final token = _tokenService.getToken();
      if (token == null) return;

      final url = Uri.parse('${AppConstants.BASE_URL}/api/money-requests/customer?serviceRequestId=${widget.requestId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            final moneyRequest = moneyRequests[0];

            // Parse and format the data properly
            final formattedRequest = {
              '_id': moneyRequest['_id']?.toString(),
              'amount': moneyRequest['amount'] is int ? moneyRequest['amount'] : (moneyRequest['amount'] is num ? (moneyRequest['amount'] as num).toInt() : 0),
              'status': moneyRequest['status']?.toString() ?? 'pending',
              'totalAmount': moneyRequest['totalAmount'] is int ? moneyRequest['totalAmount'] : (moneyRequest['totalAmount'] is num ? (moneyRequest['totalAmount'] as num).toInt() : 0),
              'tipAmount': moneyRequest['tipAmount'] is int ? moneyRequest['tipAmount'] : (moneyRequest['tipAmount'] is num ? (moneyRequest['tipAmount'] as num).toInt() : 0),
              'description': moneyRequest['description']?.toString() ?? 'Payment for service',
              'createdAt': moneyRequest['createdAt']?.toString(),
              'dueDate': moneyRequest['dueDate']?.toString(),
              'commission': moneyRequest['commission'] is Map ? Map<String, dynamic>.from(moneyRequest['commission']) : null,
              'paymentDetails': moneyRequest['paymentDetails'] is Map ? Map<String, dynamic>.from(moneyRequest['paymentDetails']) : null,
              'statusHistory': moneyRequest['statusHistory'] is List ? List<Map<String, dynamic>>.from(moneyRequest['statusHistory']) : [],
              'provider': moneyRequest['provider'] is Map ? Map<String, dynamic>.from(moneyRequest['provider']) : null,
            };

            setState(() {
              _moneyRequestDetails = formattedRequest;
              _hasMoneyRequest = true;
              // Show completion request if there's a money request
              _showCompletionRequest = true;
            });

            if (kDebugMode) {
              print('💰 Loaded money request details: $_moneyRequestDetails');
              print('💰 Payment status: ${_moneyRequestDetails?['status']}');
              print('💰 Is paid: ${(_moneyRequestDetails?['status']?.toString() ?? '').toLowerCase() == 'paid'}');
            }
          } else {
            setState(() {
              _moneyRequestDetails = null;
              _hasMoneyRequest = false;
              _showCompletionRequest = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        // No money request found
        setState(() {
          _moneyRequestDetails = null;
          _hasMoneyRequest = false;
          _showCompletionRequest = false;
        });

        if (kDebugMode) {
          print('ℹ️ No money request found for this service request');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading money request details: $e');
      }
      setState(() {
        _moneyRequestDetails = null;
        _hasMoneyRequest = false;
        _showCompletionRequest = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoneyDetails = false;
        });
      }
    }
  }

  // Update the _checkMoneyRequests method
  Future<void> _checkMoneyRequests() async {
    try {
      setState(() {
        _isCheckingMoneyRequest = true;
      });

      if (kDebugMode) {
        print('💰 Checking for existing money requests...');
        print('Request ID: ${widget.requestId}');
        print('Bundle ID: ${widget.bundleId}');
        print('Customer ID: ${widget.customerId}');
      }

      bool hasRequest = false;
      final isProvider = _userRole?.toLowerCase() == 'provider';
      final isCustomer = _userRole?.toLowerCase() == 'customer';

      if (isProvider) {
        // Provider checking logic
        if (widget.bundleId != null && widget.customerId != null) {
          if (kDebugMode) {
            print('👷 Provider: Checking with bundle API (provider check)');
          }
          hasRequest = await _checkMoneyRequestByBundleIdForProvider();
        } else if (widget.requestId != null) {
          if (kDebugMode) {
            print('👷 Provider: Checking with serviceRequestId API');
          }
          hasRequest = await _checkMoneyRequestByServiceRequestId();
        }
      }
      else if (isCustomer) {
        // Customer checking logic - updated with new endpoint
        if (widget.bundleId != null && widget.customerId != null) {
          if (kDebugMode) {
            print('👤 Customer: Checking with bundle API');
          }
          hasRequest = await _checkMoneyRequestByBundleId();
        } else if (widget.requestId != null) {
          // Try both customer endpoints
          if (kDebugMode) {
            print(
                '👤 Customer: Checking with serviceRequestId API (new endpoint)');
          }

          // Try the new endpoint first
          hasRequest = await _checkMoneyRequestByServiceRequestIdForCustomer();

          // If not found, try the old endpoint
          if (!hasRequest) {
            if (kDebugMode) {
              print('👤 Customer: Checking with requestId API (fallback)');
            }
            hasRequest = await _checkMoneyRequestByRequestId();
          }
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No suitable API endpoint available for current parameters');
        }
        hasRequest = false;
      }

      setState(() {
        _hasMoneyRequest = hasRequest;
        _isCheckingMoneyRequest = false;
      });

      if (kDebugMode) {
        print('💰 Money request check result: $_hasMoneyRequest');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money requests: $e');
      }
      setState(() {
        _hasMoneyRequest = false;
        _isCheckingMoneyRequest = false;
      });
    }
  }

  Future<bool> _checkMoneyRequestByBundleIdForProvider() async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ No authentication token found');
        }
        return false;
      }

      // Note: For providers checking, you might need a different endpoint
      // If your API doesn't have a provider endpoint for bundles,
      // you can use the customer endpoint or requestId endpoint
      final url = Uri.parse('${AppConstants
          .BASE_URL}/api/money-requests/provider?bundleId=${widget
          .bundleId}&customerId=${widget.customerId}');

      if (kDebugMode) {
        print('🔍 Provider Bundle API URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('🔍 Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Found ${moneyRequests
                  .length} money request(s) for bundle (provider)');
            }
            return true;
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ No money request found for this bundle (provider)');
        }
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money request by bundleId for provider: $e');
      }
      return false;
    }
  }

  Future<bool> _checkMoneyRequestByServiceRequestId() async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ No authentication token found');
        }
        return false;
      }

      final url = Uri.parse('${AppConstants
          .BASE_URL}/api/money-requests/provider?serviceRequestId=${widget
          .requestId}');

      if (kDebugMode) {
        print('🔍 Provider API URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('🔍 Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Found ${moneyRequests
                  .length} money request(s) for serviceRequestId');
            }
            return true;
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ No money request found for this serviceRequestId');
        }
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money request by serviceRequestId: $e');
      }
      return false;
    }
  }

  Future<bool> _checkMoneyRequestByBundleId() async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ No authentication token found');
        }
        return false;
      }

      final url = Uri.parse('${AppConstants
          .BASE_URL}/api/money-requests/customer?bundleId=${widget
          .bundleId}&customerId=${widget.customerId}');

      if (kDebugMode) {
        print('🔍 Bundle API URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('🔍 Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Found ${moneyRequests
                  .length} money request(s) for bundle');
            }
            return true;
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ No money request found for this bundle');
        }
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money request by bundleId: $e');
      }
      return false;
    }
  }

  Future<bool> _checkMoneyRequestByRequestId() async {
    try {
      final token = _tokenService.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ No authentication token found');
        }
        return false;
      }

      final url = Uri.parse(
          '${AppConstants.BASE_URL}/api/money-requests/request/${widget
              .requestId}');

      if (kDebugMode) {
        print('🔍 Request ID API URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('🔍 Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final moneyRequests = responseData['data']?['moneyRequests'] ?? [];
          if (moneyRequests.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Found ${moneyRequests
                  .length} money request(s) for requestId');
            }
            return true;
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ No money request found for this requestId');
        }
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money request by requestId: $e');
      }
      return false;
    }
  }

  Future<void> _initializeSocketConnection() async {
    try {
      if (kDebugMode) {
        print('🔗 Initializing socket connection...');
        print('Request ID: ${widget.requestId}');
        print('Bundle ID: ${widget.bundleId}');
        print('Customer ID: ${widget.customerId}');
      }

      if (!_socketController.isConnected) {
        if (kDebugMode) {
          print('🔄 Socket not connected, reconnecting...');
        }
        await _socketController.reconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      await _socketController.joinConversation(
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      if (kDebugMode) {
        print('✅ Joined conversation successfully');
      }

      // Load existing messages immediately after joining
      _loadExistingMessages();

      // Setup message listener AFTER loading existing messages
      _setupMessageListener();

      setState(() {
        _isLoadingChatHistory = false;
      });

      if (kDebugMode) {
        print('✅ Socket connection initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing socket connection: $e');
      }

      setState(() {
        _isLoadingChatHistory = false;
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

  Future<void> _loadQuickMessages() async {
    try {
      setState(() {
        _isLoadingQuickMessages = true;
      });

      // Load quick messages from API via controller
      await _quickChatController.loadQuickMessages();

      // Get messages from controller (these come from API)
      final messagesFromApi = _quickChatController.quickMessages.toList();

      if (kDebugMode) {
        print('📋 Loaded ${messagesFromApi.length} quick messages from API');
      }

      setState(() {
        _quickMessages = messagesFromApi;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading quick messages: $e');
      }

      // If API fails, show empty list
      setState(() {
        _quickMessages = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load quick questions: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isLoadingQuickMessages = false;
      });
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
        print('📜 UI: Loading ${existingMessages
            .length} existing messages from controller');
        if (existingMessages.isNotEmpty) {
          print('📜 UI: Sample message content: ${existingMessages
              .first['content']}');
        }
      }

      if (existingMessages.isNotEmpty) {
        final newMessages = existingMessages
            .map((msg) => ChatMessage.fromSocketData(msg))
            .toList();

        // Sort messages by timestamp to ensure correct order
        newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        if (mounted) {
          setState(() {
            _messages = newMessages;
          });

          if (kDebugMode) {
            print('✅ UI: Updated UI with ${_messages.length} messages');
            if (_messages.isNotEmpty) {
              print('✅ UI: Latest message: ${_messages.last.text}');
              print('✅ UI: Latest timestamp: ${_messages.last.timestamp}');
            }
          }

          // Scroll to bottom after a short delay to ensure UI is updated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && _messages.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          });
        }
      } else if (_messages.isEmpty) {
        // Only show default messages if we truly have no messages
        if (mounted) {
          setState(() {
            _messages = [
              ChatMessage(
                text: "Your service request has been confirmed!",
                isFromUser: false,
                isFromProvider: true,
                timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
              ),
              ChatMessage(
                text: "Thank you for confirming your order! I'll begin work shortly.",
                isFromUser: true,
                isFromProvider: false,
                timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
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
    // Cancel any existing subscriptions
    _messagesSubscription?.cancel();
    _specificMessageSubscription?.cancel();

    // Listen for new messages from the general stream
    _messagesSubscription = _socketController.messagesChangeStream.listen((_) {
      if (kDebugMode) {
        print('📨 General stream update received');
      }

      // Always reload messages when stream emits
      if (mounted) {
        if (kDebugMode) {
          print('🔄 UI: Reloading messages due to stream update');
        }
        _loadExistingMessages();
      }
    });

    // Also listen for specific message events
    _specificMessageSubscription =
        _socketController.messageStream.listen((message) {
          if (kDebugMode) {
            print('📨 Specific message received: ${message['content']}');
          }

          // Check if this message belongs to our conversation
          final requestId = message['requestId'];
          final bundleId = message['bundleId'];
          final customerId = message['customerId'];

          bool belongsToThisConversation = false;

          if (widget.requestId != null && requestId == widget.requestId) {
            belongsToThisConversation = true;
          } else if (widget.bundleId != null && bundleId == widget.bundleId) {
            belongsToThisConversation = true;
          } else
          if (widget.customerId != null && customerId == widget.customerId) {
            belongsToThisConversation = true;
          }

          if (belongsToThisConversation && mounted) {
            if (kDebugMode) {
              print('✅ Message belongs to this conversation, reloading...');
            }
            _loadExistingMessages();
          }
        });

    if (kDebugMode) {
      print('✅ Message listeners set up');
    }
  }

  void _sendQuickMessage(QuickMessage message) async {
    try {
      if (kDebugMode) {
        print('📤 UI: Sending quick message: ${message.message}');
        print('👤 User role: $_userRole');
      }

      // Get user role from token service
      final isProvider = _userRole?.toLowerCase() == 'provider';
      final isCustomer = _userRole?.toLowerCase() == 'customer';

      // Validate user role
      if (!isProvider && !isCustomer) {
        throw Exception('User role not recognized');
      }

      // Add a temporary message to show immediate feedback
      final tempMessage = ChatMessage(
        text: message.message,
        isFromUser: isCustomer,
        isFromProvider: isProvider,
        timestamp: DateTime.now(),
        isQuickChat: true,
        isPending: true,
      );

      setState(() {
        _messages.add(tempMessage);
      });

      // Scroll to show the new message
      _scrollToBottom();

      // Use the correct sender role based on user type
      await _socketController.sendQuickChat(
        quickChatId: message.id ?? '',
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      // Update controller with usage count
      _quickChatController.sendQuickMessage(message);

      if (kDebugMode) {
        print('✅ UI: Quick message sent by ${isProvider
            ? 'provider'
            : 'customer'}');
      }

      // Remove the pending status after sending
      setState(() {
        final index = _messages.indexWhere((msg) =>
        msg.isPending && msg.text == message.message);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isPending: false);
        }
      });

      // Wait a bit and reload all messages to ensure sync with server
      await Future.delayed(const Duration(milliseconds: 500));
      _loadExistingMessages();
    } catch (e) {
      if (kDebugMode) {
        print('❌ UI: Error sending quick message: $e');
      }

      // Remove the pending message if there was an error
      setState(() {
        _messages.removeWhere((msg) =>
        msg.isPending && msg.text == message.message);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startFeedbackTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isWaitingForAcceptance = false;
          _showFeedback = true;
        });
      }
    });
  }

  void _navigateToQuickChatPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            QuickChatPage(
              requestId: widget.requestId,
              bundleId: widget.bundleId,
              customerId: widget.customerId,
              serviceName: widget.request.serviceName,
              providerName: widget.request.provider?.fullName ??
                  widget.request.providerName ?? 'Provider',
            ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startCompletionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timerCountdown--;
        });

        if (_timerCountdown <= 0) {
          timer.cancel();
          setState(() {
            _showCompletionRequest = true;
          });
        }
      }
    });
  }

  void _handleAcceptCompletion() {
    // Navigate to review and confirm screen
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => ReviewConfirmScreen(request: widget.request),
    ///  ),
    // );
  }

  void _handleCancelCompletion() {
    setState(() {
      _showCompletionRequest = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task completion cancelled.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showTaskCompletionOverlayDialog() {
    final isProvider = _userRole?.toLowerCase() == 'provider';
    final isCustomer = _userRole?.toLowerCase() == 'customer';

    // Only providers should create money requests
    if (!isProvider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only providers can create money requests.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasMoneyRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Money request already created for this task.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _showTaskCompletionOverlay = true;
    });
  }

  void _hideTaskCompletionOverlay() {
    setState(() {
      _showTaskCompletionOverlay = false;
      _amountController.clear();
      _isSubmitting = false;
    });
  }

  Future<void> _createMoneyRequest(double amount) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final isProvider = _userRole?.toLowerCase() == 'provider';
      final isCustomer = _userRole?.toLowerCase() == 'customer';

      if (!isProvider) {
        throw Exception('Only providers can create money requests');
      }

      // Determine which API endpoint to use based on available parameters
      String apiUrl;
      Map<String, dynamic> requestBody;

      if (widget.bundleId != null && widget.customerId != null) {
        // Use bundle API endpoint for providers
        apiUrl = '${AppConstants.BASE_URL}/api/money-requests/create';
        requestBody = {
          'amount': amount,
          'bundleId': widget.bundleId,
          'customerId': widget.customerId
        };

        if (kDebugMode) {
          print('💰 Using BUNDLE API for provider money request');
          print('Bundle ID: ${widget.bundleId}');
          print('Customer ID: ${widget.customerId}');
        }
      } else if (widget.requestId != null) {
        // Use serviceRequestId API endpoint
        apiUrl = '${AppConstants.BASE_URL}/api/money-requests/create';
        requestBody = {
          'serviceRequestId': widget.requestId,
          'amount': amount,
        };

        if (kDebugMode) {
          print('💰 Using SERVICE REQUEST ID API for provider money request');
          print('Service Request ID: ${widget.requestId}');
        }
      } else {
        throw Exception(
            'No valid parameters available for creating money request');
      }

      final url = Uri.parse(apiUrl);

      if (kDebugMode) {
        print('💰 Provider creating money request...');
        print('URL: $url');
        print('Request Body: $requestBody');
        print('Amount: $amount');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('💰 API Response Status: ${response.statusCode}');
        print('💰 API Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          setState(() {
            _hasMoneyRequest = true;
          });

          _hideTaskCompletionOverlay();

          // Show success message with amount
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Money request created successfully! Amount: \$${amount
                      .toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          if (kDebugMode) {
            print('✅ Money request created successfully');
            print('Response: $responseData');
          }

          // Optionally, refresh the money request check
          await _checkMoneyRequests();
          await _loadMoneyRequestDetails();
        } else {
          final errorMessage = responseData['message'] ??
              'Failed to create money request';
          throw Exception(errorMessage);
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ??
            'Failed to create money request (Status: ${response.statusCode})';

        if (kDebugMode) {
          print('❌ Money request creation failed: $errorMessage');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception creating money request: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create money request: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleTaskDone() {
    final isProvider = _userRole?.toLowerCase() == 'provider';

    if (!isProvider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only providers can create money requests.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasMoneyRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Money request already created for this task.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate amount is reasonable (optional)
    if (widget.request.averagePrice > 0 &&
        amount > widget.request.averagePrice * 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount (\$$amount) seems high. Average price is \$${widget
                  .request.averagePrice.toInt()}.'),
          backgroundColor: Colors.orange,
        ),
      );
      // Continue anyway - just warning
    }

    _createMoneyRequest(amount);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _specificMessageSubscription?.cancel();
    _timer?.cancel();
    _amountController.dispose();

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
    final providerName = widget.request.provider?.fullName ??
        widget.request.providerName ?? 'Provider';

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
    final providerName = widget.request.provider?.fullName ??
        widget.request.providerName ?? 'Provider';
    final providerImage = widget.request.providerImage ??
        widget.request.provider?.businessLogo?.url ??
        widget.request.imagePath ?? 'assets/images/default_avatar.png';
    final providerRating = widget.request.providerRating ??
        widget.request.provider?.rating ?? 0.0;
    final providerReviewCount = widget.request.providerReviewCount ?? 0;
    final isCompleted = widget.request.status.toLowerCase() == 'completed' ||
        widget.request.status.toLowerCase() == 'done';
    final isAccepted = widget.request.status.toLowerCase() == 'accepted';

    final isProvider = _userRole?.toLowerCase() == 'provider';
    final isCustomer = _userRole?.toLowerCase() == 'customer';

    // Disable Task Done button if money request exists or still checking
    final disableTaskDone = _hasMoneyRequest || _isCheckingMoneyRequest;

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
          if (isProvider && !_isCancelled && !_isWaitingForAcceptance) ...[
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: (_isWaitingForAcceptance || _showFeedback ||
                    _isCancelled || disableTaskDone) ? null : () {
                  if (isCompleted) {
                    _showTaskCompletionOverlayDialog();
                  } else {
                    _showCancelRequestDialog();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: (_isWaitingForAcceptance || _showFeedback ||
                      _isCancelled || disableTaskDone)
                      ? Colors.grey[300]
                      : const Color(0xFFFEEEEE),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCheckingMoneyRequest
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
                    : AppText(
                  _isCancelled ? 'Cancelled' : (isCompleted ? (_hasMoneyRequest
                      ? 'Paid'
                      : 'Task Done') : 'Cancel'),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (_isWaitingForAcceptance || _showFeedback ||
                      _isCancelled || disableTaskDone)
                      ? Colors.grey[600]
                      : const Color(0xFFF34F4F),
                ),
              ),
            ),
          ] else
            if (isCustomer && !_isCancelled && !_isWaitingForAcceptance) ...[
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: TextButton(
                  onPressed: (_isWaitingForAcceptance || _showFeedback ||
                      _isCancelled) ? null : () {
                    _showCancelRequestDialog();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: (_isWaitingForAcceptance ||
                        _showFeedback || _isCancelled)
                        ? Colors.grey[300]
                        : const Color(0xFFFEEEEE),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: AppText(
                    _isCancelled ? 'Cancelled' : 'Cancel',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (_isWaitingForAcceptance || _showFeedback ||
                        _isCancelled)
                        ? Colors.grey[600]
                        : const Color(0xFFF34F4F),
                  ),
                ),
              ),
            ],
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.bundleId != null || widget.requestId != null ||
                      widget.customerId != null)
                    _buildIdSection(),

                  _buildRequestDetailsCard(),

                  // Show loading state for chat messages
                  if (_isLoadingChatHistory)
                    _buildChatLoadingState()
                  else
                    if (_showFeedback)
                      Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: _buildChatMessages(),
                          ),
                          _buildFeedbackMessage(),
                        ],
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: _buildChatMessages(),
                      ),

                  if (_isWaitingForAcceptance)
                    _buildWaitingMessage(providerName),

                  if (_isCancelled) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: AppText(
                        _cancellationReason ??
                            'The service was no longer required due to unforeseen circumstances.',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.DarkGray,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppText(
                        'Cancellation reason provided by you.',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.DarkGray,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: AppText(
                        _cancellationTime != null
                            ? '${_cancellationTime!.hour}:${_cancellationTime!
                            .minute.toString().padLeft(2, '0')} PM'
                            : '1:44 PM',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.DarkGray,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // FIXED: Show quick replies for both providers and customers
                  // Only hide quick messages when feedback is showing
                  if (!_showFeedback && !_isLoadingChatHistory)
                    _buildQuickReplies(),

                  if (isCompleted && !_showCompletionRequest &&
                      _timerCountdown > 0 && isCustomer)
                    _buildCountdownCard(),

                  // FIXED: Show completion request only for customers
                  if (_showCompletionRequest && isCustomer)
                    _buildCompletionRequestCard(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          if (_showTaskCompletionOverlay)
            _buildTaskCompletionOverlay(),
        ],
      ),
      floatingActionButton: _isWaitingForAcceptance || _showFeedback ||
          _isCancelled || _isLoadingChatHistory || _showTaskCompletionOverlay
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
          child: const Center(
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

  Widget _buildChatLoadingState() {
    return Container(
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
    );
  }

  Widget _buildTaskCompletionOverlay() {
    final isProvider = _userRole?.toLowerCase() == 'provider';

    return GestureDetector(
      onTap: _hideTaskCompletionOverlay,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    isProvider ? 'Request Payment' : 'Task Completed',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.Black,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  if (widget.bundleId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                              Icons.inventory, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          AppText(
                            'Using Bundle ID',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  AppText(
                    isProvider
                        ? 'Enter the payment amount for your service'
                        : 'Your Budget avg. \$${widget.request.averagePrice
                        .toInt()}/hr',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.DarkGray,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Payment Amount*',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.Black,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixText: '\$',
                          prefixStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.request.averagePrice > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14,
                                color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AppText(
                                'Average price for this service: \$${widget
                                    .request.averagePrice.toInt()}/hr',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleTaskDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSubmitting ? Colors.grey : AppColors
                            .primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.request_quote, size: 20,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          AppText(
                            isProvider ? 'Create Payment Request' : 'Done',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : _hideTaskCompletionOverlay,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        AppText(
                          'Cancel',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.DarkGray,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final providerName = widget.request.provider?.fullName ??
        widget.request.providerName ?? 'Provider';
    final providerImage = widget.request.providerImage ??
        widget.request.provider?.businessLogo?.url ??
        widget.request.imagePath ?? 'assets/images/default_avatar.png';
    final providerRating = widget.request.providerRating ??
        widget.request.provider?.rating ?? 0.0;
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
                'Date: ${widget.request.formattedDate} Time: ${widget.request
                    .time}',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.DarkGray,
              ),
            ],
          ),
          if (widget.request.problemDescription != null &&
              widget.request.problemDescription!.isNotEmpty) ...[
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
    final isFromCurrentUser = (message.isFromUser &&
        _userRole?.toLowerCase() == 'customer') ||
        (message.isFromProvider && _userRole?.toLowerCase() == 'provider');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
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
                color: isFromCurrentUser
                    ? AppColors.primary.withOpacity(
                    message.isPending ? 0.6 : 1.0)
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
                    color: isFromCurrentUser ? Colors.white : AppColors.Black,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        _formatTime(message.timestamp),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: isFromCurrentUser ? Colors.white70 : AppColors
                            .DarkGray,
                      ),
                      if (message.isPending) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFromCurrentUser ? Colors.white70 : AppColors
                                  .DarkGray,
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
          if (isFromCurrentUser) ...[
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
    if (_isLoadingQuickMessages) {
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppText(
                    'Loading quick questions...',
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

    if (_quickMessages.isEmpty) {
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
                  Icon(Icons.message_outlined, color: Colors.grey[600],
                      size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      'No quick questions available at the moment.',
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
              // Add refresh button for quick messages
              IconButton(
                icon: Icon(Icons.refresh, size: 16, color: AppColors.primary),
                onPressed: _loadQuickMessages,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _quickMessages.length,
              itemBuilder: (context, index) {
                final message = _quickMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => _sendQuickMessage(message),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7D6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1C400),
                            width: 1),
                      ),
                      child: AppText(
                        message.message,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8B4513),
                        maxLines: 2,
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
              image: const DecorationImage(
                image: AssetImage('assets/images/clientFeedback.png'),
                fit: BoxFit.cover,
              ),
            ),
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
            'Thank you for your order! It was a pleasure working on your request. I hope the service met your expectations. Please feel free to reach out if you need anything else!',
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
                  (index) =>
              const Icon(
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Handle report provider
            },
            child: AppText(
              'Report Provider',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          AppText(
            'Task completion request will appear in',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.DarkGray,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText(
            '$_timerCountdown seconds',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0E7A60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRequestCard() {
    final isCustomer = _userRole?.toLowerCase() == 'customer';

    // Only show this card for customers
    if (!isCustomer) {
      return const SizedBox.shrink();
    }

    final providerName = widget.request.provider?.fullName ?? widget.request.providerName ?? 'Provider';
    final providerImage = widget.request.providerImage ?? widget.request.provider?.businessLogo?.url ?? widget.request.imagePath ?? 'assets/images/default_avatar.png';
    final providerRating = widget.request.providerRating ?? widget.request.provider?.rating ?? 0.0;
    final providerReviewCount = widget.request.providerReviewCount ?? 0;

    // Extract payment information from money request details - FIXED NULL SAFETY ISSUES
    final moneyRequest = _moneyRequestDetails;
    final hasPaymentRequest = moneyRequest != null;

    // Use safe navigation with null coalescing
    final paymentStatus = hasPaymentRequest ? (moneyRequest['status'] as String? ?? 'pending') : 'pending';
    final amount = hasPaymentRequest ? (moneyRequest['amount'] as int? ?? widget.request.averagePrice.toInt()) : widget.request.averagePrice.toInt();

    // Determine if payment is completed
    final isPaid = paymentStatus.toLowerCase() == 'paid' ||
        paymentStatus.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0500CD49), // 2% #00CD4905
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x4D00CD49), // 30% #00CD494D
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Amount
          Row(
            children: [
              AppText(
                'Request Amount:',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
              const SizedBox(width: 6),
              AppText(
                '\$$amount/${isPaid ? 'consult' : 'payment'}',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0E7A60),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Service details
          AppText(
            '${widget.request.serviceName}: \$${widget.request.averagePrice.toInt()}/hr',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.Black,
          ),

          const SizedBox(height: 8),

          // Provider info
          Row(
            children: [
              // Provider image
              CircleAvatar(
                radius: 12,
                backgroundImage: providerImage.startsWith('http')
                    ? NetworkImage(providerImage)
                    : AssetImage(providerImage) as ImageProvider,
                backgroundColor: Colors.grey.shade300,
                child: providerImage.startsWith('http')
                    ? null
                    : const Icon(Icons.person, size: 12),
              ),
              const SizedBox(width: 8),
              // Provider name and review in a row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    providerName,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.Black,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      AppText(
                        '$providerRating ($providerReviewCount reviews)',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.DarkGray,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Description - Updated based on payment status
          AppText(
            isPaid
                ? 'Thank you for completing the payment! $providerName has been notified.'
                : 'Payment request from $providerName. Please complete the payment to finish the task.',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.DarkGray,
          ),

          const SizedBox(height: 12),

          // Action buttons - Updated based on payment status
          if (!isPaid) ...[
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancelCompletion,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: AppText(
                      'Cancel',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Pay Now button (replaces Accept button)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAcceptPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7A60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: _isProcessingPayment
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : AppText(
                      'Pay Now',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // View Receipt button for paid requests
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _viewPaymentDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7A60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    AppText(
                      'View Receipt',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Time and status - Updated based on payment status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.DarkGray,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText(
                  isPaid ? 'Payment Completed' : 'Payment Pending',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.Black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Add this helper method to format dates
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day
        .toString().padLeft(2, '0')} ${date.hour.toString().padLeft(
        2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

// Add these methods to your class
  bool _isProcessingPayment = false;

  void _handleAcceptPayment() async {
    final moneyRequest = _moneyRequestDetails;
    if (moneyRequest == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Get money request ID
      final moneyRequestId = moneyRequest['_id']?.toString();
      if (moneyRequestId == null || moneyRequestId.isEmpty) {
        throw Exception('Invalid payment request ID');
      }

      // Get service request ID from the money request or widget
      final serviceRequestId = moneyRequest['serviceRequest']?['_id']?.toString() ??
          widget.request.id?.toString() ??
          '';

      // Navigate to ReviewConfirmScreen and wait for result
      final result = await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (context) => ReviewConfirmScreen(
            request: widget.request,
            moneyRequestId: moneyRequestId,
            serviceRequestId: serviceRequestId, // Pass serviceRequestId
            token: token,
          ),
        ),
      );

      // Handle the result from ReviewConfirmScreen
      if (result == true) {
        // Payment was successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Update local state
        setState(() {
          // Update payment status to paid
          if (_moneyRequestDetails != null) {
            _moneyRequestDetails = {
              ..._moneyRequestDetails!,
              'status': 'paid',
              'paymentDetails': {
                'paymentMethod': 'card',
                'paidAt': DateTime.now().toIso8601String(),
              }
            };
          }
        });

        // Reload money request details from server to get updated data
        await _loadMoneyRequestDetails();

        if (kDebugMode) {
          print('✅ Payment completed successfully from ReviewConfirmScreen');
        }
      } else if (result == false) {
        // User cancelled or payment failed
        if (kDebugMode) {
          print('💰 Payment cancelled or failed in ReviewConfirmScreen');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing payment: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _updatePaymentStatus(String status) async {
    try {
      final token = _tokenService.getToken();
      if (token == null || _moneyRequestDetails == null) return;

      final moneyRequestId = _moneyRequestDetails!['_id']?.toString();
      if (moneyRequestId == null) return;

      final url = Uri.parse(
          '${AppConstants.BASE_URL}/api/money-requests/$moneyRequestId/status');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Payment status updated to $status');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating payment status: $e');
      }
      rethrow;
    }
  }

  void _viewPaymentDetails() {
    if (_moneyRequestDetails == null) return;


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
    try {
      return ChatMessage(
        text: data['content']?.toString() ?? 'No content',
        isFromUser: data['senderRole']?.toString().toLowerCase() == 'customer',
        isFromProvider: data['senderRole']?.toString().toLowerCase() == 'provider',
        timestamp: data['timestamp'] != null
            ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        senderId: data['senderId']?.toString(),
        isQuickChat: data['isQuickChat'] == true || data['quickChatId'] != null,
        isPending: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating ChatMessage from socket data: $e');
      }
      return ChatMessage(
        text: 'Error loading message',
        isFromUser: false,
        isFromProvider: false,
        timestamp: DateTime.now(),
      );
    }
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