import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/main.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/auth/screens/auth_gate.dart';
import 'package:murmur/features/mood/widgets/mood_card/mood_card.dart';
import 'package:murmur/features/mood/widgets/analysis/wellness_index.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isLoading = true;

  final GlobalKey<MoodCardState> _moodCardKey = GlobalKey<MoodCardState>();
  final GlobalKey<WellnessCardState> _wellnessCardKey =
      GlobalKey<WellnessCardState>();

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

    emotions = await firebaseService.fetchEmotions();
    moodIndex = await firebaseService.calculate7DayWellnessIndex(appUser.id);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
                    Navigator.of(context).pushAndRemoveUntil(
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
      body: isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(12.0),
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
                  _wellnessCardKey.currentState?.updateWellnessIndex(moodIndex);
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
                    title: const Text('Murmur'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mood index', style: textTheme.bodyLarge),
                          WellnessCard(
                            key: _wellnessCardKey,
                            moodIndex: moodIndex,
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          Text('What do you feel now?',
                              style: textTheme.bodyLarge),
                          MoodCard(
                            emotions: emotions,
                            appUser: appUser,
                            key: _moodCardKey,
                            wellnessCardKey: _wellnessCardKey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01),
                  ),
                ],
              ),
            ),
    );
  }
}
