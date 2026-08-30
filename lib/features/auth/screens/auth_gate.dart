import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/main.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/home/home_screen.dart';
import 'package:murmur/features/auth/screens/start_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      debugPrint("User is null");
      return;
    }

    final firebaseService = FirebaseService();
    AppUser? appUser = await firebaseService.getAppUserData();

    if (appUser != null) {
      ref.read(appUserProvider.notifier).state = appUser;
      ref.read(themeProvider.notifier).state = appUser.isDarkTheme ?? false;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    if (FirebaseAuth.instance.currentUser == null) {
      return const StartScreen();
    } else {
      return const HomeScreen();
    }
  }
}
