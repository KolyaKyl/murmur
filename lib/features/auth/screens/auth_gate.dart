import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/app/providers.dart';
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
    AppUser? appUser;
    try {
      appUser = await firebaseService.getAppUserData();
    } catch (e) {
      // Нет сети на старте — пускаем дальше с локальной темой,
      // экран сам покажет своё состояние, вместо белого экрана навсегда.
      debugPrint('AuthGate: could not load user: $e');
    }

    if (appUser != null) {
      ref.read(appUserProvider.notifier).state = appUser;
      // null означает "пользователь никогда не выбирал" — тогда остаётся
      // локальное значение. Совпадающее значение не пишем: это лишняя
      // перерисовка всего дерева ради того же самого.
      final remote = appUser.isDarkTheme;
      if (remote != null && remote != ref.read(themeProvider)) {
        await ref.read(themeProvider.notifier).setDark(remote);
      }
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
