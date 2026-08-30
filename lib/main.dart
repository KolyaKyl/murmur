import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:self_screen/config/firebase_options.dart';
import 'package:self_screen/models/app_user.dart';
import 'package:self_screen/screens/login/auth_gate.dart';
import 'package:self_screen/screens/login/forgot_password.dart';
import 'package:self_screen/screens/login/login_screen.dart';
import 'package:self_screen/screens/login/signup_screen.dart';
import 'package:self_screen/screens/login/start_screen.dart';
import 'package:self_screen/theme/theme.dart';

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
