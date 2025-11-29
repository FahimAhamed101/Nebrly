// utils/tokenService.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String onboardingStep = 'onboarding_step';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) async {
    await _prefs?.setString(_accessTokenKey, token);
  }

  String? getToken() {
    return _prefs?.getString(_accessTokenKey);
  }

  Future<void> removeToken() async {
    await _prefs?.remove(_accessTokenKey);
  }

  Future<void> saveOnboardingStep(int step) async {
    await _prefs?.setInt(onboardingStep, step);
  }

  int? getOnboardingStep() {
    return _prefs?.getInt(onboardingStep);
  }

  Future<void> removeOnboardingStep() async {
    await _prefs?.remove(onboardingStep);
  }

  Future<void> saveUserId(String id) async {
    await _prefs?.setString(_userIdKey, id);
  }

  String? getUserId() {
    return _prefs?.getString(_userIdKey);
  }

  Future<void> removeUserId() async {
    await _prefs?.remove(_userIdKey);
  }

  // Add user role methods
  Future<void> saveUserRole(String role) async {
    await _prefs?.setString(_userRoleKey, role);
    print("💾 User role saved: $role");
  }

  String? getUserRole() {
    final role = _prefs?.getString(_userRoleKey);
    print("🔍 Retrieved user role: $role");
    return role;
  }

  Future<void> removeUserRole() async {
    await _prefs?.remove(_userRoleKey);
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}