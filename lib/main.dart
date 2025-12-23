import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/provider/controllers/ProviderProfileController.dart';
import 'package:naibrly/provider/controllers/feedback_controller.dart';
import 'package:naibrly/provider/controllers/home_controller.dart';
import 'package:naibrly/provider/controllers/updateprofile_controller.dart';
import 'package:naibrly/provider/controllers/verify_information_controller.dart';
import 'package:naibrly/provider/services/analytics_service.dart';
import 'package:naibrly/provider/services/api_service.dart';
import 'package:naibrly/provider/services/feedback_service.dart';
import 'package:naibrly/provider/services/home_api_service.dart';
import 'package:naibrly/provider/services/orders_api_service.dart';
import 'package:naibrly/provider/services/profile_api_service.dart';
import 'package:naibrly/services/api_service.dart';
import 'package:naibrly/services/quick_chat_service.dart';
import 'package:naibrly/services/socket_service.dart';
import 'package:naibrly/utils/app_contants.dart';
import 'package:naibrly/utils/tokenService.dart';
import 'package:naibrly/views/base/bottomNav/auth_wrapper.dart';
import 'package:naibrly/views/base/bottomNav/bottomNavWrapper.dart';
import 'package:naibrly/views/screen/welcome/welcome_screen.dart';

import 'AllRoutes/route.dart';
import 'controller/Customer/request_controller.dart';
import 'controller/Customer/service_controller.dart';
import 'controller/networkService/networkService.dart';
import 'controller/quick_chat_controller.dart';
import 'controller/socket_controller.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and put TokenService in GetX DI
  await Get.putAsync<TokenService>(() async {
    final service = TokenService();
    await service.init();
    return service;
  }, permanent: true);
  Get.lazyPut(() => AnalyticsService(), fenix: true);
  Get.put(NetworkController());
  Get.put(ApiService());
  Get.lazyPut(() => HomeApiService());
  Get.lazyPut(() => ProviderHomeController());
  Get.put(VerifyInformationController());
  Get.put(OrdersApiService());
  Get.lazyPut(()=>FeedbackController());
  Get.lazyPut(() => FeedbackService());
  Get.lazyPut(() => ProfileApiService(), fenix: true);
  Get.lazyPut(() => ProviderProfileController(), fenix: true);
  final tokenService = Get.find<TokenService>();
  final token = tokenService.getToken();
  final bool hasToken = token != null && token.isNotEmpty;
  Get.put(MainApiService(), permanent: true);
  Get.lazyPut(()=>ServiceController());
  Get.put(QuickChatService());
  Get.put(QuickChatController());
  Get.put(SocketService());
  Get.put(SocketController());
  Get.put(ProfileController());
  await Get.putAsync<RequestController>(() async {
    final controller = RequestController();
    // Manually call onInit AFTER token service is ready

    return controller;
  }, permanent: true);

  runApp(MyApp(
    firstScreen: hasToken ? BottomMenuWrappers() : const WelcomeScreen(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget firstScreen;
  const MyApp({super.key, required this.firstScreen});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: AppConstants.FONTFAMILY,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) => SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: child ?? const SizedBox.shrink(),
      ),
        home: WelcomeScreen(),
        // initialRoute: AppRoutes.loginScreen,
        getPages: AppRoutes.pages
    );
  }
}