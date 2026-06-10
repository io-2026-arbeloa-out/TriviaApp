import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/ui_options.dart';

class MultiplayerScoreTableScreen extends StatelessWidget {
  final MultiplayerSessionData session;
  final String myUid;
  final UIOptions options;

  const MultiplayerScoreTableScreen({
    super.key,
    required this.session,
    required this.myUid,
    required this.options,
  });

  List<String> get _orderedUids {
    final sorted = [...session.playerResults]
      ..sort((a, b) => a.placement.compareTo(b.placement));

    return sorted.map((e) => e.uid).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ordered = _orderedUids;
    final myPlace = ordered.indexOf(myUid) + 1;

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
          child: Column(
            children: [
              _buildHeader(context, myPlace, ordered.length),
              Expanded(child: _buildTable(context, ordered)),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int myPlace, int total) {
    final isWinner = myPlace == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Text(
            'Koniec gry',
            style: TextStyle(
              color: options.textColor.withOpacity(0.6),
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWinner ? 'Wygrałeś!' : 'Zająłeś ${myPlace}. miejsce',
            style: TextStyle(
              color: options.textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kategoria: ${session.categoryId}',
            style: TextStyle(
              color: options.textColor.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // Trophy / place icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _placeColor(myPlace).withOpacity(0.15),
              border: Border.all(
                color: _placeColor(myPlace).withOpacity(0.6),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _placeEmoji(myPlace),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<String> ordered) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: ordered.length,
      itemBuilder: (_, i) {
        final uid = ordered[i];
        final place = i + 1;
        final player = session.playerByUid(uid);
        if (player == null) return const SizedBox.shrink();
        final isMe = uid == myUid;
        final isWinner = uid == session.winner;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isMe
                ? options.mainButtonColor.withOpacity(0.15)
                : options.secondaryColor.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMe
                  ? options.mainButtonColor.withOpacity(0.5)
                  : _placeColor(place).withOpacity(0.25),
              width: isMe ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Place
              SizedBox(
                width: 40,
                child: Text(
                  _placeEmoji(place),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.username,
                          style: TextStyle(
                            color: options.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: options.mainButtonColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ty',
                              style: TextStyle(
                                color: options.mainButtonColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isWinner) ...[
                          const SizedBox(width: 4),
                          const Text('👑', style: TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                    if (player.lotteryTimesIn > 0)
                      Text(
                        'Losowania: ${player.lotteryTimesIn}',
                        style: TextStyle(
                          color: options.textColor.withOpacity(0.45),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${player.correctAnswers}',
                    style: TextStyle(
                      color: options.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'poprawnych',
                    style: TextStyle(
                      color: options.textColor.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: options.mainButtonColor,
            foregroundColor: options.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            // Pop back to main menu (or however many screens are in the stack).
            AppRoute.instance.goToMainMenu(options);
          },
          child: const Text(
            'Menu główne',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _placeColor(int place) => switch (place) {
    1 => const Color(0xFFFFD700), // gold
    2 => const Color(0xFFC0C0C0), // silver
    3 => const Color(0xFFCD7F32), // bronze
    _ => Colors.white38,
  };

  String _placeEmoji(int place) => switch (place) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '$place.',
  };
}