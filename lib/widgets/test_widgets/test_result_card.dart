import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:self_screen/models/test_result.dart';

class TestResultCard extends StatelessWidget {
  final TestResult result;

  const TestResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillPercent = (result.score / result.maxLevel).clamp(0.0, 1.0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    result.title,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textScaler: TextScaler.linear(1.0),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(result.timestamp),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                                  result.score < result.maxLevel
                                      ? colorScheme.secondary
                                      : colorScheme.primary,
                                  result.score < result.maxLevel
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

                  //Content
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer.withAlpha(55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 12),

                            // Score
                            Text(
                              'Score: ',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            Text(
                              result.score.toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 12),

                            // result
                            Text(
                              result.result,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // recommendation
            Text(
              'Interpretation:',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textScaler: TextScaler.linear(1.0),
            ),
            const SizedBox(height: 4),
            Text(
              result.recommendation,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
