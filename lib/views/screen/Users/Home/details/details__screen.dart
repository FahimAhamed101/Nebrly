import 'package:flutter/material.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:naibrly/views/screen/Users/Home/details/provider_details_screen.dart';
import 'package:naibrly/widgets/bundle_card.dart';
import 'package:naibrly/services/mock_data_service.dart';
import 'package:naibrly/models/service_model.dart';

class DetailsScreen extends StatefulWidget {
  final Service? service;
  final String? bundleId;
  final String? requestId;
  final String? customerId;

  const DetailsScreen({
    super.key,
    this.service,
    this.bundleId,
    this.requestId,
    this.customerId,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  int? expandedIndex;
  List<Map<String, dynamic>> bundles = [];
  bool isLoadingBundles = true;
  String errorMessage = '';

  // Get service data from widget or use default
  Service get serviceData {
    return widget.service ?? Service(
      id: 'default',
      name: 'Appliance Repairs',
      image: 'assets/images/e0a5051b9af8512d821599ee993492a9954bb256.png',
      hourlyRate: 50.0,
      description: 'Our Appliance Repairs service covers the repair of your everyday appliances, such as refrigerators, washing machines, microwaves, air conditioners, and more. Our experienced technicians will efficiently and effectively solve any issues with your appliances.',
      isActive: true,
    );
  }

  // Calculate min and max price based on hourly rate
  double get minPrice => serviceData.hourlyRate * 0.8;
  double get maxPrice => serviceData.hourlyRate * 1.2;
  double get averagePrice => (minPrice + maxPrice) / 2;

  @override
  void initState() {
    super.initState();
    _loadBundles();
  }

  Future<void> _loadBundles() async {
    try {
      setState(() {
        isLoadingBundles = true;
        errorMessage = '';
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
    // Here you would typically use Clipboard.setData
  }

  void _handleOpenBundleDetails(String bundleId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening bundle details: $bundleId'),
        backgroundColor: Colors.blue,
      ),
    );
    // Navigate to bundle details screen
  }

  void _handleOpenRequestDetails(String requestId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening request details: $requestId'),
        backgroundColor: Colors.blue,
      ),
    );
    // Navigate to request details screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.White,
        title: AppText(
          serviceData.name,
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
        IosTapEffect(
          onTap: () {
            if (label == 'Bundle ID') {
              _handleOpenBundleDetails(id);
            } else if (label == 'Request ID') {
              _handleOpenRequestDetails(id);
            } else {
              _handleCopyToClipboard(id, label);
            }
          },
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
          // Image Section - Fixed to handle both network and asset images
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
                  serviceData.name,
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
                  "Hourly rate: \$${serviceData.hourlyRate.toStringAsFixed(0)}/hour",
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceImage() {
    if (serviceData.hasNetworkImage) {
      // Network image from API
      return Image.network(
        serviceData.image,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImagePlaceholder(
            loading: true,
            progress: loadingProgress.cumulativeBytesLoaded.toDouble(),
            total: loadingProgress.expectedTotalBytes?.toDouble(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    } else if (serviceData.hasAssetImage) {
      // Asset image
      return Image.asset(
        serviceData.image,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    } else {
      // No image available
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder({bool loading = false, double? progress, double? total}) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading && progress != null && total != null)
            CircularProgressIndicator(
              value: progress / total,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            )
          else
            Icon(
              Icons.home_repair_service,
              color: Colors.grey.shade500,
              size: 50,
            ),
          if (loading) const SizedBox(height: 8),
          if (loading)
            AppText(
              'Loading image...',
              color: Colors.grey.shade600,
              fontSize: 12,
            )
          else
            AppText(
              'No Image Available',
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "${serviceData.name} Service",
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
        const SizedBox(height: 8),
        if (serviceData.categoryType?['name'] != null)
          AppText(
            "Category: ${serviceData.categoryType!['name']}",
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
        else if (errorMessage.isNotEmpty)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "${serviceData.name} Providers",
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        const SizedBox(height: 16),
        _buildAverageCostSection(),
        const SizedBox(height: 20),
        _buildProviderCard(
            "Jacob Brothers",
            "5.0 (1,513 reviews)",
            "Online Now",
            "12 similar jobs done near you",
            "\$${serviceData.hourlyRate.toStringAsFixed(0)}/hr estimated budget",
            "Jacob says, \"the repair person come on time, diagnosed and fixed the issue with my leaking wa...\""
        ),
        const SizedBox(height: 12),
        _buildProviderCard(
            "Mike's Repair Services",
            "4.8 (892 reviews)",
            "Available Today",
            "8 similar jobs done near you",
            "\$${(serviceData.hourlyRate * 1.1).toStringAsFixed(0)}/hr estimated budget",
            "Mike provides excellent service with quick response times and quality workmanship for all appliance repairs."
        ),
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

  Widget _buildProviderCard(String name, String rating, String status, String location, String price, String review) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderDetailsScreen(
              providerName: name,
              rating: rating,
              status: status,
              location: location,
              price: price,
              review: review,
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
            color: Colors.black.withOpacity(0.10),
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
                color: Colors.grey.shade300,
              ),
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0E7A60)),
                      ),
                      const SizedBox(width: 6),
                      AppText(status, fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF0E7A60)),
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