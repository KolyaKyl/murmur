import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:murmur/core/widgets/section_label.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/l10n/app_localizations.dart';

class DailyMoodChart extends StatefulWidget {
  final Map<DateTime, num> indexes;
  final void Function(DateTime)? onBarTap;
  final DateTime? selectedDate;

  const DailyMoodChart({
    super.key,
    required this.indexes,
    this.onBarTap,
    this.selectedDate,
  });

  @override
  State<DailyMoodChart> createState() => _DailyMoodChartState();
}

class _DailyMoodChartState extends State<DailyMoodChart> {
  int? selectedIndex;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  @override
  void didUpdateWidget(covariant DailyMoodChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });

    if (widget.selectedDate == null && selectedIndex != null) {
      setState(() {
        selectedIndex = null;
      });
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        duration: Duration(milliseconds: 600),
        maxScroll,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.indexes.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedKeys = widget.indexes.keys.toList()..sort();
    final firstDate = DateTime(
        sortedKeys.first.year, sortedKeys.first.month, sortedKeys.first.day);
    final lastDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int totalDays = lastDate.difference(firstDate).inDays + 1;
    if (totalDays < 30) totalDays = 30;
    final days = List.generate(
      totalDays,
      (i) => lastDate.subtract(Duration(days: totalDays - 1 - i)),
    );
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data = days
        .map((date) =>
            widget.indexes[DateTime(date.year, date.month, date.day)] ?? 0.0)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 270,
        decoration: appCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 8.0 + SectionLabel.inset, bottom: 0.0),
                child: Text(
                  AppL10n.of(context).moodIndexDaily,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: data.length * 32,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: 100,
                        alignment: BarChartAlignment.start,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.transparent,
                            tooltipPadding: EdgeInsets.zero,
                            tooltipMargin: 0,
                            fitInsideVertically: true,
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) =>
                                    BarTooltipItem(
                              rod.toY.toStringAsFixed(0),
                              Theme.of(context).textTheme.labelSmall!,
                            ),
                          ),
                          touchCallback:
                              (FlTouchEvent event, barTouchResponse) {
                            if (!event.isInterestedForInteractions ||
                                barTouchResponse == null) {
                              return;
                            }

                            final touched = barTouchResponse.spot;
                            // Обрабатываем только TapDown
                            if (event.runtimeType == FlTapDownEvent &&
                                touched != null) {
                              HapticFeedback.mediumImpact();
                              final tappedIndex = touched.touchedBarGroupIndex;

                              setState(() {
                                if (selectedIndex != tappedIndex) {
                                  selectedIndex = tappedIndex;
                                } else {
                                  selectedIndex = null;
                                }
                              });

                              if (widget.onBarTap != null &&
                                  tappedIndex >= 0 &&
                                  tappedIndex < days.length) {
                                final date = days[tappedIndex];
                                widget.onBarTap!(date);
                              }
                            }
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(context).colorScheme.secondary,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= days.length) {
                                  return const SizedBox.shrink();
                                }
                                final day = days[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        weekDays[day.weekday - 1],
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      Text(
                                        '${day.day}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(data.length, (i) {
                          final value = data[i];
                          bool isSelected = false;
                          if (selectedIndex != null) {
                            isSelected = selectedIndex == i;
                          }

                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                fromY: 0,
                                toY: value.toDouble(),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixed,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary,
                                        ],
                                      ),
                                width: 25,
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
