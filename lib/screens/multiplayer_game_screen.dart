import 'dart:async';

import 'package:flutter/material.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/multiplayer_score_table_screen.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

// ── Local UI phase ─────────────────────────────────────────────────────────

enum _UIPhase {
  loading,     // waiting for first LiveGameState
  answering,   // I haven't answered yet
  waiting,     // I answered, waiting for others
  resolving,   // round resolved — showing elimination result
  eliminated,  // I was eliminated — brief screen before results
  finished,    // fetching archive + navigating
}

class MultiplayerGameScreen extends StatefulWidget {
  final UIOptions options;
  final String sessionId;
  final String myUid;
  final String myUsername;
  final List<Question> questions;
  final IMultiplayerGameService gameService;

  MultiplayerGameScreen({
    super.key,
    String? sessionId,
    String? myUid,
    String? myUsername,
    List<Question>? questions,
    IMultiplayerGameService? gameService,
    UIOptions? options,
  })  : sessionId = sessionId ?? '',
        myUid = myUid ?? '',
        myUsername = myUsername ?? '',
        questions = questions ?? const [],
        gameService = gameService ?? MultiplayerGameService(),
        options = options ?? const UIOptions();

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  UIOptions get options => widget.options;

  StreamSubscription<LiveGameState>? _stateSub;
  LiveGameState? _liveState;

  _UIPhase _uiPhase = _UIPhase.loading;

  // Current question display
  List<String> _shuffledAnswers = [];
  String? _selectedAnswer;
  int _displayedQuestionIndex = -1;

  // Whether the archive is being fetched (to avoid double navigation)
  bool _fetchingResults = false;

  @override
  void initState() {
    super.initState();
    _stateSub = widget.gameService
        .buildLiveGameStateStream(
      sessionId: widget.sessionId,
      myUid: widget.myUid,
    )
        .listen(_onStateUpdate, onError: _onStreamError);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  // ── State updates ──────────────────────────────────────────────────────────

  void _onStateUpdate(LiveGameState state) {
    if (!mounted) return;

    setState(() {
      _liveState = state;
      _uiPhase = _resolveUIPhase(state);

      // Reset answer choices when the question index advances
      if (state.currentQuestionIndex != _displayedQuestionIndex &&
          _uiPhase == _UIPhase.answering) {
        _displayedQuestionIndex = state.currentQuestionIndex;
        _selectedAnswer = null;
        _shuffledAnswers = _buildShuffledAnswers(
            widget.questions[state.currentQuestionIndex]);
      }
    });

    if (_uiPhase == _UIPhase.finished && !_fetchingResults) {
      _fetchingResults = true;
      _navigateToResults(state.sessionId);
    }
  }

  void _onStreamError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd synchronizacji: $error')),
    );
  }

  _UIPhase _resolveUIPhase(LiveGameState state) {
    switch (state.phase) {
      case SessionPhase.waiting:
        return _UIPhase.loading;

      case SessionPhase.answering:
        if (state.amIEliminated) return _UIPhase.eliminated;
        return state.hasAnswered ? _UIPhase.waiting : _UIPhase.answering;

      case SessionPhase.resolving:
        final result = state.lastRoundResult;
        if (result?.eliminatedUid == widget.myUid) return _UIPhase.eliminated;
        return _UIPhase.resolving;

      case SessionPhase.finished:
        return _UIPhase.finished;
    }
  }

  // ── Answer helpers ─────────────────────────────────────────────────────────

  List<String> _buildShuffledAnswers(Question question) {
    final answers = [
      ...question.correctAnswers,
      ...?question.wrongAnswers,//todo wszedzie do zmiany to cos
    ]..shuffle();
    return answers;
  }

  Future<void> _onAnswerTapped(String answer) async {
    if (_uiPhase != _UIPhase.answering) return;
    if (_liveState == null) return;

    setState(() => _selectedAnswer = answer);

    final state = _liveState!;
    final question = widget.questions[state.currentQuestionIndex];

    await widget.gameService.submitAnswer(
      sessionId: state.sessionId,
      uid: widget.myUid,
      roundIndex: state.currentQuestionIndex,
      questionId: question.id,
      answer: answer,
    );
  }

  Future<void> _navigateToResults(String sessionId) async {
    MultiplayerSessionData? sessionData;
    // Poll the archive — CF may take a moment after setting status=finished
    for (int attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        sessionData =
        await widget.gameService.fetchFinalSessionData(sessionId);
        break;
      } catch (_) {
        // Archive not ready yet, retry
      }
    }

    if (!mounted) return;

    if (sessionData != null) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiplayerScoreTableScreen(
            options: options,
            session: sessionData!,
            myUid: widget.myUid,
          ),
        ),
      );
    } else {
      // Fallback: archive unavailable, go back to main menu
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
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
          child: switch (_uiPhase) {
            _UIPhase.loading => _buildLoading(),
            _UIPhase.answering ||
            _UIPhase.waiting =>
                _buildQuestion(context),
            _UIPhase.resolving => _buildRoundResult(context),
            _UIPhase.eliminated => _buildEliminated(context),
            _UIPhase.finished => _buildLoading(), // brief while navigating
          },
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(color: options.textColor),
    );
  }

  // ── Question screen ────────────────────────────────────────────────────────

  Widget _buildQuestion(BuildContext context) {
    final state = _liveState!;
    final qIndex = state.currentQuestionIndex;
    if (qIndex >= widget.questions.length) return _buildLoading();

    final question = widget.questions[qIndex];
    final activePlayers = state.activePlayers;
    final answeredCount = state.answersSubmittedCount;
    final amIWaiting = _uiPhase == _UIPhase.waiting;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Column(
                children: [
                  Text(
                    'Pytanie ${qIndex + 1} / ${state.questionIds.length}',
                    style: TextStyle(
                      color: options.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Graczy aktywnych: ${activePlayers.length}',
                    style: TextStyle(
                      color: options.textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),

          // ── Answer progress bar ────────────────────────────────────────────
          _buildAnswerProgressBar(answeredCount, activePlayers.length),
          const SizedBox(height: 16),

          // ── Question card ──────────────────────────────────────────────────
          Container(
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
          const SizedBox(height: 20),

          // ── Answer grid ────────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shuffledAnswers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.0,
              ),
              itemBuilder: (_, i) =>
                  _buildAnswerButton(_shuffledAnswers[i], amIWaiting),
            ),
          ),

          // ── Waiting indicator ──────────────────────────────────────────────
          if (amIWaiting) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: options.textColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Czekanie na pozostałych graczy...',
                  style: TextStyle(
                      color: options.textColor.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerProgressBar(int answered, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Odpowiedzi: $answered / $total',
              style:
              TextStyle(color: options.textColor.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : answered / total,
            minHeight: 6,
            backgroundColor: options.secondaryColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(options.mainButtonColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(String answer, bool disabled) {
    final isSelected = _selectedAnswer == answer;

    Color bgColor = options.secondaryColor.withOpacity(0.3);
    Color borderColor = options.mainButtonColor.withOpacity(0.3);

    if (isSelected) {
      bgColor = options.mainButtonColor.withOpacity(0.4);
      borderColor = options.mainButtonColor;
    }

    return GestureDetector(
      onTap: disabled ? null : () => _onAnswerTapped(answer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
            color: options.textColor
                .withOpacity(disabled && !isSelected ? 0.4 : 1.0),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Round result screen ────────────────────────────────────────────────────

  Widget _buildRoundResult(BuildContext context) {
    final state = _liveState!;
    final result = state.lastRoundResult;
    if (result == null) return _buildLoading();

    final eliminated = result.eliminatedUid;
    final nobody = eliminated == null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            nobody ? Icons.check_circle_outline : Icons.remove_circle_outline,
            color: nobody ? Colors.green : Colors.redAccent,
            size: 72,
          ),
          const SizedBox(height: 20),
          Text(
            nobody ? 'Wszyscy odpowiedzieli poprawnie!' : 'Koniec rundy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: options.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (!nobody) ...[
            if (result.lotteryOccurred) ...[
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Text(
                  'Losowanie! ${result.lotteryPool.length} graczy w puli',
                  style: TextStyle(
                      color: options.textColor.withOpacity(0.9), fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
              ),
              child: Text(
                '${result.eliminatedUsername ?? eliminated} odpada!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: options.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Następna runda za chwilę...',
            style: TextStyle(
                color: options.textColor.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 8),
          CircularProgressIndicator(
              strokeWidth: 2, color: options.textColor.withOpacity(0.5)),
          const SizedBox(height: 32),
          _buildPlayerList(state),
        ],
      ),
    );
  }

  Widget _buildPlayerList(LiveGameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gracze',
          style: TextStyle(
              color: options.textColor.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...state.players.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(
                p.isEliminated
                    ? Icons.cancel_outlined
                    : Icons.person_outline,
                color: p.isEliminated
                    ? Colors.red.withOpacity(0.6)
                    : Colors.green.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                p.username,
                style: TextStyle(
                  color: options.textColor
                      .withOpacity(p.isEliminated ? 0.4 : 1.0),
                  decoration:
                  p.isEliminated ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ── Eliminated screen ──────────────────────────────────────────────────────

  Widget _buildEliminated(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied_outlined,
                color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            Text(
              'Odpadłeś!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: options.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Czekanie na zakończenie gry...',
              style: TextStyle(
                  color: options.textColor.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: options.textColor),
          ],
        ),
      ),
    );
  }
}