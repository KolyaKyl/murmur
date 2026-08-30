import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/mood/widgets/mood_card/mood_item.dart';
import 'package:murmur/features/mood/widgets/analysis/wellness_index.dart';

class MoodCard extends StatefulWidget {
  final List<Emotion> emotions;
  final AppUser appUser;
  final GlobalKey<WellnessCardState> wellnessCardKey;
  const MoodCard(
      {super.key,
      required this.emotions,
      required this.appUser,
      required this.wellnessCardKey});

  @override
  State<MoodCard> createState() => MoodCardState();
}

class MoodCardState extends State<MoodCard> {
  final FixedExtentScrollController _controller = FixedExtentScrollController();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadEmotions();
  }

  Future<void> _loadEmotions() async {
    if (widget.emotions.length > 11) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToDefault();
      });
    }
  }

  void scrollToDefault() {
    if (widget.emotions.length > 11) {
      _controller.animateToItem(
        _currentIndex + 11,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
      );
      setState(() {
        _currentIndex = _currentIndex + 11;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: max(
              (MediaQuery.of(context).size.height - kToolbarHeight) * 0.25,
              180),
          child: Stack(
            children: [
              ListWheelScrollView.useDelegate(
                controller: _controller,
                useMagnifier: true,
                itemExtent: 120,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.001,
                diameterRatio: 1.3,
                overAndUnderCenterOpacity: 0.3,
                squeeze: 1.3,
                onSelectedItemChanged: (index) {
                  if (_currentIndex != index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    HapticFeedback.selectionClick();
                  }
                },
                childDelegate: ListWheelChildLoopingListDelegate(
                  children: List.generate(widget.emotions.length, (index) {
                    final emotion = widget.emotions[index];
                    return MoodItem(
                      emotion: emotion,
                      isSelected: index == _currentIndex,
                      appUser: widget.appUser,
                      wellnessCardKey: widget.wellnessCardKey,
                    );
                  }),
                ),
              ),
              Positioned(
                top: (max(
                            (MediaQuery.of(context).size.height -
                                    kToolbarHeight) *
                                0.25,
                            180) -
                        120) /
                    2,
                left: 30,
                right: 30,
                child: Divider(
                  color: Colors.grey.shade400,
                  thickness: 3,
                  height: 1,
                ),
              ),
              Positioned(
                bottom: (max(
                            (MediaQuery.of(context).size.height -
                                    kToolbarHeight) *
                                0.25,
                            180) -
                        120) /
                    2,
                left: 30,
                right: 30,
                child: Divider(
                  color: Colors.grey.shade400,
                  thickness: 3,
                  height: 1,
                ),
              ),
              // Positioned(
              //   bottom: 15,
              //   left: 30,
              //   right: 30,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       Text(
              //         'Tap to record',
              //         style: textTheme.bodySmall,
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
