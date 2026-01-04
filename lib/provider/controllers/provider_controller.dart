import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/tokenService.dart';
import '../models/provider_model.dart';
import '../services/api_service.dart';

class ProviderController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final TokenService _tokenService = Get.find<TokenService>();
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var registrationSuccess = false.obs;

  // File paths for images - only businessLogo remains
  var businessLogoPath = ''.obs;

  // Form data
  var firstName = ''.obs;
  var lastName = ''.obs;
  var email = ''.obs;
  var password = ''.obs;
  var confirmPassword = ''.obs;
  var phone = ''.obs;
  var businessNameRegistered = ''.obs;
  var businessNameDBA = ''.obs;
  var providerRole = ''.obs;
  var businessPhone = ''.obs;
  var website = ''.obs;
  var servicesProvided = ''.obs;
  var businessServiceStart = ''.obs;
  var businessServiceEnd = ''.obs;
  var businessHoursStart = ''.obs;
  var businessHoursEnd = ''.obs;
  var hourlyRate = ''.obs;
  var businessAddressStreet = ''.obs;
  var businessAddressCity = ''.obs;
  var businessAddressState = ''.obs;
  var businessAddressZipCode = ''.obs;
  var experience = ''.obs;

  // Set business logo only
  void setBusinessLogo(String path) {
    businessLogoPath.value = path;
  }

  // Register provider
  Future<void> registerProvider() async {
    try {
      isLoading(true);
      errorMessage('');

      // Validate required fields
      if (!_validateForm()) {
        isLoading(false);
        return;
      }

      final request = ProviderRegisterRequest(
        firstName: firstName.value,
        lastName: lastName.value,
        email: email.value,
        password: password.value,
        confirmPassword: confirmPassword.value,
        phone: phone.value,
        businessNameRegistered: businessNameRegistered.value,
        businessNameDBA: businessNameDBA.value,
        providerRole: providerRole.value,
        businessPhone: businessPhone.value,
        website: website.value,
        servicesProvided: servicesProvided.value,
        businessServiceStart: businessServiceStart.value,
        businessServiceEnd: businessServiceEnd.value,
        businessHoursStart: businessHoursStart.value,
        businessHoursEnd: businessHoursEnd.value,
        hourlyRate: hourlyRate.value,
        businessAddressStreet: businessAddressStreet.value,
        businessAddressCity: businessAddressCity.value,
        businessAddressState: businessAddressState.value,
        businessAddressZipCode: businessAddressZipCode.value,
        experience: experience.value,
      );

      final response = await _apiService.registerProvider(
        request,
        businessLogoPath: businessLogoPath.value,
      );

      if (response.success) {
        registrationSuccess(true);

        // Debug print to see the full response
        print('Full response data: ${response.data}');

        // Save the token to TokenService - FIXED
        if (response.token != null && response.token!.isNotEmpty) {
          await _tokenService.saveToken(response.token!);
          print('Token saved successfully: ${response.token}');
        } else {
          print('No token found in response');
        }

        // Save user ID if available - FIXED
        if (response.userId != null && response.userId!.isNotEmpty) {
          await _tokenService.saveUserId(response.userId!);
          print('User ID saved: ${response.userId}');
        } else {
          print('No user ID found in response');
        }

        // Verify token was saved
        final savedToken = _tokenService.getToken();
        final savedUserId = _tokenService.getUserId();
        print('Verified - Stored Token: $savedToken');
        print('Verified - Stored User ID: $savedUserId');

        Get.snackbar(
          'Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        errorMessage(response.message);
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage('Registration failed: $e');
      Get.snackbar(
        'Error',
        'Registration failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  bool _validateForm() {
    if (firstName.value.isEmpty ||
        lastName.value.isEmpty ||
        email.value.isEmpty ||
        password.value.isEmpty ||
        confirmPassword.value.isEmpty ||
        phone.value.isEmpty ||
        businessNameRegistered.value.isEmpty ||
        businessNameDBA.value.isEmpty ||
        providerRole.value.isEmpty ||
        businessPhone.value.isEmpty ||
        servicesProvided.value.isEmpty) {
      errorMessage('Please fill all required fields');
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (password.value != confirmPassword.value) {
      errorMessage('Passwords do not match');
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!email.value.contains('@')) {
      errorMessage('Please enter a valid email');
      Get.snackbar(
        'Error',
        'Please enter a valid email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // Clear all data
  void clearData() {
    firstName('');
    lastName('');
    email('');
    password('');
    confirmPassword('');
    phone('');
    businessNameRegistered('');
    businessNameDBA('');
    providerRole('');
    businessPhone('');
    website('');
    servicesProvided('');
    businessServiceStart('');
    businessServiceEnd('');
    businessHoursStart('');
    businessHoursEnd('');
    hourlyRate('');
    businessAddressStreet('');
    businessAddressCity('');
    businessAddressState('');
    businessAddressZipCode('');
    experience('');
    businessLogoPath('');
    errorMessage('');
    registrationSuccess(false);
  }
}