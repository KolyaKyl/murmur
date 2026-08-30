import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:self_screen/config/firebase_service.dart';
import 'package:self_screen/models/app_user.dart';
import 'package:self_screen/models/psychological_test.dart';
import 'package:self_screen/models/test_result.dart';
import 'package:self_screen/screens/test_screen.dart';
import 'package:self_screen/widgets/saved_dialog.dart';
import 'package:self_screen/widgets/test_widgets/test_card.dart';

class TestsSection extends StatefulWidget {
  final AppUser appUser;

  const TestsSection({super.key, required this.appUser});

  @override
  State<TestsSection> createState() => _TestsSectionState();
}

class _TestsSectionState extends State<TestsSection> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  List<PsychologicalTest> _tests = [];
  Map<String, TestResult> _lastTestsResults = {};
  double _currentPage = 0.0;
  int _lastReportedPage = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
    _currentPage = _pageController.initialPage.toDouble();
    _lastReportedPage = _currentPage.round();
    _pageController.addListener(_pageListener);
  }

  void _pageListener() {
    final newPage = _pageController.page ?? _currentPage;
    final rounded = newPage.round();

    if (rounded != _lastReportedPage) {
      HapticFeedback.mediumImpact();
      _lastReportedPage = rounded;
    }

    setState(() {
      _currentPage = newPage;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTests() async {
    final snapshot = await FirebaseFirestore.instance.collection('tests').get();
    final tests = snapshot.docs.map((doc) {
      return PsychologicalTest.fromMap(doc.id, doc.data());
    }).toList();
    final firebaseService = FirebaseService();
    Map<String, TestResult> lastTestsResults = await firebaseService
        .fetchLatestUserTestResults(widget.appUser.id, tests);

    setState(() {
      _tests = tests;
      _lastTestsResults = lastTestsResults;
      _isLoading = false;
    });

    // Начальная установка текущей страницы (для эффекта увеличения при первом рендере)
    Future.delayed(Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _currentPage = _pageController.initialPage.toDouble());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.38, // 270,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: max(
            (MediaQuery.of(context).size.height - kToolbarHeight) * 0.38,
            270,
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _tests.length,
            itemBuilder: (context, index) {
              final scale =
                  (1 - (_currentPage - index).abs() * 0.01).clamp(0.01, 1.0);
              return Center(
                child: Transform.scale(
                  scale: scale,
                  child: TestCard(
                    test: _tests[index],
                    testresult: _lastTestsResults[_tests[index].id],
                    onTap: () => _onTapTest(_tests[index]),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _onTapTest(PsychologicalTest test) async {
    HapticFeedback.mediumImpact();
    FirebaseService.logEvent(
        'testcard_${test.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '')}_pressed');
    final result = await Navigator.push<TestResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TestScreen(test: test),
      ),
    );
    if (!mounted) return;

    if (result != null) {
      showSuccessOverlay(context);
      setState(() {
        _lastTestsResults[test.id] = result;
      });
    }
  }
}
