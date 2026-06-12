import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

class PrivateLobbyScreen extends StatefulWidget {
  const PrivateLobbyScreen({
    super.key,
    UIOptions? options,
    this.code,
    FirebaseSessionRepository? sessionRepository,
  })  : _options = options ?? const UIOptions(),
        _sessionRepository = sessionRepository;

  final UIOptions _options;

  /// 6-digit code entered by the guest. Null only when accessed via legacy route.
  final int? code;
  final FirebaseSessionRepository? _sessionRepository;

  UIOptions get options => _options;

  @override
  State<PrivateLobbyScreen> createState() => _PrivateLobbyScreenState();
}

class _PrivateLobbyScreenState extends State<PrivateLobbyScreen> {
  UIOptions get options => widget.options;

  late final FirebaseSessionRepository _sessionRepository;

  String? _sessionId;
  StreamSubscription<Map<String, dynamic>>? _sessionSub;
  List<String> _playerNames = [];
  Map<String, dynamic> _settings = {};
  bool _isConnecting = true;
  String? _connectError;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _sessionRepository =
        widget._sessionRepository ?? FirebaseSessionRepository();
    _joinSession();
  }

  Future<void> _joinSession() async {
    if (widget.code == null) {
      setState(() { _connectError = 'Brak kodu pokoju'; _isConnecting = false; });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _connectError = 'Nie jesteś zalogowany'; _isConnecting = false; });
      return;
    }

    if (mounted) setState(() { _isConnecting = true; _connectError = null; });

    try {
      final sessionId = await _sessionRepository.findPrivateSession(
        entryCode: widget.code!,
      );

      if (sessionId == null) {
        if (mounted) {
          setState(() {
            _connectError = 'Nie znaleziono gry z kodem ${widget.code}';
            _isConnecting = false;
          });
        }
        return;
      }

      await _sessionRepository.joinSession(
        sessionId: sessionId,
        uid: user.uid,
        username: user.displayName ?? user.email ?? 'Gracz',
      );

      if (!mounted) return;
      setState(() { _sessionId = sessionId; _isConnecting = false; });
      _listenToSession(sessionId);
    } on StateError catch (e) {
      if (mounted) {
        setState(() {
          _connectError = 'Nie można dołączyć: ${e.message}';
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _connectError = 'Błąd dołączania: $e'; _isConnecting = false; });
      }
    }
  }

  void _listenToSession(String sessionId) {
    _sessionSub = _sessionRepository.sessionDocStream(sessionId).listen(
          (data) {
        if (!mounted) return;
        final playerUids =
        List<String>.from(data['playerUids'] as List? ?? []);
        final players = data['players'] as Map<String, dynamic>? ?? {};
        setState(() {
          _playerNames = playerUids
              .map((uid) => players[uid]?['username'] as String? ?? '$uid')
              .toList();
          _settings = {
            'questionTimeLimit': data['questionTimeLimit'] ?? 30,
            'maxPlayers': data['maxPlayers'] ?? '—',
            'categoryId': data['categoryId'] ?? '—',
            'difficulty': data['difficulty'] ?? '—',
          };
        });

        if (data['status'] == 'inProgress') {
          _sessionSub?.cancel();
          _sessionSub = null;
          _gameStarted = true;
          _navigateToGame(sessionId);
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _connectError = 'Utracono połączenie: $e');
      },
    );
  }

  void _navigateToGame(String sessionId) {
    if (!mounted) return;
    AppRoute.instance.goToMultiplayer(
      options,
      MultiplayerGameService(
        sessionId: sessionId,
        sessionRepository: _sessionRepository,
      ),
    );
  }

  Future<void> _leave() async {
    await _sessionSub?.cancel();
    _sessionSub = null;

    if (_sessionId != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(
          _sessionRepository
              .removePlayer(sessionId: _sessionId!, uid: uid)
              .catchError((_) {}),
        );
      }
    }

    if (mounted) AppRoute.instance.goToMainMenu(options);
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    if (_sessionId != null && !_gameStarted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(
          _sessionRepository
              .removePlayer(sessionId: _sessionId!, uid: uid)
              .catchError((_) {}),
        );
      }
    }
    super.dispose();
  }

  String _difficultyLabel(String raw) => switch (raw) {
    'easy'       => 'Łatwy',
    'medium'     => 'Średni',
    'hard'       => 'Trudny',
    'impossible' => 'Niemożliwy',
    'random'     => 'Losowy',
    _            => raw,
  };

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
          child: _isConnecting
              ? _buildConnecting()
              : _connectError != null
              ? _buildError()
              : _buildLobby(),
        ),
      ),
    );
  }

  Widget _buildConnecting() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: options.textColor),
          const SizedBox(height: 16),
          Text(
            'Dołączanie do lobby...',
            style: TextStyle(color: options.textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: options.textColor, size: 48),
            const SizedBox(height: 16),
            Text(
              _connectError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: options.textColor),
            ),
            const SizedBox(height: 24),
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

  Widget _buildLobby() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCodeCard(),
                const SizedBox(height: 20),
                _buildSettingsSection(),
                const SizedBox(height: 20),
                _buildPlayersSection(),
              ],
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _leave,
            icon: Icon(Icons.arrow_back, color: options.textColor.withOpacity(0.7)),
          ),
          const SizedBox(width: 4),
          Text(
            'Lobby prywatne',
            style: TextStyle(
              color: options.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Oczekiwanie',
              style: TextStyle(
                color: Colors.orange.shade300,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: options.secondaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: options.textColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            'Kod pokoju',
            style: TextStyle(color: options.textColor.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            widget.code != null ? '${widget.code}' : '——',
            style: TextStyle(
              color: options.textColor,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final rows = [
      ['Czas na pytanie', '${_settings['questionTimeLimit'] ?? 30} s'],
      ['Maks. graczy',    '${_settings['maxPlayers'] ?? '—'}'],
      ['Kategoria',       '${_settings['categoryId'] ?? '—'}'],
      ['Trudność',        _difficultyLabel('${_settings['difficulty'] ?? ''}')],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ustawienia rozgrywki',
          style: TextStyle(color: options.textColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...rows.map(
              (row) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: options.secondaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: options.textColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Text(row[0], style: TextStyle(color: options.textColor.withOpacity(0.65), fontSize: 13)),
                const Spacer(),
                Text(row[1], style: TextStyle(color: options.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersSection() {
    final names = _playerNames.isEmpty ? ['—'] : _playerNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gracze w lobby',
          style: TextStyle(color: options.textColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...names.map(
              (name) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: options.secondaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: options.textColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: options.textColor.withOpacity(0.6), size: 18),
                const SizedBox(width: 10),
                Text(name, style: TextStyle(color: options.textColor, fontSize: 14)),
                const Spacer(),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: options.textColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextButton(
        onPressed: _leave,
        child: Text(
          'Opuść lobby',
          style: TextStyle(color: options.textColor.withOpacity(0.7)),
        ),
      ),
    );
  }
}