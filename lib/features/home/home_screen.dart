import 'package:flutter/material.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/features/auth/auth_service.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/auth/screens/auth_gate.dart';
import 'package:murmur/features/mood/widgets/mood_card/mood_card.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/core/widgets/animated_gradient.dart';
import 'package:murmur/core/widgets/section_label.dart';
import 'package:murmur/features/mood/screens/analysis_screen.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';

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
          loadError = AppL10n.of(context).couldNotLoadData;
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
            Text(AppL10n.of(context).userNotLoaded),
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
                child: Text(AppL10n.of(context).logOut)),
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
                      child: Text(AppL10n.of(context).tryAgain),
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
                          AppL10n.of(context).loading,
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
                      _HomeAppBar(moodIndex: ref.watch(moodIndexProvider)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8, AppSpacing.md, 8, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(
                                  AppL10n.of(context).whatDoYouFeelNow),
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
                        child: SizedBox(
                            height: GlassNavBar.contentInset(context,
                                withPlayer:
                                    !ref.watch(playerProvider).isEmpty)),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// Шапка главного экрана: живой градиент, индекс настроения слева сверху,
/// имя слева снизу, котик справа снизу. По скроллу схлопывается в обычный
/// аппбар, где остаётся только имя.
class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.moodIndex});

  static const double _expandedHeight = 180;

  final int moodIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: _expandedHeight,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding:
            const EdgeInsetsDirectional.only(start: 20, bottom: AppSpacing.md),
        title: Text(
          'MurMur',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedGradient(),
            // Вуаль, иначе белый текст на светлых участках градиента тонет.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/logo/logo_appar_flex.png',
                width: 164,
                height: 164,
                opacity: const AlwaysStoppedAnimation(0.92),
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              child: _MoodIndexBadge(moodIndex: moodIndex),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodIndexBadge extends StatelessWidget {
  const _MoodIndexBadge({required this.moodIndex});

  final int moodIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FirebaseService.logEvent('home_moodindex_pressed');
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnalysisScreen()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppL10n.of(context).moodIndex,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$moodIndex',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.82), size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
