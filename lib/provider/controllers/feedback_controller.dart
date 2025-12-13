import 'package:get/get.dart';
import '../services/feedback_service.dart'; // Use the service
import '../models/client_feedback.dart';

class FeedbackController extends GetxController {
  final FeedbackService _feedbackService = Get.find<FeedbackService>();

  var feedbackList = <ClientFeedback>[].obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasMore = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadFeedback();
  }

  Future<void> loadFeedback({bool loadMore = false}) async {
    if (isLoading.value) return;

    if (!loadMore) {
      currentPage.value = 1;
      feedbackList.clear();
      errorMessage.value = '';
    }

    isLoading.value = true;

    try {
      final reviewsResponse = await _feedbackService.getMyReviews(
        page: currentPage.value,
        limit: 10,
      );

      if (loadMore) {
        feedbackList.addAll(reviewsResponse.reviews);
      } else {
        feedbackList.assignAll(reviewsResponse.reviews);
      }

      currentPage.value = reviewsResponse.currentPage;
      totalPages.value = reviewsResponse.totalPages;
      hasMore.value = currentPage.value < totalPages.value;
      errorMessage.value = '';

      print('✅ Successfully loaded ${reviewsResponse.reviews.length} reviews');
      print('📊 Total reviews: ${reviewsResponse.totalReviews}');
      print('⭐ Average rating: ${reviewsResponse.averageRating}');

    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Error loading feedback: $e');
      Get.snackbar(
        'Error',
        'Failed to load feedback: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void loadMoreFeedback() {
    if (hasMore.value && !isLoading.value) {
      currentPage.value++;
      loadFeedback(loadMore: true);
    }
  }

  void toggleExpansion(String feedbackId) {
    final index = feedbackList.indexWhere((feedback) => feedback.id == feedbackId);
    if (index != -1) {
      feedbackList[index].isExpanded = !feedbackList[index].isExpanded;
      feedbackList.refresh();
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}