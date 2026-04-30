import 'dart:async';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import 'package:triviaapp/models/ui_options.dart';
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
  final UIOptions _options;
  final SingleplayerSessionData _sessionData;
  final ISingleplayerGameService _gameService;

  SingleplayerGameScreen({
    super.key,
    UIOptions? options,
    required SingleplayerSessionData sessionData,
    ISingleplayerGameService? gameService,
  })  : _options = options ?? UIOptions(),
        _sessionData = sessionData,
        _gameService = gameService ?? SingleplayerGameService();

  @override
  State<SingleplayerGameScreen> createState() => _SingleplayerGameScreenState();
}

class _SingleplayerGameScreenState extends State<SingleplayerGameScreen>
    with TickerProviderStateMixin {
  UIOptions get options => widget._options;
  SingleplayerGameOptions get gameOptions => widget._sessionData.options;
  ISingleplayerGameService get gameService => widget._gameService;
  String get category => widget._sessionData.category;
  SingleplayerSessionData get sessionData => widget._sessionData;
  List<bool> get results => widget._sessionData.results;

  _Phase _phase = _Phase.loading;
  String _errorMessage = '';

  List<Question> _questions = [];
  int _currentIndex = 0;
  int _answeredQuestions = 0;

  late _QuestionState _questionState;

  AnimationController? _timerController;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timerController?.dispose();
    super.dispose();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<void> _loadQuestions() async {
    try {
      final questions = await gameService.loadQuestions(gameOptions, category);
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
    _timerController?.dispose();
    _timerController = null;

    _currentIndex++;
    final question = _questions[_currentIndex];

    setState(() {
      _questionState = _QuestionState(
        answers: gameService.getAnswerOptions(question),
      );
      _phase = _Phase.playing;
    });

    if (gameOptions.timePerQuestion > 0) {
      _timerController = AnimationController(
        vsync: this,
        duration: Duration(seconds: gameOptions.timePerQuestion),
      )
        ..addListener(() => setState(() {}))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _onTimeOut();
        })
        ..forward();
    }
  }

  void _onTimeOut() {
    if (_phase != _Phase.playing) return;
    _registerAnswer('', _questions[_currentIndex]);
  }

  void _onAnswerTapped(String answer) {
    if (_phase != _Phase.playing) return;
    _timerController?.stop();
    _registerAnswer(answer, _questions[_currentIndex]);
  }

  void _registerAnswer(String answer, Question question) {
    final isCorrect =
        answer.isNotEmpty && gameService.checkAnswer(question, answer);
    _answeredQuestions++;
    results.add(isCorrect);

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
      AppRoute.instance.goToSingleplayerScoreTable(options, sessionData);
      return;
    }
    _startQuestion();
  }

  int _correctAnswers() => results.where((e) => e).length;

  Future<void> _onClosePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: options.mainColor,
        title: Text(
          'Opuszczenie rozgrywki',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: options.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy na pewno chcesz opuścić rozgrywkę?',
          textAlign: TextAlign.center,
          style: TextStyle(color: options.textColor),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: options.mainButtonColor,
                  foregroundColor: options.textColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Menu główne'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: options.mainButtonColor,
                  foregroundColor: options.textColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Wróć do pytania'),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    AppRoute.instance.goToMainMenu(options);
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
    return Center(child: CircularProgressIndicator(color: options.textColor));
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
          const SizedBox(height: 12),
          // Okienko feedbacku zawsze rezerwuje przestrzeń pod headerem.
          // Gdy nie ma feedbacku, Opacity ukrywa widget ale zachowuje rozmiar.
          Opacity(
            opacity: inFeedback ? 1.0 : 0.0,
            child: _buildFeedbackBar(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildQuestionCard(context, question),
                const SizedBox(height: 20),
                _buildAnswerGrid(question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _onClosePressed,
          icon: const Icon(Icons.close),
          color: options.textColor,
        ),
        Column(
          children: [
            Text(
              'Pytanie $_currentIndex / ${_questions.length}',
              style: TextStyle(
                  color: options.textColor, fontWeight: FontWeight.bold),
            ),
            if (_answeredQuestions > 0)
              Text(
                'Wynik: ${_correctAnswers()} / $_answeredQuestions',
                style: TextStyle(
                  color: options.textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildTimerBar() {
    final ctrl = _timerController;
    final fraction =
    ctrl != null ? (1.0 - ctrl.value).clamp(0.0, 1.0) : 0.0;
    final secondsLeft = (fraction * gameOptions.timePerQuestion).ceil();

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
            '${secondsLeft}s',
            style: TextStyle(color: options.textColor, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    return SizedBox(
      width: double.infinity,
      child: Container(
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
      ),
    );
  }

  Widget _buildAnswerGrid(Question question) {
    final answers = _questionState.answers;
    final isBool = question.type == question.type; // always 2 cols
    final crossCount = 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: answers.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: answers.length == 2 ? 2.5 : 2.0,
      ),
      itemBuilder: (_, i) => _buildAnswerButton(answers[i], question),
    );
  }

  Widget _buildAnswerButton(String answer, Question question) {
    final selected = _questionState.selectedAnswer == answer;
    final inFeedback = _phase == _Phase.feedback;
    final isCorrectAnswer = question.correctAnswers.any(
          (c) => c.trim().toLowerCase() ==
          _toDbValue(answer).trim().toLowerCase(),
    );

    Color bgColor = options.secondaryColor.withOpacity(0.3);
    Color borderColor = options.mainButtonColor.withOpacity(0.3);

    if (inFeedback && selected) {
      // Podświetl tylko wybraną odpowiedź
      if (isCorrectAnswer) {
        bgColor = Colors.green.withOpacity(0.3);
        borderColor = Colors.green;
      } else {
        bgColor = Colors.red.withOpacity(0.3);
        borderColor = Colors.red;
      }
    } else if (inFeedback && isCorrectAnswer) {
      // Zawsze podświetl poprawną odpowiedź na zielono
      bgColor = Colors.green.withOpacity(0.3);
      borderColor = Colors.green;
    } else if (!inFeedback && selected) {
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
    final correctAnswer = _phase == _Phase.feedback
        ? _fromDbValue(_questions[_currentIndex].correctAnswers.first)
        : '';

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
                      fontSize: 13,
                    ),
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
              _currentIndex + 1 >= _questions.length ? 'Wyniki' : 'Następne',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _toDbValue(String answer) => switch (answer) {
    'Prawda' => 'True',
    'Fałsz' => 'False',
    _ => answer,
  };

  String _fromDbValue(String answer) => switch (answer) {
    'True' => 'Prawda',
    'False' => 'Fałsz',
    _ => answer,
  };
}