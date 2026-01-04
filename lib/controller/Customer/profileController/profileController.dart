import 'dart:convert';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import '../../../models/profileInfo/persosnalinfo.dart';
import '../../../utils/app_contants.dart';
import '../../../utils/tokenService.dart';

class ProfileController extends GetxController {
  Rxn<UserModel> profileInfo = Rxn<UserModel>();

  Future<void> fetchUserData() async {
    const String url = '${AppConstants.BASE_URL}/api/users/profile';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${TokenService().getToken()}',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userJson = data['data']['user'];
        final user = UserModel.fromJson(userJson);
        print("Error fetching user data: $data");
        profileInfo.value = user;
        update();
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }
}
