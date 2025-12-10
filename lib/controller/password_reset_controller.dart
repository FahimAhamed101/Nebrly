// controllers/auth/password_reset_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/services/api_service.dart';

import '../views/screen/Users/auth/Otp_screen.dart';

class PasswordResetController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  Future<void> sendResetPasswordEmail(String email) async {
    if (email.isEmpty) {
      errorMessage.value = 'Please enter your email address';
      return;
    }

    if (!GetUtils.isEmail(email)) {
      errorMessage.value = 'Please enter a valid email address';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final response = await _apiService.post(
        'auth/password-reset/forgot-password',
        {
          'email': email,
        },
      );

      if (response['success'] == true) {
        successMessage.value = response['message'] ?? 'Reset password email sent successfully!';
        Get.snackbar(
          'Success',
          successMessage.value,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to OTP screen after successful email send
        Get.to(() => OtpScreen(email: email));
      } else {
        errorMessage.value = response['message'] ?? 'Failed to send reset password email';
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }
}