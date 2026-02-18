import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:naibrly/models/money_request_model.dart';
import 'package:naibrly/services/api_service.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../base/AppText/appText.dart';
import '../../../../base/Ios_effect/iosTapEffect.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String selectedFilter = 'All';

  final MainApiService _apiService = Get.find<MainApiService>();
  final List<MoneyRequest> _payments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: AppColors.White,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.Black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText(
          "Payment History",
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.Black,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const AppText(
                  "Filter:",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.Black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Completed', 'Pending', 'Failed'].map((filter) {
                        final isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IosTapEffect(
                            onTap: () {
                              setState(() {
                                selectedFilter = filter;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.LightGray,
                                  width: 1,
                                ),
                              ),
                              child: AppText(
                                filter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.DarkGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Color(0xFFEEEEEE)),
          
          // Payment History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _buildPaymentList(),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments({bool loadMore = false}) async {
    if (_isLoadingMore) return;
    if (loadMore && _currentPage >= _totalPages) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = '';
      }
    });

    try {
      final nextPage = loadMore ? _currentPage + 1 : 1;
      final response = await _apiService.get(
        'money-requests/customer/history',
        queryParams: {
          'page': nextPage.toString(),
          'limit': '20',
        },
      );

      final data = response['data'] ?? {};
      final payments = (data['payments'] as List? ?? [])
          .map((e) => MoneyRequest.fromJson(e))
          .toList();

      final pagination = data['pagination'] ?? {};

      setState(() {
        if (loadMore) {
          _payments.addAll(payments);
        } else {
          _payments
            ..clear()
            ..addAll(payments);
        }
        _currentPage = pagination['current'] ?? nextPage;
        _totalPages = pagination['pages'] ?? 1;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payment history: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<MoneyRequest> get _filteredPayments {
    if (selectedFilter == 'All') return _payments;

    final statusFilter = selectedFilter.toLowerCase();
    return _payments.where((payment) {
      final status = payment.status.toLowerCase();
      if (statusFilter == 'completed') {
        return status == 'paid' || status == 'completed';
      }
      if (statusFilter == 'pending') {
        return status == 'pending' || status == 'accepted';
      }
      if (statusFilter == 'failed') {
        return status == 'failed' || status == 'cancelled';
      }
      return true;
    }).toList();
  }

  Widget _buildPaymentList() {
    final payments = _filteredPayments;

    if (payments.isEmpty) {
      return const Center(
        child: AppText(
          'No payment history found',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.DarkGray,
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          if (!_isLoadingMore && _currentPage < _totalPages) {
            _fetchPayments(loadMore: true);
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: payments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == payments.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final payment = payments[index];
          final isCompleted = payment.status.toLowerCase() == 'paid';
          final isPending = payment.status.toLowerCase() == 'pending' || payment.status.toLowerCase() == 'accepted';

          final serviceTitle = payment.serviceRequest?.serviceType ??
              payment.bundle?.title ??
              payment.description;

          final providerName = payment.provider.businessNameRegistered.isNotEmpty
              ? payment.provider.businessNameRegistered
              : 'Service Provider';

          final paidAt = payment.paymentDetails.paidAt ?? payment.updatedAt;
          final formattedDate = DateFormat('yyyy-MM-dd').format(paidAt);

          final paymentMethod = payment.paymentDetails.paymentMethod.isNotEmpty
              ? payment.paymentDetails.paymentMethod
              : 'Card';

          final transactionId = payment.paymentDetails.transactionId ?? 'N/A';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.LightGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            serviceTitle,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.Black,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            providerName,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.DarkGray,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          '\$${payment.totalAmount.toStringAsFixed(2)}',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.Black,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.1)
                                : isPending
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppText(
                            _statusLabel(payment.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isCompleted
                                ? Colors.green
                                : isPending
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const AppText(
                      'Date: ',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.DarkGray,
                    ),
                    AppText(
                      formattedDate,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.DarkGray,
                    ),
                    const Spacer(),
                    const AppText(
                      'Method: ',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.DarkGray,
                    ),
                    AppText(
                      paymentMethod,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.DarkGray,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText(
                  'Transaction ID: $transactionId',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.DarkGray,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          AppText(
            _errorMessage,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.DarkGray,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _fetchPayments(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'cancelled':
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}
