import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model_provider.dart' show UserModel;
import '../services/profile_api_service.dart';

class UpdateprofileController extends GetxController {
  final ProfileApiService _apiService = Get.find<ProfileApiService>();
  final ImagePicker _picker = ImagePicker();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isRefreshing = false.obs;
  final Rx<File?> businessLogo = Rx<File?>(null);
  final RxBool isUpdating = false.obs;

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
      // Debug print to see what data is loaded
      print('Loaded user: ${user.value?.firstName} ${user.value?.lastName}');
      print('Business name: ${user.value?.businessNameRegistered}');
      print('Services count: ${user.value?.servicesProvided.length}');
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

  Future<void> pickBusinessLogo() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > 3) {
          Get.snackbar(
            'File Too Large',
            'Please select an image smaller than 3 MB',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        businessLogo.value = file;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> updateProviderProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String businessNameRegistered,
    required String description,
    required String experience,
    required String maxBundleCapacity,
    List<Map<String, dynamic>>? servicesToRemove,
    List<Map<String, dynamic>>? servicesToUpdate,
    List<Map<String, dynamic>>? servicesToAdd,
  }) async {
    try {
      isUpdating.value = true;
      error.value = '';

      final success = await _apiService.updateProviderProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        businessNameRegistered: businessNameRegistered,
        description: description,
        experience: experience,
        maxBundleCapacity: maxBundleCapacity,
        servicesToRemove: servicesToRemove,
        servicesToUpdate: servicesToUpdate,
        servicesToAdd: servicesToAdd,
        businessLogo: businessLogo.value,
      );

      if (success) {
        // Clear the picked file after successful upload
        businessLogo.value = null;
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
      isUpdating.value = false;
    }
  }

  // Helper getters
  String get businessName => user.value?.businessNameRegistered ?? 'Loading...';
  String get userEmail => user.value?.email ?? '';
  double get availableBalance => user.value?.availableBalance ?? 0.0;
  double get pendingPayout => user.value?.pendingPayout ?? 0.0;
  bool get canWithdraw => user.value?.hasPayoutSetup == true && availableBalance > 0;
  bool get isUserOnline => user.value?.isAvailable ?? false;
}