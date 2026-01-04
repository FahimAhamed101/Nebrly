// Create a new file: views/base/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/tokenService.dart';
import '../../screen/auth/login_screen.dart';

import 'bottomNavWrapper.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final TokenService _tokenService = TokenService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await _tokenService.init();
    final loggedIn = await _tokenService.isLoggedIn();

    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const BottomMenuWrappers() : LoginScreen();
  }
}