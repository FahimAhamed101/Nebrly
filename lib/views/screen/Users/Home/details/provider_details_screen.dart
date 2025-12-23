import 'package:flutter/material.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/provider/models/client_feedback.dart';
import 'package:naibrly/provider/widgets/home/client_feedback_section.dart';
import 'package:naibrly/widgets/payment_confirmation_bottom_sheet.dart';
import 'package:naibrly/widgets/naibrly_now_bottom_sheet.dart';
import 'package:naibrly/provider/services/api_service.dart';
import 'dart:convert';

import '../../../../../services/api_service.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final String? providerId;
  final String? selectedServiceName;
  final String providerName;
  final String rating;
  final String status;
  final String location;
  final String price;
  final String review;

  const ProviderDetailsScreen({
    Key? key,
    this.providerId,
    this.selectedServiceName,
    required this.providerName,
    required this.rating,
    required this.status,
    required this.location,
    required this.price,
    required this.review,
  }) : super(key: key);

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  List<ClientFeedback> _feedbackList = [];
  bool _hasMoreFeedback = true;
  bool isLoadingProviderData = false;
  String errorMessage = '';
  Map<String, dynamic>? providerData;
  List<dynamic> otherServices = [];

  @override
  void initState() {
    super.initState();
    _loadInitialFeedback();

    // Fetch provider data if providerId is available
    if (widget.providerId != null && widget.selectedServiceName != null) {
      _fetchProviderData();
    }
  }

  Future<void> _fetchProviderData() async {
    print('🚀 _fetchProviderData called');
    print('providerId: ${widget.providerId}');
    print('selectedServiceName: ${widget.selectedServiceName}');

    if (widget.providerId == null || widget.selectedServiceName == null) {
      print('❌ Missing providerId or selectedServiceName');
      return;
    }

    setState(() {
      isLoadingProviderData = true;
      errorMessage = '';
    });

    try {
      print('🔄 Calling MainApiService.getProviderServiceDetails...');
      print('Provider ID: ${widget.providerId}');
      print('Service Name: ${widget.selectedServiceName}');

      final response = await MainApiService.getProviderServiceDetails(
        widget.providerId!,
        widget.selectedServiceName!,
      );

      print('📦 API Response received');
      print('Response: $response');
      print('Response type: ${response.runtimeType}');
      print('success key: ${response['success']}');
      print('data key: ${response['data']}');

      if (response['success'] == true && response['data'] != null) {
        print('✅ Response is successful with data');
        print('Provider: ${response['data']['provider']}');
        print('Selected Service: ${response['data']['selectedService']}');
        print('Other Services: ${response['data']['otherServices']}');

        setState(() {
          providerData = response['data'];
          print('✅ providerData set in state: $providerData');

          if (providerData?['otherServices'] != null) {
            otherServices = List<dynamic>.from(providerData!['otherServices']);
            print('✅ otherServices set: ${otherServices.length} services');
          }
          isLoadingProviderData = false;
        });

        print('✅ State updated successfully');
        print('providerData after setState: $providerData');
      } else {
        print('❌ Response unsuccessful or no data');
        print('success: ${response['success']}');
        print('data: ${response['data']}');

        setState(() {
          errorMessage = 'Failed to load provider data';
          isLoadingProviderData = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _fetchProviderData: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        errorMessage = 'Error loading provider data: $e';
        isLoadingProviderData = false;
      });
    }
  }

  void _loadInitialFeedback() {
    // Load initial feedback
  }

  void _loadMoreFeedback() {
    setState(() {
      final currentCount = _feedbackList.length;
    });
  }

  void _toggleFeedbackExpansion(String feedbackId) {
    setState(() {
      final feedbackIndex = _feedbackList.indexWhere((fb) => fb.id == feedbackId);
    });
  }

  // Get display values from API data or fallback to widget props
  String get displayProviderName {
    if (providerData != null && providerData!['provider'] != null) {
      return providerData!['provider']['businessName'] ?? widget.providerName;
    }
    return widget.providerName;
  }

  String get displayRating {
    if (providerData != null && providerData!['provider'] != null) {
      return "${providerData!['provider']['rating']} (${providerData!['provider']['totalReviews']} reviews)";
    }
    return widget.rating;
  }

  String get displayPrice {
    if (providerData != null && providerData!['selectedService'] != null) {
      final hourlyRate = providerData!['selectedService']['hourlyRate'];
      return "\$$hourlyRate/hr";
    }
    return widget.price;
  }

  String get displayServiceName {
    if (providerData != null && providerData!['selectedService'] != null) {
      return providerData!['selectedService']['name'] ?? widget.selectedServiceName ?? 'Service';
    }
    return widget.selectedServiceName ?? 'Service';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          "$displayProviderName's Profile and Services",
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        centerTitle: false,
      ),
      body: isLoadingProviderData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderProfile(),
            const SizedBox(height: 24),
            _buildCallToActionButton(),
            const SizedBox(height: 32),
            _buildServicesSection(),
            const SizedBox(height: 32),
            ClientFeedbackSection(
              feedbackList: _feedbackList,
              onToggleExpansion: _toggleFeedbackExpansion,
              onLoadMore: _loadMoreFeedback,
              hasMoreFeedback: _hasMoreFeedback,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderProfile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset('assets/images/home.png'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                displayProviderName,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0E7A60),
                ),
              ),
              const SizedBox(width: 6),
              AppText(
                widget.status,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0E7A60),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              AppText(
                displayRating,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            widget.location,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: displayPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const TextSpan(
                  text: " estimated budget",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText(
              widget.review,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToActionButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showNaibrlyNowBottomSheet(
            context,
            serviceName: displayServiceName,
            providerName: displayProviderName,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E7A60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const AppText(
          "Naibrly Now",
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "$displayProviderName's Services",
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        const SizedBox(height: 16),

        // Display selected service first
        if (providerData != null && providerData!['selectedService'] != null)
          Column(
            children: [
              _buildServiceCard(
                providerData!['selectedService']['name'],
                "assets/images/service.png",
                isSelected: true,
              ),
              const SizedBox(height: 12),
            ],
          ),

        // Display other services
        if (otherServices.isNotEmpty)
          ...otherServices.map<Widget>((service) {
            return Column(
              children: [
                _buildServiceCard(
                  service['name'],
                  "assets/images/service.png",
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildServiceCard(String serviceName, String imagePath, {bool isSelected = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 15,
          ),
        ],
        border: Border.all(
          width: 0.8,
          color: isSelected
              ? AppColors.primary.withOpacity(0.3)
              : Colors.black.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.shade200,
            ),
            child: Icon(
              serviceName.contains('Electrical') ? Icons.electrical_services :
              serviceName.contains('Appliance') ? Icons.home_repair_service :
              serviceName.contains('Security') ? Icons.security :
              Icons.build,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppText(
              serviceName,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppText(
                'Current',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}