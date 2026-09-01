import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/features/breathing/data/breathing_providers.dart';
import 'package:murmur/features/breathing/models/practice.dart';
import 'package:murmur/features/breathing/screens/practice_setup_sheet.dart';
import 'package:murmur/features/breathing/widgets/practice_ring.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/core/widgets/premium_badge.dart';

/// Список практик. Фильтр не по «категории», а по ситуации: человек
/// приходит сюда с вопросом «что мне сейчас нужно», а не с календарём.
class BreathingScreen extends ConsumerWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final practices = ref.watch(practicesProvider);
    final filtered = ref.watch(filteredPracticesProvider);

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: kToolbarHeight + 20,
        onRefresh: () async {
          ref.invalidate(practicesProvider);
          ref.invalidate(breathingCategoriesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: Text(l10n.navBreathing),
            ),
            const SliverToBoxAdapter(child: _CategoryChips()),
            practices.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.couldNotLoadData)),
              ),
              data: (_) => filtered.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.noPracticesYet)),
                    )
                  : SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm + 2),
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.md,
                            i == 0 ? AppSpacing.sm : 0, AppSpacing.md, 0),
                        child: _PracticeCard(practice: filtered[i]),
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: GlassNavBar.contentInset(context,
                    withPlayer: !ref.watch(playerProvider).isEmpty),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(practiceFilterProvider);
    final categories =
        ref.watch(breathingCategoriesProvider).valueOrNull ?? const [];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _Chip(
            label: AppL10n.of(context).allCategories,
            selected: selected == null,
            onTap: () => ref.read(practiceFilterProvider.notifier).state = null,
          ),
          for (final c in categories)
            _Chip(
              label: c.title,
              selected: selected == c.id,
              onTap: () => ref.read(practiceFilterProvider.notifier).state =
                  selected == c.id ? null : c.id,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected
                ? scheme.onSurface.withValues(alpha: 0.13)
                : Colors.transparent,
            border: Border.all(
                color: selected ? Colors.transparent : scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends ConsumerWidget {
  const _PracticeCard({required this.practice});

  final BreathingPractice practice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    // Названия категорий берём из справочника, а не из зашитого списка:
    // новая категория должна появляться без правки кода.
    final titles = {
      for (final c
          in ref.watch(breathingCategoriesProvider).valueOrNull ?? const [])
        c.id: c.title
    };
    final purpose = practice.categories.map((c) => titles[c] ?? c).join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => PracticeSetupSheet.show(context, practice),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md - 2),
        decoration: appCardDecoration(context),
        child: Row(
          children: [
            PracticeRing(practice: practice),
            const SizedBox(width: AppSpacing.md - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(practice.title,
                      style: textTheme.bodyLarge?.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(practice.rhythm,
                      style:
                          textTheme.bodyMedium?.copyWith(letterSpacing: 0.6)),
                  const SizedBox(height: 5),
                  Text(purpose,
                      style: textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (practice.premium)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: PremiumBadge(),
              ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
