import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:self_screen/config/firebase_service.dart';
import 'package:self_screen/main.dart';
import 'package:self_screen/models/app_user.dart';
import 'package:self_screen/models/psychological_test.dart';
import 'package:self_screen/models/question_answer.dart';
import 'package:self_screen/models/test_result.dart';
import 'package:self_screen/widgets/test_widgets/questin_card.dart';

class TestScreen extends ConsumerStatefulWidget {
  final PsychologicalTest test;
  const TestScreen({super.key, required this.test});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  bool isLoading = true;
  bool isSubmitting = false;
  late AppUser? appUser;
  List<Question> questions = [];
  Map<int, int?> selectedAnswers = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initTest();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTest() async {
    setState(() => isLoading = true);

    appUser = ref.read(appUserProvider);
    if (appUser == null) {
      debugPrint('No user found in provider');
      setState(() => isLoading = false);
      return;
    }

    final firebaseService = FirebaseService();
    questions = await firebaseService.fetchTestQuestions(widget.test.id);
    selectedAnswers = {for (var i = 0; i < questions.length; i++) i: null};

    setState(() => isLoading = false);
  }

  Future<void> _submitTest() async {
    HapticFeedback.mediumImpact();
    if (isSubmitting) return;

    if (selectedAnswers.values.any((answer) => answer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    //confitmation
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        title: const Text('Confirm comletion'),
        content: const Text(
            'Are you sure you want to complete the test and save the results?'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: Colors.red,
              backgroundColor: Colors.transparent,
            ),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.red,
                  ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Colors.transparent,
            ),
            child: Text(
              'Save',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );

    // Если пользователь нажал Cancel или закрыл диалог
    if (shouldSave != true) {
      return;
    }

    setState(() => isSubmitting = true);

    int totalScore = 0;
    for (var i = 0; i < questions.length; i++) {
      final answerIndex = selectedAnswers[i];
      if (answerIndex != null) {
        totalScore = totalScore + questions[i].answers[answerIndex].score;
      }
    }

    final firebaseService = FirebaseService();
    await firebaseService.saveTestResult(
      userId: appUser!.id,
      test: widget.test,
      score: totalScore,
    );
    int maxLevel = firebaseService.getMaxLevel(widget.test.levels);
    final resultMap =
        firebaseService.getRecommendation(totalScore, widget.test.levels);

    setState(() => isSubmitting = false);
    if (!mounted) return;
    Navigator.pop(
        context,
        TestResult(
          id: '',
          title: widget.test.title,
          subname: widget.test.subname,
          testId: widget.test.id,
          score: totalScore,
          maxLevel: maxLevel,
          timestamp: DateTime.now(),
          result: resultMap['result'] ?? 'Unknown',
          recommendation:
              resultMap['recommendation'] ?? 'Score is out of range.',
        ));
  }

  void _onAnswerSelected(int questionIndex, int answerIndex) {
    setState(() {
      HapticFeedback.mediumImpact();
      selectedAnswers[questionIndex] = answerIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final answeredCount = selectedAnswers.values.where((a) => a != null).length;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            scrolledUnderElevation: 0,
            expandedHeight: 175,
            // floating: true,
            pinned: true,
            // snap: true,
            stretch: true,
            backgroundColor: colors.surface,
            title: Text(
              widget.test.title,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2.0),
              child: Container(
                color: colors.surface,
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                child: Row(
                  children: List.generate(questions.length, (index) {
                    final isAnswered = index < answeredCount;
                    return Expanded(
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.only(
                            right: index == questions.length - 1 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? colors.primary
                              : colors.onPrimaryFixed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background color/ subname/ helper
                  Container(
                    color: colors.surfaceContainer,
                    child: Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width - 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              //test subname
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: Text(
                                  widget.test.subname,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                  ),
                                  textScaler: TextScaler.linear(1.0),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              //Helper
                              widget.test.helper.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 8),
                                      child: Text(
                                        widget.test.helper,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 4,
                                        textScaler: TextScaler.linear(1.0),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Test logo image
                  if (widget.test.logoUrl.isNotEmpty)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CachedNetworkImage(
                        imageUrl: widget.test.logoUrl,
                        height: 160,
                        width: 160,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          height: 160,
                          width: 160,
                          color: colors.surfaceContainer,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.psychology_alt,
                          size: 160,
                          color: colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isLoading)
            // progress loading
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceDim,
                    borderRadius: BorderRadius.circular(12.0),
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
              ),
            )
          else
          // coming soon holder
          if (questions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Test is coming soon...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textScaler: TextScaler.linear(1.0),
                ),
              ),
            )
          else
            //questions
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final question = questions[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: TestQuestionCard(
                      question: question,
                      questionNumber: index + 1,
                      selectedAnswer: selectedAnswers[index],
                      onAnswerSelected: (answerIndex) =>
                          _onAnswerSelected(index, answerIndex),
                    ),
                  );
                },
                childCount: questions.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: isLoading || questions.isEmpty
          ? SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: _submitTest,
              icon: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onSurface,
                      ),
                    )
                  : Icon(Icons.done_all, color: colors.onSurface),
              label: Text(
                isSubmitting ? 'Saving...' : 'Complete',
                style: TextStyle(color: colors.onSurface),
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
    );
  }
}
