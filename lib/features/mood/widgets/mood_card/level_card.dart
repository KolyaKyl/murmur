import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/theme/app_theme.dart';

class LevelCard extends StatefulWidget {
  final num initialLevel;
  final Function(num) onChanged;
  final String label;
  final String emoji;
  final String heroTag;

  const LevelCard({
    super.key,
    required this.initialLevel,
    required this.onChanged,
    required this.label,
    required this.emoji,
    required this.heroTag,
  });

  @override
  State<LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<LevelCard>
    with SingleTickerProviderStateMixin {
  late num _level;
  List<Colors> colorsList = [];

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _updateLevel(DragUpdateDetails details) {
    final delta = details.delta.dx;
    setState(() {
      _level += delta * 0.04;
      _level = _level.clamp(1, 10);
    });
    widget.onChanged(_level.round());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final fillPercent = (_level / 10).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _updateLevel,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Color level
            Positioned.fill(
              child: Row(
                children: [
                  // Filled part
                  Expanded(
                    flex: (fillPercent * 1000).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  // Notfilled part
                  Expanded(
                    flex: 1000 - (fillPercent * 1000).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _level < 10
                                ? colorScheme.secondary
                                : colorScheme.primary,
                            _level < 10
                                ? colorScheme.onPrimaryFixed
                                : colorScheme.secondary,
                          ],
                          // stops: [0.0, 0.95, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _level = (_level >= 10) ? 1 : _level + 1;
                  });
                  widget.onChanged(_level.round());
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 16, 25, 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.withAlpha(18),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag:
                                    'mood-emoji-${widget.emoji}-${widget.heroTag}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Transform.scale(
                                    scale: 1,
                                    child: Text(
                                      widget.emoji,
                                      style: const TextStyle(fontSize: 90),
                                      textScaler: TextScaler.linear(1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Hero(
                                tag:
                                    'mood-emoji-${widget.label}-text-${widget.heroTag}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Transform.scale(
                                    scale: 1,
                                    child: Text(
                                      widget.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(fontSize: 30),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '${_level.round()}',
                                style: textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Level',
                                style: textTheme.titleLarge
                                    ?.copyWith(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Swipe or tap to adjust',
                        style: textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
