import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import 'package:triviaapp/models/ui_options.dart';

class SingleplayerOptionsScreen extends StatefulWidget {
  final String _category;
  final UIOptions _options;

  SingleplayerOptionsScreen({
    super.key,
    required String category,
    UIOptions? options,
  }) : _options = options ?? UIOptions(),
       _category = category;

  @override
  State<SingleplayerOptionsScreen> createState() =>
      _SingleplayerOptionsScreenState();
}

class _SingleplayerOptionsScreenState
    extends State<SingleplayerOptionsScreen> {
  UIOptions get options => widget._options;
  String get category => widget._category;

  SingleplayerGameOptions _gameOptions = const SingleplayerGameOptions();

  static const List<int> _numQuestionChoices = [10, 15, 20];
  static const List<int> _timeChoices = [0, 15, 20, 30]; // 0 = brak limitu
  static const List<QuestionType> _questionTypes = QuestionType.values;

  String _timeLabel(int seconds) {
    if (seconds == 0) return 'Brak limitu';
    return '${seconds}s';
  }

  String _typeLabel(QuestionType? type) {
    if (type == null) return 'Mieszane';
    switch (type) {
      case QuestionType.true_false:
        return 'Prawda / Fałsz';
      case QuestionType.open4:
        return '4 opcje';
      case QuestionType.open6:
        return '6 opcji';
      case QuestionType.open:
        return 'Otwarte';
      case QuestionType.mixed:
        return 'Mieszane';
    }
  }

  void _startGame() {
    AppRoute.instance.goToSingleplayerGame(
        options,
        SingleplayerSessionData(category: category, options: _gameOptions)
    );
  }

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 8),
                _buildCategoryBadge(context),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSection(
                          context,
                          label: 'Liczba pytań',
                          children: _numQuestionChoices
                              .map((n) => _buildChip(
                            label: '$n',
                            selected: _gameOptions.numQuestions == n,
                            onTap: () => setState(() {
                              _gameOptions =
                                  _gameOptions.copyWith(numQuestions: n);
                            }),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          context,
                          label: 'Czas na odpowiedź',
                          children: _timeChoices
                              .map((t) => _buildChip(
                            label: _timeLabel(t),
                            selected:
                            _gameOptions.timePerQuestion == t,
                            onTap: () => setState(() {
                              _gameOptions = _gameOptions.copyWith(
                                  timePerQuestion: t);
                            }),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          context,
                          label: 'Typ pytań',
                          children: _questionTypes
                              .map((type) => _buildChip(
                            label: _typeLabel(type),
                            selected: _gameOptions.questionType == type,
                            onTap: () => setState(() {
                              _gameOptions = _gameOptions.copyWith(
                                  questionType: type);
                            }),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: options.mainButtonColor,
                            foregroundColor: options.textColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _startGame,
                          child: const Text(
                            'Graj',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: options.textColor,
        ),
        Text(
          'Ustawienia gry',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: options.mainButtonColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: options.mainButtonColor.withOpacity(0.4)),
        ),
        child: Text(
          category,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String label,
        required List<Widget> children,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: children),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? options.mainButtonColor
              : options.secondaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? options.mainButtonColor
                : options.mainButtonColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: options.textColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}