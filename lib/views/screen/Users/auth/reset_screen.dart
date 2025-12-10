import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/screen/Users/auth/Otp_screen.dart';

import '../../../../controller/password_reset_controller.dart';
import '../../../base/appTextfield/appTextfield.dart';
import '../../../base/primaryButton/primary_button.dart';

class ResetScreen extends StatelessWidget {
  ResetScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final PasswordResetController _passwordResetController = Get.put(PasswordResetController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      appBar: AppBar(
        backgroundColor: AppColors.White,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: AppText(
                "Reset Your Password",
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter your email address below and we'll send you a link with instructions.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Image.asset(
                "assets/images/Group 513789 (2).png",
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
            const SizedBox(height: 40),

            // Email TextField
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Email Address",
                // Add any other styling to match AppTextField
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                _passwordResetController.clearMessages();
              },
            ),

            // Error Message (if any)
            Obx(() {
              if (_passwordResetController.errorMessage.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _passwordResetController.errorMessage.value,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 32),

            // Send Verification Code Button
            // Send Verification Code Button
            // Send Verification Code Button
            // Send Verification Code Button
            Obx(() {
              return PrimaryButton(
                text: _passwordResetController.isLoading.value
                    ? "Sending..."
                    : "Send Verification Code",
                onTap: () {
                  // Prevent multiple taps while loading
                  if (_passwordResetController.isLoading.value) return;

                  _passwordResetController.sendResetPasswordEmail(
                    emailController.text.trim(),
                  );
                },
              );
            }),

            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  "Need Help ",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                Container(
                  height: 20,
                  width: 2,
                  color: AppColors.black,
                ),
                AppText(
                  " FAQ ",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                Container(
                  height: 20,
                  width: 2,
                  color: AppColors.black,
                ),
                AppText(
                  " Terms Of use ",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}