import 'package:flutter/material.dart';
import 'package:triviaapp/models/live_game_state.dart';

class LotteryWidget extends StatefulWidget {
  final List<PlayerLiveState> players;
  final String eliminatedUid;

  final Duration animationLength;

  final VoidCallback? onAnimationComplete;

  const LotteryWidget({
    super.key,
    required this.players,
    required this.eliminatedUid,
    required this.animationLength,
    this.onAnimationComplete,
  });

  @override
  State<LotteryWidget> createState() => _LotteryState();
}

class _LotteryState extends State<LotteryWidget>
    with SingleTickerProviderStateMixin {

  // ── Layout constants ────────────────────────────────────────────────────────
  static const double _cardW = 88.0;
  static const double _cardH = 110.0;
  static const double _gap   = 10.0;
  static const double _step  = _cardW + _gap; // distance between card left-edges

  /// How many full player-list loops before landing on the target.
  static const int _targetRep = 6;

  // ── Animation ───────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;

  /// How many pixels the tape has scrolled to the left.
  Animation<double>? _scroll;

  // ── Tape ────────────────────────────────────────────────────────────────────
  late final List<PlayerLiveState> _tape;
  late final int _targetIdx; // index of the eliminated player in _tape

  // ── State ────────────────────────────────────────────────────────────────────
  final ValueNotifier<bool> _done = ValueNotifier(false);
  bool _scrollReady = false;

  // ────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: widget.animationLength)
      ..addStatusListener(_onStatus);

    // Build tape: (_targetRep + 2) repetitions so we never run out of cards.
    _tape = List.generate(_targetRep + 2, (_) => widget.players)
        .expand((e) => e)
        .toList();

    // Find the target player in the target repetition.
    final repStart = _targetRep * widget.players.length;
    final found    = _tape.indexWhere((p) => p.uid == widget.eliminatedUid, repStart);
    _targetIdx     = found >= 0 ? found : repStart;
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) {
      _done.value = true;
      widget.onAnimationComplete?.call();
    }
  }

  /// Calculates the end scroll offset and starts the animation.
  /// Called once from [build] after we know the viewport width.
  void _initScroll(double viewportWidth) {
    if (_scrollReady) return;
    _scrollReady = true;

    // Card[i] unscrolled centre = i * _step + _cardW / 2.
    // We want that centre to equal viewportWidth / 2 when scroll == endScroll:
    //   i * _step + _cardW / 2 − endScroll = viewportWidth / 2
    //   => endScroll = i * _step + _cardW / 2 − viewportWidth / 2
    final endScroll = _targetIdx * _step + _cardW / 2 - viewportWidth / 2;

    _scroll = Tween<double>(begin: 0.0, end: endScroll.clamp(0.0, double.infinity))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.decelerate));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _done.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final vw = constraints.maxWidth;
      _initScroll(vw);
      if (_scroll == null) return const SizedBox.shrink();

      return SizedBox(
        height: _cardH + 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Scrolling tape ────────────────────────────────────────────
            // ValueListenableBuilder ensures a full rebuild when _done fires,
            // so the highlighted card renders immediately on completion.
            ValueListenableBuilder<bool>(
              valueListenable: _done,
              builder: (_, done, __) => AnimatedBuilder(
                animation: _scroll!,
                builder: (_, __) => ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-_scroll!.value, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _tape.length; i++)
                            _TapeCard(
                              player:      _tape[i],
                              highlighted: done && i == _targetIdx,
                              cardW: _cardW,
                              cardH: _cardH,
                              gap:   _gap,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Edge fades ────────────────────────────────────────────────
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: _EdgeFade(width: vw * 0.18, fadeRight: false),
            ),
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: _EdgeFade(width: vw * 0.18, fadeRight: true),
            ),

            // ── Centre indicator line ─────────────────────────────────────
            Container(
              width: 3,
              height: _cardH + 8,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.55),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual card

class _TapeCard extends StatelessWidget {
  final PlayerLiveState player;
  final bool highlighted;
  final double cardW, cardH, gap;

  const _TapeCard({
    required this.player,
    required this.highlighted,
    required this.cardW,
    required this.cardH,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    const highlightColor = Colors.amber;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: cardW,
      height: cardH,
      margin: EdgeInsets.only(right: gap, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.white.withOpacity(0.14)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? highlightColor
              : Colors.white.withOpacity(0.18),
          width: highlighted ? 2.5 : 1.5,
        ),
        boxShadow: highlighted
            ? [
          BoxShadow(
            color: highlightColor.withOpacity(0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: highlighted
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: highlighted
                  ? [
                BoxShadow(
                  color: highlightColor.withOpacity(0.45),
                  blurRadius: 8,
                ),
              ]
                  : null,
            ),
            child: ClipOval(
              child: Image.asset(
                player.profilePicture,
                fit: BoxFit.cover,
                width: 46,
                height: 46,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              player.username,
              style: TextStyle(
                color: Colors.white.withOpacity(highlighted ? 1.0 : 0.7),
                fontWeight:
                highlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edge gradient overlay

class _EdgeFade extends StatelessWidget {
  final double width;
  final bool fadeRight; // true → dark on right, false → dark on left

  const _EdgeFade({required this.width, required this.fadeRight});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
            colors: fadeRight
                ? [Colors.transparent, Colors.black.withOpacity(0.7)]
                : [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
      ),
    );
  }
}