import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:naibrly/utils/tokenService.dart';
import 'package:naibrly/views/base/bottomNav/bottomNavWrapper.dart';
import '../../../provider/provider_main.dart';
import '../../../provider/screens/profile/ProviderProfilePage.dart';
import '../../../utils/app_contants.dart';
import '../../../views/screen/Users/Home/home_screen.dart';
import '../../networkService/networkService.dart';

class SignUpController extends GetxController {
  final TextEditingController firstname = TextEditingController();
  final TextEditingController streetName = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController lastname = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController streetNumberName = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController zipCode = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController aptSuite = TextEditingController();
  RxBool isLoading = false.obs;
  final RxBool showHide = false.obs;
  final RxBool showHide1 = false.obs;
  var privacy = false.obs;
  void passwordToggle() {
    showHide.value = !showHide.value;
  }
  void passwordToggle1() {
    showHide1.value = !showHide1.value;
  }
  Future<File?> cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
          sourcePath: imageFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: "crop Image",
              toolbarColor: AppColors.black,
              toolbarWidgetColor: AppColors.White,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio5x3,
              ],
            ),
            IOSUiSettings(title: "Crop Image", aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio5x3,
            ])
          ]);
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<File> compressImage(File file, {int targetSizeKB = 100}) async {
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
        print("⚠️ Compression failed. Using original image.");
        return file;
      }

      compressedFile = File(result.path);
      final fileSize = await compressedFile.length();
      final sizeKB = fileSize / 1024;

      print("📦 Compressed size @ $quality% quality: ${sizeKB.toStringAsFixed(2)} KB");

      if (fileSize <= maxSizeInBytes || quality <= 30) {
        print("✅ Final compression size: ${sizeKB.toStringAsFixed(2)} KB");
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
  RxString base64CompressedImage = ''.obs;
  RxString studentAddPath = ''.obs;
  Rx<File?> frontLicenseFile = Rx<File?>(null);
  Rx<File?> backLicenseFile = Rx<File?>(null);
  Future<File?> pickAddImage(ImageSource source) async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return null;

    final extension = pickedFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      Get.snackbar(
        "Invalid Format",
        "Only JPG, JPEG, PNG files are allowed.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    File originalfile = File(pickedFile.path);
    int originalSize = await originalfile.length();
    print("Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB");

    File? croppedFile = await cropImage(originalfile);
    if (croppedFile == null) {
      print("Image cropping cancelled");
      return null;
    }

    int croppedSize = await croppedFile.length();
    print("Cropped image size: ${(croppedSize / 1024).toStringAsFixed(2)} KB");

    File compressedFile = await compressImage(croppedFile, targetSizeKB: 100);
    int compressedSize = await compressedFile.length();

    if (compressedSize > 100 * 1024) {
      Get.snackbar(
        "Image Too Large",
        "Could not compress image below 100KB. Please select a smaller image.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      return null;
    }

    final bytes = await compressedFile.readAsBytes();
    base64CompressedImage.value = base64Encode(bytes);
    studentAddPath.value = compressedFile.path;
    print("Final compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB");
    return compressedFile;
  }
  Rx<File?> profileImage = Rx<File?>(null);
  Future<void> pickProfileImage() async {
    try {
      final File? image = await pickAddImage(ImageSource.gallery);
      if (image != null) {
        profileImage.value = image;
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }
  Future<void> signUp(BuildContext context,{
    String? firstnames,
    String? lasnames,
    String? emails,
    String? passwords,
    String? confrimpasswords,
    String? phones,
    String? streets,
    String? states,
    String? zipcodes,
    String? citys,
    String? aptSuites,
  }) async {
    final String url = '${AppConstants.BASE_URL}/api/auth/register/customer';
    final networkController = Get.find<NetworkController>();
    if (!networkController.isOnline.value) {
      return ;
    }
    isLoading.value = true;

    try {
      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll({
        'Accept': 'application/json',
      });
      request.fields.addAll({
        "firstName": firstnames ?? '',
        "lastName": lasnames ?? "",
        "email": emails ?? '',
        "password": passwords ?? '',
        "confirmPassword": confrimpasswords ?? '',
        "phone": phones ?? '',
        "street": streets ?? '',
        "city": citys ?? '',
        "state": states ?? '',
        "zipCode": zipcodes ?? '',
        "aptSuite": aptSuites ?? '',
      });
      if (profileImage.value != null) {
        final File compressedFile = await compressImage(
          profileImage.value!,
          targetSizeKB: 100,
        );

        request.files.add(await http.MultipartFile.fromPath(
          'profileImage',
          compressedFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      }
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final token = data['data']['token'];
        TokenService().saveToken(token);

        final role = data['data']['user']['role'];
        await TokenService().saveUserRole(role);
        Navigator.push(context, MaterialPageRoute(builder: (context) => BottomMenuWrappers()),);
        await TokenService().saveToken(token);

        showSuccess(context,"Account created successfully!",);
        isLoading.value = false;
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
    }finally{
      isLoading.value = false;
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

  @override
  void onClose() {
    firstname.dispose();
    lastname.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    phoneNumber.dispose();
    streetName.dispose();
    state.dispose();
    zipCode.dispose();
    aptSuite.dispose();
    city.dispose();
    super.onClose();
  }
}