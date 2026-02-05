// repositories/payout_repository.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import '../../utils/tokenService.dart';
import '../models/payout_information_model.dart';

class PayoutRepository {
  final String baseUrl = 'https://naibrly-backend-main.onrender.com/api';
  String? get _token {
    final tokenService = Get.find<TokenService>();
    return tokenService.getToken();
  }


  Future<PayoutInformationResponse> getPayoutInformation() async {
  final token = _token;
  if (token == null || token.isEmpty) {
  throw Exception('No authentication token found');
  }


    final response = await http.get(
      Uri.parse('$baseUrl/providers/payout/my-information'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Add your auth token
      },
    );

    if (response.statusCode == 200) {
      return PayoutInformationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load payout information');
    }
  }

  Future<Map<String, dynamic>> updatePayoutInformation({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String routingNumber,


  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }


    final response = await http.put(



      Uri.parse('$baseUrl/payout/information'),





      headers: {



        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',// Add your auth token
      },
      body: json.encode({
        'accountHolderName': accountHolderName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'routingNumber': routingNumber,
      }),


    );

    if (response.statusCode == 200) {

      return json.decode(response.body);

    } else {
      print(response.body);
      throw Exception('Failed to update payout information');
    }
  }
}