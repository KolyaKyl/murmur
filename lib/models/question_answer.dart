// question.dart
class Question {
  final String text;
  final String? helper;
  final int order;
  final List<Answer> answers;

  Question({
    required this.text,
    this.helper,
    required this.order,
    required this.answers,
  });

  factory Question.fromFirestore(Map<String, dynamic> data) {
    return Question(
      text: data['Text'] ?? '',
      helper: data['Helper'],
      order: data['Order'] ?? 0,
      answers: (data['Answers'] as List<dynamic>)
          .map((a) => Answer.fromMap(a))
          .toList(),
    );
  }
}

class Answer {
  final String title;
  final int score;

  Answer({required this.title, required this.score});

  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      title: map['Title'] ?? '',
      score: map['Score'] ?? 0,
    );
  }
}
