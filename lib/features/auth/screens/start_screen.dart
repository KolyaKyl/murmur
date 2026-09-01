import 'dart:io';
import 'package:flutter/material.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/features/auth/screens/login_screen.dart';
import 'package:murmur/features/auth/screens/signup_screen.dart';
import 'package:murmur/features/auth/screens/terms_screen.dart';
import 'package:murmur/core/widgets/loading_dialog.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/l10n/app_localizations.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Без final: didChangeDependencies вызывается при каждой смене
  // унаследованных зависимостей, в том числе при смене темы.
  late ThemeData theme;
  late ColorScheme colorScheme;
  late LinearGradient gradient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;

    gradient = LinearGradient(
      colors: [
        colorScheme.primary,
        colorScheme.secondary,
        colorScheme.onPrimaryFixed,
      ],
    );
  }

  Widget buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    String? imagePath,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withAlpha(18),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          width: double.infinity,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    icon,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image(
                    height: 28,
                    width: 28,
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              Flexible(
                child: Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: icon != null ? TextAlign.start : TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    showLoadingDialog(context);
    try {
      bool success = await AuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return; // важно!
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).googleSignInFailed)),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    showLoadingDialog(context);
    try {
      bool success = await AuthService.signInWithApple();
      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).appleSignInFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: const Image(
                    height: 140,
                    width: 140,
                    image: AssetImage('assets/logo/logo_round.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MurMur',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Вход через Apple — только на iOS. На Android нативный
                // диалог недоступен, кнопка молча ничего не делала.
                if (Platform.isIOS) ...[
                  buildGradientButton(
                    text: AppL10n.of(context).logInWithApple,
                    imagePath: 'assets/logo/apple_icon.png',
                    onPressed: () {
                      FirebaseService.logEvent(
                          'startscreen_login_apple_pressed');
                      _handleAppleSignIn();
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Login with Google
                buildGradientButton(
                  text: AppL10n.of(context).logInWithGoogle,
                  imagePath: 'assets/logo/google_icon.png',
                  onPressed: () {
                    FirebaseService.logEvent(
                        'startscreen_login_google_pressed');
                    _handleGoogleSignIn();
                  },
                ),
                const SizedBox(height: 16),

                // Login with Email
                buildGradientButton(
                  text: AppL10n.of(context).logInWithEmail,
                  icon: Icons.email,
                  onPressed: () {
                    FirebaseService.logEvent('startscreen_login_email_pressed');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Sign Up
                buildGradientButton(
                  text: AppL10n.of(context).signUp,
                  icon: Icons.person_add,
                  onPressed: () {
                    FirebaseService.logEvent('startscreen_signup_pressed');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()),
                    );
                  },
                ),

                const SizedBox(
                  height: 24,
                ),

                //TC
                Text(
                  'by continuing, you agree to our',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(
                  height: 6,
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TermsScreen()),
                    );
                  },
                  child: Text(
                    AppL10n.of(context).termsAndConditions,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize:
                          Theme.of(context).textTheme.labelLarge!.fontSize,
                      fontWeight:
                          Theme.of(context).textTheme.labelLarge!.fontWeight,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
