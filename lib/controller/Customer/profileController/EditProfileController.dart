import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  // Update profile with form-data
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
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            profileImage.path,
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Get.back();
        Get.snackbar("Success", "Profile updated successfully");
      } else {
        Get.snackbar("Error", "Failed to update profile: ${response.statusCode}");
        print("Error response: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile: $e");
      print("Exception: $e");
    }
  }
}