// controllers/verifyController/verifyController.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/services/api_service.dart';

class VerifyController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxInt start = 60.obs;
  final RxBool isVerifying = false.obs;
  final RxBool isResending = false.obs;
  Timer? _timer;

  // Start the countdown timer
  void startTimer() {
    start.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (start.value > 0) {
        start.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // Dispose timer when not needed
  void disposeTimer() {
    _timer?.cancel();
  }

  // Resend OTP function
  Future<void> resendOtp(String email) async {
    if (isResending.value) return;

    try {
      isResending.value = true;

      final response = await _apiService.post(
        'auth/password-reset/forgot-password',
        {
          'email': email,
        },
      );

      if (response['success'] == true) {
        startTimer(); // Restart timer
        Get.snackbar(
          'Success',
          'OTP has been resent to your email',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to resend OTP',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend OTP: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isResending.value = false;
    }
  }

  // Verify OTP function
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (isVerifying.value) return false;

    try {
      isVerifying.value = true;

      final response = await _apiService.post(
        'auth/password-reset/verify-otp',
        {
          'email': email,
          'otp': otp,
        },
      );

      if (response['success'] == true) {
        Get.snackbar(
          'Success',
          response['message'] ?? 'OTP verified successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Invalid OTP code',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Verification failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isVerifying.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}