import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:self_screen/config/firebase_service.dart';
import 'package:self_screen/models/app_user.dart';
import 'package:self_screen/models/psychological_test.dart';
import 'package:self_screen/models/test_result.dart';
import 'package:self_screen/screens/test_screen.dart';
import 'package:self_screen/widgets/saved_dialog.dart';
import 'package:self_screen/widgets/test_widgets/test_card.dart';
import 'package:self_screen/widgets/test_widgets/test_result_card.dart';

class TestsScreen extends StatefulWidget {
  final AppUser appUser;
  const TestsScreen({super.key, required this.appUser});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  final FirebaseService _firebaseService = FirebaseService();
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  List<PsychologicalTest> _tests = [];
  Map<String, List<TestResult>> _testResults = {};
  bool _isLoading = true;

  bool _showResults = true;

  @override
  void initState() {
    super.initState();
    _loadTestsAndResults();
  }

  Future<void> _onTestChanged(int index) async {
    setState(() => _showResults = false);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _selectedIndex.value = index;
      _showResults = true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  Future<void> _loadTestsAndResults() async {
    final snapshot = await FirebaseFirestore.instance.collection('tests').get();
    final tests = snapshot.docs
        .map((doc) => PsychologicalTest.fromMap(doc.id, doc.data()))
        .toList();

    final Map<String, List<TestResult>> results = {};
    for (final test in tests) {
      results[test.id] = await _firebaseService.fetchUserTestResults(
        widget.appUser.id,
        test.id,
      );
    }

    setState(() {
      _tests = tests;
      _testResults = results;
      _isLoading = false;
    });
  }

  void _onTapTest(PsychologicalTest test) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<TestResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TestScreen(test: test),
      ),
    );

    if (result != null) {
      if (mounted) {
        showSuccessOverlay(context);
      }
      final updated = await _firebaseService.fetchUserTestResults(
        widget.appUser.id,
        result.testId,
      );
      setState(() => _testResults[result.testId] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  scrolledUnderElevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  floating: false,
                  pinned: true,
                  snap: false,
                  elevation: 0,
                  title: const Text('Psychological Tests'),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: max(
                      (MediaQuery.of(context).size.height - kToolbarHeight) *
                          0.35,
                      300,
                    ),
                    child: PageView.builder(
                      itemCount: _tests.length,
                      onPageChanged: (index) => _onTestChanged(index),
                      controller: _pageController,
                      itemBuilder: (context, index) {
                        final test = _tests[index];
                        final scale = (1 -
                                (_pageController.hasClients
                                            ? (_pageController.page ?? 0) -
                                                index
                                            : 0)
                                        .abs() *
                                    0.01)
                            .clamp(0.01, 1.0);
                        return Center(
                          child: Transform.scale(
                            scale: scale,
                            child: TestCard(
                              test: test,
                              testresult: null,
                              onTap: () => _onTapTest(test),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    //curve: Curves.easeOutCubic,
                    duration: const Duration(milliseconds: 200),
                    opacity: _showResults ? 1.0 : 0.0,
                    child: AnimatedSlide(
                      curve: Curves.easeOutCubic,
                      duration: const Duration(milliseconds: 800),
                      offset: _showResults ? Offset.zero : const Offset(0, 1),
                      child: Column(
                        key: ValueKey(_selectedIndex.value),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_testResults[_tests[_selectedIndex.value].id]
                                  ?.isNotEmpty ??
                              false)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Text(
                                'Results:',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          if (_testResults[_tests[_selectedIndex.value].id]
                                  ?.isNotEmpty ??
                              false)
                            ..._testResults[_tests[_selectedIndex.value].id]!
                                .map((r) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: TestResultCard(result: r),
                                    )),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
    );
  }
}
