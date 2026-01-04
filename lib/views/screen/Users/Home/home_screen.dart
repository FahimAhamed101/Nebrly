import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/screen/Users/Home/create_bundle_bottomsheet.dart';
import 'package:naibrly/widgets/bundle_card.dart';
import 'package:naibrly/widgets/service_request_card.dart';
import 'package:naibrly/services/mock_data_service.dart';
import '../../../../controller/Customer/bundlesController/createBundle.dart';
import '../../../../controller/Customer/profileController/profileController.dart';
import '../../../../controller/Customer/service_request_controller.dart';
import '../../search/search_results_screen.dart';
import '../Bundles/bundels_screen.dart';

import 'base/popularService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedLanguage = "Category";
  final List<String> languages = ["Home", "Service", "Popular", "Organization"];

  List<Map<String, dynamic>> bundles = [];
  bool isLoadingBundles = true;
  int? expandedIndex;

  // Search controllers
  final TextEditingController _popularSearchController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final GlobalKey _popularSearchFieldKey = GlobalKey();
  final LayerLink _popularSearchLink = LayerLink();
  OverlayEntry? _popularOverlay;
  double _popularFieldWidth = 0;
  final List<String> _popularItems = const [
    'Home Repairs',
    'Cleaning & Organization',
    'Renovations & Upgrades',
    'Electrical',
    'Plumbing',
    'HVAC',
    'Appliance Repairs',
  ];

  // Controllers
  final ProfileController profileController = Get.put(ProfileController());
  final CreateBundleController bundleController = Get.put(CreateBundleController());
  final ServiceRequestController serviceRequestController = Get.put(ServiceRequestController());

  @override
  void initState() {
    super.initState();
    _loadBundles();
    profileController.fetchUserData();
    bundleController.getNaibrlyBundle(context);
    serviceRequestController.fetchServiceRequests();

    // Set default values
    _popularSearchController.text = "Home Repairs";
    _zipCodeController.text = "59856";
  }

  @override
  void dispose() {
    _closePopularSearches();
    _popularSearchController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBundles() async {
    await MockDataService.initialize();

    setState(() {
      bundles = MockDataService.getActiveBundles().take(3).toList();
      isLoadingBundles = false;
    });
  }

  void _performSearch() {
    final serviceName = _popularSearchController.text.trim();
    final zipCode = _zipCodeController.text.trim();

    if (serviceName.isEmpty) {
      Get.snackbar(
        'Search Error',
        'Please select or enter a service name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    if (zipCode.isEmpty) {
      Get.snackbar(
        'Search Error',
        'Please enter a zip code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    // Validate zip code format (5 digits)
    if (!RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      Get.snackbar(
        'Invalid Zip Code',
        'Please enter a valid 5-digit zip code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    // Navigate to search results
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          serviceName: serviceName,
          zipCode: zipCode,
        ),
      ),
    );
  }

  void _openPopularSearches() {
    if (_popularOverlay != null) return;
    final overlay = Overlay.of(context);
    final RenderBox? box = _popularSearchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    _popularFieldWidth = box?.size.width ?? 0;

    _popularOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closePopularSearches,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _popularSearchLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 48 + 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: _popularFieldWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Text(
                          'Popular searches',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ..._popularItems.map((item) => InkWell(
                        onTap: () {
                          setState(() {
                            _popularSearchController.text = item;
                          });
                          _closePopularSearches();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18, color: Colors.grey.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_popularOverlay!);
  }

  void _closePopularSearches() {
    _popularOverlay?.remove();
    _popularOverlay = null;
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.White,
        title: RichText(
          text: const TextSpan(
            text: "Welcome to user ",
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: "Naibrly,",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: " Find Services,",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.White,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Search Bar - NOW FUNCTIONAL
            Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 0.8,
                  color: AppColors.textcolor.withOpacity(0.25),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CompositedTransformTarget(
                      link: _popularSearchLink,
                      child: TextFormField(
                        key: _popularSearchFieldKey,
                        controller: _popularSearchController,
                        readOnly: true,
                        onTap: _openPopularSearches,
                        decoration: const InputDecoration(
                          hintText: "Home Repairs",
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        style: const TextStyle(color: AppColors.textcolor),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.textcolor.withOpacity(0.4),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  SvgPicture.asset("assets/icons/location.svg"),
                  Expanded(
                    child: TextFormField(
                      controller: _zipCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        hintText: "59856",
                        border: InputBorder.none,
                        isCollapsed: true,
                        counterText: "", // Hide character counter
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black.withOpacity(0.50),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textcolor),
                    ),
                  ),
                  GestureDetector(
                    onTap: _performSearch,
                    child: Container(
                      width: 45,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset("assets/icons/search-normal.svg"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Service Requests Section - Using GetX Obx
            Obx(() {
              if (serviceRequestController.isLoading.value) {
                return Column(
                  children: [
                    Row(
                      children: [
                        const AppText(
                          "Service Requests",
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                        const SizedBox(width: 12),
                        SvgPicture.asset("assets/icons/Icon (4).svg"),
                        const Spacer(),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }

              if (serviceRequestController.error.value.isNotEmpty) {
                return Column(
                  children: [
                    Row(
                      children: [
                        const AppText(
                          "Service Requests",
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                        const SizedBox(width: 12),
                        SvgPicture.asset("assets/icons/Icon (4).svg"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              serviceRequestController.error.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => serviceRequestController.refreshServiceRequests(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }

              final pendingRequests = serviceRequestController.pendingRequests;

              if (pendingRequests.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Row(
                    children: [
                      const AppText(
                        "Service Requests",
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      const SizedBox(width: 12),
                      SvgPicture.asset("assets/icons/Icon (4).svg"),
                      const Spacer(),
                      AppText(
                        "${pendingRequests.length} Pending",
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ServiceRequestCard.fromServiceRequest(
                    serviceRequest: pendingRequests.first,
                    onAccept: () async {
                      await serviceRequestController.acceptServiceRequest(pendingRequests.first.id);
                    },
                    onCancel: () async {
                      await serviceRequestController.cancelServiceRequest(pendingRequests.first.id);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),

            // Bundles Section
            Obx(() {
              final bundleList = bundleController.bundles.take(3).toList();

              return Column(
                children: [
                  Row(
                    children: [
                      const AppText(
                        "Naibrly Bundles",
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      const SizedBox(width: 12),
                      SvgPicture.asset("assets/icons/Icon (4).svg"),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BundelsScreen()),
                          );
                        },
                        child: const AppText(
                          "View All",
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (bundleController.isLoading.value)
                    const Center(child: CircularProgressIndicator())
                  else if (bundleList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No bundles available'),
                    )
                  else
                    ...bundleList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bundle = entry.value;

                      final List<Map<String, dynamic>> participantList =
                      bundle.participants.map((participant) {
                        final customer = participant.customer;
                        return {
                          'name': '${customer.firstName} ${customer.lastName}',
                          'avatar': customer.profileImage.url,
                          'location': '${customer.address.city}, ${customer.address.state}',
                        };
                      }).toList();

                      return Column(
                        children: [
                          BundleCard(
                            bundleId: bundle.id,
                            loadingBundleId: bundleController.loadingBundleId,
                            serviceTitle: bundle.title,
                            originalPrice: '\$${bundle.originalPrice.toInt()}',
                            discountedPrice: '\$${bundle.finalPrice.toInt()}',
                            savings: '-\$${bundle.discountAmount.toInt()}',
                            providers: participantList,
                            benefits: bundle.services.map((s) => s.name).toList(),
                            participants: bundle.currentParticipants,
                            maxParticipants: bundle.maxParticipants,
                            serviceDate: bundle.serviceDate.toIso8601String(),
                            discountPercentage: bundle.discountPercent,
                            publishedText: 'Published ${_timeAgo(bundle.createdAt)}',
                            isExpanded: expandedIndex == index,
                            onToggleExpansion: () {
                              setState(() {
                                expandedIndex = expandedIndex == index ? null : index;
                              });
                            },
                            onJoinBundle: () {
                              bundleController.joinNaibrlyBundle(context, bundle.id);
                            },
                          ),
                          if (index < bundleList.length - 1) const SizedBox(height: 12),
                        ],
                      );
                    }),
                ],
              );
            }),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const CreateBundleBottomSheet(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7A60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Create Bundle",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BundelsScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFF0E7A60),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Naibrly Bundles",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E7A60),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Popular Services Section
            Row(
              children: [
                const AppText(
                  "Popular Services",
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.black,
                ),
                const SizedBox(width: 12),
                SvgPicture.asset("assets/icons/Icon (4).svg"),
                const Spacer(),
                buildLanguageSelector(languages, selectedLanguage),
              ],
            ),
            const SizedBox(height: 5),
            Popularservice(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PopupMenuButton<String> buildLanguageSelector(
      List<String> languages,
      String? selectedValue,
      ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        setState(() {
          selectedLanguage = value;
        });
        debugPrint("Selected Language: $value");
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: AppText(
            "Select Category",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xff71717A),
          ),
        ),
        ...languages.map(
              (lang) => PopupMenuItem<String>(
            value: lang,
            child: Row(
              children: [
                if (selectedLanguage == lang)
                  const Icon(Icons.check, color: Colors.green, size: 16),
                if (selectedLanguage == lang) const SizedBox(width: 6),
                AppText(
                  lang,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF000000).withOpacity(0.10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            AppText(
              selectedLanguage ?? "Category",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            const SizedBox(width: 8),
            SvgPicture.asset("assets/icons/elements (1).svg"),
          ],
        ),
      ),
    );
  }
}