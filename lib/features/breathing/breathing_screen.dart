import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/l10n/app_localizations.dart';

/// Заглушка. Практики и экран дыхания — следующая фаза.
class BreathingScreen extends ConsumerWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            scrolledUnderElevation: 0,
            elevation: 0,
            title: Text(AppL10n.of(context).navBreathing),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(AppL10n.of(context).comingSoon)),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: GlassNavBar.contentInset(context,
                  withPlayer: !ref.watch(playerProvider).isEmpty),
            ),
          ),
        ],
      ),
    );
  }
}
