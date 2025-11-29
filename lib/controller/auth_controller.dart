// controllers/auth_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_contants.dart';
import '../utils/tokenService.dart';
import '../utils/logger.dart';
import '../views/base/bottomNav/bottomNavWrapper.dart';
import 'networkService/networkService.dart';

class AuthController extends GetxController {
  // Common controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Customer signup controllers
  final TextEditingController firstname = TextEditingController();
  final TextEditingController lastname = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController streetName = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController zipCode = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController aptSuite = TextEditingController();

  // Provider signup controllers
  final TextEditingController businessName = TextEditingController();
  final TextEditingController providerRole = TextEditingController();
  final TextEditingController experience = TextEditingController();
  final TextEditingController serviceDescription = TextEditingController();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool passShowHide = false.obs;
  final RxBool showHide = false.obs;
  final RxBool showHide1 = false.obs;
  var privacy = false.obs;
  Rx<File?> profileImage = Rx<File?>(null);
  final RxString userRole = 'customer'.obs; // 'customer' or 'provider'

  void togglePasswordVisibility() {
    passShowHide.value = !passShowHide.value;
  }

  void passwordToggle() {
    showHide.value = !showHide.value;
  }

  void passwordToggle1() {
    showHide1.value = !showHide1.value;
  }

  void setUserRole(String role) {
    userRole.value = role;
  }

  // Login function for both customer and provider
  Future<void> loginUser(BuildContext context) async {
    final String url = '${AppConstants.BASE_URL}/api/auth/login';
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      showError(context, "Please connect to the internet!");
      return;
    }

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showError(context, "Please fill all fields");
      return;
    }

    isLoading.value = true;

    final body = {
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Logger.log("Response: ${response.body}", type: "info");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['data']['token'];
        final id = data['data']['user']['id'];
        final role = data['data']['user']['role'];

        print("Response: ${role} role");
        await TokenService().saveToken(token);
        await TokenService().saveUserId(id);
        await TokenService().saveUserRole(role); // Save user role
        print("Response: ${token} token");

        // Redirect both customer and provider to BottomMenuWrappers
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BottomMenuWrappers()),
                (Route<dynamic> route) => false
        );

        showSuccess(context, "Login Successful!");
      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Login failed. Please try again.";
        showError(context, message);
      }
    } catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\n$stackTrace", type: "error");
      showError(context, "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  // Customer Signup
  Future<void> signUpCustomer(BuildContext context) async {
    final String url = '${AppConstants.BASE_URL}/api/auth/register/customer';
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      showError(context, "Please connect to the internet!");
      return;
    }

    if (!_validateCustomerInputs()) {
      return;
    }

    isLoading.value = true;

    try {
      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll({
        'Accept': 'application/json',
      });

      request.fields.addAll({
        "firstName": firstname.text.trim(),
        "lastName": lastname.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "confirmPassword": confirmPasswordController.text,
        "phone": phoneNumber.text.trim(),
        "street": streetName.text.trim(),
        "city": city.text.trim(),
        "state": state.text.trim(),
        "zipCode": zipCode.text.trim(),
        "aptSuite": aptSuite.text.trim(),
      });

      if (profileImage.value != null) {
        final File compressedFile = await _compressImage(profileImage.value!, targetSizeKB: 100);
        request.files.add(await http.MultipartFile.fromPath(
          'profileImage',
          compressedFile.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final token = data['data']['token'];
        await TokenService().saveToken(token);
        await TokenService().saveUserRole('customer'); // Save customer role

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BottomMenuWrappers()),
                (Route<dynamic> route) => false
        );
        showSuccess(context, "Account created successfully!");
      } else {
        final data = jsonDecode(responseBody);
        final message = data["message"] ?? "Registration failed. Please try again.";
        showError(context, message);
      }
    } catch (e) {
      showError(context, "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  // Provider Signup
  Future<void> signUpProvider(BuildContext context) async {
    final String url = '${AppConstants.BASE_URL}/api/auth/register/provider';
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      showError(context, "Please connect to the internet!");
      return;
    }

    if (!_validateProviderInputs()) {
      return;
    }

    isLoading.value = true;

    try {
      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll({
        'Accept': 'application/json',
      });

      request.fields.addAll({
        "firstName": firstname.text.trim(),
        "lastName": lastname.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "confirmPassword": confirmPasswordController.text,
        "phone": phoneNumber.text.trim(),
        "businessName": businessName.text.trim(),
        "providerRole": providerRole.text.trim(),
        "experience": experience.text.trim(),
        "serviceDescription": serviceDescription.text.trim(),
        "street": streetName.text.trim(),
        "city": city.text.trim(),
        "state": state.text.trim(),
        "zipCode": zipCode.text.trim(),
        "aptSuite": aptSuite.text.trim(),
      });

      if (profileImage.value != null) {
        final File compressedFile = await _compressImage(profileImage.value!, targetSizeKB: 100);
        request.files.add(await http.MultipartFile.fromPath(
          'profileImage',
          compressedFile.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final token = data['data']['token'];
        await TokenService().saveToken(token);
        await TokenService().saveUserRole('provider'); // Save provider role

        // FIXED: Redirect to BottomMenuWrappers instead of ProviderProfilePage
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BottomMenuWrappers()),
                (Route<dynamic> route) => false
        );
        showSuccess(context, "Provider account created successfully!");
      } else {
        final data = jsonDecode(responseBody);
        final message = data["message"] ?? "Registration failed. Please try again.";
        showError(context, message);
      }
    } catch (e) {
      showError(context, "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateCustomerInputs() {
    if (firstname.text.isEmpty) {
      showError(Get.context!, "First name is required");
      return false;
    }
    if (lastname.text.isEmpty) {
      showError(Get.context!, "Last name is required");
      return false;
    }
    if (emailController.text.isEmpty) {
      showError(Get.context!, "Email is required");
      return false;
    }
    if (passwordController.text.isEmpty) {
      showError(Get.context!, "Password is required");
      return false;
    }
    if (confirmPasswordController.text.isEmpty) {
      showError(Get.context!, "Confirm password is required");
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showError(Get.context!, "Passwords do not match");
      return false;
    }
    if (phoneNumber.text.isEmpty) {
      showError(Get.context!, "Phone number is required");
      return false;
    }
    if (streetName.text.isEmpty) {
      showError(Get.context!, "Street address is required");
      return false;
    }
    if (city.text.isEmpty) {
      showError(Get.context!, "City is required");
      return false;
    }
    if (state.text.isEmpty) {
      showError(Get.context!, "State is required");
      return false;
    }
    if (zipCode.text.isEmpty) {
      showError(Get.context!, "Zip code is required");
      return false;
    }
    if (!privacy.value) {
      showError(Get.context!, "Please accept terms and conditions");
      return false;
    }
    return true;
  }

  bool _validateProviderInputs() {
    if (!_validateCustomerInputs()) return false;

    if (businessName.text.isEmpty) {
      showError(Get.context!, "Business name is required");
      return false;
    }
    if (providerRole.text.isEmpty) {
      showError(Get.context!, "Provider role is required");
      return false;
    }
    if (experience.text.isEmpty) {
      showError(Get.context!, "Experience is required");
      return false;
    }
    return true;
  }

  // Image compression methods
  Future<File> _compressImage(File file, {int targetSizeKB = 100}) async {
    int quality = 50;
    File? compressedFile;
    int maxSizeInBytes = targetSizeKB * 1024;

    do {
      final targetPath = file.path.replaceFirst(
        RegExp(r'\.(jpg|jpeg|png|webp|heic)$'),
        '_compressed_${quality}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        return file;
      }

      compressedFile = File(result.path);
      final fileSize = await compressedFile.length();

      if (fileSize <= maxSizeInBytes || quality <= 30) {
        return compressedFile;
      }

      if (quality > 70) {
        quality -= 10;
      } else if (quality > 50) {
        quality -= 5;
      } else {
        quality -= 2;
      }
    } while (true);
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File originalFile = File(pickedFile.path);
        File? croppedFile = await _cropImage(originalFile);
        if (croppedFile != null) {
          profileImage.value = await _compressImage(croppedFile, targetSizeKB: 100);
        }
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: "Crop Image",
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: "Crop Image")
        ],
      );
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void clearControllers() {
    firstname.clear();
    lastname.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    phoneNumber.clear();
    streetName.clear();
    state.clear();
    zipCode.clear();
    city.clear();
    aptSuite.clear();
    businessName.clear();
    providerRole.clear();
    experience.clear();
    serviceDescription.clear();
    profileImage.value = null;
    privacy.value = false;
  }

  @override
  void onClose() {
    firstname.dispose();
    lastname.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumber.dispose();
    streetName.dispose();
    state.dispose();
    zipCode.dispose();
    city.dispose();
    aptSuite.dispose();
    businessName.dispose();
    providerRole.dispose();
    experience.dispose();
    serviceDescription.dispose();
    super.onClose();
  }
}