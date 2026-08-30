import 'dart:io';
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: scheme.surface,
          toolbarWidgetColor: scheme.onSurface,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
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
        const SnackBar(content: Text('Could not upload the photo. Try again.')),
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
            title: const Text('Profile Settings'),
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
                        labelText: 'Name',
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
                        labelText: 'Gender',
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
                        labelText: 'Birth Date',
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
                        child: Text('Delete profile?')),
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
                  'Cancel',
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
                  'Save',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
            title: const Text('Delete Profile'),
            content: Text(
              isDeleting
                  ? 'Deleting your data...'
                  : 'This action will permanently delete your profile and all your data. Are you sure you want to continue?',
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
                    'Cancel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    setDialogState(() => isDeleting = true);
                    final firebaseService = FirebaseService();
                    await firebaseService.deleteUserData(user.id);
                    await AuthService.deleteAccount();
                    ref.read(appUserProvider.notifier).state = null;
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
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
                    'Delete',
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

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = ref.watch(themeProvider);
    final user = ref.watch(appUserProvider);
    final firebaseService = FirebaseService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: kToolbarHeight),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 30),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (!_isUploading) {
                      _pickAndUploadProfilePhoto(user);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 146,
                        height: 146,
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
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: ClipOval(
                          child: _isUploading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildProfileImage(user),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  user.email,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user.birthDate != null)
                      Text(
                        DateFormat('yyyy-MM-dd').format(user.birthDate!),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    user.gender == 'Unknown'
                        ? SizedBox.shrink()
                        : Text(
                            ', ${user.gender ?? ''}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart_outlined_rounded),
            title: const Text('Mood Analysis'),
            onTap: () {
              FirebaseService.logEvent('profile_moodanal_pressed');
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AnalysisScreen(),
              ));
            },
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Dark Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(width: 30),
                Switch(
                  value: isDarkTheme,
                  onChanged: (val) async {
                    await ref.read(themeProvider.notifier).setDark(val);
                    await firebaseService.updateUserThemePreference(val);
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Profile Settings'),
            onTap: () {
              _showEditProfileDialog(context, user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              await AuthService.signOut();
              ref.read(appUserProvider.notifier).state = null;
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
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
