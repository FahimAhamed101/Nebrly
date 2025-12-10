import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/provider/controllers/feedback_controller.dart';
import '../models/provider_profile.dart';
import '../models/service_request.dart';
import '../models/analytics.dart';
import '../models/client_feedback.dart';
import '../services/home_api_service.dart';
import '../services/analytics_service.dart';

class ProviderHomeController extends GetxController {
  final Rx<ProviderProfile> providerProfile = ProviderProfile.demo().obs;
  final RxList<ServiceRequest> activeRequests = <ServiceRequest>[].obs;
  final RxList<ServiceRequest> acceptedRequests = <ServiceRequest>[].obs;
  final Rx<Analytics> analytics = Analytics.demo().obs;
  final RxBool isLoadingAnalytics = false.obs;
  final RxString analyticsErrorMessage = ''.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // Get the FeedbackController instance
  FeedbackController get feedbackController => Get.find<FeedbackController>();

  // Getters for feedback data - use the feedback controller's data
  List<ClientFeedback> get clientFeedback => feedbackController.feedbackList;
  bool get hasMoreFeedback => feedbackController.hasMore.value;

  @override
  void onInit() {
    super.onInit();
    print('🚀 ProviderHomeController initialized');
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    try {
      // Set loading state
      isLoading.value = true;
      errorMessage.value = '';

      print('🔄 Starting to load all home data...');

      // Load multiple data sources in parallel with proper error handling
      final results = await Future.wait([
        _loadServiceRequests().catchError((e) {
          print('❌ Error in service requests: $e');
          return Future.value(); // Return empty future to continue
        }),
        _loadAnalyticsData().catchError((e) {
          print('❌ Error in analytics: $e');
          return Future.value(); // Return empty future to continue
        }),
        _loadFeedbackIfNeeded().catchError((e) {
          print('❌ Error in feedback: $e');
          return Future.value(); // Return empty future to continue
        }),
      ], eagerError: false);

      print('✅ All home data loaded successfully');

      // Check if any critical data failed to load
      if (activeRequests.isEmpty && acceptedRequests.isEmpty) {
        print('⚠️ No service requests loaded');
      }

      if (analytics.value.todayOrders == 0 && analytics.value.monthlyOrders == 0) {
        print('⚠️ No analytics data loaded (using demo)');
      }

    } catch (e, stackTrace) {
      errorMessage.value = 'Failed to load some data: ${e.toString()}';
      print('❌ Error loading home data: $e');
      print('📍 Stack trace: $stackTrace');

      // Show error snackbar
      Get.snackbar(
        'Error',
        'Failed to load some data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // ALWAYS set loading to false when done
      isLoading.value = false;
      print('🏁 Loading complete. isLoading = false');
    }
  }

  Future<void> _loadServiceRequests() async {
    try {
      print('🔄 Loading service requests...');

      final apiService = Get.find<HomeApiService>();
      final allRequests = await apiService.getServiceRequests();

      print('✅ API returned ${allRequests.length} total requests');

      if (allRequests.isEmpty) {
        print('⚠️ No service requests found in API response');
        // Clear existing requests
        activeRequests.clear();
        acceptedRequests.clear();
        return;
      }

      // Separate pending and accepted requests
      final pending = allRequests.where((r) => r.status == RequestStatus.pending).toList();
      final accepted = allRequests.where((r) => r.status == RequestStatus.accepted).toList();

      // Update observables
      activeRequests.assignAll(pending);
      acceptedRequests.assignAll(accepted);

      print('📊 Service Requests loaded:');
      print('   - Active (pending): ${pending.length}');
      print('   - Accepted: ${accepted.length}');

      // Log sample requests for debugging
      if (pending.isNotEmpty) {
        print('📋 Sample pending request: ${pending.first.id} - ${pending.first.serviceName}');
      }
      if (accepted.isNotEmpty) {
        print('📋 Sample accepted request: ${accepted.first.id} - ${accepted.first.serviceName}');
      }

    } catch (e) {
      print('❌ Error loading service requests: $e');
      // Clear lists on error
      activeRequests.clear();
      acceptedRequests.clear();
      rethrow;
    }
  }

  // In your ProviderHomeController, update _loadAnalyticsData method:
  Future<void> _loadAnalyticsData() async {
    try {
      isLoadingAnalytics.value = true;
      analyticsErrorMessage.value = '';

      print('🔄 Loading analytics data...');

      // Get the analytics service
      AnalyticsService analyticsService;
      try {
        analyticsService = Get.find<AnalyticsService>();
      } catch (e) {
        // If not registered, create and put it
        analyticsService = AnalyticsService();
        Get.put(analyticsService);
      }

      final apiAnalytics = await analyticsService.getProviderAnalytics();

      // Check if API returned all zeros
      if (apiAnalytics.todayOrders == 0 &&
          apiAnalytics.monthlyOrders == 0 &&
          apiAnalytics.todayEarnings == 0 &&
          apiAnalytics.monthlyEarnings == 0) {

        print('⚠️ Analytics API returned all zeros - using demo data instead');
        analytics.value = Analytics.demo();

        // Show info message to user
        Get.snackbar(
          'Info',
          'No analytics data yet. Showing demo data. Start accepting jobs to see your stats!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.blue[100],
          colorText: Colors.blue[800],
        );
      } else {
        // Update analytics observable with real data
        analytics.value = apiAnalytics;

        print('✅ Analytics loaded successfully');
        print('📊 Today: ${apiAnalytics.todayOrders} orders, \$${apiAnalytics.todayEarnings}');
        print('📊 Month: ${apiAnalytics.monthlyOrders} orders, \$${apiAnalytics.monthlyEarnings}');
      }

    } catch (e) {
      analyticsErrorMessage.value = 'Failed to load analytics: ${e.toString()}';
      print('❌ Error loading analytics: $e');

      // Use demo data if API fails
      analytics.value = Analytics.demo();
      print('🔄 Using demo analytics data');
    } finally {
      isLoadingAnalytics.value = false;
    }
  }

  Future<void> _loadFeedbackIfNeeded() async {
    try {
      // Load feedback if not already loading
      if (feedbackController.feedbackList.isEmpty && !feedbackController.isLoading.value) {
        print('🔄 Loading feedback...');
        await feedbackController.loadFeedback();
        print('✅ Feedback loaded successfully');
      } else {
        print('ℹ️ Feedback already loaded or loading');
      }
    } catch (e) {
      print('❌ Error loading feedback: $e');
      // Don't rethrow - feedback is not critical
    }
  }

  Future<void> refreshData() async {
    print('🔄 Refreshing all home data...');
    isLoading.value = true;
    await loadHomeData();
    print('✅ All data refreshed successfully');
  }

  void toggleFeedbackExpansion(String feedbackId) {
    feedbackController.toggleExpansion(feedbackId);
  }

  void loadMoreFeedback() {
    feedbackController.loadMoreFeedback();
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      print('🔄 Accepting request: $requestId');

      // Find the request in active requests
      final requestIndex = activeRequests.indexWhere((req) => req.id == requestId);
      if (requestIndex == -1) {
        throw Exception('Request not found: $requestId');
      }

      final request = activeRequests[requestIndex];

      // Call API to accept the request
      await Get.find<HomeApiService>().acceptRequest(requestId);

      // Create updated request with accepted status
      final updatedRequest = ServiceRequest(
        id: request.id,
        serviceType: request.serviceType,
        serviceName: request.serviceName,
        pricePerHour: request.pricePerHour,
        clientName: request.clientName,
        clientImage: request.clientImage,
        clientRating: request.clientRating,
        clientReviewCount: request.clientReviewCount,
        address: request.address,
        date: request.date,
        time: request.time,
        problemNote: request.problemNote,
        status: RequestStatus.accepted,
        isTeamService: request.isTeamService,
        teamMembers: request.teamMembers,
        bundleType: request.bundleType,
      );

      // Remove from active requests and add to accepted requests
      activeRequests.removeAt(requestIndex);
      acceptedRequests.insert(0, updatedRequest);

      print('✅ Request $requestId accepted successfully');
      print('📊 Active requests: ${activeRequests.length}');
      print('📊 Accepted requests: ${acceptedRequests.length}');

      // Show success message
      Get.snackbar(
        'Success',
        'Request accepted successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      errorMessage.value = 'Failed to accept request: ${e.toString()}';
      print('❌ Error accepting request: $e');

      Get.snackbar(
        'Error',
        'Failed to accept request: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      rethrow;
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      print('🔄 Cancelling request: $requestId');

      final requestIndex = activeRequests.indexWhere((req) => req.id == requestId);
      if (requestIndex == -1) {
        throw Exception('Request not found: $requestId');
      }

      // Call API to cancel the request
      await Get.find<HomeApiService>().cancelRequest(requestId);

      // Remove from local state
      activeRequests.removeAt(requestIndex);

      print('✅ Request $requestId cancelled successfully');
      print('📊 Active requests: ${activeRequests.length}');

      Get.snackbar(
        'Success',
        'Request declined successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      errorMessage.value = 'Failed to cancel request: ${e.toString()}';
      print('❌ Error cancelling request: $e');

      Get.snackbar(
        'Error',
        'Failed to decline request: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      rethrow;
    }
  }
}