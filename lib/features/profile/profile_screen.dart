import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/screens/analysis_screen.dart';
import 'package:murmur/features/auth/screens/auth_gate.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/features/sounds/screens/library_lists_screen.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/breathing/screens/breathing_stats_screen.dart';

/// Заготовка таба «Профиль». Содержимое перенесено из удалённого AppDrawer
/// как есть, кроме психологических тестов. На экран пока никто не ведёт —
/// он подключается на шаге 4 (навигация).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _avatarImage;
  bool _isUploading = false;

  Future<void> _pickAndUploadProfilePhoto(AppUser user) async {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppL10n.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.cropPhoto,
          toolbarColor: scheme.surface,
          toolbarWidgetColor: scheme.onSurface,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: l10n.cropPhoto,
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (cropped == null) return;

    setState(() {
      _avatarImage = File(cropped.path);
      _isUploading = true;
    });

    final firebaseService = FirebaseService();
    final photoUrl = await firebaseService.uploadUserProfilePhoto(
      File(cropped.path),
      user.id,
    );

    if (photoUrl != null) {
      final updatedUser = user.copyWith(photoUrl: photoUrl);
      await firebaseService.updateUserProfile(updatedUser);
      ref.read(appUserProvider.notifier).state = updatedUser;
    } else if (mounted) {
      setState(() => _avatarImage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).couldNotUploadPhoto)),
      );
    }

    if (mounted) setState(() => _isUploading = false);
  }

  Widget _buildProfileImage(AppUser? user) {
    if (_avatarImage != null) {
      return Image.file(_avatarImage!, fit: BoxFit.cover);
    } else if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: user.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Icon(Icons.person, size: 65),
      );
    } else {
      return const Icon(Icons.add_a_photo, size: 65);
    }
  }

  void _showEditProfileDialog(BuildContext context, AppUser? user) {
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);

    DateTime birthDate = user.birthDate ?? DateTime(1990, 1, 1);
    final genderOptions = ['Male', 'Female', 'Unknown'];
    String gender =
        genderOptions.contains(user.gender) ? user.gender! : 'Unknown';

    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
            title: Text(AppL10n.of(context).profileSettings),
            content: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      cursorColor: Theme.of(context).colorScheme.onSurface,
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).nameLabel,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).genderLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: gender,
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => gender = value);
                            }
                          },
                          items: genderOptions.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).birthDateLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: birthDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => birthDate = picked);
                          }
                        },
                        child: Text(
                          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                        onPressed: () async {
                          _showDeleteConfirmDialog(context, user);
                        },
                        child: Text(AppL10n.of(context).deleteProfileQ)),
                  ],
                );
              },
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  AppL10n.of(context).cancel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final updatedUser = user.copyWith(
                    name: nameController.text.trim(),
                    gender: gender,
                    birthDate: birthDate,
                  );

                  final firebaseService = FirebaseService();
                  await firebaseService.updateUserProfile(updatedUser);
                  ref.read(appUserProvider.notifier).state = updatedUser;

                  if (context.mounted) Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  AppL10n.of(context).save,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AppUser? user) {
    if (user == null) return;
    bool isDeleting = false;
    String? errorText;
    final passwordController = TextEditingController();
    final needsPassword = AuthService.needsPasswordToReauthenticate;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
            title: Text(AppL10n.of(context).deleteProfile),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeleting
                      ? AppL10n.of(context).deletingYourData
                      : AppL10n.of(context).deleteProfileBody,
                ),
                if (!isDeleting && needsPassword) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppL10n.of(context).confirmYourPassword,
                    ),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    errorText!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isDeleting) ...[
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    foregroundColor: Theme.of(context).colorScheme.error,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    AppL10n.of(context).cancel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    setDialogState(() {
                      isDeleting = true;
                      errorText = null;
                    });
                    try {
                      // Переавторизация строго до удаления: иначе можно
                      // потерять данные и остаться с живым аккаунтом.
                      await AuthService.reauthenticate(
                        password: passwordController.text,
                      );
                      final firebaseService = FirebaseService();
                      await firebaseService.deleteUserData(user.id);
                      await AuthService.deleteAccount();
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() {
                        isDeleting = false;
                        errorText = switch (e.code) {
                          'wrong-password' ||
                          'invalid-credential' =>
                            AppL10n.of(context).wrongPassword,
                          'password-required' =>
                            AppL10n.of(context).enterPasswordToContinue,
                          'reauth-cancelled' =>
                            AppL10n.of(context).signInCancelled,
                          _ => AppL10n.of(context).couldNotDeleteAccount,
                        };
                      });
                      return;
                    } catch (e) {
                      setDialogState(() {
                        isDeleting = false;
                        errorText = AppL10n.of(context).couldNotDeleteAccount;
                      });
                      return;
                    }
                    ref.read(appUserProvider.notifier).state = null;
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (route) => false,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    AppL10n.of(context).delete,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 18),
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final current = ref.read(localeProvider)?.languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppL10n.of(context).language),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: current,
            onChanged: (code) async {
              if (code == null) return;
              await ref.read(localeProvider.notifier).setLocale(Locale(code));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final locale in LocaleController.supported)
                  RadioListTile<String>(
                    value: locale.languageCode,
                    title: Text(LocaleController.names[locale.languageCode]!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Дата рождения и пол одной строкой. Пол «Unknown» не показываем —
  /// это значение по умолчанию, а не выбор пользователя.
  String _personalLine(AppUser user) {
    final parts = <String>[
      if (user.birthDate != null)
        DateFormat('yyyy-MM-dd').format(user.birthDate!),
      if (user.gender != null && user.gender != 'Unknown') user.gender!,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = ref.watch(themeProvider);
    final user = ref.watch(appUserProvider);
    final firebaseService = FirebaseService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).navProfile)),
      body: ListView(
        padding: EdgeInsets.only(
            bottom: GlassNavBar.contentInset(context,
                withPlayer: !ref.watch(playerProvider).isEmpty)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!_isUploading) _pickAndUploadProfilePhoto(user);
                  },
                  child: Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.onPrimaryFixed,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipOval(
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildProfileImage(user),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _personalLine(user),
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Редактирование живёт карандашом рядом с данными,
                // отдельной строки в списке для него больше нет.
                IconButton(
                  tooltip: AppL10n.of(context).editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditProfileDialog(context, user),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(AppL10n.of(context).recentlyPlayed),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    const SoundListScreen(kind: SoundListKind.recent))),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: Text(AppL10n.of(context).favorites),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    const SoundListScreen(kind: SoundListKind.favorites))),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: Text(AppL10n.of(context).myMixes),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MixesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.air),
            title: Text(AppL10n.of(context).breathingStats),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BreathingStatsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart_outlined_rounded),
            title: Text(AppL10n.of(context).moodAnalysis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FirebaseService.logEvent('profile_moodanal_pressed');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalysisScreen()),
              );
            },
          ),
          const Divider(height: AppSpacing.lg, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.pets_outlined),
            title: Text(AppL10n.of(context).purring),
            subtitle: Text(AppL10n.of(context).purringSubtitle),
            value: ref.watch(ambientEnabledProvider),
            onChanged: (val) async {
              await ref.read(ambientEnabledProvider.notifier).setEnabled(val);
              await ref.read(playerProvider.notifier).setAmbientEnabled(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(AppL10n.of(context).darkTheme),
            value: isDarkTheme,
            onChanged: (val) async {
              await ref.read(themeProvider.notifier).setDark(val);
              await firebaseService.updateUserThemePreference(val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppL10n.of(context).language),
            trailing: Text(
              LocaleController.names[ref.watch(localeProvider)?.languageCode ??
                      Localizations.localeOf(context).languageCode] ??
                  '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppL10n.of(context).logOut),
            onTap: () async {
              await AuthService.signOut();
              ref.read(appUserProvider.notifier).state = null;
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
