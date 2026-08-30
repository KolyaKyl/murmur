import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/mood_record.dart';
import 'package:murmur/features/mood/widgets/analysis/mood_chart.dart';
import 'package:murmur/features/mood/widgets/analysis/mood_curve_day.dart';
import 'package:murmur/features/mood/widgets/analysis/mood_record_card.dart';
import 'package:murmur/core/widgets/saved_dialog.dart';
import 'package:murmur/core/theme/app_theme.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool isLoading = false;
  List<MoodRecord> records = [];
  List<MoodRecord> dayRecords = [];
  late AppUser? appUser;

  Map<DateTime, num> dailyIndexes = {};
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUser(init: true);
    });
  }

  Future<void> _initUser({bool init = false}) async {
    if (mounted && init) {
      setState(() {
        isLoading = true;
      });
    }

    appUser = ref.read(appUserProvider);

    if (appUser == null) {
      debugPrint('No user found in provider');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final firebaseService = FirebaseService();
    try {
      records = await firebaseService.fetchMoodRecords(appUser!.id);
    } catch (e) {
      debugPrint('Analysis load failed: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not load your records. Check your connection.')),
        );
      }
      return;
    }

    selectedDate = null;
    dayRecords = records;

    dailyIndexes = calculateDailyWellnessIndicesFromRecords(records);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<DateTime, num> calculateDailyWellnessIndicesFromRecords(
      List<MoodRecord> records) {
    final Map<DateTime, List<double>> moodByDay = {};
    final firebaseService = FirebaseService();

    for (final record in records) {
      final date = DateTime(
          record.timestamp.year, record.timestamp.month, record.timestamp.day);

      moodByDay.putIfAbsent(date, () => []).add(record.moodIndex);
    }

    final Map<DateTime, num> dailyIndices = {};

    for (final entry in moodByDay.entries) {
      final moodValues = entry.value;
      final num average = moodValues.isNotEmpty
          ? firebaseService.computeDayIndex(moodValues)
          : 0;
      dailyIndices[entry.key] = average;
    }

    return dailyIndices;
  }

  void _getRecordsForDate(selectedDate) {
    List<MoodRecord> tempList = records.where((record) {
      final recordDate = DateTime(
          record.timestamp.year, record.timestamp.month, record.timestamp.day);
      return recordDate == selectedDate;
    }).toList();

    setState(() {
      dayRecords = tempList;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedRecords = List<MoodRecord>.from(dayRecords)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      body: isLoading
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
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              edgeOffset: kToolbarHeight + 20,
              onRefresh: () async => await _initUser(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    scrolledUnderElevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    floating: false,
                    pinned: true,
                    snap: false,
                    elevation: 0,
                    title: const Text('Mood Analysis'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: DailyMoodChart(
                        indexes: dailyIndexes,
                        selectedDate: selectedDate,
                        onBarTap: (date) {
                          setState(() {
                            if (selectedDate == date) {
                              selectedDate = null;
                              dayRecords = records;
                            } else {
                              selectedDate = date;
                              _getRecordsForDate(date);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  dayRecords.isNotEmpty
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final record = sortedRecords[index];
                              return Column(
                                children: [
                                  index == 0
                                      ? Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: selectedDate != null
                                                  ? DailyMoodCurveChart(
                                                      records: dayRecords,
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              child: MoodRecordCard(
                                                record: record,
                                                appUser: appUser!,
                                                update: (bool saved) {
                                                  showSuccessOverlay(context,
                                                      isDeleted: !saved);
                                                  _initUser();
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: MoodRecordCard(
                                            record: record,
                                            appUser: appUser!,
                                            update: (bool saved) {
                                              showSuccessOverlay(context,
                                                  isDeleted: !saved);
                                              _initUser();
                                            },
                                          ),
                                        ),
                                ],
                              );
                            },
                            childCount: sortedRecords.length,
                          ),
                        )
                      : SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 16,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'No data',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      textScaler: TextScaler.linear(1.0),
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Icon(
                                      Icons.cloud_off,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 38,
                                    )
                                  ],
                                ),
                                Text(
                                  'Add a mood record',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  textScaler: TextScaler.linear(1.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
