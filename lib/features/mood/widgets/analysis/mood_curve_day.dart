import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:murmur/features/mood/models/mood_record.dart';

class DailyMoodCurveChart extends StatefulWidget {
  final List<MoodRecord> records;

  const DailyMoodCurveChart({
    super.key,
    required this.records,
  });

  @override
  State<DailyMoodCurveChart> createState() => _DailyMoodCurveChartState();
}

class _DailyMoodCurveChartState extends State<DailyMoodCurveChart> {
  final ScrollController _scrollController = ScrollController();
  int? _lastTouchedIndex;

  @override
  void initState() {
    super.initState();
    // Прокрутка после первого построения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  @override
  void didUpdateWidget(covariant DailyMoodCurveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Прокрутка при обновлении записей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients && widget.records.isNotEmpty) {
      final lastTimestamp = widget.records.first.timestamp;
      final minutesSinceMidnight =
          lastTimestamp.hour * 60 + lastTimestamp.minute;
      const pixelsPerMinute = 0.4;
      final targetOffset = minutesSinceMidnight * pixelsPerMinute;

      // Ограничим прокрутку максимумом
      final maxExtent = _scrollController.position.maxScrollExtent;
      final safeOffset = targetOffset > maxExtent ? maxExtent : targetOffset;

      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...widget.records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<FlSpot> spots = sorted.map((record) {
      final time = record.timestamp;
      final minutesSinceMidnight = time.hour * 60 + time.minute;
      final x = minutesSinceMidnight.toDouble();
      final y = ((record.moodIndex + 1) / 2) * 100;
      return FlSpot(x, y);
    }).toList();

    const pixelsPerMinute = 0.4;
    const totalMinutes = 1440;
    const minChartWidth = pixelsPerMinute * totalMinutes;

    final screenWidth = MediaQuery.of(context).size.width;
    final chartWidth =
        screenWidth > minChartWidth ? screenWidth : minChartWidth;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 275,
        color: Theme.of(context).colorScheme.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mood curve (Hourly)',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(
                      widget.records[0].timestamp,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ],
              ),
            ),
            // График с прокруткой
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 1440,
                      minY: 0,
                      maxY: 102,
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) =>
                                Theme.of(context).colorScheme.surfaceDim,
                            tooltipRoundedRadius: 8,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipPadding: const EdgeInsets.all(4),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final index = spot.spotIndex;
                                if (index < 0 || index >= sorted.length) {
                                  return null;
                                }

                                final record = sorted[index];
                                final time = record.timestamp;
                                final hours =
                                    time.hour.toString().padLeft(2, '0');
                                final minutes =
                                    time.minute.toString().padLeft(2, '0');
                                final level = record.level;
                                final triggers = record.selectedTriggers;

                                final theme = Theme.of(context).textTheme;

                                final emojiAndLevel =
                                    '${record.emoji} lvl: $level';
                                final moodName = record.name;
                                final triggerText = triggers.isNotEmpty
                                    ? triggers.join(' ')
                                    : null;
                                final timeText = '$hours:$minutes';

                                return LineTooltipItem(
                                  '',
                                  const TextStyle(),
                                  children: [
                                    TextSpan(
                                      text: '$emojiAndLevel\n',
                                      style: theme.titleLarge
                                          ?.copyWith(fontSize: 18),
                                    ),
                                    TextSpan(
                                      text: '$moodName\n',
                                      style: theme.labelMedium,
                                    ),
                                    if (triggerText != null)
                                      TextSpan(
                                        text: '$triggerText\n',
                                        style: theme.labelSmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(200)),
                                      ),
                                    TextSpan(
                                      text: timeText,
                                      style: theme.labelSmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            }),
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              FlDotData(show: false),
                            );
                          }).toList();
                        },
                        touchCallback:
                            (FlTouchEvent event, LineTouchResponse? response) {
                          if (response?.lineBarSpots == null ||
                              response!.lineBarSpots!.isEmpty) {
                            return;
                          }

                          final currentIndex =
                              response.lineBarSpots!.first.spotIndex;

                          if (event is FlTapDownEvent) {
                            HapticFeedback.mediumImpact();
                            _lastTouchedIndex = currentIndex;
                          } else if (event is FlLongPressMoveUpdate) {
                            if (_lastTouchedIndex != currentIndex) {
                              HapticFeedback.mediumImpact();
                              _lastTouchedIndex = currentIndex;
                            }
                          }
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 60,
                            getTitlesWidget: (value, _) {
                              final hours = value ~/ 60;
                              final label = hours.toString().padLeft(2, '0');
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  label,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 20,
                        verticalInterval: 60,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Theme.of(context).colorScheme.secondary,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                        getDrawingVerticalLine: (_) => FlLine(
                          color: Theme.of(context).colorScheme.secondary,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryFixed,
                                strokeColor: Colors.transparent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                    ),
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
