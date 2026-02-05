import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:naibrly/controller/Customer/profileController/profileController.dart';
import 'package:http_parser/http_parser.dart'; // Add this import
import '../../../utils/app_contants.dart';
import '../../../utils/tokenService.dart';

class EditProfileController extends GetxController {
  Rx<File?> selectedImageEDT = Rx<File?>(null);
  RxString userProfileImageUrl = ''.obs;
  RxBool isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        selectedImageEDT.value = File(pickedFile.path);
        print("✅ Image selected: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Image pick error: $e");
      Get.snackbar("Error", "Failed to pick image");
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String aptSuite,
    File? profileImage,
  }) async {
    // Prevent multiple clicks
    if (isLoading.value) return;
    isLoading.value = true;

    print("🚀 Starting profile update...");

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Get token
      String? token = await TokenService().getToken();
      if (token == null || token.isEmpty) {
        Get.back();
        Get.snackbar("Error", "Authentication failed");
        isLoading.value = false;
        return;
      }

      print("📤 URL: ${AppConstants.BASE_URL}/api/users/update-profile");
      print("🔑 Token: ${token.substring(0, 20)}...");

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${AppConstants.BASE_URL}/api/users/update-profile'),
      );

      // CRITICAL: Add headers - DON'T set Content-Type manually for multipart
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      // DO NOT SET: request.headers['Content-Type'] - it's set automatically

      // Add text fields - EXACTLY as in Postman (lowercase)
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phone'] = phone;
      request.fields['street'] = street;
      request.fields['city'] = city;
      request.fields['state'] = state;
      request.fields['zipCode'] = zipCode;
      request.fields['aptSuite'] = aptSuite;

      print("📝 Fields added:");
      request.fields.forEach((key, value) {
        print("   $key: $value");
      });

      // Add image file if selected
      if (profileImage != null && await profileImage.exists()) {
        print("🖼️ Preparing image file...");
        print("   Path: ${profileImage.path}");

        final fileSize = await profileImage.length();
        print("   Size: ${(fileSize / 1024).toStringAsFixed(2)} KB");

        // Determine MIME type based on file extension
        String mimeType = 'image/jpeg';
        String extension = profileImage.path.split('.').last.toLowerCase();

        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'jpg' || extension == 'jpeg') {
          mimeType = 'image/jpeg';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        }

        print("   MIME Type: $mimeType");

        // Create multipart file with explicit MIME type
        var multipartFile = await http.MultipartFile.fromPath(
          'profileImage', // MUST match Postman field name
          profileImage.path,
          contentType: MediaType.parse(mimeType),
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$extension',
        );

        request.files.add(multipartFile);
        print("✅ Image file added to request");
        print("   Field name: profileImage");
        print("   Filename: ${multipartFile.filename}");
      } else if (profileImage != null) {
        print("⚠️ Image file doesn't exist at: ${profileImage.path}");
      } else {
        print("📷 No image selected for upload");
      }

      print("\n🔍 Final request summary:");
      print("   Method: ${request.method}");
      print("   URL: ${request.url}");
      print("   Headers: ${request.headers}");
      print("   Fields: ${request.fields.length}");
      print("   Files: ${request.files.length}");

      // Send request with timeout
      print("\n📡 Sending request...");
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("Request timeout after 30 seconds");
        },
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      print("\n📨 Response received!");
      print("   Status: ${response.statusCode}");
      print("   Headers: ${response.headers}");

      // Log response body safely
      if (response.body.isNotEmpty) {
        try {
          // Try to pretty print JSON
          final jsonResponse = json.decode(response.body);
          print("   Body: ${JsonEncoder.withIndent('  ').convert(jsonResponse)}");
        } catch (_) {
          // If not JSON, print as-is
          String preview = response.body.length > 500
              ? "${response.body.substring(0, 500)}..."
              : response.body;
          print("   Body: $preview");
        }
      } else {
        print("   Body: (empty)");
      }

      // Close loading
      Get.back();
      isLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);
          print("\n✅ Parsing success response...");

          // Check for success indicator
          bool success = jsonResponse['success'] == true ||
              jsonResponse['status'] == 'success' ||
              jsonResponse['user'] != null;

          String message = jsonResponse['message'] ??
              jsonResponse['msg'] ??
              "Profile updated successfully";

          if (success) {
            print("✅ Update successful!");

            // Refresh profile data
            await Get.find<ProfileController>().fetchUserData();

            // Clear selected image
            selectedImageEDT.value = null;

            // Show success message
            Get.snackbar(
              "Success!",
              message,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: 2),
            );

            // Navigate back
            await Future.delayed(Duration(milliseconds: 1500));
            Get.back();
          } else {
            // Success status code but success:false in body
            String errorMsg = jsonResponse['message'] ??
                jsonResponse['error']?.toString() ??
                "Update failed";
            print("⚠️ Success status but failure response: $errorMsg");
            Get.snackbar("Error", errorMsg);
          }
        } catch (e) {
          print("⚠️ JSON parse error: $e");
          // Assume success for 2xx even if JSON parsing fails
          await Get.find<ProfileController>().fetchUserData();
          selectedImageEDT.value = null;
          Get.snackbar(
            "Success!",
            "Profile updated",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          await Future.delayed(Duration(milliseconds: 1500));
          Get.back();
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        print("❌ Validation error (422)");
        try {
          final errorJson = json.decode(response.body);
          String errorMsg = "Validation error";

          if (errorJson['errors'] != null) {
            errorMsg = "";
            if (errorJson['errors'] is Map) {
              errorJson['errors'].forEach((key, value) {
                if (value is List) {
                  errorMsg += "${value.join(', ')}\n";
                } else {
                  errorMsg += "$value\n";
                }
              });
            } else {
              errorMsg = errorJson['errors'].toString();
            }
          } else if (errorJson['message'] != null) {
            errorMsg = errorJson['message'];
          }

          Get.snackbar("Validation Error", errorMsg.trim());
        } catch (_) {
          Get.snackbar("Error", "Validation failed");
        }
      } else if (response.statusCode == 401) {
        print("❌ Unauthorized (401)");
        Get.snackbar("Unauthorized", "Please login again");
      } else if (response.statusCode == 413) {
        print("❌ File too large (413)");
        Get.snackbar("Error", "Image file too large. Please choose a smaller image.");
      } else {
        // Other errors
        print("❌ Server error (${response.statusCode})");
        String errorMsg = "Server error (${response.statusCode})";

        try {
          final errorJson = json.decode(response.body);
          errorMsg = errorJson['message'] ??
              errorJson['error']?.toString() ??
              errorMsg;
        } catch (_) {
          if (response.body.isNotEmpty && response.body.length < 200) {
            errorMsg = response.body;
          }
        }

        Get.snackbar("Error", errorMsg);
      }
    } on TimeoutException catch (e) {
      Get.back();
      isLoading.value = false;
      print("⏰ Timeout: $e");
      Get.snackbar(
        "Timeout",
        "Request took too long. Check your connection.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } on SocketException catch (e) {
      Get.back();
      isLoading.value = false;
      print("🌐 Network error: $e");
      Get.snackbar(
        "Network Error",
        "Check your internet connection",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      Get.back();
      isLoading.value = false;
      print("🔥 Unexpected error: $e");
      print("📝 Stack trace:");
      print(stackTrace);
      Get.snackbar(
        "Error",
        "Failed to update: ${e.toString().split('\n').first}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}