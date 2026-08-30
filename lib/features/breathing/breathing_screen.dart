import 'package:flutter/material.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';

/// Заглушка. Практики и экран дыхания — фаза 6.
class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('Breathing'),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Coming soon')),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: GlassNavBar.contentInset(context)),
          ),
        ],
      ),
    );
  }
}
