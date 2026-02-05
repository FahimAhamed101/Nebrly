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
    final providerJson = json['provider'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['provider'])
        : json;
    final serviceJson = json['service'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['service'])
        : <String, dynamic>{};
    final matchingServiceJson = providerJson['matchingService'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(providerJson['matchingService'])
        : <String, dynamic>{};

    List<ServiceProvided> services = [];
    if (providerJson['servicesProvided'] is List) {
      services = (providerJson['servicesProvided'] as List)
          .map((s) => ServiceProvided.fromJson(s))
          .toList();
    } else if (serviceJson.isNotEmpty) {
      services = [
        ServiceProvided.fromJson({
          '_id': serviceJson['providerServiceId'] ?? serviceJson['_id'] ?? '',
          'name': serviceJson['name'] ?? '',
          'description': serviceJson['description'],
          'hourlyRate': serviceJson['hourlyRate'],
        }),
      ];
    } else if (matchingServiceJson.isNotEmpty) {
      services = [
        ServiceProvided.fromJson({
          '_id': matchingServiceJson['_id'] ?? '',
          'name': matchingServiceJson['name'] ?? '',
          'description': matchingServiceJson['description'],
          'hourlyRate': matchingServiceJson['hourlyRate'],
        }),
      ];
    }

    Map<String, dynamic>? businessAddressJson =
    providerJson['businessAddress'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(providerJson['businessAddress'])
        : providerJson['serviceArea'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(providerJson['serviceArea'])
        : null;
    if (_isAddressEmpty(businessAddressJson)) {
      final serviceAreas = providerJson['serviceAreas'];
      if (serviceAreas is List && serviceAreas.isNotEmpty) {
        final firstArea = serviceAreas.first;
        if (firstArea is Map<String, dynamic>) {
          businessAddressJson = Map<String, dynamic>.from(firstArea);
        }
      }
    }

    return SearchProvider(
      id: providerJson['_id'] ?? providerJson['id'] ?? '',
      firstName: providerJson['firstName'] ?? '',
      lastName: providerJson['lastName'] ?? '',
      phone: providerJson['phone'],
      businessNameRegistered:
      providerJson['businessNameRegistered'] ?? providerJson['businessName'] ?? '',
      rating: providerJson['rating'] != null
          ? (providerJson['rating'] as num).toDouble()
          : null,
      totalReviews: providerJson['totalReviews'] ?? providerJson['reviewsCount'],
      isAvailable: providerJson['isAvailable'],
      profileImage: providerJson['profileImage'] != null
          ? ProfileImage.fromJson(providerJson['profileImage'])
          : null,
      businessLogo: providerJson['businessLogo'] != null
          ? BusinessLogo.fromJson(providerJson['businessLogo'])
          : null,
      businessAddress: businessAddressJson != null
          ? BusinessAddress.fromJson(businessAddressJson)
          : null,
      servicesProvided: services,
    );
  }

  String get displayName {
    if (businessNameRegistered.isNotEmpty) {
      return businessNameRegistered;
    }
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : 'Unknown Provider';
  }

  String get locationDisplay {
    if (businessAddress != null) {
      final city = businessAddress!.city.trim();
      final state = businessAddress!.state.trim();
      final zip = businessAddress!.zipCode.trim();
      if (city.isNotEmpty && state.isNotEmpty) {
        return '$city, $state';
      }
      if (city.isNotEmpty) return city;
      if (state.isNotEmpty) return state;
      if (zip.isNotEmpty) return zip;
    }
    return 'Location not specified';
  }

  static bool _isAddressEmpty(Map<String, dynamic>? address) {
    if (address == null) return true;
    final city = address['city']?.toString().trim() ?? '';
    final state = address['state']?.toString().trim() ?? '';
    final zip = address['zipCode']?.toString().trim() ?? '';
    return city.isEmpty && state.isEmpty && zip.isEmpty;
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
      id: json['_id'] ?? json['providerServiceId'] ?? '',
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
    super.key,
    required this.serviceName,
    required this.zipCode,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxList<SearchProvider> _providers = <SearchProvider>[].obs;
  final RxList<SearchProvider> _allProviders = <SearchProvider>[].obs;
  final RxList<RelatedService> _relatedServices = <RelatedService>[].obs;
  final Rx<SearchCriteria?> _searchCriteria = Rx<SearchCriteria?>(null);
  final Rx<SearchStats?> _stats = Rx<SearchStats?>(null);
  final Rx<PaginationInfo?> _pagination = Rx<PaginationInfo?>(null);
  final RxBool _isLoading = true.obs;
  final RxString _error = ''.obs;
  final RxString _apiMessage = ''.obs;
  final RxBool _showDebugInfo = false.obs;
  final RxBool _showFilters = false.obs;

  // Price range filter
  final Rx<RangeValues> _priceRange = const RangeValues(10, 150).obs;
  final RxDouble _averageRate = 56.78.obs;
  final RxString _selectedCategory = 'All'.obs;

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
        _allProviders.assignAll(
          providersData.map((p) => SearchProvider.fromJson(p)).toList(),
        );

        // Calculate average rate
        _calculateAverageRate();

        // Apply initial filter
        _applyPriceFilter();

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

        if (_allProviders.isEmpty) {
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

  void _calculateAverageRate() {
    final rates = <double>[];
    for (final provider in _allProviders) {
      for (final service in provider.servicesProvided) {
        if (service.hourlyRate != null) {
          rates.add(service.hourlyRate!);
        }
      }
    }
    if (rates.isNotEmpty) {
      _averageRate.value = rates.reduce((a, b) => a + b) / rates.length;
    }
  }

  void _applyPriceFilter() {
    _providers.assignAll(
      _allProviders.where((provider) {
        // Check if any service falls within the price range
        for (final service in provider.servicesProvided) {
          if (service.hourlyRate != null) {
            if (service.hourlyRate! >= _priceRange.value.start &&
                service.hourlyRate! <= _priceRange.value.end) {
              return true;
            }
          }
        }
        // If no hourly rate, include by default
        return provider.servicesProvided.isEmpty ||
            provider.servicesProvided.every((s) => s.hourlyRate == null);
      }).toList(),
    );
  }

  List<double> _generateChartData() {
    // Generate distribution data for price range
    final List<double> chartData = List.filled(12, 0.0);
    final rangeSize = (150 - 10) / 12;

    for (final provider in _allProviders) {
      for (final service in provider.servicesProvided) {
        if (service.hourlyRate != null) {
          final rate = service.hourlyRate!;
          if (rate >= 10 && rate <= 150) {
            final index = ((rate - 10) / rangeSize).floor().clamp(0, 11);
            chartData[index] += 0.1;
          }
        }
      }
    }

    return chartData;
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
        ],
      ),
      backgroundColor: const Color(0xFFFAFAFA),
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

        if (_error.value.isNotEmpty && _allProviders.isEmpty) {
          return _buildNoResultsView();
        }

        return CustomScrollView(
          slivers: [
            // Search bar and filters
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.serviceName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.zipCode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0E7A60),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Price Range and Category filters
                    Row(
                      children: [
                        // Price Range button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              _showFilters.toggle();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Price Range',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E7A60),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Price Range Slider (collapsible)
                    if (_showFilters.value) ...[
                      const SizedBox(height: 20),
                      _buildPriceRangeSlider(),
                    ],
                  ],
                ),
              ),
            ),

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
              child: Container(
                color: Colors.white,
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

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
                child: Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 16),
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

  Widget _buildPriceRangeSlider() {
    final chartData = _generateChartData();
    final double maxValue = chartData.isNotEmpty ? chartData.reduce((a, b) => a > b ? a : b) : 1.0;

    return Obx(() => Column(
      children: [
        // Bar chart
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: chartData.map((value) {
              final double normalizedHeight = maxValue > 0 ? (value / maxValue) * 100 : 0;
              return Container(
                width: 18,
                height: normalizedHeight.clamp(2.0, 100.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFB4F4D3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF0E7A60),
            inactiveTrackColor: const Color(0xFF0E7A60).withOpacity(0.2),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF0E7A60).withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 2,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackHeight: 2,
          ),
          child: RangeSlider(
            values: _priceRange.value,
            min: 10,
            max: 150,
            onChanged: (RangeValues values) {
              _priceRange.value = values;
              _applyPriceFilter();
            },
          ),
        ),

        const SizedBox(height: 8),

        // Price labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_priceRange.value.start.round()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${_priceRange.value.end.round()}+',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Average rate
        Text(
          'avg. rate is \$${_averageRate.value.toStringAsFixed(2)}/hr',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    ));
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
    final logoUrl = provider.businessLogo?.url.trim() ?? '';
    final hasLogo = logoUrl.isNotEmpty;
    final initial = _getProviderInitial(provider);

    // Get the lowest rate from services
    double? lowestRate;
    double? highestRate;
    for (final service in provider.servicesProvided) {
      if (service.hourlyRate != null) {
        if (lowestRate == null || service.hourlyRate! < lowestRate) {
          lowestRate = service.hourlyRate;
        }
        if (highestRate == null || service.hourlyRate! > highestRate) {
          highestRate = service.hourlyRate;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Provider Details',
            'Opening ${provider.displayName}\'s profile',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider image
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: hasLogo
                      ? DecorationImage(
                    image: NetworkImage(logoUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: const Color(0xFFF5F5F5),
                ),
                child: !hasLogo
                    ? Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E7A60),
                    ),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 16),

              // Provider info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price range
                    if (lowestRate != null)
                      Text(
                        lowestRate == highestRate
                            ? 'Avg. price: \$${lowestRate.round()} - \$${highestRate!.round()}'
                            : 'Avg. price: \$${lowestRate.round()} - \$${(highestRate ?? lowestRate).round()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProviderInitial(SearchProvider provider) {
    final candidates = [
      provider.businessNameRegistered,
      provider.firstName,
      provider.lastName,
      provider.displayName,
    ];
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed[0].toUpperCase();
      }
    }
    return '?';
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

  // Debug info cards
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
            const Row(
              children: [
                Icon(Icons.pages, color: Colors.orange),
                SizedBox(width: 8),
                Text(
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
                    const Icon(Icons.info, color: Colors.blue, size: 16),
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

  @override
  void dispose() {
    super.dispose();
  }
}