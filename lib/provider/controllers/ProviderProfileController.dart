// controllers/profile_controller.dart
import 'package:get/get.dart';


import '../../models/user_model_provider.dart' show UserModel;
import '../services/profile_api_service.dart';

class ProviderProfileController extends GetxController {
  final ProfileApiService _apiService = Get.find<ProfileApiService>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isRefreshing = false.obs;

  @override
  void onInit() {
    fetchProfile();
    super.onInit();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      error.value = '';
      final userData = await _apiService.getProfile();
      user.value = userData;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshProfile() async {
    isRefreshing.value = true;
    await fetchProfile();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final success = await _apiService.updateProfile(data);
      if (success) {
        await fetchProfile(); // Refresh profile data
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return true;
      }
      return false;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Helper getters for common data
  String get businessName => user.value?.businessNameRegistered ?? 'Loading...';
  String get userEmail => user.value?.email ?? '';
  double get availableBalance => user.value?.availableBalance ?? 0.0;
  double get pendingPayout => user.value?.pendingPayout ?? 0.0;
  bool get canWithdraw => user.value?.hasPayoutSetup == true && availableBalance > 0;
}