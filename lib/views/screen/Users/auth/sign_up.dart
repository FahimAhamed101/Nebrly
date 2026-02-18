import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/appTextfield/appTextfield.dart';
import 'package:naibrly/views/base/primaryButton/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../controller/Customer/authCustomer/signupController.dart';
import '../../../../utils/app_icon.dart';
import 'base/countryTextfield.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final SignUpController controller = Get.put(SignUpController());
  static final Uri _termsUrl = Uri.parse('https://naibrly.com/terms');
  static final Uri _privacyUrl = Uri.parse('https://naibrly.com/privacy');
  static const List<String> _usStates = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
    'DC',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.White,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.black),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      backgroundColor: AppColors.White,
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
              children: [
                const SizedBox(height: 10,),
                Align(alignment: Alignment.center, child: Image.asset("assets/images/Frame 2147226486.png",width: 155,height: 48,),),
                const SizedBox(height: 25,),
                Row(
                  children: [
                    Obx(() => ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Center(
                        child: controller.profileImage.value != null
                            ? Image.file(
                          controller.profileImage.value!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        )
                            : SvgPicture.asset(
                          "assets/icons/user_color.svg",
                          width: 30,
                          height: 30,
                        ),
                      ),
                    )),
                    const SizedBox(width: 8,),
                    const UploadImage(),
                  ],
                ),
                const SizedBox(height: 12,),
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: controller.firstname, hint: "First Name")),
                    const SizedBox(width: 10,),
                    Expanded(child: AppTextField(controller: controller.lastname, hint: "Last Name")),

                  ],
                ),
                const SizedBox(height: 10,),
                AppTextField(controller: controller.email, hint: "Email Address"),
                const SizedBox(height: 10,),
                Obx(() => AppTextField(
                  obscure: controller.showHide.value,
                  // ✅ dynamic obscure
                  keyboardType: TextInputType.twitter,
                  controller: controller.password,
                  // ✅ use passwordController here
                  hint: "Password",
                  helperText:
                      "Password must contain:\n- Minimum 6 characters\n- 1 number\n- 1 capital letter\n- 1 special character",
                  helperStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black50,
                  ),
                  helperMaxLines: 5,
                  suffix: IconButton(
                    icon: Icon(
                      controller.showHide.value
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: Colors.black.withOpacity(0.50),
                    ),
                    onPressed: () {
                      controller.passwordToggle();
                    },
                  ),
                ),),
                const SizedBox(height: 10,),
                Obx(
                      () => AppTextField(
                    obscure: controller.showHide1.value,
                    // ✅ dynamic obscure
                    keyboardType: TextInputType.twitter,
                    controller: controller.confirmPassword,
                    // ✅ use passwordController here
                    hint: "Confirm Password",
                    suffix: IconButton(
                      icon: Icon(
                        controller.showHide1.value
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: Colors.black.withOpacity(0.50),
                      ),
                      onPressed: () {
                        controller.passwordToggle1();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16,),
                CustomCountryCodePicker(
                  countryCodeController:controller.phoneNumber,
                  initialCountryCode: "US",
                ),
                const SizedBox(height: 5,),
                AppTextField(
                    controller: controller.streetName,
                    hint: "Street Number and Name"),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: controller.aptSuite, hint: "Apt / Suite")),
                    const SizedBox(width: 10,),
                    Expanded(child: AppTextField(controller: controller.city, hint: "City")),

                  ],
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: controller.zipCode, hint: "Zip code",keyboardType: TextInputType.number,)),
                    const SizedBox(width: 10,),
                    Expanded(
                      child: Obx(
                            () => DropdownButtonFormField<String>(
                          value: controller.selectedState.value.isEmpty
                              ? null
                              : controller.selectedState.value,
                          items: _usStates
                              .map((state) => DropdownMenuItem<String>(
                            value: state,
                            child: Text(state),
                          ))
                              .toList(),
                          onChanged: (value) {
                            controller.selectedState.value = value ?? '';
                            controller.state.text = value ?? '';
                          },
                          icon: const Icon(
                            CupertinoIcons.chevron_down,
                            size: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: "State",
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: AppColors.black50,
                              fontSize: 14,
                            ),
                            floatingLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppColors.White,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 1,
                                color: AppColors.black50.withOpacity(0.60),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                width: 1.5,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    Obx(
                          () => Transform.scale(
                        scale: 1.1, // adjust size as needed
                        child: Checkbox(
                          value: controller.privacy.value,
                          onChanged: (val) {
                            controller.privacy.value = val ?? false; // ✅ assignment, not comparison
                          },
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).textTheme.titleSmall?.color ?? Colors.grey,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    // 🧩 RichText beside the checkbox
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: "I agree to the ",style: TextStyle(fontWeight: FontWeight.w500,color: AppColors.black)),
                            TextSpan(
                              text: "Terms of Service",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _openUrl(_termsUrl);
                                },
                            ),
                            const TextSpan(text: " and ",style: TextStyle(fontWeight: FontWeight.w500,color: AppColors.black)),
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _openUrl(_privacyUrl);
                                },
                            ),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20,),
                Obx(() {
                  return PrimaryButton(
                    loading: controller.isLoading.value,
                    text: "Sign Up",
                    onTap: () async {
                      final firstname = controller.firstname.text.trim();
                      final lastname = controller.lastname.text.trim();
                      final email = controller.email.text.trim();
                      final password = controller.password.text;
                      final confirmPassword = controller.confirmPassword.text;
                      final phone = controller.phoneNumber.text;
                      final street = controller.streetName.text;
                      final state = controller.selectedState.value.trim();
                      final zipcode = controller.zipCode.text;
                      final aptsuit = controller.aptSuite.text;
                      final city = controller.city.text;
                      if (firstname.isEmpty) {
                        showError(context, "First name is required");
                        return;
                      }
                      if (lastname.isEmpty) {
                        showError(context, "Last name is required");
                        return;
                      }
                      if (email.isEmpty) {
                        showError(context, "Email is required");
                        return;
                      }
                      if (password.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      if (!controller.isPasswordValid()) {
                        showError(
                          context,
                          "Password must be at least 6 characters and include 1 number, 1 capital letter, and 1 special character",
                        );
                        return;
                      }
                      if (phone.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      if (street.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      if (state.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      if (zipcode.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      if (aptsuit.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      if (password != confirmPassword) {
                        showError(context, "Passwords do not match");
                        return;
                      }
                      await controller.signUp(
                        context,
                        firstnames: firstname,
                        lasnames: lastname,
                        emails: email,
                        passwords: password,
                        confrimpasswords: confirmPassword,
                        phones: phone,
                        streets: street,
                        citys: city,
                        states: state,
                        zipcodes: zipcode,
                        aptSuites: aptsuit,
                      );

                    },
                  );
                }),
                const SizedBox(height: 20,),
                orDivided(),
                const SizedBox(height: 18,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:Colors.white,
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xffeeeeee),
                            offset: Offset(0, 3),
                            blurRadius: 5,
                          )
                        ],
                        borderRadius: BorderRadius.circular(100),

                      ),
                      child: SvgPicture.asset(AppIcons.google),
                    ),
                    const SizedBox(width: 10,),
                    Container(
                      height: 50,
                      width: 50,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:Colors.white,
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xffeeeeee),
                            offset: Offset(0, 3),
                            blurRadius: 5,
                          )
                        ],
                        borderRadius: BorderRadius.circular(100),

                      ),
                      child: SvgPicture.asset(AppIcons.apple),
                    ),
                  ],
                )
              ]
          )
      ),
    );
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

  Future<void> _openUrl(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showError(context, "Could not open link");
    }
  }

  Widget orDivided(){
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.secondary,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: AppText("Or continue with",fontSize: 14,fontWeight: FontWeight.w400,color: AppColors.black,),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
class UploadImage extends StatelessWidget {
  const UploadImage({super.key});

  @override
  Widget build(BuildContext context) {
    final SignUpController controller = Get.find();
    return GestureDetector(
      onTap: () {
        controller.pickProfileImage(); // pick image on tap
      },
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1,
            color: AppColors.black50,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppText(
              "Upload Image",
              color: AppColors.black,
              fontSize: 14,
            ),
            const SizedBox(width: 8),
            SvgPicture.asset("assets/icons/elements (4).svg"),
          ],
        ),
      ),
    );
  }
}


