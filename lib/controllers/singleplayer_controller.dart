import 'package:flutter/foundation.dart';
import 'package:triviaapp/controllers/controller_timer.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';

enum SingleplayerPhase { loading, playing, checking, feedback, error, finished }

class SingleplayerQuestionState {
  final List<String> answers;
  final String? selectedAnswer;
  final bool? isCorrect;
  final List<String> correctAnswers;
  SingleplayerQuestionState({
    required List<String> answers,
    this.selectedAnswer,
    this.isCorrect,
    List<String> correctAnswers = const [],
  }) : answers = List.unmodifiable(answers),
       correctAnswers = List.unmodifiable(correctAnswers);
}

class SingleplayerController extends ChangeNotifier {
  final ISingleplayerGameService service;
  final SingleplayerSessionData session;
  final ScheduleTimer _schedule;
  bool _disposed = false;
  bool _submitting = false;
  int _generation = 0;
  CancelTimer? _cancelTimeout;
  String _pendingAnswer = '';
  SingleplayerPhase phase = SingleplayerPhase.loading;
  String errorMessage = '';
  bool validationFailed = false;
  List<Question> questions = const [];
  int currentIndex = 0;
  SingleplayerQuestionState questionState = SingleplayerQuestionState(
    answers: const [],
  );
  int get answeredQuestions => session.results.length;
  int get correctAnswers => session.results.where((result) => result).length;

  SingleplayerController({
    required this.service,
    required this.session,
    ScheduleTimer? schedule,
  }) : _schedule = schedule ?? scheduleControllerTimer;

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final loaded = await service.loadQuestions(
        session.options,
        session.category,
      );
      if (_disposed || generation != _generation) return;
      if (loaded.isEmpty) {
        errorMessage = 'Brak pytań dla wybranej kategorii i typu.';
        phase = SingleplayerPhase.error;
        notifyListeners();
        return;
      }
      questions = List.unmodifiable(loaded);
      _beginQuestion();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      errorMessage = 'Nie udało się załadować pytań.';
      phase = SingleplayerPhase.error;
      notifyListeners();
    }
  }

  void _beginQuestion() {
    _cancelTimeout?.call();
    questionState = SingleplayerQuestionState(
      answers: service.getAnswerOptions(questions[currentIndex]),
    );
    phase = SingleplayerPhase.playing;
    validationFailed = false;
    if (session.options.timePerQuestion > 0) {
      _cancelTimeout = _schedule(
        Duration(seconds: session.options.timePerQuestion),
        timeOut,
      );
    }
    notifyListeners();
  }

  void timeOut() {
    if (!_disposed && phase == SingleplayerPhase.playing) answer('');
  }

  Future<void> answer(String value) async {
    if (_disposed || phase != SingleplayerPhase.playing) return;
    _pendingAnswer = value;
    _cancelTimeout?.call();
    phase = SingleplayerPhase.checking;
    await _validate();
  }

  Future<void> retryAnswer() async {
    if (_disposed || phase != SingleplayerPhase.checking || !validationFailed) {
      return;
    }
    await _validate();
  }

  Future<void> _validate() async {
    if (_submitting) return;
    _submitting = true;
    validationFailed = false;
    final generation = _generation;
    notifyListeners();
    try {
      final result = await service.checkAnswer(
        questions[currentIndex],
        _pendingAnswer,
      );
      if (_disposed || generation != _generation) return;
      session.results.add(result.isCorrect);
      questionState = SingleplayerQuestionState(
        answers: questionState.answers,
        selectedAnswer: _pendingAnswer.isEmpty ? '—' : _pendingAnswer,
        isCorrect: result.isCorrect,
        correctAnswers: result.correctAnswers,
      );
      phase = SingleplayerPhase.feedback;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      validationFailed = true;
    } finally {
      _submitting = false;
      if (!_disposed && generation == _generation) notifyListeners();
    }
  }

  void next() {
    if (_disposed || phase != SingleplayerPhase.feedback) return;
    if (currentIndex + 1 == questions.length) {
      phase = SingleplayerPhase.finished;
      notifyListeners();
    } else {
      currentIndex++;
      _beginQuestion();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cancelTimeout?.call();
    super.dispose();
  }
}
