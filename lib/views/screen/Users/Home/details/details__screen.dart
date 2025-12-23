import 'package:flutter/material.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:naibrly/views/screen/Users/Home/details/provider_details_screen.dart';
import 'package:naibrly/widgets/bundle_card.dart';
import 'package:naibrly/services/mock_data_service.dart';
import 'package:naibrly/models/service_model.dart';
import 'package:naibrly/services/api_service.dart';
import 'dart:convert';

import '../../../../../provider/services/api_service.dart';

class DetailsScreen extends StatefulWidget {
  final Service? service;
  final String? bundleId;
  final String? requestId;
  final String? customerId;
  final String? providerId;
  final String? selectedServiceName;

  // Rename to avoid conflict with built-in print()
  void printProviderDetails() {
    print('Provider ID: $providerId');
    print('Selected Service: $selectedServiceName');
  }

  const DetailsScreen({
    super.key,
    this.service,
    this.bundleId,
    this.requestId,
    this.customerId,
    this.providerId,
    this.selectedServiceName,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  int? expandedIndex;
  List<Map<String, dynamic>> bundles = [];
  bool isLoadingBundles = true;
  bool isLoadingProviderData = false;
  String errorMessage = '';
  Map<String, dynamic>? providerData;
  List<dynamic> otherServices = [];

  // Get service data from widget or use default
  Service get serviceData {
    if (widget.service != null) {
      return widget.service!;
    }

    // Create default service based on selectedServiceName
    double hourlyRate = 50.0;
    String description = 'Professional service provider';

    if (widget.selectedServiceName == 'Electrical') {
      hourlyRate = 75.0;
      description = 'Professional electrical services including wiring, repairs, installations, and maintenance for residential and commercial properties.';
    } else if (widget.selectedServiceName == 'Appliance Repairs') {
      hourlyRate = 50.0;
      description = 'Our Appliance Repairs service covers the repair of your everyday appliances, such as refrigerators, washing machines, microwaves, air conditioners, and more.';
    } else if (widget.selectedServiceName == 'Security Camera Installation') {
      hourlyRate = 2.0;
      description = 'Expert security camera installation services including setup, configuration, and maintenance.';
    }

    return Service(
      id: 'default',
      name: widget.selectedServiceName ?? 'Service',
      image: 'assets/images/service_placeholder.png',
      hourlyRate: hourlyRate,
      description: description,
      isActive: true,
      providerId: widget.providerId,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBundles();

    // Debug what's being passed
    print('📋 DetailsScreen initState called');
    print('widget.providerId: ${widget.providerId}');
    print('widget.selectedServiceName: ${widget.selectedServiceName}');

    // Fetch provider data if providerId is available
    if (widget.providerId != null && widget.selectedServiceName != null) {
      print('✅ Both providerId and selectedServiceName are available, calling _fetchProviderData');
      _fetchProviderData();
    } else {
      print('❌ Missing data for provider fetch:');
      print('   providerId is null: ${widget.providerId == null}');
      print('   selectedServiceName is null: ${widget.selectedServiceName == null}');
    }
  }

  Future<void> _fetchProviderData() async {
    if (widget.providerId == null || widget.selectedServiceName == null) {
      return;
    }

    setState(() {

      isLoadingProviderData = true;
      errorMessage = '';
    });

    try {
      // Call your API endpoint
      final response = await MainApiService.getProviderServiceDetails(
        widget.providerId!,
        widget.selectedServiceName!,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          providerData = response['data'];
          if (providerData?['otherServices'] != null) {
            otherServices = List<dynamic>.from(providerData!['otherServices']);
          }
          isLoadingProviderData = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load provider data';
          isLoadingProviderData = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading provider data: $e';
        isLoadingProviderData = false;
      });
      print('Provider data fetch error: $e');
    }
  }

  // Calculate min and max price based on hourly rate from API or service data
  double get minPrice {
    if (providerData != null && providerData!['selectedService'] != null) {
      final hourlyRate = (providerData!['selectedService']['hourlyRate'] ?? 0).toDouble();
      return hourlyRate * 0.8;
    }
    return serviceData.hourlyRate * 0.8;
  }

  double get maxPrice {
    if (providerData != null && providerData!['selectedService'] != null) {
      final hourlyRate = (providerData!['selectedService']['hourlyRate'] ?? 0).toDouble();
      return hourlyRate * 1.2;
    }
    return serviceData.hourlyRate * 1.2;
  }

  double get averagePrice => (minPrice + maxPrice) / 2;

  // Get the hourly rate from API or service data
  double get hourlyRate {
    if (providerData != null && providerData!['selectedService'] != null) {
      return (providerData!['selectedService']['hourlyRate'] ?? 0).toDouble();
    }
    return serviceData.hourlyRate;
  }

  // Get service name from API or service data
  String get serviceName {
    if (providerData != null && providerData!['selectedService'] != null) {
      return providerData!['selectedService']['name'] ?? serviceData.name;
    }
    return serviceData.name;
  }

  // Get provider name from API or service data
  String get providerName {
    if (providerData != null && providerData!['provider'] != null) {
      return providerData!['provider']['businessName'] ?? 'Provider';
    }
    return 'Professional Provider';
  }

  Future<void> _loadBundles() async {
    try {
      setState(() {
        isLoadingBundles = true;
      });

      await MockDataService.initialize();
      final loadedBundles = MockDataService.getActiveBundles();

      setState(() {
        bundles = loadedBundles;
        isLoadingBundles = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load bundles: $e';
        isLoadingBundles = false;
      });
    }
  }

  Future<void> _handleJoinBundle(String bundleId) async {
    try {
      final success = await MockDataService.joinBundle(bundleId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined bundle!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBundles();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join bundle. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSeeAllBundles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to all bundles screen'),
      ),
    );
  }

  void _handleCopyToClipboard(String text, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $text'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleOpenBundleDetails(String bundleId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening bundle details: $bundleId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleOpenRequestDetails(String requestId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening request details: $requestId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToProviderDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderDetailsScreen(
          providerName: providerName,
          rating: providerData != null
              ? "${providerData!['provider']['rating']} (${providerData!['provider']['totalReviews']} reviews)"
              : "4.5 (6 reviews)",
          status: "Available Now",
          location: "Serving your area",
          price: "\$${hourlyRate.toStringAsFixed(0)}/hour",
          review: "Professional service with excellent customer satisfaction",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.White,
        title: AppText(
          serviceName,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      backgroundColor: AppColors.White,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display provider info if available
            if (widget.providerId != null)
              _buildProviderInfoSection(),

            // Display bundle and request IDs if available
            if (widget.bundleId != null || widget.requestId != null || widget.customerId != null)
              _buildIdSection(),

            _buildServiceCard(),
            const SizedBox(height: 20),
            _buildDescriptionSection(),
            const SizedBox(height: 30),
            _buildBundlesSection(),
            const SizedBox(height: 30),
            _buildProvidersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfoSection() {
    if (isLoadingProviderData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            color: Colors.black.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty && errorMessage.contains('provider data')) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(height: 8),
            AppText(
              errorMessage,
              color: Colors.red,
              fontSize: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (providerData != null && providerData!['provider'] != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
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
            color: Colors.black.withOpacity(0.10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        providerData!['provider']['businessName'] ?? 'Provider',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          AppText(
                            "${providerData!['provider']['rating']} (${providerData!['provider']['totalReviews']} reviews)",
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (otherServices.isNotEmpty) ...[
              AppText(
                "Other Services Offered:",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: otherServices.map<Widget>((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          service['name'] ?? 'Service',
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          "\$${service['hourlyRate']}/hr",
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    }

    return Container(); // Return empty container if no provider data
  }

  Widget _buildIdSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
          color: Colors.black.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.providerId != null) ...[
            _buildClickableId(
              label: 'Provider ID',
              id: widget.providerId!,
              icon: Icons.business,
              color: Colors.purple,
              onTap: () => _navigateToProviderDetails(),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.bundleId != null) ...[
            _buildClickableId(
              label: 'Bundle ID',
              id: widget.bundleId!,
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () => _handleOpenBundleDetails(widget.bundleId!),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.requestId != null) ...[
            _buildClickableId(
              label: 'Request ID',
              id: widget.requestId!,
              icon: Icons.request_page,
              color: Colors.blue,
              onTap: () => _handleOpenRequestDetails(widget.requestId!),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.customerId != null) ...[
            _buildClickableId(
              label: 'Customer ID',
              id: widget.customerId!,
              icon: Icons.person,
              color: Colors.green,
              onTap: () => _handleCopyToClipboard(widget.customerId!, 'Customer ID'),
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
    required VoidCallback onTap,
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
        IosTapEffect(
          onTap: onTap,
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
                  label == 'Provider ID' ? Icons.person_search :
                  label.contains('ID') ? Icons.open_in_new : Icons.content_copy,
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

  Widget _buildServiceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.White,
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
          color: Colors.black.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: _buildServiceImage(),
          ),

          // Title and Price
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  serviceName,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: "Avg. price: ",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: "\$${minPrice.toStringAsFixed(0)} - \$${maxPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0E7A60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  "Hourly rate: \$${hourlyRate.toStringAsFixed(0)}/hour",
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                if (providerData != null && providerData!['provider'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      AppText(
                        providerData!['provider']['businessName'],
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceImage() {
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            serviceName.contains('Electrical') ? Icons.electrical_services :
            serviceName.contains('Appliance') ? Icons.home_repair_service :
            serviceName.contains('Security') ? Icons.security :
            Icons.build,
            color: Colors.grey.shade500,
            size: 50,
          ),
          const SizedBox(height: 8),
          AppText(
            serviceName,
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          if (providerData != null && providerData!['provider'] != null) ...[
            const SizedBox(height: 8),
            AppText(
              "by ${providerData!['provider']['businessName']}",
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "$serviceName Service",
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        const SizedBox(height: 12),
        AppText(
          serviceData.description,
          color: AppColors.textcolor.withOpacity(0.8),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }

  Widget _buildBundlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppText(
              "Naibrly Bundles",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            const Spacer(),
            IosTapEffect(
              onTap: _handleSeeAllBundles,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: const AppText(
                  "See all",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0E7A60),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoadingBundles)
          const Center(child: CircularProgressIndicator())
        else if (errorMessage.isNotEmpty && errorMessage.contains('bundles'))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                AppText(
                  errorMessage,
                  color: Colors.red,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                IosTapEffect(
                  onTap: _loadBundles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AppText(
                      'Retry',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (bundles.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                  const SizedBox(height: 8),
                  const AppText(
                    'No bundles available',
                    color: Colors.grey,
                    fontSize: 14,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...bundles.asMap().entries.map((entry) {
              final index = entry.key;
              final bundle = entry.value;
              return Column(
                children: [
                  BundleCard(
                    serviceTitle: bundle['title'] ?? 'Unknown Bundle',
                    originalPrice: '\$${bundle['originalPrice']}',
                    discountedPrice: '\$${bundle['discountedPrice']}',
                    savings: '-\$${(bundle['originalPrice'] - bundle['discountedPrice']).toStringAsFixed(2)}',
                    providers: List<Map<String, dynamic>>.from(bundle['providers'] ?? []),
                    benefits: List<String>.from(bundle['benefits'] ?? []),
                    isExpanded: expandedIndex == index,
                    onToggleExpansion: () {
                      setState(() {
                        expandedIndex = expandedIndex == index ? null : index;
                      });
                    },
                    onJoinBundle: () {
                      _handleJoinBundle(bundle['id']);
                    },
                  ),
                  if (index < bundles.length - 1) const SizedBox(height: 12),
                ],
              );
            }),
      ],
    );
  }

  Widget _buildProvidersSection() {
    print('🔍 Building providers section...');
    print('providerData is null: ${providerData == null}');
    print('isLoadingProviderData: $isLoadingProviderData');

    if (providerData != null) {
      print('providerData keys: ${providerData!.keys}');
      print('provider exists: ${providerData!['provider'] != null}');
    }

    List<Widget> providerCards = [];

    // Show loading state
    if (isLoadingProviderData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "$serviceName Providers",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          const SizedBox(height: 16),
          _buildAverageCostSection(),
          const SizedBox(height: 20),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    // Show API provider data if available
    if (providerData != null && providerData!['provider'] != null) {
      final provider = providerData!['provider'];
      final selectedService = providerData!['selectedService'];

      print('✅ Adding main provider card');
      print('Business Name: ${provider['businessName']}');
      print('Provider ID: ${provider['id']}');

      // Get hourly rate safely
      final selectedServiceHourlyRate = selectedService != null && selectedService['hourlyRate'] != null
          ? selectedService['hourlyRate'].toDouble()
          : hourlyRate;

      providerCards.add(
        InkWell(
          onTap: () {
            print('🔥 Tapping main provider card');
            print('Navigating with providerId: ${provider['id']}');
            print('Navigating with serviceName: $serviceName');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderDetailsScreen(
                  providerId: provider['id'],
                  selectedServiceName: serviceName,
                  providerName: provider['businessName'] ?? providerName,
                  rating: "${provider['rating']} (${provider['totalReviews']} reviews)",
                  status: "Available Now",
                  location: "Serving your area",
                  price: "\$${selectedServiceHourlyRate.toStringAsFixed(0)}/hour",
                  review: "Professional service provider with excellent customer ratings",
                ),
              ),
            );
          },
          child: _buildProviderCard(
            provider['businessName'] ?? providerName,
            "${provider['rating'] ?? 0.0} (${provider['totalReviews'] ?? 0} reviews)",
            "Available Now",
            "Serving your area",
            "\$${selectedServiceHourlyRate.toStringAsFixed(0)}/hour",
            "Professional service provider with excellent customer ratings",
            isMainProvider: true,
          ),
        ),
      );
      providerCards.add(const SizedBox(height: 12));
    } else if (errorMessage.isNotEmpty) {
      // Show error state
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "$serviceName Providers",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(height: 8),
                AppText(
                  'Failed to load provider data: $errorMessage',
                  color: Colors.red,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchProviderData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      print('⚠️ No API provider data available, showing only default providers');
    }

    // Add default providers
    providerCards.addAll([
      InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDetailsScreen(
                providerId: "jacob_brothers_default",
                selectedServiceName: serviceName,
                providerName: "Jacob Brothers",
                rating: "5.0 (1,513 reviews)",
                status: "Online Now",
                location: "12 similar jobs done near you",
                price: "\$${hourlyRate.toStringAsFixed(0)}/hr estimated budget",
                review: "Jacob says, \"the repair person come on time, diagnosed and fixed the issue with my leaking wa...\"",
              ),
            ),
          );
        },
        child: _buildProviderCard(
          "Jacob Brothers",
          "5.0 (1,513 reviews)",
          "Online Now",
          "12 similar jobs done near you",
          "\$${hourlyRate.toStringAsFixed(0)}/hr estimated budget",
          "Jacob says, \"the repair person come on time, diagnosed and fixed the issue with my leaking wa...\"",
        ),
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDetailsScreen(
                providerId: "mike_services_default",
                selectedServiceName: serviceName,
                providerName: "Mike's Repair Services",
                rating: "4.8 (892 reviews)",
                status: "Available Today",
                location: "8 similar jobs done near you",
                price: "\$${(hourlyRate * 1.1).toStringAsFixed(0)}/hr estimated budget",
                review: "Mike provides excellent service with quick response times and quality workmanship for all appliance repairs.",
              ),
            ),
          );
        },
        child: _buildProviderCard(
          "Mike's Repair Services",
          "4.8 (892 reviews)",
          "Available Today",
          "8 similar jobs done near you",
          "\$${(hourlyRate * 1.1).toStringAsFixed(0)}/hr estimated budget",
          "Mike provides excellent service with quick response times and quality workmanship for all appliance repairs.",
        ),
      ),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "$serviceName Providers",
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        const SizedBox(height: 16),
        _buildAverageCostSection(),
        const SizedBox(height: 20),
        ...providerCards,
      ],
    );
  }

  Widget _buildAverageCostSection() {
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
          color: Colors.black.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                "\$${averagePrice.toStringAsFixed(0)}/consult",
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const AppText(
            "Avg. cost in your area",
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB4F4D3), Color(0xFF0E7A60)],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 200,
                top: -8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF0E7A60), width: 2),
                  ),
                ),
              ),
              Positioned(
                left: 180,
                top: -25,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E7A60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppText(
                    "\$${averagePrice.toStringAsFixed(0)}/consult avg.",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(String name, String rating, String status, String location, String price, String review, {bool isMainProvider = false}) {
    return GestureDetector(
      onTap: _navigateToProviderDetails,
      child: Container(
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
            color: isMainProvider ? AppColors.primary.withOpacity(0.3) : Colors.black.withOpacity(0.10),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isMainProvider ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade300,
              ),
              child: Icon(
                Icons.person,
                color: isMainProvider ? AppColors.primary : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText(
                        name,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      if (isMainProvider) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AppText(
                            'Main Provider',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      AppText(rating, fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMainProvider ? AppColors.primary : const Color(0xFF0E7A60),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppText(status, fontSize: 12, fontWeight: FontWeight.w400, color: isMainProvider ? AppColors.primary : const Color(0xFF0E7A60)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      AppText(location, fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(price, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                  const SizedBox(height: 8),
                  AppText(
                    review,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}