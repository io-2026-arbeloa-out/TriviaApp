import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/score_table_screen.dart';
import 'package:triviaapp/services/singleplayer_game_service.dart';

enum _Phase { loading, playing, feedback, error }

class _QuestionState {
  final List<String> answers;
  final String? selectedAnswer;
  final bool? isCorrect;

  const _QuestionState({
    required this.answers,
    this.selectedAnswer,
    this.isCorrect,
  });

  _QuestionState copyWith({
    List<String>? answers,
    String? selectedAnswer,
    bool? isCorrect,
  }) {
    return _QuestionState(
      answers: answers ?? this.answers,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class SingleplayerGameScreen extends StatefulWidget {
  final String _category;
  final UIOptions _options;
  final SingleplayerGameOptions _gameOptions;
  final ISingleplayerGameService _gameService;

  SingleplayerGameScreen({
    super.key,
    required String category,
    UIOptions? options,
    required SingleplayerGameOptions gameOptions,
    ISingleplayerGameService? gameService,
  }) : _options = options ?? UIOptions(),
       _category = category,
       _gameOptions = gameOptions,
       _gameService = gameService ?? SingleplayerGameService();

  @override
  State<SingleplayerGameScreen> createState() => _SingleplayerGameScreenState();
}

class _SingleplayerGameScreenState extends State<SingleplayerGameScreen> {
  UIOptions get options => widget._options;
  SingleplayerGameOptions get gameOptions => widget._gameOptions;
  ISingleplayerGameService get gameService => widget._gameService;
  String get category => widget._category;

  _Phase _phase = _Phase.loading;
  String _errorMessage = '';

  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;

  late _QuestionState _questionState;
  final List<bool> _results = [];

  int _timeLeft = 0;
  Timer? _timer;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<void> _loadQuestions() async {
    try {
      final questions = await gameService.loadQuestions(
        gameOptions,
        category,//todo question type parser
      );
      if (questions.isEmpty) {
        setState(() {
          _phase = _Phase.error;
          _errorMessage = 'Brak pytań dla wybranej kategorii i typu.';
        });
        return;
      }
      _questions = questions;
      _startQuestion();
    } catch (e) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage = 'Nie udało się załadować pytań.';
      });
    }
  }

  // ── Question flow ──────────────────────────────────────────────────────────

  void _startQuestion() {
    _timer?.cancel();
    final question = _questions[_currentIndex];

    setState(() {
      _questionState = _QuestionState(answers: _buildAnswerOptions(question));
      _timeLeft = gameOptions.timePerQuestion;
      _phase = _Phase.playing;
    });

    if (gameOptions.timePerQuestion > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_timeLeft <= 1) {
          _timer?.cancel();
          _onTimeOut();
        } else {
          setState(() => _timeLeft--);
        }
      });
    }
  }

  void _onTimeOut() {
    final question = _questions[_currentIndex];
    _registerAnswer('', question);
  }

  void _onAnswerTapped(String answer) {
    if (_phase != _Phase.playing) return;
    _timer?.cancel();
    final question = _questions[_currentIndex];
    _registerAnswer(answer, question);
  }

  void _registerAnswer(String answer, Question question) {
    final isCorrect =
        answer.isNotEmpty && gameService.checkAnswer(question, answer);

    if (isCorrect) {
      _results.add(true);
    } else {
      _results.add(false);
    }

    setState(() {
      _questionState = _questionState.copyWith(
        selectedAnswer: answer.isEmpty ? '—' : answer,
        isCorrect: isCorrect,
      );
      _phase = _Phase.feedback;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      _finishGame();
      return;
    }
    _currentIndex++;
    _startQuestion();
  }

  void _finishGame() {
    AppRoute.instance.goToScoreTable(options, _results);
  }

  // ── Answer options ─────────────────────────────────────────────────────────

  List<String> _buildAnswerOptions(Question question) {
    if (question.type == QuestionType.boolean) {
      return ['Prawda', 'Fałsz'];
    }
    final opts = [
      ...question.correctAnswers,
      ...?question.wrongAnswers,
    ];
    opts.shuffle(_random);
    return opts;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [options.mainColor, options.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.loading => _buildLoading(),
            _Phase.error => _buildError(),
            _Phase.playing || _Phase.feedback => _buildGame(context),
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(color: options.textColor),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: options.textColor, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: options.mainButtonColor,
                foregroundColor: options.textColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Wróć'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final question = _questions[_currentIndex];
    final inFeedback = _phase == _Phase.feedback;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGameHeader(context),
          const SizedBox(height: 8),
          if (gameOptions.timePerQuestion > 0) _buildTimerBar(),
          const SizedBox(height: 16),
          _buildQuestionCard(context, question),
          const SizedBox(height: 20),
          Expanded(child: _buildAnswerGrid(question)),
          if (inFeedback) ...[
            const SizedBox(height: 12),
            _buildFeedbackBar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildGameHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: options.textColor,
        ),
        Column(
          children: [
            Text(
              'Pytanie ${_currentIndex + 1} / ${_questions.length}',
              style: TextStyle(
                  color: options.textColor, fontWeight: FontWeight.bold),
            ),
            Text(
              'Wynik: $_score',
              style: TextStyle(
                  color: options.textColor.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildTimerBar() {
    final fraction = gameOptions.timePerQuestion > 0
        ? _timeLeft / gameOptions.timePerQuestion
        : 1.0;

    final barColor = fraction > 0.5
        ? Colors.green
        : fraction > 0.25
        ? Colors.orange
        : Colors.red;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: options.secondaryColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_timeLeft}s',
            style: TextStyle(color: options.textColor, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: options.secondaryColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        question.text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: options.textColor,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAnswerGrid(Question question) {
    final answers = _questionState.answers;
    final isBool = question.type == QuestionType.boolean;
    final crossCount = isBool ? 2 : 2;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: answers.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isBool ? 2.5 : 2.0,
      ),
      itemBuilder: (_, i) => _buildAnswerButton(answers[i], question),
    );
  }

  Widget _buildAnswerButton(String answer, Question question) {
    final selected = _questionState.selectedAnswer == answer;
    final inFeedback = _phase == _Phase.feedback;
    final isCorrect = question.correctAnswers.any(
          (c) => c.trim().toLowerCase() == answer.trim().toLowerCase(),
    );

    Color bgColor = options.secondaryColor.withOpacity(0.3);
    Color borderColor = options.mainButtonColor.withOpacity(0.3);

    if (inFeedback) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.3);
        borderColor = Colors.green;
      } else if (selected) {
        bgColor = Colors.red.withOpacity(0.3);
        borderColor = Colors.red;
      }
    } else if (selected) {
      bgColor = options.mainButtonColor.withOpacity(0.3);
      borderColor = options.mainButtonColor;
    }

    return GestureDetector(
      onTap: inFeedback ? null : () => _onAnswerTapped(answer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          answer,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: options.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackBar(BuildContext context) {
    final isCorrect = _questionState.isCorrect ?? false;
    final correctAnswer =
        _questions[_currentIndex].correctAnswers.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Poprawna odpowiedź!' : 'Błędna odpowiedź',
                  style: TextStyle(
                    color: options.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isCorrect)
                  Text(
                    'Prawidłowa: $correctAnswer',
                    style: TextStyle(
                        color: options.textColor.withOpacity(0.8),
                        fontSize: 13),
                  ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: options.mainButtonColor,
              foregroundColor: options.textColor,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _nextQuestion,
            child: Text(
              _currentIndex + 1 >= _questions.length
                  ? 'Wyniki'
                  : 'Następne',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}