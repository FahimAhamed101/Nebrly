// views/screen/auth/login_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/appTextfield/appTextfield.dart';
import 'package:naibrly/views/screen/Users/auth/sign_up.dart';
import '../../../controller/auth_controller.dart';
import '../../base/AppText/appText.dart';
import '../../base/Ios_effect/iosTapEffect.dart';
import '../../base/primaryButton/primary_button.dart';
import 'base/or/orLogin.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController controller = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    // Set default email and password after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // controller.emailController.text = "prov1@gmail.com";
      // controller.passwordController.text = "Password@123";
       controller.emailController.text = "afaysal220@gmail.com";
          controller.passwordController.text = "AbcD@7281";
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.White,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.02),
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                "assets/images/Frame 2147226485.png",
                height: 200,
                width: 160,
              ),
            ),
            AppText(
              "Welcome Back!",
              fontWeight: FontWeight.w400,
              fontSize: 28,
              color: AppColors.textcolor,
            ),
            SizedBox(height: size.height * 0.01),
            AppText(
              "Hello there, login to continue",
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: AppColors.textcolor,
            ),
            SizedBox(height: size.height * 0.03),
            AppTextField(controller: controller.emailController, hint: "Email Address"),
            SizedBox(height: 15),
            Obx(
                  () => AppTextField(
                obscure: !controller.passShowHide.value,
                keyboardType: TextInputType.text,
                controller: controller.passwordController,
                hint: "Password",
                suffix: IconButton(
                  icon: Icon(
                    controller.passShowHide.value
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    color: Colors.white38,
                  ),
                  onPressed: () {
                    controller.togglePasswordVisibility();
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () {
                  // Your forgot password logic here
                  // Note: You had controller.pickProfileImage() which doesn't seem
                  // right for a "Forgot Password?" link
                  Get.toNamed('/reset-password'); // Example navigation
                },
                child: AppText(
                  "Forgot Password?",
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textcolor,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.04),
            Obx(() {
              return PrimaryButton(
                loading: controller.isLoading.value,
                text: "Login",
                onTap: () {
                  controller.loginUser(context);
                },
              );
            }),
            SizedBox(height: size.height * 0.04),
            const OrDivider(),
            SizedBox(height: size.height * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoogleOrAppcle(onTap: () {}, icon: "assets/icons/Group (5).svg"),
                SizedBox(width: 16),
                GoogleOrAppcle(onTap: () {}, icon: "assets/icons/Google (1).svg"),
              ],
            ),
            SizedBox(height: size.height * 0.05),
            IosTapEffect(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (builder) => SignUp()));
              },
              child: Align(
                alignment: Alignment.center,
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppText("Create account", fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.secondary),
                      Container(height: 2, color: AppColors.secondary.withOpacity(0.50)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleOrAppcle extends StatelessWidget {
  final VoidCallback onTap;
  final String icon;

  const GoogleOrAppcle({super.key, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF000000).withOpacity(0.04),
              offset: Offset(0, 6),
              blurRadius: 24,
            ),
          ],
          color: Colors.white,
          border: Border.all(
            width: 1,
            color: AppColors.secondary.withOpacity(0.20),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SvgPicture.asset(icon)],
          ),
        ),
      ),
    );
  }
}