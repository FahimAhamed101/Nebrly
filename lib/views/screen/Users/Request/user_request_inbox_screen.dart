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
import '../../../../controller/payment_controller.dart';
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
  final PaymentController _paymentController = Get.find<PaymentController>();
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
  String? _userId;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _specificMessageSubscription;
  List<ChatMessage> _messages = [];
  bool _isLoadingChatHistory = true;
  bool _isLoadingQuickMessages = false;
  List<QuickMessage> _quickMessages = [];

  // Add this for tracking initialization state
  bool _isInitializing = false;

  // Track if we're currently processing payment
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();

    // Get user role and ID from token service
    _userRole = _tokenService.getUserRole();
    _userId = _tokenService.getUserId();

    if (kDebugMode) {
      print('👤 User role: $_userRole');
      print('👤 User ID: $_userId');
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

    // Only start completion timer if status is 'completed' AND user is customer
    if (widget.request.status.toLowerCase() == 'completed' &&
        _userRole?.toLowerCase() == 'customer') {
      _startCompletionTimer();
    }

    // Initialize everything in proper sequence
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      setState(() {
        _isInitializing = true;
      });

      // 1. Load quick messages first
      await _loadQuickMessages();

      // 2. Check money requests using GetX controller
      await _checkMoneyRequests();

      // 3. Initialize socket connection and load chat history
      await _initializeSocketConnection();

      // 4. Load money request details if exists
      if (_paymentController.hasMoneyRequest && widget.requestId != null) {
        await _paymentController.loadMoneyRequestDetails(
          serviceRequestId: widget.requestId!,
        );

        // Check if we should show completion request
        if (_paymentController.moneyRequestDetails != null) {
          setState(() {
            _showCompletionRequest = true;
          });
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing screen: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _checkMoneyRequests() async {
    try {
      await _paymentController.checkMoneyRequests(
        userRole: _userRole,
        bundleId: widget.bundleId,
        requestId: widget.requestId,
        customerId: widget.customerId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money requests: $e');
      }
    }
  }

  Future<void> _initializeSocketConnection() async {
    try {
      if (kDebugMode) {
        print('🔗 Initializing socket connection...');
        print('User Role: $_userRole');
        print('User ID: $_userId');
      }

      // Ensure socket is connected
      if (!_socketController.isConnected) {
        await _socketController.reconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      // Join the conversation
      await _socketController.joinConversation(
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      if (kDebugMode) {
        print('✅ Joined conversation successfully');
      }

      // Load existing messages immediately
      _loadExistingMessages();

      // Setup message listeners
      _setupMessageListener();

      setState(() {
        _isLoadingChatHistory = false;
      });

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing socket connection: $e');
      }

      setState(() {
        _isLoadingChatHistory = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to chat: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _loadQuickMessages() async {
    try {
      setState(() {
        _isLoadingQuickMessages = true;
      });

      await _quickChatController.loadQuickMessages();
      final messagesFromApi = _quickChatController.quickMessages.toList();

      setState(() {
        _quickMessages = messagesFromApi;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading quick messages: $e');
      }
      setState(() {
        _quickMessages = [];
      });
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
        print('📜 Loading ${existingMessages.length} existing messages');
      }

      if (existingMessages.isNotEmpty) {
        final newMessages = existingMessages
            .map((msg) => ChatMessage.fromSocketData(msg, _userId))
            .toList();

        // Sort by timestamp
        newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        if (mounted) {
          setState(() {
            _messages = newMessages;
          });

          // Scroll to bottom after UI update
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      } else {
        // Only show default messages if truly empty
        if (mounted && _messages.isEmpty) {
          setState(() {
            _messages = _getDefaultMessages();
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading existing messages: $e');
      }
    }
  }

  List<ChatMessage> _getDefaultMessages() {
    final isCustomer = _userRole?.toLowerCase() == 'customer';
    final isProvider = _userRole?.toLowerCase() == 'provider';

    if (isCustomer) {
      return [
        ChatMessage(
          text: "Your service request has been confirmed!",
          isFromUser: false,
          isFromProvider: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          senderId: 'system',
        ),
        ChatMessage(
          text: "Thank you for confirming your order! I'll begin work shortly.",
          isFromUser: true,
          isFromProvider: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          senderId: _userId,
        ),
      ];
    } else if (isProvider) {
      return [
        ChatMessage(
          text: "You have accepted the service request!",
          isFromUser: false,
          isFromProvider: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          senderId: 'system',
        ),
        ChatMessage(
          text: "Please contact the customer for details.",
          isFromUser: false,
          isFromProvider: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          senderId: 'system',
        ),
      ];
    }

    return [];
  }

  void _setupMessageListener() {
    // Cancel any existing subscriptions
    _messagesSubscription?.cancel();
    _specificMessageSubscription?.cancel();

    // Listen for general message stream updates
    _messagesSubscription = _socketController.messagesChangeStream.listen((_) {
      if (kDebugMode) {
        print('📨 General stream update received');
      }
      if (mounted) {
        _loadExistingMessages();
      }
    });

    // Listen for specific new messages
    _specificMessageSubscription = _socketController.messageStream.listen((message) {
      if (kDebugMode) {
        print('📨 Specific message received: ${message['content']}');
      }

      // Check if this message belongs to our conversation
      final belongsToConversation = _checkMessageBelongsToConversation(message);

      if (belongsToConversation && mounted) {
        if (kDebugMode) {
          print('✅ Message belongs to this conversation, updating...');
        }
        _loadExistingMessages();
      }
    });

    if (kDebugMode) {
      print('✅ Message listeners set up');
    }
  }

  bool _checkMessageBelongsToConversation(Map<String, dynamic> message) {
    final requestId = message['requestId']?.toString();
    final bundleId = message['bundleId']?.toString();
    final customerId = message['customerId']?.toString();

    if (widget.requestId != null && requestId == widget.requestId) {
      return true;
    }

    if (widget.bundleId != null && bundleId == widget.bundleId) {
      return true;
    }

    if (widget.customerId != null && customerId == widget.customerId) {
      return true;
    }

    return false;
  }

  void _sendQuickMessage(QuickMessage message) async {
    try {
      if (kDebugMode) {
        print('📤 Sending quick message: ${message.message}');
      }

      final isProvider = _userRole?.toLowerCase() == 'provider';
      final isCustomer = _userRole?.toLowerCase() == 'customer';

      if (!isProvider && !isCustomer) {
        throw Exception('User role not recognized');
      }

      // Add temporary message for immediate feedback
      final tempMessage = ChatMessage(
        text: message.message,
        isFromUser: isCustomer,
        isFromProvider: isProvider,
        timestamp: DateTime.now(),
        senderId: _userId,
        isQuickChat: true,
        isPending: true,
      );

      setState(() {
        _messages.add(tempMessage);
      });

      _scrollToBottom();

      // Send the quick chat message
      await _socketController.sendQuickChat(
        quickChatId: message.id ?? '',
        requestId: widget.requestId,
        bundleId: widget.bundleId,
        customerId: widget.customerId,
      );

      // Update controller with usage count
      _quickChatController.sendQuickMessage(message);

      // Remove pending status
      setState(() {
        final index = _messages.indexWhere((msg) =>
        msg.isPending && msg.text == message.message && msg.senderId == _userId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isPending: false);
        }
      });

      // Reload messages after a delay
      await Future.delayed(const Duration(milliseconds: 500));
      _loadExistingMessages();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending quick message: $e');
      }

      // Remove the pending message on error
      setState(() {
        _messages.removeWhere((msg) =>
        msg.isPending && msg.text == message.message && msg.senderId == _userId);
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
        builder: (context) => QuickChatPage(
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

  Future<void> _cancelServiceRequest() async {
    if (widget.requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid request ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _paymentController.cancelServiceRequest(requestId: widget.requestId!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling request: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelBundle() async {
    if (widget.bundleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid bundle ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _paymentController.cancelBundle(bundleId: widget.bundleId!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bundle cancelled successfully!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling bundle: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel bundle: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text('Cancel Request?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request.isBundle
                  ? 'Are you sure you want to cancel this bundle?'
                  : 'Are you sure you want to cancel this service request?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The ${widget.request.isBundle ? 'bundle' : 'request'} will be cancelled immediately.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.request.isBundle) {
                _cancelBundle();
              } else {
                _cancelServiceRequest();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
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

    if (!isProvider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only providers can create money requests.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_paymentController.hasMoneyRequest) {
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

      final isProvider = _userRole?.toLowerCase() == 'provider';
      if (!isProvider) {
        throw Exception('Only providers can create money requests');
      }

      await _paymentController.createMoneyRequest(
        amount: amount,
        bundleId: widget.bundleId,
        serviceRequestId: widget.requestId,
      );

      _hideTaskCompletionOverlay();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Money request created successfully! Amount: \$${amount.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh data
      await _checkMoneyRequests();
      if (widget.requestId != null) {
        await _paymentController.loadMoneyRequestDetails(
          serviceRequestId: widget.requestId!,
        );
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

    if (_paymentController.hasMoneyRequest) {
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
        content: Text('$label copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _completeServiceRequest() async {
    if (widget.requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid request ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _paymentController.completeServiceRequest(requestId: widget.requestId!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request marked as completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing request: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete request: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _completeBundle() async {
    if (widget.bundleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid bundle ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _paymentController.completeBundle(bundleId: widget.bundleId!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bundle marked as completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing bundle: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete bundle: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showCompleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Mark as Completed?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request.isBundle
                  ? 'Are you sure you want to mark this bundle as completed?'
                  : 'Are you sure you want to mark this service request as completed?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will mark the ${widget.request.isBundle ? 'bundle' : 'request'} as completed and notify the customer.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.request.isBundle) {
                _completeBundle();
              } else {
                _completeServiceRequest();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark as Completed'),
          ),
        ],
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
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Center(
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
        ),
      );
    }

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

    // Use GetX controller values
    final disableTaskDone = _paymentController.hasMoneyRequest ||
        _paymentController.isCheckingMoneyRequest;

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
          if (!_isCancelled && !_isWaitingForAcceptance) ...[
            // PROVIDER ROLE
            if (isProvider) ...[
              // Show "Accept" button for accepted requests (to mark as completed)
              if (isAccepted && !isCompleted) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: _paymentController.isCompletingRequest ? null : _showCompleteConfirmationDialog,
                    icon: _paymentController.isCompletingRequest
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.check_circle, size: 18),
                    label: Text(
                      _paymentController.isCompletingRequest ? 'Processing...' : 'Accept',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: _paymentController.isCompletingRequest
                          ? Colors.grey[400]
                          : Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // Show "Task Done" button for completed requests (to create money request)
              if (isCompleted) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: (_showFeedback || disableTaskDone) ? null : () {
                      _showTaskCompletionOverlayDialog();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: (_showFeedback || disableTaskDone)
                          ? Colors.grey[300]
                          : const Color(0xFFFEEEEE),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _paymentController.isCheckingMoneyRequest
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                        : AppText(
                      _paymentController.hasMoneyRequest ? 'Paid' : 'Task Done',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (_showFeedback || disableTaskDone)
                          ? Colors.grey[600]
                          : const Color(0xFFF34F4F),
                    ),
                  ),
                ),
              ],

              // Always show Cancel button for non-completed, non-cancelled requests
              if (!isCompleted) ...[
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _paymentController.isCompletingRequest ? null : _showCancelConfirmationDialog,
                    style: TextButton.styleFrom(
                      backgroundColor: _paymentController.isCompletingRequest
                          ? Colors.grey[300]
                          : const Color(0xFFFEEEEE),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AppText(
                      'Cancel',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _paymentController.isCompletingRequest
                          ? Colors.grey[600]
                          : const Color(0xFFF34F4F),
                    ),
                  ),
                ),
              ],
            ],

            // CUSTOMER ROLE
            if (isCustomer) ...[
              // Always show Cancel button for non-completed, non-cancelled requests
              if (!isCompleted) ...[
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _paymentController.isCompletingRequest ? null : _showCancelConfirmationDialog,
                    style: TextButton.styleFrom(
                      backgroundColor: _paymentController.isCompletingRequest
                          ? Colors.grey[300]
                          : const Color(0xFFFEEEEE),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AppText(
                      'Cancel',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _paymentController.isCompletingRequest
                          ? Colors.grey[600]
                          : const Color(0xFFF34F4F),
                    ),
                  ),
                ),
              ],
            ],
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
                  else if (_showFeedback)
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

                  if (!_showFeedback && !_isLoadingChatHistory)
                    _buildQuickReplies(),

                  if (isCompleted && !_showCompletionRequest &&
                      _timerCountdown > 0 && isCustomer)
                    _buildCountdownCard(),

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
              width: MediaQuery.of(context).size.width * 0.85,
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
                          const Icon(Icons.inventory, size: 16, color: Colors.orange),
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
                        : 'Your Budget avg. \$${widget.request.averagePrice.toInt()}/hr',
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
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                            const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AppText(
                                'Average price for this service: \$${widget.request.averagePrice.toInt()}/hr',
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
                        backgroundColor: _isSubmitting ? Colors.grey : AppColors.primary,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.request_quote, size: 20, color: Colors.white),
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
                    onPressed: _isSubmitting ? null : _hideTaskCompletionOverlay,
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
                'Date: ${widget.request.formattedDate} Time: ${widget.request.time}',
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
    final isCustomer = _userRole?.toLowerCase() == 'customer';
    final isProvider = _userRole?.toLowerCase() == 'provider';

    // Determine if message is from current user
    bool isFromCurrentUser = false;

    if (isCustomer) {
      // For customers: message is from current user if isFromUser is true
      isFromCurrentUser = message.isFromUser && message.senderId == _userId;
    } else if (isProvider) {
      // For providers: message is from current user if isFromProvider is true
      isFromCurrentUser = message.isFromProvider && message.senderId == _userId;
    }

    // If we can't determine by senderId, fall back to the flags
    if (message.senderId == null) {
      if (isCustomer) {
        isFromCurrentUser = message.isFromUser;
      } else if (isProvider) {
        isFromCurrentUser = message.isFromProvider;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
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
                        color: isFromCurrentUser ? Colors.white70 : AppColors.DarkGray,
                      ),
                      if (message.isPending) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFromCurrentUser ? Colors.white70 : AppColors.DarkGray,
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                  Icon(Icons.message_outlined, color: Colors.grey[600], size: 20),
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
              IconButton(
                icon: Icon(Icons.refresh, size: 16, color: AppColors.primary),
                onPressed: _loadQuickMessages,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7D6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1C400), width: 1),
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

    if (!isCustomer) {
      return const SizedBox.shrink();
    }

    final providerName = widget.request.provider?.fullName ?? widget.request.providerName ?? 'Provider';
    final providerImage = widget.request.providerImage ?? widget.request.provider?.businessLogo?.url ?? widget.request.imagePath ?? 'assets/images/default_avatar.png';
    final providerRating = widget.request.providerRating ?? widget.request.provider?.rating ?? 0.0;
    final providerReviewCount = widget.request.providerReviewCount ?? 0;

    final moneyRequest = _paymentController.moneyRequestDetails;
    final hasPaymentRequest = moneyRequest != null;
    final paymentStatus = hasPaymentRequest ? (moneyRequest!['status'] as String? ?? 'pending') : 'pending';
    final amount = hasPaymentRequest ? (moneyRequest!['amount'] as int? ?? widget.request.averagePrice.toInt()) : widget.request.averagePrice.toInt();
    final isPaid = paymentStatus.toLowerCase() == 'paid' || paymentStatus.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0500CD49),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x4D00CD49),
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

          AppText(
            '${widget.request.serviceName}: \$${widget.request.averagePrice.toInt()}/hr',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.Black,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
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

          AppText(
            isPaid
                ? 'Thank you for completing the payment! $providerName has been notified.'
                : 'Payment request from $providerName. Please complete the payment to finish the task.',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.DarkGray,
          ),

          const SizedBox(height: 12),

          if (!isPaid) ...[
            Row(
              children: [
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
                    const Icon(Icons.receipt, size: 16, color: Colors.white),
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

  void _handleAcceptPayment() async {
    final moneyRequest = _paymentController.moneyRequestDetails;
    if (moneyRequest == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final token = _tokenService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final moneyRequestId = moneyRequest['_id']?.toString();
      if (moneyRequestId == null || moneyRequestId.isEmpty) {
        throw Exception('Invalid payment request ID');
      }

      final serviceRequestId = moneyRequest['serviceRequest']?['_id']?.toString() ??
          widget.request.id?.toString() ??
          '';

      final result = await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (context) => ReviewConfirmScreen(
            request: widget.request,
            moneyRequestId: moneyRequestId,
            serviceRequestId: serviceRequestId,
            token: token,
          ),
        ),
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Reload money request details to update status
        if (widget.requestId != null) {
          await _paymentController.loadMoneyRequestDetails(
            serviceRequestId: widget.requestId!,
          );
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

  void _viewPaymentDetails() {
    final moneyRequest = _paymentController.moneyRequestDetails;
    if (moneyRequest == null) return;

    // Show payment details dialog or navigate to receipt screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${moneyRequest['amount']}'),
            Text('Status: ${moneyRequest['status']}'),
            if (moneyRequest['paymentDetails'] != null)
              Text('Method: ${moneyRequest['paymentDetails']?['paymentMethod'] ?? 'N/A'}'),
            if (moneyRequest['createdAt'] != null)
              Text('Date: ${moneyRequest['createdAt']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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

  factory ChatMessage.fromSocketData(Map<String, dynamic> data, String? currentUserId) {
    try {
      final senderRole = data['senderRole']?.toString().toLowerCase() ?? '';
      final senderId = data['senderId']?.toString();

      // Determine if message is from current user
      final isCurrentUser = senderId == currentUserId;

      return ChatMessage(
        text: data['content']?.toString() ?? 'No content',
        isFromUser: senderRole == 'customer',
        isFromProvider: senderRole == 'provider',
        timestamp: data['timestamp'] != null
            ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        senderId: senderId,
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