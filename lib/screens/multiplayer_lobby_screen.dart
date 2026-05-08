import 'dart:async';

import 'package:flutter/material.dart';
import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/screens/multiplayer_game_screen.dart';
import 'package:triviaapp/services/multiplayer_connection_service.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

enum _LobbyPhase { connecting, waiting, loadingQuestions, error }

class MultiplayerLobbyScreen extends StatefulWidget {
  final UIOptions options;
  final String uid;
  final String username;
  final String categoryId;
  final int maxPlayers;
  final IMultiplayerConnectionService? connectionService;
  final IMultiplayerGameService? gameService;
  final FirebaseQuestionRepository? questionRepository;

  const MultiplayerLobbyScreen({
    super.key,
    required this.uid,
    required this.username,
    required this.categoryId,
    required this.maxPlayers,
    UIOptions? options,
    this.connectionService,
    this.gameService,
    this.questionRepository,
  }) : options = options ?? const UIOptions();

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  UIOptions get options => widget.options;

  late final IMultiplayerConnectionService _connectionService;
  late final IMultiplayerGameService _gameService;
  late final FirebaseQuestionRepository _questionRepository;

  _LobbyPhase _phase = _LobbyPhase.connecting;
  String _errorMessage = '';
  String? _sessionId;
  int _currentPlayerCount = 0;
  StreamSubscription<Map<String, dynamic>>? _sessionSub;

  @override
  void initState() {
    super.initState();

    final sessionRepo = FirebaseSessionRepository();
    _questionRepository =
        widget.questionRepository ?? FirebaseQuestionRepository();
    _connectionService = widget.connectionService ??
        MultiplayerConnectionService(
          sessionRepository: sessionRepo,
          questionRepository: _questionRepository,
        );
    _gameService = widget.gameService ??
        MultiplayerGameService(repo: sessionRepo);

    _connect();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  // ── Connection ─────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    try {
      final sessionId = await _connectionService.connectPlayer(
        uid: widget.uid,
        username: widget.username,
        categoryId: widget.categoryId,
        maxPlayers: widget.maxPlayers,
      );

      _sessionId = sessionId;
      setState(() => _phase = _LobbyPhase.waiting);
      _listenToSession(sessionId);
    } catch (e) {
      setState(() {
        _phase = _LobbyPhase.error;
        _errorMessage = 'Nie udało się połączyć z lobby.\n$e';
      });
    }
  }

  void _listenToSession(String sessionId) {
    final repo = FirebaseSessionRepository();
    _sessionSub = repo.sessionDocStream(sessionId).listen(
          (data) async {
        final status = data['status'] as String? ?? 'waiting';
        final playerUids = data['playerUids'] as List? ?? [];

        if (!mounted) return;
        setState(() => _currentPlayerCount = playerUids.length);

        if (status == 'inProgress') {
          await _sessionSub?.cancel();
          _sessionSub = null;
          _onGameStarted(sessionId, data);
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _phase = _LobbyPhase.error;
          _errorMessage = 'Utracono połączenie z lobby.\n$e';
        });
      },
    );
  }

  Future<void> _onGameStarted(
      String sessionId,
      Map<String, dynamic> sessionData,
      ) async {
    if (!mounted) return;
    setState(() => _phase = _LobbyPhase.loadingQuestions);

    try {
      final questionIds =
      List<String>.from(sessionData['questionIds'] as List? ?? []);
      final categoryId = sessionData['categoryId'] as String;

      final questions = await _questionRepository.getQuestionsByIds(
        category: categoryId,
        ids: questionIds,
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiplayerGameScreen(
            options: options,
            sessionId: sessionId,
            myUid: widget.uid,
            myUsername: widget.username,
            questions: questions,
            gameService: _gameService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LobbyPhase.error;
        _errorMessage = 'Nie udało się załadować pytań.\n$e';
      });
    }
  }

  Future<void> _onLeave() async {
    await _sessionSub?.cancel();
    _sessionSub = null;
    if (mounted) Navigator.of(context).pop();
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (_phase) {
                _LobbyPhase.error => _buildError(),
                _LobbyPhase.loadingQuestions => _buildLoadingQuestions(),
                _ => _buildWaiting(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    final isConnecting = _phase == _LobbyPhase.connecting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isConnecting
              ? 'Łączenie z lobby...'
              : 'Oczekiwanie na graczy',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        CircularProgressIndicator(color: options.textColor),
        const SizedBox(height: 24),
        if (!isConnecting && _sessionId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: options.secondaryColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$_currentPlayerCount / ${widget.maxPlayers}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: options.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'graczy w lobby',
                  style: TextStyle(
                      color: options.textColor.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kod sesji: ${_sessionId!.substring(0, 6).toUpperCase()}',
            style: TextStyle(
                color: options.textColor.withOpacity(0.5), fontSize: 12),
          ),
        ],
        const SizedBox(height: 32),
        TextButton(
          onPressed: _onLeave,
          child: Text(
            'Opuść lobby',
            style: TextStyle(color: options.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingQuestions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ładowanie pytań...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        CircularProgressIndicator(color: options.textColor),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: options.textColor, size: 48),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
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
    );
  }
}