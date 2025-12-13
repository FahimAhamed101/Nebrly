// screens/search/search_results_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';

// Models remain the same as in your original code
class SearchProvider {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String businessNameRegistered;
  final double? rating;
  final int? totalReviews;
  final bool? isAvailable;
  final ProfileImage? profileImage;
  final BusinessLogo? businessLogo;
  final BusinessAddress? businessAddress;
  final List<ServiceProvided> servicesProvided;

  SearchProvider({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.businessNameRegistered,
    this.rating,
    this.totalReviews,
    this.isAvailable,
    this.profileImage,
    this.businessLogo,
    this.businessAddress,
    required this.servicesProvided,
  });

  factory SearchProvider.fromJson(Map<String, dynamic> json) {
    List<ServiceProvided> services = [];
    if (json['servicesProvided'] is List) {
      services = (json['servicesProvided'] as List)
          .map((s) => ServiceProvided.fromJson(s))
          .toList();
    }

    return SearchProvider(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      businessNameRegistered: json['businessNameRegistered'] ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      totalReviews: json['totalReviews'],
      isAvailable: json['isAvailable'],
      profileImage: json['profileImage'] != null
          ? ProfileImage.fromJson(json['profileImage'])
          : null,
      businessLogo: json['businessLogo'] != null
          ? BusinessLogo.fromJson(json['businessLogo'])
          : null,
      businessAddress: json['businessAddress'] != null
          ? BusinessAddress.fromJson(json['businessAddress'])
          : null,
      servicesProvided: services,
    );
  }

  String get displayName {
    if (businessNameRegistered.isNotEmpty) {
      return businessNameRegistered;
    }
    return '$firstName $lastName';
  }

  String get locationDisplay {
    if (businessAddress != null) {
      return '${businessAddress!.city}, ${businessAddress!.state}';
    }
    return 'Location not specified';
  }
}

class ProfileImage {
  final String url;
  final String publicId;
  ProfileImage({required this.url, required this.publicId});
  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(url: json['url'] ?? '', publicId: json['publicId'] ?? '');
  }
}

class BusinessLogo {
  final String url;
  final String publicId;
  BusinessLogo({required this.url, required this.publicId});
  factory BusinessLogo.fromJson(Map<String, dynamic> json) {
    return BusinessLogo(url: json['url'] ?? '', publicId: json['publicId'] ?? '');
  }
}

class BusinessAddress {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String? aptSuite;

  BusinessAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.aptSuite,
  });

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      aptSuite: json['aptSuite'],
    );
  }
}

class ServiceProvided {
  final String id;
  final String name;
  final String? description;
  final double? hourlyRate;

  ServiceProvided({
    required this.id,
    required this.name,
    this.description,
    this.hourlyRate,
  });

  factory ServiceProvided.fromJson(Map<String, dynamic> json) {
    return ServiceProvided(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      hourlyRate: json['hourlyRate'] != null
          ? (json['hourlyRate'] as num).toDouble()
          : null,
    );
  }
}

class RelatedService {
  final String id;
  final String name;
  final String? description;

  RelatedService({
    required this.id,
    required this.name,
    this.description,
  });

  factory RelatedService.fromJson(Map<String, dynamic> json) {
    return RelatedService(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class SearchCriteria {
  final String serviceName;
  final String zipCode;
  final String originalQuery;

  SearchCriteria({
    required this.serviceName,
    required this.zipCode,
    required this.originalQuery,
  });

  factory SearchCriteria.fromJson(Map<String, dynamic> json) {
    return SearchCriteria(
      serviceName: json['serviceName'] ?? '',
      zipCode: json['zipCode'] ?? '',
      originalQuery: json['originalQuery'] ?? '',
    );
  }
}

class SearchStats {
  final int totalProviders;
  final int providersInArea;
  final bool serviceAvailable;

  SearchStats({
    required this.totalProviders,
    required this.providersInArea,
    required this.serviceAvailable,
  });

  factory SearchStats.fromJson(Map<String, dynamic> json) {
    return SearchStats(
      totalProviders: json['totalProviders'] ?? 0,
      providersInArea: json['providersInArea'] ?? 0,
      serviceAvailable: json['serviceAvailable'] ?? false,
    );
  }
}

class PaginationInfo {
  final int current;
  final int total;
  final int pages;
  final bool hasMore;

  PaginationInfo({
    required this.current,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      current: json['current'] ?? 1,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String serviceName;
  final String zipCode;

  const SearchResultsScreen({
    Key? key,
    required this.serviceName,
    required this.zipCode,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxList<SearchProvider> _providers = <SearchProvider>[].obs;
  final RxList<RelatedService> _relatedServices = <RelatedService>[].obs;
  final Rx<SearchCriteria?> _searchCriteria = Rx<SearchCriteria?>(null);
  final Rx<SearchStats?> _stats = Rx<SearchStats?>(null);
  final Rx<PaginationInfo?> _pagination = Rx<PaginationInfo?>(null);
  final RxBool _isLoading = true.obs;
  final RxString _error = ''.obs;
  final RxString _apiMessage = ''.obs;
  final RxBool _showDebugInfo = false.obs;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print('🔍 Searching for: ${widget.serviceName} in ${widget.zipCode}');

      final response = await _apiService.post(
        'search/providers',
        {
          'serviceName': widget.serviceName,
          'zipCode': widget.zipCode,
        },
      );

      print('📡 Full Response: $response');

      if (response['success'] == true) {
        _apiMessage.value = response['message'] ?? '';
        final data = response['data'];

        if (data['searchCriteria'] != null) {
          _searchCriteria.value = SearchCriteria.fromJson(data['searchCriteria']);
        }

        final providersData = data['providers'] as List? ?? [];
        _providers.assignAll(
          providersData.map((p) => SearchProvider.fromJson(p)).toList(),
        );

        final relatedServicesData = data['relatedServices'] as List? ?? [];
        _relatedServices.assignAll(
          relatedServicesData.map((s) => RelatedService.fromJson(s)).toList(),
        );

        if (data['stats'] != null) {
          _stats.value = SearchStats.fromJson(data['stats']);
        }

        if (data['pagination'] != null) {
          _pagination.value = PaginationInfo.fromJson(data['pagination']);
        }

        if (_providers.isEmpty) {
          _error.value = 'No providers found';
        }
      } else {
        _error.value = response['message'] ?? 'Search failed';
      }
    } catch (e) {
      print('❌ Search Error: $e');
      _error.value = 'Error searching: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(() => Text(
          _searchCriteria.value?.serviceName ?? widget.serviceName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        )),
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              _showDebugInfo.value ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade600,
            ),
            onPressed: () => _showDebugInfo.toggle(),
            tooltip: 'Toggle Debug Info',
          )),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              Get.snackbar(
                'Filters',
                'Filtering options coming soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7A60)),
                ),
                SizedBox(height: 16),
                Text(
                  'Finding providers...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (_error.value.isNotEmpty && _providers.isEmpty) {
          return _buildNoResultsView();
        }

        return CustomScrollView(
          slivers: [
            // Debug info section (collapsible)
            if (_showDebugInfo.value) ...[
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchCriteria.value != null) _buildSearchCriteriaCard(),
                      const SizedBox(height: 12),
                      if (_stats.value != null) _buildStatsCard(),
                      const SizedBox(height: 12),
                      if (_pagination.value != null) _buildPaginationCard(),
                    ],
                  ),
                ),
              ),
            ],

            // Results count header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_providers.length} provider${_providers.length != 1 ? 's' : ''} found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (_stats.value != null && _stats.value!.providersInArea > 0)
                      Text(
                        'in ${widget.zipCode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Provider list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index >= _providers.length) return null;
                    return _buildProviderCard(_providers[index]);
                  },
                  childCount: _providers.length,
                ),
              ),
            ),

            // Related services section
            if (_relatedServices.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildRelatedServicesSection(),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No providers found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any providers for "${widget.serviceName}" in ${widget.zipCode}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            if (_relatedServices.isNotEmpty) ...[
              Text(
                'Try these related services:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _relatedServices.map((service) {
                  return InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResultsScreen(
                            serviceName: service.name,
                            zipCode: widget.zipCode,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E7A60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0E7A60).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          color: Color(0xFF0E7A60),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7A60),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Try New Search',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(SearchProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Provider Details',
            'Opening ${provider.displayName}\'s profile',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Provider image
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: provider.profileImage?.url != null
                          ? DecorationImage(
                        image: NetworkImage(provider.profileImage!.url),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: Colors.grey.shade200,
                    ),
                    child: provider.profileImage?.url == null
                        ? Center(
                      child: Text(
                        provider.firstName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E7A60),
                        ),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Provider info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                provider.locationDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Rating
                        if (provider.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                provider.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (provider.totalReviews != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${provider.totalReviews})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Availability indicator
                  if (provider.isAvailable != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isAvailable!
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: provider.isAvailable!
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: provider.isAvailable!
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.isAvailable! ? 'Available' : 'Busy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: provider.isAvailable!
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Services chips
              if (provider.servicesProvided.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.servicesProvided
                      .take(3)
                      .map((service) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E7A60).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0E7A60),
                          ),
                        ),
                        if (service.hourlyRate != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• \$${service.hourlyRate!.toStringAsFixed(0)}/hr',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          'Message',
                          'Messaging ${provider.displayName}',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.message_outlined, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0E7A60),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          'Booking',
                          'Booking ${provider.displayName}',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7A60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Related Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _relatedServices.map((service) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultsScreen(
                      serviceName: service.name,
                      zipCode: widget.zipCode,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Debug info cards (simplified versions)
  Widget _buildSearchCriteriaCard() {
    final criteria = _searchCriteria.value!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Criteria',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text('Service: ${criteria.serviceName}', style: const TextStyle(fontSize: 11)),
          Text('Zip: ${criteria.zipCode}', style: const TextStyle(fontSize: 11)),
          Text('Query: ${criteria.originalQuery}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _stats.value!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stats',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text('Total: ${stats.totalProviders}', style: const TextStyle(fontSize: 11)),
          Text('In Area: ${stats.providersInArea}', style: const TextStyle(fontSize: 11)),
          Text('Available: ${stats.serviceAvailable}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPaginationCard() {
    final pagination = _pagination.value!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pages, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Pagination Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Page',
                  '${pagination.current} / ${pagination.pages}',
                  Icons.pages,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Total Results',
                  pagination.total.toString(),
                  Icons.list,
                  Colors.purple,
                ),
              ],
            ),
            if (pagination.hasMore) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'More results available',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }





  @override
  void dispose() {
    super.dispose();
  }
}