import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:naibrly/controller/Customer/profileController/profileController.dart';
import '../../../utils/app_contants.dart';
import '../../../utils/tokenService.dart';

class EditProfileController extends GetxController {
  Rx<File?> selectedImageEDT = Rx<File?>(null);
  RxString userProfileImageUrl = ''.obs;

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        selectedImageEDT.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image: $e");
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
    final BuildContext? context = Get.context;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${AppConstants.BASE_URL}/api/users/update-profile'),
      );

      // Add headers
      String? token = await TokenService().getToken();
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phone'] = phone;
      request.fields['street'] = street;
      request.fields['city'] = city;
      request.fields['state'] = state;
      request.fields['zipCode'] = zipCode;
      request.fields['aptSuite'] = aptSuite;

      // Add image file if selected
      if (profileImage != null && profileImage.existsSync()) {
        var multipartFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          filename: 'profile_${DateTime
              .now()
              .millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);



      if (response.statusCode == 200 || response.statusCode == 201) {
        // Close loading
        Navigator.of(context, rootNavigator: true).pop();

        // Navigate back
        Navigator.of(context).pop();
        Get.find<ProfileController>().fetchUserData();
        // Show simple toast using ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle error
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}