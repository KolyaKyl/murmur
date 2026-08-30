import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/core/widgets/loading_dialog.dart';
import 'package:murmur/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Widget buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      colors: [
        colorScheme.primary,
        colorScheme.secondary,
        colorScheme.onPrimaryFixed,
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

  void _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
        ),
      );
      return;
    }

    if (!EmailValidator.validate(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email format'),
        ),
      );
      return;
    }

    showLoadingDialog(context);

    try {
      await AuthService.signInWithEmail(email: email, password: password);

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    }
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text('Murmur', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 32),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: colorScheme.onSurface,
                    decoration: _customDecoration('Email'),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    cursorColor: colorScheme.onSurface,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _customDecoration(
                      'Password',
                      isPassword: true,
                      toggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      isObscured: _obscurePassword,
                    ),
                  ),

                  // Forgot password button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Log In Button
                  buildGradientButton(
                    text: 'Log In',
                    icon: Icons.login,
                    onPressed: () {
                      FirebaseService.logEvent('loginscreen_login_pressed');
                      _loginWithEmail();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Navigation
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text(
                      'First time here? Sign Up',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
