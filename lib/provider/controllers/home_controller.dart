import 'package:get/get.dart';
import 'package:naibrly/provider/controllers/feedback_controller.dart';
import '../models/provider_profile.dart';
import '../models/service_request.dart';
import '../models/analytics.dart';
import '../models/client_feedback.dart';
import '../services/home_api_service.dart';

class ProviderHomeController extends GetxController {
  final Rx<ProviderProfile> providerProfile = ProviderProfile.demo().obs;
  final RxList<ServiceRequest> activeRequests = <ServiceRequest>[].obs;
  final RxList<ServiceRequest> acceptedRequests = <ServiceRequest>[].obs;
  final Rx<Analytics> analytics = Analytics.demo().obs;

  // REMOVED: final RxList<ClientFeedback> clientFeedback = <ClientFeedback>[].obs;
  // This was causing the duplicate definition

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // REMOVED: final RxBool hasMoreFeedback = true.obs;
  // This was causing the "value" error since RxBool doesn't have a .value getter

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
      isLoading.value = true;
      errorMessage.value = '';

      // Load feedback if not already loading
      if (feedbackController.feedbackList.isEmpty && !feedbackController.isLoading.value) {
        feedbackController.loadFeedback();
      }

      print('🔄 Starting to load home data from API...');

      final apiService = Get.find<HomeApiService>();

      // Load ALL requests from API
      final allRequests = await apiService.getServiceRequests();

      print('✅ API returned ${allRequests.length} total requests');

      // Separate pending and accepted requests
      final pending = allRequests.where((r) => r.status == RequestStatus.pending).toList();
      final accepted = allRequests.where((r) => r.status == RequestStatus.accepted).toList();

      print('📊 Breakdown:');
      print('   - Pending (active): ${pending.length}');
      print('   - Accepted: ${accepted.length}');

      // Update observables
      activeRequests.assignAll(pending);
      acceptedRequests.assignAll(accepted);

      print('✅ Data loaded successfully:');
      print('   - activeRequests.length = ${activeRequests.length}');
      print('   - acceptedRequests.length = ${acceptedRequests.length}');

      if (pending.isEmpty) {
        print('ℹ️ No pending requests to display');
      } else {
        print('📋 Pending requests:');
        for (var req in pending) {
          print('   - ${req.serviceName} for ${req.clientName} on ${req.date}');
        }
      }

      if (accepted.isEmpty) {
        print('ℹ️ No accepted requests to display');
      } else {
        print('📋 Accepted requests:');
        for (var req in accepted) {
          print('   - ${req.serviceName} for ${req.clientName} on ${req.date}');
        }
      }

    } catch (e, stackTrace) {
      errorMessage.value = 'Failed to load data: ${e.toString()}';
      print('❌ Error loading home data: $e');
      print('📍 Stack trace: $stackTrace');

      // Show error snackbar
      Get.snackbar(
        'Error',
        'Failed to load requests: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      print('✅ Loading complete. isLoading = false');
    }
  }

  Future<void> refreshData() async {
    await Future.wait([
      loadHomeData(),
      feedbackController.loadFeedback(),
    ]);
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