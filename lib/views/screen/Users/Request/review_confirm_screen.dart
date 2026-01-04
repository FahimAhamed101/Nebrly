import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naibrly/models/user_request1.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
class ReviewConfirmScreen extends StatefulWidget {
  final UserRequest request;
  final String moneyRequestId;
  final String? token;
  final String serviceRequestId;

  const ReviewConfirmScreen({
    super.key,
    required this.request,
    required this.moneyRequestId,
    required this.serviceRequestId,
    this.token,
  });

  @override
  State<ReviewConfirmScreen> createState() => _ReviewConfirmScreenState();
}

class _ReviewConfirmScreenState extends State<ReviewConfirmScreen> {
  final TextEditingController _tipController = TextEditingController(text: '0');
  double _tipAmount = 0.0;
  bool _isProcessingPayment = false;
  bool _isLoading = true;
  final String _baseUrl = 'https://ungustatory-erringly-ralph.ngrok-free.dev';

  Map<String, dynamic>? _moneyRequestData;
  double _baseAmount = 0.0;
  String _providerName = '';
  String _providerImage = '';
  String _serviceType = '';
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _tipController.addListener(_updateTipAmount);
    _fetchMoneyRequestData();
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _fetchMoneyRequestData() async {
    try {
      final token = widget.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is required');
      }

      final url = Uri.parse('$_baseUrl/api/money-requests/customer?serviceRequestId=${widget.serviceRequestId}');

      if (kDebugMode) {
        print('📱 Fetching money request data for service: ${widget.serviceRequestId}');
        print('📱 API URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('📱 Money Request Data Response Status: ${response.statusCode}');
        print('📱 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success && responseData['data'] != null) {
          final moneyRequests = responseData['data']['moneyRequests'] as List;
          if (moneyRequests.isNotEmpty) {
            final moneyRequest = moneyRequests.firstWhere(
                  (mr) => mr['_id'] == widget.moneyRequestId,
              orElse: () => moneyRequests.first,
            );

            setState(() {
              _moneyRequestData = moneyRequest;
              _baseAmount = (moneyRequest['amount'] as num?)?.toDouble() ?? 0.0;
              _tipAmount = (moneyRequest['tipAmount'] as num?)?.toDouble() ?? 0.0;
              _serviceType = moneyRequest['serviceRequest']?['serviceType'] ?? widget.request.serviceName;

              final scheduledDateStr = moneyRequest['serviceRequest']?['scheduledDate'];
              if (scheduledDateStr != null) {
                _scheduledDate = DateTime.parse(scheduledDateStr);
              }

              final provider = moneyRequest['provider'];
              if (provider != null) {
                _providerName = provider['businessNameRegistered'] ?? 'Provider';
                _providerImage = provider['businessLogo']?['url'] ?? '';
              }

              _tipController.text = _tipAmount.toStringAsFixed(0);
              _isLoading = false;
            });
          } else {
            throw Exception('No money requests found');
          }
        } else {
          throw Exception('Failed to load money request data');
        }
      } else {
        throw Exception('Failed to fetch data. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching money request data: $e');
      }
      setState(() {
        _baseAmount = widget.request.averagePrice.toDouble();
        _serviceType = widget.request.serviceName;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using default data: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateTipAmount() {
    final tipText = _tipController.text.replaceAll('\$', '').trim();
    final tip = double.tryParse(tipText) ?? 0.0;
    setState(() {
      _tipAmount = tip;
    });
  }

  double get _totalAmount => _baseAmount + _tipAmount;

  String _formatDate(DateTime? date) {
    if (date == null) return widget.request.formattedDate;
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // NEW: Call accept money request API
  Future<bool> _acceptMoneyRequest() async {
    try {
      final token = widget.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is required');
      }

      final moneyRequestId = widget.moneyRequestId;
      if (moneyRequestId.isEmpty) {
        throw Exception('Money request ID is required');
      }

      final url = Uri.parse('$_baseUrl/api/money-requests/$moneyRequestId/accept');

      if (kDebugMode) {
        print('✅ Accepting money request ID: $moneyRequestId');
        print('✅ API URL: $url');
      }

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reason': 'Payment confirmed by customer',
        }),
      );

      if (kDebugMode) {
        print('✅ Accept API Response Status: ${response.statusCode}');
        print('✅ Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          if (kDebugMode) {
            print('✅ Money request accepted successfully');
          }
          return true;
        } else {
          final errorMessage = responseData['message'] ?? 'Failed to accept money request';
          throw Exception(errorMessage);
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Bad request';
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Money request not found');
      } else if (response.statusCode == 409) {
        // Already accepted - treat as success
        if (kDebugMode) {
          print('✅ Money request already accepted');
        }
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Server error (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error accepting money request: $e');
      }
      rethrow;
    }
  }

  // NEW: Process payment after acceptance
  Future<void> _processPayment() async {
    try {
      final token = widget.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is required');
      }

      final moneyRequestId = widget.moneyRequestId;
      final url = Uri.parse('$_baseUrl/api/money-requests/$moneyRequestId/pay');

      if (kDebugMode) {
        print('💰 Processing payment for money request ID: $moneyRequestId');
        print('💰 Payment API URL: $url');
        print('💰 Base Amount: $_baseAmount');
        print('💰 Tip Amount: $_tipAmount');
        print('💰 Total Amount: $_totalAmount');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paymentMethod': 'card',
          'tipAmount': _tipAmount,
          'totalAmount': _totalAmount,
        }),
      );

      if (kDebugMode) {
        print('💰 Payment API Response Status: ${response.statusCode}');
        print('💰 Payment API Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success) {
          final sessionUrl = responseData['data']?['sessionUrl'] ??
              responseData['data']?['checkoutUrl'] ??
              responseData['checkoutUrl'] ??
              responseData['sessionUrl'];

          if (sessionUrl != null && sessionUrl is String && sessionUrl.isNotEmpty) {
            // Open Stripe Checkout session
            await _openStripeCheckout(sessionUrl);
          } else {
            // Fallback to success dialog if no session URL
            _showSuccessDialog();
          }
        } else {
          final errorMessage = responseData['message'] ?? 'Payment failed';
          throw Exception(errorMessage);
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Payment failed (Bad Request)';
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Payment request not found');
      } else if (response.statusCode == 409) {
        throw Exception('Payment already completed');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Payment failed (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Payment failed: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _openStripeCheckout(String sessionUrl) async {
    try {
      if (kDebugMode) {
        print('🔗 Opening Stripe Checkout URL: $sessionUrl');
      }

      // Show a loading dialog while preparing checkout
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const AppText(
            'Processing Payment',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.Black,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7A60)),
              ),
              const SizedBox(height: 20),
              const AppText(
                'Redirecting to secure payment page...',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.DarkGray,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Wait a moment for the dialog to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Open the Stripe Checkout URL
      final url = Uri.parse(sessionUrl);

      // Close the loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Open URL in browser
      final result = await _launchUrl(url);

      if (!result) {
        // If URL launch fails, show manual option
        _showManualRedirectDialog(sessionUrl);
      }

      // After redirecting to Stripe, show completion dialog
      _showCheckoutRedirectDialog();

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening Stripe Checkout: $e');
      }

      // Close any open dialogs
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error and fallback to manual redirect
      _showManualRedirectDialog(sessionUrl);
    }
  }

  Future<bool> _launchUrl(Uri url) async {
    try {
      // You can use url_launcher package for this
      // Add to pubspec.yaml: url_launcher: ^6.1.14

      // Example using url_launcher:
      // return await launchUrl(url, mode: LaunchMode.externalApplication);

      // For now, using a try-catch approach
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showManualRedirectDialog(String sessionUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Payment Setup Complete',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0E7A60),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'Your payment session has been created.',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
            ),
            const SizedBox(height: 10),
            const AppText(
              'Please click the link below to complete your payment:',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.Black,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(sessionUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: AppText(
                'Click here to pay',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0E7A60),
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 10),
            const AppText(
              'After completing payment on Stripe, return to this app.',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
              fontStyle: FontStyle.italic,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCheckoutRedirectDialog();
            },
            child: const AppText(
              'I\'ll pay later',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.DarkGray,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(sessionUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
                Navigator.of(context).pop();
                _showCheckoutRedirectDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7A60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const AppText(
              'Open Payment Link',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutRedirectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Redirected to Payment',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0E7A60),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF0E7A60),
              size: 50,
            ),
            const SizedBox(height: 15),
            const AppText(
              'You have been redirected to Stripe Checkout.',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const AppText(
              'Complete your payment on the Stripe page and return here.',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      'Don\'t close this app while completing payment.',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.DarkGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close this dialog
              Navigator.of(context).pop(true); // Return to previous screen
            },
            child: const AppText(
              'I\'ve Completed Payment',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E7A60),
            ),
          ),
        ],
      ),
    );
  }

// Update the success dialog to handle both scenarios
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Payment Successful!',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0E7A60),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF0E7A60),
              size: 50,
            ),
            const SizedBox(height: 10),
            const AppText(
              'Your payment has been processed successfully.',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AppText(
              'Service: $_serviceType',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            AppText(
              'Total: \$${_totalAmount.toStringAsFixed(2)}',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E7A60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            child: const AppText(
              'Done',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E7A60),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Main payment handler
  Future<void> _handleConfirmPayment() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Accept and Pay',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.Black,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Service: $_serviceType',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.Black,
            ),
            const SizedBox(height: 5),
            AppText(
              'Amount: \$${_baseAmount.toStringAsFixed(2)}',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.DarkGray,
            ),
            AppText(
              'Tip: \$${_tipAmount.toStringAsFixed(2)}',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.DarkGray,
            ),
            const SizedBox(height: 5),
            AppText(
              'Total: \$${_totalAmount.toStringAsFixed(2)}',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E7A60),
            ),
            const SizedBox(height: 8),
            const AppText(
              'Do you accept this request and want to proceed with payment?',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const AppText(
              'Cancel',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.DarkGray,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7A60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const AppText(
              'Accept & Pay Now',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      setState(() {
        _isProcessingPayment = true;
      });

      try {
        // Step 1: Accept the money request
        final accepted = await _acceptMoneyRequest();

        if (accepted) {
          // Step 2: Process payment
          await _processPayment();
        }
      } catch (e) {
        _showErrorDialog('Failed to process payment: ${e.toString()}');
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Payment Failed',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
        content: AppText(
          message,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.DarkGray,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText(
              'OK',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        title: const AppText(
          'Review and confirm',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.Black,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  _serviceType,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.Black,
                ),
                const SizedBox(height: 6),
                AppText(
                  'Request Amount: \$${_baseAmount.toInt()}/consult',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.Black,
                ),
                const SizedBox(height: 3),
                AppText(
                  'Date: ${_formatDate(_scheduledDate)}',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.DarkGray,
                ),

                const SizedBox(height: 24),

                // Service Provider Card
                if (_providerName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: _providerImage.isNotEmpty
                              ? NetworkImage(_providerImage) as ImageProvider
                              : const AssetImage('assets/default_profile.png'),
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                _providerName,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.Black,
                              ),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  SizedBox(width: 3),
                                  AppText(
                                    '4.5 (120 reviews)',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.DarkGray,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                const AppText(
                  'Tips',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.Black,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _tipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            'Service Amount:',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.DarkGray,
                          ),
                          AppText(
                            '\$${_baseAmount.toStringAsFixed(2)}',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.Black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            'Tip Amount:',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.DarkGray,
                          ),
                          AppText(
                            '\$${_tipAmount.toStringAsFixed(2)}',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.Black,
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            'Total Amount:',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.Black,
                          ),
                          AppText(
                            '\$${_totalAmount.toStringAsFixed(2)}',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0E7A60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: AppText(
                    '\$${_totalAmount.toInt()}',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E7A60),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment || _isLoading ? null : _handleConfirmPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7A60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : _isLoading
                        ? const AppText(
                      'Loading...',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )
                        : const AppText(
                      'Accept and Pay',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: const AppText(
                      'Terms & Condition',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0E7A60),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          if (_isLoading || _isProcessingPayment)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7A60)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Terms & Conditions',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.Black,
        ),
        content: const AppText(
          'By confirming this payment, you agree to our terms and conditions. The service will be provided as scheduled and payment will be processed securely.',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.DarkGray,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText(
              'Close',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E7A60),
            ),
          ),
        ],
      ),
    );
  }
}