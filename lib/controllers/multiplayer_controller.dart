import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:triviaapp/controllers/controller_timer.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/session_status.dart';

enum MultiplayerPhase {
  loading,
  answering,
  waiting,
  resolving,
  eliminated,
  finished,
}

class MultiplayerController extends ChangeNotifier {
  final IMultiplayerGameService service;
  final ScheduleTimer _schedule;
  StreamSubscription<LiveGameState>? _subscription;
  CancelTimer? _cancelWatchdog;
  CancelTimer? _cancelRoundWatchdog;
  CancelTimer? _cancelResultsRetry;
  bool _disposed = false;
  bool _leaving = false;
  int _connection = 0;
  int _answerVersion = 0;
  bool _submitting = false;
  bool _fetchingResults = false;
  int _resultAttempts = 0;
  LiveGameState? state;
  MultiplayerPhase phase = MultiplayerPhase.loading;
  List<String> answers = const [];
  String? selectedAnswer;
  bool? isAnswerCorrect;
  List<String> revealedAnswers = const [];
  bool hasAnswered = false;
  Object? answerError;
  Object? connectionError;
  Object? resultsError;
  bool roundStalled = false;
  RoundResult? cachedRoundResult;
  MultiplayerSessionData? finalSession;

  MultiplayerController({required this.service, ScheduleTimer? schedule})
    : _schedule = schedule ?? scheduleControllerTimer;

  Future<void> connect() async {
    if (_disposed || _leaving || phase == MultiplayerPhase.finished) return;
    final connection = ++_connection;
    await _subscription?.cancel();
    if (_disposed || _leaving || connection != _connection) return;
    connectionError = null;
    _cancelWatchdog?.call();
    _cancelWatchdog = _schedule(const Duration(seconds: 12), () {
      if (_disposed || connection != _connection) return;
      connectionError = StateError(
        'Brak aktualizacji sesji. Spróbuj połączyć się ponownie.',
      );
      notifyListeners();
    });
    _subscription = service.buildLiveGameStateStream().listen(
      (value) {
        if (!_disposed && !_leaving && connection == _connection) {
          _onState(value);
        }
      },
      onError: (Object error) {
        if (_disposed || _leaving || connection != _connection) return;
        connectionError = error;
        notifyListeners();
      },
      onDone: () {
        if (_disposed ||
            _leaving ||
            connection != _connection ||
            phase == MultiplayerPhase.finished) {
          return;
        }
        connectionError = StateError('Połączenie z sesją zostało zakończone.');
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void _onState(LiveGameState value) {
    if (state != null &&
        value.currentQuestionIndex < state!.currentQuestionIndex) {
      return;
    }
    if (state?.phase == RoundPhase.resolving &&
        value.isAnswering &&
        value.currentQuestionIndex == state!.currentQuestionIndex) {
      return;
    }
    _cancelWatchdog?.call();
    connectionError = null;
    final newRound = value.currentQuestionIndex != state?.currentQuestionIndex;
    if (newRound) {
      _answerVersion++;
      _submitting = false;
      hasAnswered = false;
      selectedAnswer = null;
      isAnswerCorrect = null;
      revealedAnswers = const [];
      answerError = null;
      if (value.currentQuestionIndex < service.questions.length) {
        answers = List.unmodifiable(
          service.questions[value.currentQuestionIndex].answers.toList()
            ..shuffle(),
        );
      }
    }
    final previousPhase = phase;
    state = value;
    if (newRound ||
        value.phase != RoundPhase.resolving ||
        value.status != SessionStatus.inProgress) {
      _cancelRoundWatchdog?.call();
      roundStalled = false;
    }
    if (value.lastRoundResult != null) {
      cachedRoundResult = value.lastRoundResult;
    }
    if (value.status == SessionStatus.finished && value.resultsReady) {
      phase = MultiplayerPhase.finished;
      _subscription?.cancel();
      _subscription = null;
      if (!_fetchingResults) _fetchResults();
    } else if (value.status != SessionStatus.inProgress) {
      phase = MultiplayerPhase.loading;
    } else if (value.phase == RoundPhase.resolving) {
      phase = MultiplayerPhase.resolving;
      if (previousPhase != phase || newRound) {
        roundStalled = false;
        _cancelRoundWatchdog = _schedule(const Duration(seconds: 12), () {
          if (!_disposed && !_leaving && phase == MultiplayerPhase.resolving) {
            roundStalled = true;
            notifyListeners();
          }
        });
      }
    } else {
      roundStalled = false;
      phase = value.amIEliminated
          ? MultiplayerPhase.eliminated
          : hasAnswered
          ? MultiplayerPhase.waiting
          : MultiplayerPhase.answering;
    }
    notifyListeners();
  }

  Future<void> answer(String value) async {
    if (_disposed ||
        _leaving ||
        phase != MultiplayerPhase.answering ||
        hasAnswered) {
      return;
    }
    selectedAnswer = value;
    hasAnswered = true;
    phase = MultiplayerPhase.waiting;
    await _submit();
  }

  Future<void> retryAnswer({int? expectedRoundIndex}) async {
    if (_disposed ||
        _leaving ||
        answerError == null ||
        !hasAnswered ||
        state?.isAnswering != true ||
        (expectedRoundIndex != null &&
            state?.currentQuestionIndex != expectedRoundIndex)) {
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _submitting = true;
    answerError = null;
    final version = _answerVersion;
    final index = state!.currentQuestionIndex;
    notifyListeners();
    try {
      final result = await service.submitAnswer(
        roundIndex: index,
        questionId: service.questions[index].id,
        answer: selectedAnswer!,
      );
      if (_disposed || _leaving || version != _answerVersion) return;
      isAnswerCorrect = result.isCorrect;
      revealedAnswers = List.unmodifiable(result.correctAnswers);
    } catch (error) {
      if (_disposed ||
          _leaving ||
          version != _answerVersion ||
          state?.isAnswering != true) {
        return;
      }
      answerError = error;
    } finally {
      if (!_disposed && !_leaving && version == _answerVersion) {
        _submitting = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchResults() async {
    _fetchingResults = true;
    _resultAttempts++;
    try {
      final result = await service.fetchFinalSessionData();
      if (_disposed || _leaving) return;
      finalSession = result;
      resultsError = null;
      notifyListeners();
    } catch (error) {
      if (_disposed || _leaving) return;
      if (_resultAttempts < 5) {
        _cancelResultsRetry = _schedule(
          const Duration(seconds: 2),
          _fetchResults,
        );
      } else {
        resultsError = error;
        notifyListeners();
      }
    }
  }

  Future<void> leave() async {
    if (_leaving || _disposed) return;
    _leaving = true;
    _connection++;
    _answerVersion++;
    _cancelWatchdog?.call();
    _cancelRoundWatchdog?.call();
    _cancelResultsRetry?.call();
    await _subscription?.cancel();
    await service.leaveGame();
  }

  @override
  void dispose() {
    _disposed = true;
    _connection++;
    _answerVersion++;
    _subscription?.cancel();
    _cancelWatchdog?.call();
    _cancelRoundWatchdog?.call();
    _cancelResultsRetry?.call();
    super.dispose();
  }
}
