
import 'dart:convert';
import 'package:http/http.dart'as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/provider/provider_main.dart';
import 'package:naibrly/provider/screens/profile/ProviderProfilePage.dart';
import 'package:naibrly/utils/logger.dart';
import 'package:naibrly/views/screen/Users/Home/home_screen.dart';

import '../../../utils/app_contants.dart';
import '../../../utils/tokenService.dart';
import '../../../views/base/bottomNav/bottomNavWrapper.dart';
import '../../networkService/networkService.dart';
class LoginController extends GetxController{
  RxBool passShowHide = false.obs;
  void toggle(){
    passShowHide.value = ! passShowHide.value;
  }
}
class SignInController extends GetxController{
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final RxBool isLoading = false.obs;
  RxBool passShowHide = false.obs;
  void toggle() {
    passShowHide.value = !passShowHide.value;
  }

  Future<void> loginUser(
      BuildContext context,
      String emails,
      String password,
      ) async {
    final String url = '${AppConstants.BASE_URL}/api/auth/login';
    final networkController = Get.find<NetworkController>();
    if (!networkController.isOnline.value) {
      showError(context, "Please connect to the internet!");
      return;
    }

    isLoading.value = true;

    final body = {
      'email': emails.trim(),
      'password': password.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Logger.log("Response: ${response.body}", type: "info");
      if (response.statusCode == 200 || response.statusCode ==201) {
        final data = jsonDecode(response.body);
        final token = data['data']['token'];
        final id = data['data']['user']['id'];
        final role = data['data']['user']['role'];
        if(role=="customer"){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>ProviderProfilePage()), (Route<dynamic>route)=>false);
        }else{
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const NairblyApp()), (Route<dynamic>route)=>false);
        }
        await TokenService().saveToken(token);
        await TokenService().saveUserId(id);
        //showSuccess(context, "Login Successful!");
      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Login failed. Please try again.";
        Logger.log("Error: ${response.body}", type: "error");
        //showError(context, message);
      }
    } catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\n$stackTrace", type: "error");
      //showError(context, "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }


  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

}