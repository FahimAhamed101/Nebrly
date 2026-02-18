// controllers/request_controller.dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:naibrly/models/user_request1.dart';
import 'package:naibrly/utils/enums.dart';
import '../../services/api_service.dart';
import '../../utils/tokenService.dart';

class RequestController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();
  final TokenService _tokenService = TokenService();

  final RxList<UserRequest> allRequests = <UserRequest>[].obs;
  final RxList<UserRequest> filteredRequests = <UserRequest>[].obs;
  final Rx<RequestFilter> currentFilter = RequestFilter.open.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMore = true.obs;
  final RxBool bundlesLoaded = false.obs;
  final RxString userRole = 'customer'.obs;

  @override
  void onInit() {
    super.onInit();

    // Delay loading to ensure token is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initUserRole();
      if (await _hasAuthToken()) {
        await loadRequests();
      }
    });
  }

  Future<void> _initUserRole() async {
    await _tokenService.init();
    final token = _tokenService.getToken();
    final role = _tokenService.getUserRole();
    if (token == null || token.isEmpty) {
      userRole.value = '';
      print('RequestController initialized with no token');
      return;
    }
    userRole.value = role ?? 'customer';
    print('RequestController initialized for: ${userRole.value}');
  }

  Future<bool> _hasAuthToken() async {
    await _tokenService.init();
    final token = _tokenService.getToken();
    return token != null && token.isNotEmpty;
  }

  void changeFilter(RequestFilter filter) {
    currentFilter.value = filter;
    _filterRequests();
  }

  // Get the appropriate API endpoint based on user role
  String get _apiEndpoint {
    return userRole.value == 'provider'
        ? 'service-requests/provider/my-requests'
        : 'service-requests/customer/my-all-requests';
  }

  Future<void> loadRequests({bool loadMore = false}) async {
    if (isLoading.value) return;

    if (!await _hasAuthToken()) {
      errorMessage.value = 'Please log in to view requests';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (!loadMore) {
        currentPage.value = 1;
        allRequests.clear();
        bundlesLoaded.value = false;
      }

      print("🎯 Loading requests for role: ${userRole.value}");
      print("🌐 Using API endpoint: $_apiEndpoint");
      print("📄 Current page: ${currentPage.value}");

      final response = await _apiService.get(
        _apiEndpoint,
        queryParams: {'page': currentPage.value.toString()},
      );

      print("✅ API Response received:");
      print("==============================");
      print("Response status: ${response['success']}");
      print("Response message: ${response['message']}");
      print("Response code: ${response['code']}");

      if (response['data'] != null) {
        print("📊 Data structure keys: ${response['data'].keys.toList()}");

        if (response['data']['serviceRequests'] != null) {
          print("🛠️ Service Requests found:");
          print("  Items count: ${response['data']['serviceRequests']['items']?.length ?? 0}");
          print("  Pagination: ${response['data']['serviceRequests']['pagination']}");

          if (response['data']['serviceRequests']['items'] != null) {
            final items = response['data']['serviceRequests']['items'];
            print("  First item sample: ${items.isNotEmpty ? items[0] : 'No items'}");
          }
        }

        if (response['data']['bundles'] != null) {
          print("📦 Bundles found:");
          print("  Items count: ${response['data']['bundles']['items']?.length ?? 0}");

          if (response['data']['bundles']['items'] != null) {
            final bundleItems = response['data']['bundles']['items'];
            print("  First bundle sample: ${bundleItems.isNotEmpty ? bundleItems[0] : 'No bundles'}");
          }
        }
      } else {
        print("⚠️ No data in response");
      }
      print("==============================");

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Parse service requests
        if (data['serviceRequests'] != null && data['serviceRequests']['items'] != null) {
          final List<dynamic> items = data['serviceRequests']['items'];
          final List<UserRequest> newRequests = [];

          print("🔍 Parsing ${items.length} service requests...");

          for (var i = 0; i < items.length; i++) {
            try {
              print("  Parsing item $i: ${items[i]['_id'] ?? 'No ID'}");
              final request = UserRequest.fromJson(items[i]);
              newRequests.add(request);
            } catch (e) {
              print('❌ Error parsing service request $i: $e');
              print('  Item data: ${items[i]}');
            }
          }

          if (loadMore) {
            allRequests.addAll(newRequests);
            print("➕ Added ${newRequests.length} requests (load more)");
          } else {
            allRequests.assignAll(newRequests);
            print("🔄 Assigned ${newRequests.length} requests (fresh load)");
          }

          if (data['serviceRequests']['pagination'] != null) {
            final pagination = data['serviceRequests']['pagination'];
            print("📄 Pagination info:");
            print("  Current: ${pagination['current']}");
            print("  Pages: ${pagination['pages']}");
            print("  Total: ${pagination['total']}");

            currentPage.value = pagination['current'] ?? currentPage.value;
            totalPages.value = pagination['pages'] ?? totalPages.value;
            hasMore.value = currentPage.value < totalPages.value;

            print("  Has more: $hasMore");
          }
        }

        // Parse bundles for BOTH customers and providers on first load
        // FIXED: Removed the role check that was preventing providers from seeing bundles
        if (!bundlesLoaded.value &&
            data['bundles'] != null &&
            data['bundles']['items'] != null) {

          final List<dynamic> bundleItems = data['bundles']['items'];
          final List<UserRequest> bundleRequests = [];

          print("🎁 Parsing ${bundleItems.length} bundles for ${userRole.value}...");

          for (var i = 0; i < bundleItems.length; i++) {
            try {
              print("  Parsing bundle $i: ${bundleItems[i]['_id'] ?? 'No ID'}");
              final bundleRequest = UserRequest.fromBundleJson(bundleItems[i]);
              bundleRequests.add(bundleRequest);
            } catch (e) {
              print('❌ Error parsing bundle $i: $e');
              print('  Bundle data: ${bundleItems[i]}');
            }
          }

          allRequests.addAll(bundleRequests);
          bundlesLoaded.value = true;
          print("📦 Added ${bundleRequests.length} bundles for ${userRole.value}");
        }

        // Sort all requests by creation date (newest first)
        allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print("📊 Total requests after sorting: ${allRequests.length}");

        _filterRequests();
        print("🎯 Filtered requests: ${filteredRequests.length}");

        if (loadMore) {
          currentPage.value++;
          print("📈 Incremented page to: ${currentPage.value}");
        }

        print("✅ Load requests completed successfully!");

      } else {
        errorMessage.value = response['message'] ?? 'Failed to load requests';
        print("❌ API Error: ${errorMessage.value}");
        print("   Full error response: $response");
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Exception loading requests: $e');
    } finally {
      isLoading.value = false;
      print("🏁 Loading finished. isLoading: ${isLoading.value}");
    }
  }

  void _filterRequests() {
    filteredRequests.clear();
    if (currentFilter.value == RequestFilter.open) {
      filteredRequests.addAll(allRequests.where((r) => r.isOpen));
    } else {
      filteredRequests.addAll(allRequests.where((r) => r.isClosed));
    }
  }

  int get openCount {
    return allRequests.where((r) => r.isOpen).length;
  }

  int get closedCount {
    return allRequests.where((r) => r.isClosed).length;
  }

  int get totalRequests {
    return allRequests.length;
  }

  String get roleDisplayInfo {
    return userRole.value == 'provider'
        ? 'Service Provider Dashboard'
        : 'My Requests & Bundles';
  }

  bool canCancelRequest(UserRequest request) {
    return userRole.value == 'customer' && request.isOpen;
  }

  bool canAcceptRequest(UserRequest request) {
    return userRole.value == 'provider' && request.isOpen;
  }

  bool canCompleteRequest(UserRequest request) {
    return userRole.value == 'provider' && request.isOpen;
  }

  Future<void> refreshRequests() async {
    await _initUserRole();
    currentPage.value = 1;
    bundlesLoaded.value = false;
    await loadRequests();
  }

  Future<void> loadMore() async {
    if (hasMore.value && !isLoading.value) {
      await loadRequests(loadMore: true);
    }
  }

  Future<void> updateUserRole(String newRole) async {
    userRole.value = newRole;
    currentPage.value = 1;
    allRequests.clear();
    bundlesLoaded.value = false;
    await loadRequests();
  }
}

