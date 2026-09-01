import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/widgets/loading_dialog.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _customDecoration(String hint,
      {bool isPassword = false,
      VoidCallback? toggleVisibility,
      bool? isObscured}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: colorScheme.outline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: colorScheme.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: colorScheme.outline,
        ),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      contentPadding: const EdgeInsets.all(16),
      suffixIcon: isPassword && toggleVisibility != null
          ? IconButton(
              icon: Icon(
                isObscured! ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: toggleVisibility,
            )
          : null,
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
      if (!mounted) return;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar(AppL10n.of(context).fillAllFields);
      return;
    }

    if (!EmailValidator.validate(email)) {
      _showSnackBar(AppL10n.of(context).invalidEmailFormat);
      return;
    }

    if (password.length < 6) {
      _showSnackBar(AppL10n.of(context).passwordTooShort);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar(AppL10n.of(context).passwordsDoNotMatch);
      return;
    }

    showLoadingDialog(context);

    try {
      // bool success =
      bool success = await AuthService.signUpWithEmail(
        name: username,
        email: email,
        password: password,
      );
      if (!mounted) return;

      Navigator.pop(context); // remove loading dialog
      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      Navigator.pop(context); // remove loading dialog
      _showSnackBar('Sign up failed: ${e.toString()}');
    }
  }

  Widget buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    String? imagePath,
    bool square = false,
  }) {
    double buttonSize = square ? 60 : double.infinity;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      colors: [
        colorScheme.primary,
        colorScheme.secondary,
        if (!square) colorScheme.onPrimaryFixed,
      ],
    );

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
          width: buttonSize,
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
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Image(
                    height: 28,
                    width: 28,
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              square
                  ? const SizedBox.shrink()
                  : Flexible(
                      child: Text(
                        text,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign:
                            icon != null ? TextAlign.start : TextAlign.center,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dividerWithText(String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(text, style: theme.textTheme.labelMedium),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: const Image(
                      height: 100,
                      width: 100,
                      image: AssetImage('assets/logo/logo_round.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('MurMur', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 32),

                  // Username
                  TextField(
                    cursorColor: colorScheme.onSurface,
                    controller: _usernameController,
                    decoration: _customDecoration(AppL10n.of(context).username),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    cursorColor: colorScheme.onSurface,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _customDecoration(AppL10n.of(context).email),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    cursorColor: colorScheme.onSurface,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _customDecoration(
                      AppL10n.of(context).password,
                      isPassword: true,
                      toggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      isObscured: _obscurePassword,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    cursorColor: colorScheme.onSurface,
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _customDecoration(
                      AppL10n.of(context).confirmPassword,
                      isPassword: true,
                      toggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      isObscured: _obscureConfirmPassword,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  buildGradientButton(
                    text: AppL10n.of(context).signUp,
                    icon: Icons.person_add,
                    onPressed: () {
                      FirebaseService.logEvent('signupscreen_signup_pressed');
                      _handleSignUp();
                    },
                  ),
                  const SizedBox(height: 8),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: dividerWithText(AppL10n.of(context).orLogInWith),
                  ),
                  const SizedBox(height: 8),

                  // Sign Up with Google
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Вход через Apple — только на iOS, см. start_screen.
                      if (Platform.isIOS) ...[
                        buildGradientButton(
                          text: AppL10n.of(context).logInWithApple,
                          imagePath: 'assets/logo/apple_icon.png',
                          square: true,
                          onPressed: () {
                            FirebaseService.logEvent(
                                'signupscreen_login_apple_pressed');
                            _handleAppleSignIn();
                          },
                        ),
                        const SizedBox(width: 16),
                      ],
                      buildGradientButton(
                        text: AppL10n.of(context).logInWithGoogle,
                        imagePath: 'assets/logo/google_icon.png',
                        square: true,
                        onPressed: () {
                          FirebaseService.logEvent(
                              'signupscreen_login_google_pressed');
                          _handleGoogleSignIn();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      AppL10n.of(context).alreadyHaveAccount,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
