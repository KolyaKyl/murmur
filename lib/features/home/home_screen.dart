import 'package:flutter/material.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/auth/screens/auth_gate.dart';
import 'package:murmur/features/mood/widgets/mood_card/mood_card.dart';
import 'package:murmur/features/mood/widgets/analysis/wellness_index.dart';
import 'package:murmur/core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isLoading = true;
  String? loadError;

  final GlobalKey<MoodCardState> _moodCardKey = GlobalKey<MoodCardState>();

  List<Emotion> emotions = [];
  int moodIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    final firebaseService = FirebaseService();
    final appUser = ref.read(appUserProvider);

    if (appUser == null) return;

    try {
      emotions = await firebaseService.fetchEmotions();
      moodIndex = await firebaseService.calculate7DayWellnessIndex(appUser.id);
      ref.read(moodIndexProvider.notifier).state = moodIndex;
      if (mounted) {
        setState(() {
          loadError = null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Home load failed: $e');
      if (mounted) {
        setState(() {
          loadError = 'Could not load your data. Check your connection.';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider);
    final textTheme = Theme.of(context).textTheme;

    if (appUser == null) {
      return Scaffold(
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User not loaded'),
            TextButton(
                onPressed: () async {
                  await AuthService.signOut();
                  ref.read(appUserProvider.notifier).state = null;
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                      (route) => false,
                    );
                  }
                },
                child: Text('Log Out')),
          ],
        )),
      );
    }

    return Scaffold(
      body: loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(height: 16),
                    Text(
                      loadError!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() => isLoading = true);
                        _loadMoodData();
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : isLoading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceDim,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  edgeOffset: kToolbarHeight + 20,
                  onRefresh: () async {
                    await _loadMoodData();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _moodCardKey.currentState?.scrollToDefault();
                    });
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        scrolledUnderElevation: 0,
                        pinned: false,
                        floating: true,
                        snap: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        elevation: 0,
                        title: const Text('MurMur'),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mood index', style: textTheme.bodyLarge),
                              const WellnessCard(),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.01),
                              Text('What do you feel now?',
                                  style: textTheme.bodyLarge),
                              MoodCard(
                                emotions: emotions,
                                appUser: appUser,
                                key: _moodCardKey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Место под плавающий бар, иначе последний элемент
                      // прячется под стеклом.
                      SliverToBoxAdapter(
                        child:
                            SizedBox(height: GlassNavBar.contentInset(context)),
                      ),
                    ],
                  ),
                ),
    );
  }
}
