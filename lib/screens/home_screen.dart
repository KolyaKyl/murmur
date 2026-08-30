import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_screen/config/auth_services.dart';
import 'package:self_screen/config/firebase_service.dart';
import 'package:self_screen/main.dart';
import 'package:self_screen/models/emotion.dart';
import 'package:self_screen/screens/login/auth_gate.dart';
import 'package:self_screen/widgets/drawer.dart';
import 'package:self_screen/widgets/mood_card/mood_card.dart';
import 'package:self_screen/widgets/test_widgets/tests_section.dart';
import 'package:self_screen/widgets/analysis/wellness_index.dart';

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
  Key testsSectionKey = UniqueKey();

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
        testsSectionKey = UniqueKey();
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
      drawer: AppDrawer(wellnessCardKey: _wellnessCardKey),
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
                    title: const Text('Self Screen'),
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
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          Text('Psychological tests',
                              style: textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: TestsSection(
                      key: testsSectionKey,
                      appUser: appUser,
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
