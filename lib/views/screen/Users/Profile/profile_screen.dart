import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:naibrly/controller/Customer/profileController/profileController.dart';
import 'package:naibrly/utils/app_contants.dart';
import 'package:naibrly/utils/tokenService.dart';
import 'package:naibrly/views/screen/Users/Profile/ProfileEdit/edit_profile.dart';
import 'package:naibrly/views/screen/Users/Profile/PrivacyPolicy/privacy_policy_screen.dart';
import 'package:naibrly/views/screen/Users/Profile/TermsCondition/terms_condition_screen.dart';
import 'package:naibrly/views/screen/Users/Profile/PaymentHistory/payment_history_screen.dart';


import '../../../../utils/app_colors.dart';
import '../../../../utils/app_icon.dart';
import '../../../base/AppText/appText.dart';
import '../../../base/CustomImage/customNetworkImage.dart';
import '../../../base/Ios_effect/iosTapEffect.dart';
import 'package:get/get.dart';
import '../../welcome/welcome_screen.dart';
import 'Faq_screen/faq_screen.dart';
import 'base/iconTextRow.dart';
import 'base/settingItem.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController applycupon = TextEditingController();
  final ProfileController controller = Get.put(ProfileController());
  final TokenService _tokenService = Get.find<TokenService>(); // Add this
  final _controller01 = ValueNotifier<bool>(false);

  final List<String> settingItem = [
    "Help & Support",
    "Privacy Policy",
    "Terms & Condition",
    "Payment History",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.White,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: AppColors.White,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: AppText("Your Profile",fontSize: 18,fontWeight: FontWeight.w700,color: AppColors.Black,),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.White,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.LightGray,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    AppIcons.edit,
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (builder)=>EditProfileScreen()));
                  },
                ),
              ),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[];
          },
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height *0.01),
                Obx(()=>Align(
                  alignment: Alignment.center,
                  child: CustomNetworkImage(
                    imageUrl:"${controller.profileInfo.value!.profileImage.url}",
                    height: 130,
                    width: 130,
                    boxShape: BoxShape.circle,
                    border: Border.all(
                      width: 2,
                      color: AppColors.LightGray,
                    ),
                  ),
                ),),

                SizedBox(height: MediaQuery.of(context).size.height *0.01),
                Obx(() => AppText(
                  '${controller.profileInfo.value!.firstName} ${controller.profileInfo.value!.lastName}',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.Black,
                )),

                SizedBox(height: 4),

                AppText(
                    "Home owner",
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.Black
                ),
                SizedBox(height: MediaQuery.of(context).size.height *0.05),
                Align(
                  alignment: Alignment.topLeft,
                  child: AppText(
                      'My Information',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textcolor
                  ),
                ),
                aboutSections(),
                SizedBox(height: MediaQuery.of(context).size.height *0.04),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'Notifications',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.Black,
                    ),
                    AdvancedSwitch(
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.LightGray,
                      width: 44,
                      height: 22,
                      controller: _controller01,
                      borderRadius: BorderRadius.circular(77),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFEEEEEE)),

                SizedBox(height: 5),
                ListView.builder(
                  itemCount: settingItem.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final items = settingItem[index];
                    return SettingItem(
                      title: items,
                      iconPath: AppIcons.arrow_right,
                      onTap: () {
                        switch(index){
                          case 0:
                            Navigator.push(context,MaterialPageRoute(builder: (builder)=>FaqScreen()));
                            break;
                          case 1:
                            Navigator.push(context,MaterialPageRoute(builder: (builder)=>PrivacyPolicyScreen()));
                            break;
                          case 2:
                            Navigator.push(context,MaterialPageRoute(builder: (builder)=>TermsConditionScreen()));
                            break;
                          case 3:
                            Navigator.push(context,MaterialPageRoute(builder: (builder)=>PaymentHistoryScreen()));
                            break;
                        }
                      },
                    );
                  },
                ),

                SizedBox(height: 5),
                IosTapEffect(
                  onTap: () async {
                    showCustomDialog(context);
                  },
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: AppText(
                        'Logout',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height *0.02),
              ],
            ),
          ),
        ));
  }

  Padding aboutSections() {
    return Padding(
      padding: EdgeInsets.only(left: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),

          Obx(()=>  IconTextRow(
            iconPath: AppIcons.men,
            text: "${controller.profileInfo.value!.firstName} ${controller.profileInfo.value!.lastName}",
          ),),


          SizedBox(height: 10),

          IconTextRow(
            iconPath: AppIcons.men,
            text: 'Home owner',
          ),

          SizedBox(height: 10),
          Obx(() {
            final address = controller.profileInfo.value?.address;
            final addressText = address != null
                ? '${address.street}, ${address.city}, ${address.state} ${address.zipCode}'
                : 'No address available';

            return IconTextRow(
              iconPath: "assets/icons/locations.svg",
              text: addressText,
            );
          }),

          SizedBox(height: 10),
          Obx(()=>IconTextRow(
            iconPath: AppIcons.call,
            text: controller.profileInfo.value!.phone,
          ),),


          SizedBox(height: 10),
          Obx(()=> IconTextRow(
            iconPath: AppIcons.mail,
            text: controller.profileInfo.value!.email,
          )),

          SizedBox(height: 10),
          IconTextRow(
            iconPath: AppIcons.mail,
            text: 'Zip: 62704',
          ),

          SizedBox(height: 10),
          Obx(() {
            final createdAt = controller.profileInfo.value?.createdAt;
            String dateText = createdAt != null
                ? DateFormat('yyyy MMMM dd').format(DateTime.parse(createdAt).toLocal())
                : 'No date available';

            return IconTextRow(
              iconPath: AppIcons.calender,
              text: "Joined: $dateText",
            );
          }),

        ],
      ),
    );
  }

  void showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: (){
                    Get.back();
                  },
                  child: Align(
                      alignment: Alignment.topRight,
                      child: SvgPicture.asset("assets/icons/maki_cross.svg")),
                ),
                Align(
                    alignment: Alignment.topLeft,
                    child:AppText("Log Out",color: AppColors.Black,fontSize: 20,fontWeight: FontWeight.bold,)),
                SizedBox(height: 8),
                Text(
                  "Are you sure you want to log out your account?",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                    color: AppColors.DarkGray,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: (){
                          Get.back();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.LightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Cancel",
                                style: TextStyle(
                                  color: AppColors.Black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width *0.05,),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Close dialog first
                          Navigator.of(context).pop();

                          // Perform logout
                          await _performLogout();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Log Out",
                                style: TextStyle(
                                  color: AppColors.White,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Clear tokens
      final TokenService tokenService = Get.find<TokenService>();

      // Clear tokens
      await tokenService.removeToken();
      await tokenService.removeUserId();

      // Clear any other stored data if needed
      // await _tokenService.clearAll();

      // Navigate to login/welcome screen
      Get.offAll(() => WelcomeScreen()); // Replace with your actual login/welcome screen

      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}