import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/services/api_service.dart';

class SetNewPasswordController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  // Observable properties
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool showhide = true.obs;
  final RxBool showhideConfirm = true.obs;

  // Toggle password visibility
  void passwordToggle() {
    showhide.value = !showhide.value;
  }

  // Toggle confirm password visibility
  void confirmPasswordToggle() {
    showhideConfirm.value = !showhideConfirm.value;
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  // Reset password API call
  Future<void> resetPassword({
    required String email,
    required String password,
    required String confirmPassword,
    required VoidCallback onSuccess,
  }) async {
    // Clear any previous errors
    errorMessage.value = '';

    // Validation
    if (password.isEmpty || confirmPassword.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }

    if (password != confirmPassword) {
      errorMessage.value = 'Passwords do not match';
      return;
    }

    if (password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters';
      return;
    }

    // Check for password strength
    if (!_isPasswordStrong(password)) {
      errorMessage.value = 'Password must contain both letters and numbers';
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiService.post(
        'auth/password-reset/reset-password',
        {
          'email': email,
          'newPassword': password,
          'confirmPassword': confirmPassword,
        },
      );

      if (response['success'] == true) {
        // Success - call the callback
        onSuccess();
      } else {
        errorMessage.value = response['message'] ?? 'Failed to reset password';
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      errorMessage.value = 'Unable to reset password. Please try again.';
      Get.snackbar(
        'Error',
        'Network error. Please check your connection.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Reset password error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Check password strength
  bool _isPasswordStrong(String password) {
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasNumber;
  }

  @override
  void onClose() {
    clearError();
    showhide.value = true;
    showhideConfirm.value = true;
    super.onClose();
  }
}