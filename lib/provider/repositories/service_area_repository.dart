// repositories/service_area_repository.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import '../../utils/tokenService.dart';
import '../models/service_area_model.dart';

class ServiceAreaRepository {
  final String baseUrl = 'https://naibrly-backend-main.onrender.com/api';
  String? get _token {
    final tokenService = Get.find<TokenService>();
    return tokenService.getToken();
  }
  Future<ServiceAreaResponse> getMyServiceAreas() async {

    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }




    final response = await http.get(
      Uri.parse('$baseUrl/providers/service-areas/my-areas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ServiceAreaResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load service areas');
    }
  }

  Future<Map<String, dynamic>> addServiceArea({
    required String zipCode,
    String? city,
    String? state,
  }) async {

    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/providers/service-areas/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'zipCode': zipCode,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add service area');
    }
  }

  Future<Map<String, dynamic>> removeServiceArea(String areaId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/providers/service-areas/$areaId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to remove service area');
    }
  }
}
