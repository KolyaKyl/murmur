import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/mood/widgets/mood_card/mood_item.dart';
import 'package:murmur/core/theme/app_theme.dart';

class MoodCard extends StatefulWidget {
  final List<Emotion> emotions;
  final AppUser appUser;
  const MoodCard({super.key, required this.emotions, required this.appUser});

  @override
  State<MoodCard> createState() => MoodCardState();
}

class MoodCardState extends State<MoodCard> {
  /// Колесо ужато на 15% от исходного. Масштабируются вместе три числа:
  /// высота строки, размер эмодзи и высота карточки — иначе эмодзи вылезет
  /// за пределы строки. Менять только здесь.
  static const double scale = 0.85;
  static const double itemExtent = 120 * scale;
  static const double emojiSize = 80 * scale;

  /// Просвет над и под центральной строкой: по нему видно, что колесо
  /// крутится. Меньше 20 — соседние эмоции перестают выглядывать.
  static const double peek = 20;

  /// Высота ровно по содержимому. Раньше считалась от высоты экрана,
  /// но строка колеса фиксированная, и от размера экрана менялся только
  /// просвет — на больших телефонах он раздувался без пользы.
  static const double cardHeight = itemExtent + peek * 2;

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
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              ListWheelScrollView.useDelegate(
                controller: _controller,
                useMagnifier: true,
                itemExtent: itemExtent,
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
                    );
                  }),
                ),
              ),
              Positioned(
                top: peek,
                left: 30,
                right: 30,
                child: Divider(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  thickness: 3,
                  height: 1,
                ),
              ),
              Positioned(
                bottom: peek,
                left: 30,
                right: 30,
                child: Divider(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
