import 'dart:async';

import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/controllers/multiplayer_controller.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/widgets/lottery_animation.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final UIOptions _options;
  final IMultiplayerGameService _gameService;

  const MultiplayerGameScreen({
    super.key,
    UIOptions? options,
    required IMultiplayerGameService gameService,
  })  : _options = options ?? const UIOptions(),
        _gameService = gameService;

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  UIOptions get options => widget._options;
  IMultiplayerGameService get gameService => widget._gameService;

  late final MultiplayerController _controller;
  LiveGameState? get _liveState => _controller.state;
  MultiplayerPhase get _uiPhase => _controller.phase;
  List<String> get _shuffledAnswers => _controller.answers;
  String? get _selectedAnswer => _controller.selectedAnswer;
  bool? get _isAnswerCorrect => _controller.isAnswerCorrect;
  List<String> get _revealedAnswers => _controller.revealedAnswers;
  bool get _hasAnsweredThisRound => _controller.hasAnswered;
  RoundResult? get _cachedRoundResult => _controller.cachedRoundResult;
  static const Duration _lotteryAnimationLength = Duration(seconds: 4);
  bool _lotteryRevealDone = false;
  MultiplayerPhase? _lastVisualPhase;
  Object? _lastAnswerError, _lastConnectionError, _lastResultsError;
  bool _stalledNotified = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = MultiplayerController(service: gameService);
    _controller.addListener(_onControllerChanged);
    _controller.connect();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(SnackBar message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(message);
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_lastVisualPhase != _uiPhase && _uiPhase == MultiplayerPhase.resolving) {
      _lotteryRevealDone = false;
    }
    _lastVisualPhase = _uiPhase;
    final answerError = _controller.answerError;
    if (answerError != null && answerError != _lastAnswerError) {
      final round = _liveState?.currentQuestionIndex;
      _showMessage(SnackBar(
        content: Text('Błąd wysyłania odpowiedzi: $answerError'),
        action: SnackBarAction(
          label: 'Ponów',
          onPressed: () => _controller.retryAnswer(expectedRoundIndex: round),
        ),
      ));
    }
    _lastAnswerError = answerError;
    final connectionError = _controller.connectionError;
    if (connectionError != null && connectionError != _lastConnectionError) {
      _showMessage(SnackBar(
        content: Text('Błąd połączenia: $connectionError'),
        action: SnackBarAction(label: 'Ponów', onPressed: _controller.connect),
      ));
    }
    _lastConnectionError = connectionError;
    if (_controller.resultsError != null &&
        _controller.resultsError != _lastResultsError) {
      _showMessage(const SnackBar(
        content: Text('Nie udało się pobrać wyników. Spróbuj ponownie później.'),
      ));
    }
    _lastResultsError = _controller.resultsError;
    if (_controller.roundStalled && !_stalledNotified) {
      _stalledNotified = true;
      _showMessage(SnackBar(
        content: const Text('Runda trwa zbyt długo. Możesz opuścić grę przyciskiem wyjścia.'),
        action: SnackBarAction(label: 'Opuść', onPressed: _onLeavePressed),
      ));
    } else if (!_controller.roundStalled) {
      _stalledNotified = false;
    }
    setState(() {});
    final result = _controller.finalSession;
    if (result != null && !_navigated) {
      _navigated = true;
      AppRoute.instance.goToMultiplayerScoreTable(
        options: options, session: result, myUid: gameService.myUid,
      );
    }
  }

  Future<void> _onAnswerTapped(String answer) => _controller.answer(answer);
  // ── Leave ─────────────────────────────────────────────────────────────────

  Future<void> _onLeavePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: options.secondaryColor,
        title: Text(
          'Opuść grę',
          style: TextStyle(color: options.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy na pewno chcesz opuścić rozgrywkę?',
          style: TextStyle(color: options.textColor.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Zostań',
              style: TextStyle(color: options.textColor.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Opuść',
              style: TextStyle(
                color: options.mainButtonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    // Fire-and-forget — navigation must not wait on Firestore.
    unawaited(_controller.leave().catchError((_) {}));
    AppRoute.instance.goToMainMenu(options);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final state = _liveState;
    if (state == null || _uiPhase == MultiplayerPhase.loading) {
      return Center(child: CircularProgressIndicator(color: options.textColor));
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(state),
            Expanded(child: _buildQuestionArea(state)),
            _buildBottomBar(state),
          ],
        ),
        if (_uiPhase == MultiplayerPhase.resolving ||
            (_uiPhase == MultiplayerPhase.finished && _cachedRoundResult != null))
          _buildResolvingOverlay(state),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(LiveGameState state) {
    final current = state.currentQuestionIndex + 1;
    final total = state.questionIds.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _onLeavePressed,
            icon: Icon(Icons.exit_to_app, color: options.textColor.withValues(alpha: 0.7)),
            tooltip: 'Opuść grę',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            'Pytanie $current / $total',
            style: TextStyle(
              color: options.textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: options.secondaryColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.activeCount} ${state.activeCount == 1 ? 'gracz' : 'graczy'}',
              style: TextStyle(
                color: options.textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Question area ─────────────────────────────────────────────────────────

  Widget _buildQuestionArea(LiveGameState state) {
    final qi = state.currentQuestionIndex;
    if (qi >= gameService.questions.length) {
      return Center(
        child: CircularProgressIndicator(color: options.textColor),
      );
    }

    final question = gameService.questions[qi];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuestionCard(question, state),
          const SizedBox(height: 16),
          ..._shuffledAnswers.map((opt) => _buildAnswerButton(opt, question)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, LiveGameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: options.secondaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: options.textColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          if (state.amIEliminated)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tryb widza',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: options.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String option, Question question) {
    // ── Color logic ──────────────────────────────────────────────────────
    // Before answering: neutral style.
    // After answering:
    //   • Selected + correct → green
    //   • Selected + wrong   → red
    //   • Correct (not selected, revealed when wrong) → green outline
    //   • Everything else    → dimmed
    final isSelected = option == _selectedAnswer;
    final isCorrectOption = _revealedAnswers.contains(option);

    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? trailingIcon;

    if (!_hasAnsweredThisRound) {
      // Unanswered state.
      bgColor = options.secondaryColor.withValues(alpha: 0.25);
      borderColor = options.textColor.withValues(alpha: 0.2);
      textColor = options.textColor;
    } else if (isSelected) {
      // The option the player tapped.
      if (_isAnswerCorrect == true) {
        bgColor = Colors.green.withValues(alpha: 0.25);
        borderColor = Colors.green;
        textColor = Colors.green.shade200;
        trailingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
      } else if (_isAnswerCorrect == false) {
        bgColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.red.shade400;
        textColor = Colors.red.shade200;
        trailingIcon = const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
      } else {
        bgColor = options.secondaryColor.withValues(alpha: 0.25);
        borderColor = options.mainButtonColor;
        textColor = options.textColor;
      }
    } else if (isCorrectOption && _isAnswerCorrect == false) {
      // Reveal correct answer when player was wrong.
      bgColor = Colors.green.withValues(alpha: 0.12);
      borderColor = Colors.green.withValues(alpha: 0.6);
      textColor = Colors.green.shade300;
      trailingIcon =
          Icon(Icons.check_circle_outline, color: Colors.green.shade300, size: 20);
    } else {
      // Other wrong options — dimmed.
      bgColor = options.secondaryColor.withValues(alpha: 0.1);
      borderColor = options.textColor.withValues(alpha: 0.08);
      textColor = options.textColor.withValues(alpha: 0.35);
    }

    return GestureDetector(
      onTap: (_hasAnsweredThisRound || (_liveState?.amIEliminated ?? false))
          ? null
          : () => _onAnswerTapped(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }


  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(LiveGameState state) {
    final message = switch (_uiPhase) {
      MultiplayerPhase.waiting    => 'Oczekiwanie na pozostałych graczy...',
      MultiplayerPhase.eliminated => 'Zostałeś wyeliminowany — oglądasz grę',
      MultiplayerPhase.answering  => 'Wybierz odpowiedź',
      _              => '',
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: options.secondaryColor.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_uiPhase == MultiplayerPhase.waiting) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: options.textColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            message,
            style: TextStyle(
              color: options.textColor.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Resolving overlay ─────────────────────────────────────────────────────

  Widget _buildResolvingOverlay(LiveGameState state) {
    // Fallback na cache — overlay pozostaje widoczny podczas przejscia do wynikow
    final result = state.lastRoundResult ?? _cachedRoundResult;
    if (result == null) return const SizedBox.shrink();

    final eliminatedUid = result.eliminatedUid;
    final isEliminated  = eliminatedUid == gameService.myUid;
    final showLottery   = result.lotteryOccurred &&
        result.lotteryPool.isNotEmpty &&
        eliminatedUid != null;

    // While the spinner is running the result is hidden — only revealed
    // once the tape stops (_lotteryRevealDone = true).
    final bool revealResult = !showLottery || _lotteryRevealDone;

    // ── Text content ──────────────────────────────────────────────────────────
    final String emoji;
    final String title;
    final String subtitle;
    final Color  accentColor;

    if (result.opponentLeft) {
      // Gra zakonczona bo przeciwnik wyszedl — pozostaly gracz wygrywa
      emoji       = '🏆';
      title       = 'Wygrałeś!';
      subtitle    = 'Twój przeciwnik opuścił grę.';
      accentColor = Colors.green;
    } else if (!revealResult) {
      // Spinner still running — neutral placeholder
      emoji       = '🎲';
      title       = 'Trwa losowanie...';
      subtitle    = 'Zaraz dowiemy się kto odpada.';
      accentColor = Colors.amber;
    } else if (eliminatedUid == null) {
      emoji       = '✅';
      title       = 'Wszyscy odpowiedzieli poprawnie!';
      subtitle    = 'Nikt nie odpada w tej rundzie.';
      accentColor = Colors.green;
    } else if (isEliminated) {
      emoji       = '💀';
      title       = 'Odpadłeś!';
      subtitle    = result.lotteryOccurred
          ? 'Losowanie wybrało ciebie.'
          : 'Twoja odpowiedź była błędna.';
      accentColor = Colors.red;
    } else {
      final name  = result.eliminatedUsername ?? eliminatedUid;
      emoji       = '❌';
      title       = '$name odpada!';
      subtitle    = result.lotteryOccurred
          ? 'Losowanie wybrało $name.'
          : 'Odpowiedź $name była błędna.';
      accentColor = Colors.orange;
    }

    // ── Layout ─────────────────────────────────────────────────────────────────
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: options.mainColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji / icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  emoji,
                  key: ValueKey(emoji),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  key: ValueKey(title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: options.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  subtitle,
                  key: ValueKey(subtitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: options.textColor.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
              ),

              // ── Lottery spinner ─────────────────────────────────────────────
              if (showLottery) ...[
                const SizedBox(height: 20),
                LotteryWidget(
                  // Key tied to the round index — preserves animation state
                  // across parent rebuilds within the same resolving phase.
                  key: ValueKey('lottery_${state.currentQuestionIndex}'),
                  players: state.players
                      .where((player) => result.lotteryPool.containsKey(player.uid))
                      .toList(),
                  eliminatedUid: eliminatedUid,
                  animationLength: _lotteryAnimationLength,
                  onAnimationComplete: () {
                    if (mounted) setState(() => _lotteryRevealDone = true);
                  },
                ),
              ],

              const SizedBox(height: 20),

              // "Next question" indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: options.textColor.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _uiPhase == MultiplayerPhase.finished
                        ? 'Ładowanie wyników...'
                        : 'Kolejne pytanie za chwilę...',
                    style: TextStyle(
                      color: options.textColor.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
