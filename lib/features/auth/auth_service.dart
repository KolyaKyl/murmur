// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static Future<bool> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return false; // Вход отменён

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) return false;

    final firebaseService = FirebaseService();
    AppUser? appUser = await firebaseService.getAppUserData();

    if (appUser == null) {
      await firebaseService.saveUser(
        id: user.uid,
        name: user.displayName ?? 'No Name',
        email: user.email ?? '',
        gender: 'Unknown',
        birthDate: DateTime(1990, 1, 1),
      );

      return true;
    } else {
      return true;
    }
  }

  /// Вход через Apple ID
  static Future<bool> signInWithApple() async {
    try {
      // Получаем credential от Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Создаем OAuth credential для Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Логиним в Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final user = userCredential.user;
      if (user == null) return false;

      final firebaseService = FirebaseService();
      AppUser? appUser = await firebaseService.getAppUserData();

      if (appUser == null) {
        await firebaseService.saveUser(
          id: user.uid,
          name: appleCredential.givenName ?? 'No Name',
          email: appleCredential.email ?? '',
          gender: 'Unknown',
          birthDate: DateTime(1990, 1, 1),
        );
      }

      return true;
    } catch (e) {
      print("Apple Sign In error: $e");
      return false;
    }
  }

  static Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final user = userCredential.user;
    if (user == null) return false;

    final firebaseService = FirebaseService();
    await firebaseService.saveUser(
      id: user.uid,
      name: name,
      email: user.email ?? '',
      gender: 'Unknown',
      birthDate: DateTime(1990, 1, 1),
    );
    return true;
  }

  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// Есть ли у текущего аккаунта вход по паролю — тогда для переавторизации
  /// нужен пароль, молча её не сделать.
  static bool get needsPasswordToReauthenticate {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final ids = user.providerData.map((p) => p.providerId);
    if (ids.contains('google.com') || ids.contains('apple.com')) return false;
    return ids.contains('password');
  }

  /// Firebase требует свежий вход для удаления аккаунта, иначе
  /// `requires-recent-login`. Вызывать до того, как что-то удалено.
  static Future<void> reauthenticate({String? password}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ids = user.providerData.map((p) => p.providerId).toList();

    if (ids.contains('google.com')) {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'reauth-cancelled',
          message: 'Sign-in was cancelled.',
        );
      }
      final googleAuth = await googleUser.authentication;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
      return;
    }

    if (ids.contains('apple.com')) {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );
      await user.reauthenticateWithCredential(
        OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        ),
      );
      return;
    }

    if (ids.contains('password')) {
      if (password == null || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'password-required',
          message: 'Enter your password to continue.',
        );
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    }
  }

  /// Предполагает, что [reauthenticate] уже отработал.
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Apple требует отзывать токен при удалении аккаунта (App Store 5.1.1(v)),
    // иначе приложение заворачивают на ревью. authorizationCode живёт минуты,
    // поэтому берём свежий прямо сейчас, а не сохранённый при входе.
    final signedInWithApple =
        user.providerData.any((p) => p.providerId == 'apple.com');
    if (signedInWithApple) {
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
        );
        final code = appleCredential.authorizationCode;
        await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(code);
      } catch (e) {
        // Отзыв не удался — аккаунт всё равно удаляем, иначе пользователь
        // застрянет в приложении, которое отказывается его отпускать.
        debugPrint('Apple token revoke failed: $e');
      }
    }

    await user.delete();
  }

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();
}
