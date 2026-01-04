// Update your AppRoutes to include AuthWrapper
import 'package:get/get.dart';
import '../views/base/bottomNav/auth_wrapper.dart';
import '../views/screen/Users/auth/reset_screen.dart';
import '../views/screen/auth/login_screen.dart';
import '../views/screen/auth/sign_up.dart';
import '../views/screen/welcome/welcome_screen.dart';
import '../views/screen/Users/Profile/profile_screen.dart';
import '../provider/screens/select_service_area_screen.dart';
import '../provider/views/home/home_screen.dart';
import '../provider/screens/profile/ProviderProfilePage.dart';

import '../views/base/bottomNav/bottomNavWrapper.dart';

class AppRoutes {
  static String welcomeScreen = "/welcome_screen";
  static String loginScreen = "/login_screen";
  static String signUpScreen = "/sign_up_screen";
  static String profileScreen = "/profile_screen";
  static String providerHomeScreen = "/provider_home_screen";
  static String selectServiceAreaScreen = "/servicearea";
  static String providerProfilePage = "/provider_profile";
  static String authWrapper = "/auth_wrapper";
  static String bottomMenuWrapper = "/bottom_menu_wrapper";
  static String resetScreen = "/reset-password";

  static List<GetPage> pages = [
    GetPage(name: welcomeScreen, page: () => const WelcomeScreen()),
    GetPage(name: authWrapper, page: () => const AuthWrapper()),
    GetPage(name: bottomMenuWrapper, page: () => const BottomMenuWrappers()),
    GetPage(name: profileScreen, page: () => ProfileScreen()),
    GetPage(
        name: providerProfilePage,
        page: () => const ProviderProfilePage(),
        transition: Transition.noTransition
    ),


    GetPage(name: resetScreen, page: () => ResetScreen(), transition: Transition.noTransition),
    GetPage(name: loginScreen, page: () => LoginScreen(), transition: Transition.noTransition),
    GetPage(name: signUpScreen, page: () => SignUp(), transition: Transition.noTransition),
    GetPage(name: providerHomeScreen, page: () => const ProviderHomeScreen(), transition: Transition.noTransition),
    GetPage(name: selectServiceAreaScreen, page: () => const SelectServiceAreaScreen(), transition: Transition.noTransition),
  ];
}