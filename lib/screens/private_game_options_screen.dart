import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_connection_service.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

class PrivateGameOptionsScreen extends StatefulWidget {
  const PrivateGameOptionsScreen({
    super.key,
    UIOptions? options,
    IMultiplayerConnectionService? connectionService,
    FirebaseSessionRepository? sessionRepository,
  })  : _options = options ?? const UIOptions(),
        _connectionService = connectionService,
        _sessionRepository = sessionRepository;

  final UIOptions _options;
  final IMultiplayerConnectionService? _connectionService;
  final FirebaseSessionRepository? _sessionRepository;

  @override
  State<PrivateGameOptionsScreen> createState() =>
      _PrivateGameOptionsScreenState();
}

class _PrivateGameOptionsScreenState extends State<PrivateGameOptionsScreen> {
  UIOptions get options => widget._options;

  late final IMultiplayerConnectionService _connectionService;
  late final FirebaseSessionRepository _sessionRepository;

  static const List<int> _timeLimitOptions = [10, 20, 30, 60];
  static const List<int> _maxPlayerOptions = [2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<String> _categoryOptions = [
    'general',
    'sports',
    'science',
    'history',
  ];
  static const List<Difficulty> _difficultyOptions = [
    Difficulty.easy,
    Difficulty.medium,
    Difficulty.hard,
    Difficulty.impossible,
  ];

  late final int _lobbyCode;

  // ── Jeden obiekt zamiast trzech osobnych zmiennych ─────────────────────────
  late OnlineGameOptions _gameOptions;

  String? _sessionId;
  StreamSubscription<Map<String, dynamic>>? _sessionSub;
  List<String> _playerNames = [];
  bool _isConnecting = true;
  String? _connectError;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _connectionService =
        widget._connectionService ?? MultiplayerConnectionService();
    _sessionRepository =
        widget._sessionRepository ?? FirebaseSessionRepository();

    _lobbyCode = 100000 + Random().nextInt(900000);

    _gameOptions = OnlineGameOptions(
      categoryId: 'general',
      maxPlayers: 4,
      questionTimeLimit: 30,
      entryCode: _lobbyCode,
      difficulty: Difficulty.medium,
    );

    _createSession();
  }

  Future<void> _createSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _connectError = 'Nie jesteś zalogowany';
          _isConnecting = false;
        });
      }
      return;
    }

    if (mounted) setState(() { _isConnecting = true; _connectError = null; });

    try {
      final sessionId = await _connectionService.connectPlayer(
        uid: user.uid,
        username: user.displayName ?? user.email ?? 'Host',
        settings: _gameOptions,
      );

      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _isConnecting = false;
      });
      _listenToSession(sessionId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectError = 'Błąd tworzenia sesji: $e';
        _isConnecting = false;
      });
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

  Future<void> _applyChanges() async {
    if (_sessionId == null) return;
    try {
      await _sessionRepository.updateSessionSettings(
        sessionId: _sessionId!,
        questionTimeLimit: _gameOptions.questionTimeLimit,
        maxPlayers: _gameOptions.maxPlayers,
        categoryId: _gameOptions.categoryId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zapisano zmiany')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e')),
        );
      }
    }
  }

  Future<void> _startGame() async {
    if (_sessionId == null) return;
    try {
      await _sessionRepository.startSession(sessionId: _sessionId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd startu gry: $e')),
        );
      }
    }
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

  String _difficultyLabel(Difficulty d) => switch (d) {
    Difficulty.easy       => 'Łatwy',
    Difficulty.medium     => 'Średni',
    Difficulty.hard       => 'Trudny',
    Difficulty.impossible => 'Niemożliwy',
    Difficulty.random     => 'Losowy'
  };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) return _buildLoading();
    if (_connectError != null) return _buildError();
    return _buildLobby();
  }

  BoxDecoration get _background => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [options.mainColor, options.secondaryColor],
    ),
  );

  Widget _buildLoading() {
    return Scaffold(
      body: Container(
        decoration: _background,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: options.textColor),
                const SizedBox(height: 16),
                Text(
                  'Tworzenie sesji...',
                  style: TextStyle(color: options.textColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      body: Container(
        decoration: _background,
        child: SafeArea(
          child: Center(
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
                    onPressed: _createSession,
                    child: const Text('Spróbuj ponownie'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Wróć',
                      style: TextStyle(color: options.textColor.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLobby() {
    return Scaffold(
      body: Container(
        decoration: _background,
        child: SafeArea(
          child: Column(
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back,
                color: options.textColor.withOpacity(0.7)),
          ),
          const SizedBox(width: 4),
          Text(
            'Prywatna gra',
            style: TextStyle(
              color: options.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
            style: TextStyle(
                color: options.textColor.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '$_lobbyCode',
            style: TextStyle(
              color: options.textColor,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Udostępnij ten kod pozostałym graczom',
            style: TextStyle(
                color: options.textColor.withOpacity(0.45), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ustawienia',
          style: TextStyle(
              color: options.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
        const SizedBox(height: 10),
        _buildDropdownRow<int>(
          label: 'Czas na pytanie',
          value: _gameOptions.questionTimeLimit,
          items: _timeLimitOptions,
          display: (v) => '$v s',
          onChanged: (v) =>
              setState(() => _gameOptions = _gameOptions.copyWith(questionTimeLimit: v)),
        ),
        const SizedBox(height: 8),
        _buildDropdownRow<int>(
          label: 'Maks. graczy',
          value: _gameOptions.maxPlayers,
          items: _maxPlayerOptions,
          display: (v) => '$v',
          onChanged: (v) =>
              setState(() => _gameOptions = _gameOptions.copyWith(maxPlayers: v)),
        ),
        const SizedBox(height: 8),
        _buildDropdownRow<String>(
          label: 'Kategoria',
          value: _gameOptions.categoryId,
          items: _categoryOptions,
          display: (v) => v,
          onChanged: (v) =>
              setState(() => _gameOptions = _gameOptions.copyWith(categoryId: v)),
        ),
        const SizedBox(height: 8),
        _buildDropdownRow<Difficulty>(
          label: 'Poziom trudności',
          value: _gameOptions.difficulty,
          items: _difficultyOptions,
          display: _difficultyLabel,
          onChanged: (v) =>
              setState(() => _gameOptions = _gameOptions.copyWith(difficulty: v)),
        ),
      ],
    );
  }

  Widget _buildDropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) display,
    required void Function(T) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: options.secondaryColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: options.textColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(color: options.textColor, fontSize: 14)),
          ),
          DropdownButton<T>(
            value: value,
            dropdownColor: options.mainColor,
            style: TextStyle(color: options.textColor, fontSize: 14),
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.keyboard_arrow_down,
                color: options.textColor.withOpacity(0.6), size: 20),
            items: items
                .map((e) => DropdownMenuItem<T>(
              value: e,
              child: Text(display(e),
                  style: TextStyle(color: options.textColor)),
            ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection() {
    final names = _playerNames.isEmpty ? ['Ty (Host)'] : _playerNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gracze',
              style: TextStyle(
                  color: options.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(width: 8),
            Text(
              '${names.length} / ${_gameOptions.maxPlayers}',
              style: TextStyle(
                  color: options.textColor.withOpacity(0.5), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...names.map(
              (name) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: options.secondaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: options.textColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.person,
                    color: options.textColor.withOpacity(0.6), size: 18),
                const SizedBox(width: 10),
                Text(name,
                    style:
                    TextStyle(color: options.textColor, fontSize: 14)),
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: options.textColor,
                side: BorderSide(color: options.textColor.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _applyChanges,
              child: const Text('Zapisz zmiany'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: options.mainButtonColor,
                foregroundColor: options.textColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _startGame,
              child: const Text('Rozpocznij grę',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}