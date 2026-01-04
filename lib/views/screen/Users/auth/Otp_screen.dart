import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/screen/Users/auth/set_new_password.dart';
import 'package:pinput/pinput.dart';

import '../../../../controller/verifyController.dart';
import '../../../base/AppText/appText.dart';
import '../../../base/Ios_effect/iosTapEffect.dart';
import '../../../base/primaryButton/primary_button.dart';

class OtpScreen extends StatefulWidget {
  final String email; // Add email parameter

  const OtpScreen({super.key, required this.email}); // Require email

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final VerifyController controller = Get.put(VerifyController());
  final TextEditingController pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.startTimer();
    // Optionally, auto-focus the OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    controller.disposeTimer();
    super.dispose();
  }

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const AppText(
              "Authentication Code",
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                children: [
                  const TextSpan(
                    text: "Enter 5-digit code we just texted to your Email ",
                  ),
                  TextSpan(
                    text: widget.email, // Use the actual email
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildPinCodeWidget(),
            const SizedBox(height: 16),
            _buildTimerAndResend(),
            const SizedBox(height: 40),
            Obx(() {
              return PrimaryButton(
                text: controller.isVerifying.value ? "Verifying..." : "Confirm",
                onTap: () {
                  _verifyOtp();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPinCodeWidget() {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Pinput(
      controller: pincodeController,
      length: 4, // Changed to 5 digits as mentioned in text
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      submittedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          color: AppColors.primary.withOpacity(0.05),
          border: Border.all(color: AppColors.primary),
        ),
      ),
      showCursor: true,
      onCompleted: (pin) {
        _verifyOtp();
      },
    );
  }

  Widget _buildTimerAndResend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const AppText(
          "Didn't get the code?",
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        const SizedBox(width: 4),
        Obx(() => AppText(
          " ${controller.start.value} sec",
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.primary,
        )),
        const Spacer(),
        Obx(() {
          if (controller.start.value == 0) {
            return IntrinsicWidth(
              child: Column(
                children: [
                  IosTapEffect(
                    onTap: () {
                      controller.resendOtp(widget.email);
                      controller.startTimer();
                    },
                    child: const AppText(
                      "Resend",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    height: 1.2,
                    color: AppColors.primary,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  void _verifyOtp() {
    final otp = pincodeController.text.trim();

    if (otp.isEmpty || otp.length != 5) {
      Get.snackbar(
        'Error',
        'Please enter a valid 5-digit OTP',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Call your OTP verification API here
    // Example:
    // controller.verifyOtp(
    //   email: widget.email,
    //   otp: otp,
    //   onSuccess: () {
    //     Get.to(() => SetNewPassword(email: widget.email));
    //   },
    // );

    // For now, navigate directly to SetNewPassword
    Get.to(() => SetNewPassword(email: widget.email));
  }
}