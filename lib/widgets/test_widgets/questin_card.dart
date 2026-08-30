import 'package:flutter/material.dart';
import 'package:self_screen/models/question_answer.dart';

class TestQuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;

  const TestQuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$questionNumber. ${question.text}',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.clip,
            ),

            // Helper text if available
            if (question.helper != null && question.helper!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  question.helper!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        // color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                  overflow: TextOverflow.clip,
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(
                color: Colors.grey.shade400,
                thickness: 2,
                height: 1,
              ),
            ),

            // Answers list
            RadioGroup<int>(
              groupValue: selectedAnswer,
              onChanged: (value) {
                if (value != null) onAnswerSelected(value);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: question.answers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final answer = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: RadioListTile<int>(
                        title: Text(
                          answer.title,
                        ),
                        value: index,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.only(left: 4),
                        controlAffinity: ListTileControlAffinity.leading,
                        visualDensity: VisualDensity.compact,
                        dense: true,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
