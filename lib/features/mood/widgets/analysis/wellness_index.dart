import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/features/mood/screens/analysis_screen.dart';

class WellnessCard extends ConsumerStatefulWidget {
  const WellnessCard({super.key});

  @override
  ConsumerState<WellnessCard> createState() => _WellnessCardState();
}

class _WellnessCardState extends ConsumerState<WellnessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  String _getLabelForIndex(int index) {
    if (index == 0) return 'No data';
    if (index >= 80) return 'Peak';
    if (index >= 60) return 'High';
    if (index >= 40) return 'Average';
    if (index >= 20) return 'Low';
    return 'Bottom';
  }

  String _getSuggestion(int index) {
    if (index == 0) return 'Add a mood record';
    if (index >= 80) return 'Perfect, ride the wave!';
    if (index >= 60) return 'Looking good, respect!';
    if (index >= 40) return 'Not bad, but kick it up!';
    if (index >= 20) return 'Take a deep breath.';
    return 'Caution! Need a reset.';
  }

  Icon _getIconForIndex(int index) {
    final status = Theme.of(context).moodStatus;
    if (index == 0) {
      return Icon(Icons.cloud_off, color: status.empty, size: 38);
    } else if (index >= 80) {
      return Icon(Icons.rocket_launch, color: status.peak, size: 38);
    } else if (index >= 60) {
      return Icon(Icons.trending_up, color: status.high, size: 38);
    } else if (index >= 40) {
      return Icon(Icons.show_chart, color: status.average, size: 38);
    } else if (index >= 20) {
      return Icon(Icons.trending_down, color: status.low, size: 38);
    } else {
      return Icon(Icons.battery_1_bar, color: status.bottom, size: 38);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    final colorScheme = Theme.of(context).colorScheme;

    _color1 = ColorTween(
      begin: colorScheme.primary,
      end: colorScheme.secondary,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _color2 = ColorTween(
      begin: colorScheme.secondary,
      end: colorScheme.onPrimaryFixed,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final index = ref.watch(moodIndexProvider);
    final label = _getLabelForIndex(index);
    final suggestion = _getSuggestion(index);
    final icon = _getIconForIndex(index);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        height: max(
            (MediaQuery.of(context).size.height - kToolbarHeight) * 0.14, 120),
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _color1.value ?? colorScheme.primary,
                    _color2.value ?? colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    FirebaseService.logEvent('wellnessindexcard_pressed');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AnalysisScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer.withAlpha(55),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ' ',
                          style: textTheme.labelMedium?.copyWith(
                            // fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.linear(1.0),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 150),
                              child: Text(
                                '$index',
                                style: textTheme.displayLarge?.copyWith(
                                    fontSize: 70,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : colorScheme.onSurface),
                                textScaler: TextScaler.linear(1.0),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 170),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: textTheme.titleLarge?.copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w500,
                                            color: index == 0
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                : colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis,
                                        textScaler: TextScaler.linear(1.0),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      icon,
                                    ],
                                  ),
                                  Text(
                                    suggestion,
                                    style: textTheme.titleLarge?.copyWith(
                                        fontSize: 18,
                                        color: index == 0
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                            : colorScheme.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textScaler: TextScaler.linear(1.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width - 70),
                          child: Text(
                            'Calculated as the average of the last 7 days',
                            style: textTheme.labelMedium?.copyWith(
                              // fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textScaler: TextScaler.linear(1.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
