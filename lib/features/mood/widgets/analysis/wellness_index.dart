import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/features/mood/screens/analysis_screen.dart';

class WellnessCard extends StatefulWidget {
  final int moodIndex;

  const WellnessCard({
    super.key,
    required this.moodIndex,
  });

  @override
  State<WellnessCard> createState() => WellnessCardState();
}

class WellnessCardState extends State<WellnessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  int _wellnessIndex = 0;
  String _wellnessLabel = 'Loading...';
  String _welnessSuggestion = '';
  Icon _wellnessIcon = Icon(
    Icons.cloud_off,
    color: Colors.grey,
  );

  void updateWellnessIndex(int index) {
    setState(() {
      _wellnessIndex = index;
      _wellnessLabel = _getLabelForIndex(index);
      _welnessSuggestion = _getSuggestion(index);
      _wellnessIcon = _getIconForIndex(index);
    });
  }

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
    if (index == 0) {
      return const Icon(
        Icons.cloud_off,
        color: Colors.grey,
        size: 38,
      );
    } else if (index >= 80) {
      return const Icon(
        Icons.rocket_launch,
        color: Colors.deepPurple,
        size: 38,
      );
    } else if (index >= 60) {
      return const Icon(
        Icons.trending_up,
        color: Colors.green,
        size: 38,
      );
    } else if (index >= 40) {
      return const Icon(
        Icons.show_chart,
        color: Colors.yellow,
        size: 38,
      );
    } else if (index >= 20) {
      return const Icon(
        Icons.trending_down,
        color: Colors.orange,
        size: 38,
      );
    } else {
      return const Icon(
        Icons.battery_1_bar,
        color: Colors.red,
        size: 38,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _wellnessIndex = widget.moodIndex;
    updateWellnessIndex(_wellnessIndex);
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

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: max(
            (MediaQuery.of(context).size.height - kToolbarHeight) * 0.14, 120),
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    FirebaseService.logEvent('wellnessindexcard_pressed');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AnalysisScreen(
                          wellnessCardKey:
                              widget.key as GlobalKey<WellnessCardState>,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer.withAlpha(55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ' ',
                          style: textTheme.labelMedium?.copyWith(
                            // fontWeight: FontWeight.bold,
                            color: Colors.grey,
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
                                '$_wellnessIndex',
                                style: textTheme.displayLarge?.copyWith(
                                    fontSize: 70,
                                    fontWeight: FontWeight.bold,
                                    color: _wellnessIndex == 0
                                        ? Colors.grey
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
                                        _wellnessLabel,
                                        style: textTheme.titleLarge?.copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w500,
                                            color: _wellnessIndex == 0
                                                ? Colors.grey
                                                : colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis,
                                        textScaler: TextScaler.linear(1.0),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      _wellnessIcon,
                                    ],
                                  ),
                                  Text(
                                    _welnessSuggestion,
                                    style: textTheme.titleLarge?.copyWith(
                                        fontSize: 18,
                                        color: _wellnessIndex == 0
                                            ? Colors.grey
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
                              color: Colors.grey,
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
