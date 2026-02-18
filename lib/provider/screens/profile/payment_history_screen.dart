import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:naibrly/services/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MainApiService _apiService = Get.find<MainApiService>();

  final List<ProviderPaymentEntry> _entries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _searchController.addListener(() {
      setState(() {});
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payments History",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Jane Doe",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0E7A60)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0E7A60),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentEntry(ProviderPaymentEntry entry) {
    final isWithdrawal = entry.type == 'withdrawal';
    final amountColor = isWithdrawal ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          entry.avatarUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(entry.avatarUrl),
                  backgroundColor: Colors.grey.shade200,
                )
              : Image.asset(
                  "assets/images/jane.png",
                  color: Colors.grey,
                  width: 36,
                  height: 36,
                ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isWithdrawal ? '-' : '+'}${entry.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: amountColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat('HH:mm dd MMM, yyyy').format(entry.date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchHistory({bool loadMore = false}) async {
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
        'money-requests/provider/history',
        queryParams: {
          'page': nextPage.toString(),
          'limit': '20',
        },
      );

      final data = response['data'] ?? {};
      final items = (data['payments'] as List? ?? [])
          .map((e) => ProviderPaymentEntry.fromJson(e))
          .toList();

      final pagination = data['pagination'] ?? {};

      setState(() {
        if (loadMore) {
          _entries.addAll(items);
        } else {
          _entries
            ..clear()
            ..addAll(items);
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

  Widget _buildHistoryList() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _entries
        : _entries.where((entry) => entry.searchText.contains(query)).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No payment history found',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          if (!_isLoadingMore && _currentPage < _totalPages) {
            _fetchHistory(loadMore: true);
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildPaymentEntry(filtered[index]);
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
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _fetchHistory(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ProviderPaymentEntry {
  final String id;
  final String type;
  final double amount;
  final String status;
  final DateTime date;
  final String title;
  final String subtitle;
  final String avatarUrl;

  ProviderPaymentEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
  });

  String get searchText => '$title $subtitle'.toLowerCase();

  factory ProviderPaymentEntry.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'payment';

    if (type == 'withdrawal') {
      final date = _parseDate(json['processedAt']) ??
          _parseDate(json['updatedAt']) ??
          _parseDate(json['createdAt']) ??
          DateTime.now();

      final payoutRef = json['payoutReference']?.toString() ?? '';
      final status = json['status']?.toString() ?? 'pending';

      return ProviderPaymentEntry(
        id: json['_id']?.toString() ?? '',
        type: type,
        amount: (json['amount'] ?? 0).toDouble(),
        status: status,
        date: date,
        title: 'Withdrawal',
        subtitle: payoutRef.isNotEmpty ? 'Ref: $payoutRef' : 'Status: $status',
        avatarUrl: '',
      );
    }

    final customer = json['customer'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['customer'])
        : {};
    final firstName = customer['firstName']?.toString() ?? '';
    final lastName = customer['lastName']?.toString() ?? '';
    final customerName = ('$firstName $lastName').trim().isEmpty
        ? 'Customer'
        : ('$firstName $lastName').trim();

    final serviceRequest = json['serviceRequest'] as Map<String, dynamic>?;
    final bundle = json['bundle'] as Map<String, dynamic>?;
    final serviceName = serviceRequest?['serviceType']?.toString() ??
        bundle?['title']?.toString() ??
        json['description']?.toString() ??
        'Service';

    final paymentDetails = json['paymentDetails'] as Map<String, dynamic>?;
    final date = _parseDate(paymentDetails?['paidAt']) ??
        _parseDate(json['updatedAt']) ??
        _parseDate(json['createdAt']) ??
        DateTime.now();

    final avatarUrl = (customer['profileImage'] is Map<String, dynamic>)
        ? (customer['profileImage']['url']?.toString() ?? '')
        : '';

    return ProviderPaymentEntry(
      id: json['_id']?.toString() ?? '',
      type: type,
      amount: (json['totalAmount'] ?? json['amount'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'paid',
      date: date,
      title: 'Payment received',
      subtitle: '$customerName, $serviceName',
      avatarUrl: avatarUrl,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
