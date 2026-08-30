import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:murmur/core/firebase/firebase_options.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/auth/screens/auth_gate.dart';
import 'package:murmur/features/auth/screens/forgot_password_screen.dart';
import 'package:murmur/features/auth/screens/login_screen.dart';
import 'package:murmur/features/auth/screens/signup_screen.dart';
import 'package:murmur/features/auth/screens/start_screen.dart';
import 'package:murmur/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  runApp(const ProviderScope(child: MyApp()));
}

final themeProvider = StateProvider<bool>((ref) => false);
final appUserProvider = StateProvider<AppUser?>((ref) => null);
final analyticsProvider =
    Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    return MaterialApp(
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
        '/home': (context) => const AuthGate(), //const HomeScreen(),
      },
    );
  }
}
