class GameAnswer {
  final bool isCorrect;
  final List<String> correctAnswers;

  const GameAnswer({required this.isCorrect, required this.correctAnswers});

  factory GameAnswer.fromJson(Map<String, dynamic> json) => GameAnswer(
    isCorrect: json['isCorrect'] as bool,
    correctAnswers: List<String>.from(json['correctAnswers'] as List),
  );
}
