import 'package:flutter/material.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:naibrly/views/screen/Users/Home/details/provider_details_screen.dart';
import 'package:naibrly/widgets/bundle_card.dart';
import 'package:naibrly/services/mock_data_service.dart';
import 'package:naibrly/models/service_model.dart';
import 'package:naibrly/provider/services/api_service.dart';

import '../../../../../services/api_service.dart';

class DetailsScreen extends StatefulWidget {
  final Service? service;
  final String? bundleId;
  final String? requestId;
  final String? customerId;
  final String? providerId;
  final String? selectedServiceName;

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

  // Store data for all providers
  Map<String, Map<String, dynamic>> allProvidersData = {};

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
      providers: widget.providerId != null ? [widget.providerId!] : [],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBundles();

    print('📋 DetailsScreen initState called');
    print('widget.providerId: ${widget.providerId}');
    print('widget.selectedServiceName: ${widget.selectedServiceName}');
    print('service.providers: ${serviceData.providers}');

    // Fetch all providers' data
    if (widget.selectedServiceName != null && serviceData.providers.isNotEmpty) {
      print('✅ Fetching data for ${serviceData.providers.length} providers');
      _fetchAllProvidersData();
    } else {
      print('❌ Missing data for providers fetch');
    }
  }

  Future<void> _fetchAllProvidersData() async {
    if (widget.selectedServiceName == null) return;

    setState(() {
      isLoadingProviderData = true;
      errorMessage = '';
    });

    try {
      final providerIds = serviceData.providers;

      if (providerIds.isEmpty) {
        setState(() {
          isLoadingProviderData = false;
        });
        return;
      }

      print('🔄 Fetching data for providers: $providerIds');

      // Fetch all providers in parallel
      final results = await MainApiService.getMultipleProvidersServiceDetails(
        providerIds,
        widget.selectedServiceName!,
      );

      setState(() {
        allProvidersData = results;

        // Set the main providerData to the first one or the selected one
        if (widget.providerId != null && results.containsKey(widget.providerId)) {
          providerData = results[widget.providerId];
        } else if (results.isNotEmpty) {
          providerData = results.values.first;
        }

        // Update other services list
        if (providerData?['otherServices'] != null) {
          otherServices = List<dynamic>.from(providerData!['otherServices']);
        }

        isLoadingProviderData = false;
      });

      print('✅ Successfully loaded ${results.length} providers');
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading provider data: $e';
        isLoadingProviderData = false;
      });
      print('❌ Provider data fetch error: $e');
    }
  }

  // Helper method to fetch single provider
  Future<Map<String, dynamic>> _fetchSingleProvider(String providerId) async {
    if (allProvidersData.containsKey(providerId)) {
      return allProvidersData[providerId]!;
    }

    try {
      final response = await MainApiService.getProviderServiceDetails(
        providerId,
        widget.selectedServiceName!,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          allProvidersData[providerId] = response['data'];
        });
        return response['data'];
      }
    } catch (e) {
      print('Error fetching provider $providerId: $e');
    }

    return {};
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
                      const Icon(Icons.business, size: 16, color: AppColors.primary),
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
    // Try to get the image URL from various sources
    String? imageUrl;

    // 1. First try to get from service's categoryType image
    if (widget.service?.categoryType?['image'] != null) {
      final imageData = widget.service!.categoryType!['image'];
      if (imageData is Map<String, dynamic> && imageData['url'] != null) {
        imageUrl = imageData['url'] as String;
      } else if (imageData is String && imageData.isNotEmpty) {
        imageUrl = imageData;
      }
    }

    // 2. Try to get from providerData's selectedService if available
    if (imageUrl == null && providerData != null && providerData!['selectedService'] != null) {
      final serviceData = providerData!['selectedService'];
      if (serviceData['image'] != null) {
        if (serviceData['image'] is Map<String, dynamic> && serviceData['image']['url'] != null) {
          imageUrl = serviceData['image']['url'] as String;
        } else if (serviceData['image'] is String && serviceData['image'].isNotEmpty) {
          imageUrl = serviceData['image'] as String;
        }
      }
    }

    // 3. If we have a valid URL, show the image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    // 4. Fallback to placeholder if no image found
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
          // Try to show a relevant icon based on the service name
          _getServiceIcon(),
          const SizedBox(height: 12),
          AppText(
            serviceName,
            color: Colors.grey.shade700,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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

// Helper method to get appropriate icon based on service name
  Widget _getServiceIcon() {
    final serviceNameLower = serviceName.toLowerCase();

    if (serviceNameLower.contains('clean')) {
      return Icon(Icons.cleaning_services, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('repair') || serviceNameLower.contains('maintenance')) {
      return Icon(Icons.home_repair_service, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('install')) {
      return Icon(Icons.build, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('electr')) {
      return Icon(Icons.electrical_services, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('plumb')) {
      return Icon(Icons.plumbing, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('security') || serviceNameLower.contains('camera')) {
      return Icon(Icons.security, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('landscap') || serviceNameLower.contains('garden')) {
      return Icon(Icons.grass, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('move')) {
      return Icon(Icons.local_shipping, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('paint')) {
      return Icon(Icons.format_paint, color: Colors.grey.shade500, size: 50);
    } else if (serviceNameLower.contains('remodel') || serviceNameLower.contains('renovat')) {
      return Icon(Icons.construction, color: Colors.grey.shade500, size: 50);
    } else {
      return Icon(Icons.home_repair_service, color: Colors.grey.shade500, size: 50);
    }
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
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                  SizedBox(height: 8),
                  AppText(
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
    // Get all providers for this service
    final providerIds = serviceData.providers;

    if (providerIds.isEmpty) {
      return Container(); // No providers to show
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: AppText(
            "Available Providers",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        // Show loading state while fetching provider data
        if (isLoadingProviderData)
          _buildProviderLoadingCard(),
        // Show error if exists
        if (errorMessage.isNotEmpty && errorMessage.contains('provider data'))
          _buildProviderErrorCard(),
        // Show all providers
        ...providerIds.asMap().entries.map((entry) {
          final index = entry.key;
          final providerId = entry.value;

          return Column(
            children: [
              _buildSingleProviderCard(providerId, index),
              if (index < providerIds.length - 1)
                const SizedBox(height: 12),
            ],
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProviderLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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

  Widget _buildProviderErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 8),
          IosTapEffect(
            onTap: () => _fetchAllProvidersData(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppText(
                'Retry',
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleProviderCard(String providerId, int index) {
    final isCurrentProvider = providerId == widget.providerId;
    final providerInfo = allProvidersData[providerId];

    if (providerInfo == null) {
      // Show loading or fetch individual provider
      return FutureBuilder<Map<String, dynamic>>(
        future: _fetchSingleProvider(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildProviderLoadingCard();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildProviderPlaceholder(providerId, index);
          }

          final data = snapshot.data!;
          return _buildProviderInfoCard(
            providerId: providerId,
            providerInfo: data,
            isCurrentProvider: isCurrentProvider,
          );
        },
      );
    }

    return _buildProviderInfoCard(
      providerId: providerId,
      providerInfo: providerInfo,
      isCurrentProvider: isCurrentProvider,
    );
  }

  Widget _buildProviderPlaceholder(String providerId, int index) {
    return Container(
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
            child: const Icon(Icons.business, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "Provider ${index + 1}",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                const SizedBox(height: 4),
                const AppText(
                  "Tap to view details",
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildProviderInfoCard({
    required String providerId,
    required Map<String, dynamic> providerInfo,
    required bool isCurrentProvider,
  }) {
    final provider = providerInfo['provider'];
    if (provider == null) return _buildProviderPlaceholder(providerId, 0);

    final otherServices = providerInfo['otherServices'] as List<dynamic>? ?? [];
    final selectedService = providerInfo['selectedService'];
    final hourlyRate = selectedService != null && selectedService['hourlyRate'] != null
        ? selectedService['hourlyRate'].toDouble()
        : this.hourlyRate;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderDetailsScreen(
              providerId: providerId,
              selectedServiceName: serviceName,
              providerName: provider['businessName'] ?? 'Provider',
              rating: "${provider['rating'] ?? 0.0} (${provider['totalReviews'] ?? 0} reviews)",
              status: "Available Now",
              location: "Serving your area",
              price: "\$${hourlyRate.toStringAsFixed(0)}/hour", // FIXED: Changed \${ to \$
              review: "Professional service provider with excellent customer ratings",
            ),
          ),
        );
      },
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
            color: isCurrentProvider
                ? AppColors.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.10),
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
                    color: isCurrentProvider
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade300,
                  ),
                  child: Icon(
                    Icons.business,
                    color: isCurrentProvider ? AppColors.primary : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AppText(
                              provider['businessName'] ?? 'Provider',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (isCurrentProvider) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const AppText(
                                'Selected',
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
                          AppText(
                            "${provider['rating'] ?? 0.0} (${provider['totalReviews'] ?? 0} reviews)",
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        "\$${hourlyRate.toStringAsFixed(0)}/hour", // FIXED: Changed \${ to \$
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (otherServices.isNotEmpty) ...[
              const SizedBox(height: 12),
              const AppText(
                "Other Services Offered:",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: otherServices.take(3).map<Widget>((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
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
                          "\$${service['hourlyRate']}/hr", // FIXED: Changed \${ to \$
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (otherServices.length > 3) ...[
                const SizedBox(height: 8),
                AppText(
                  "+${otherServices.length - 3} more services",
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}