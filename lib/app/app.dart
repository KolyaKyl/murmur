import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/auth/screens/auth_gate.dart';
import 'package:murmur/features/auth/screens/forgot_password_screen.dart';
import 'package:murmur/features/auth/screens/login_screen.dart';
import 'package:murmur/features/auth/screens/signup_screen.dart';
import 'package:murmur/features/auth/screens/start_screen.dart';

class MurmurApp extends ConsumerWidget {
  const MurmurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Murmur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
      routes: {
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const AuthGate(),
      },
    );
  }
}
