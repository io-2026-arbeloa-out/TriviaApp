import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/ui_options.dart';

class SingleplayerScoreTableScreen extends StatelessWidget {
  const SingleplayerScoreTableScreen({
    super.key,
    required UIOptions options,
    required List<bool> results,
    required String category,
    required SingleplayerGameOptions gameOptions,
  })  : _options = options,
        _results = results,
        _category = category,
        _gameOptions = gameOptions;

  final UIOptions _options;
  final List<bool> _results;
  final String _category;
  final SingleplayerGameOptions _gameOptions;

  UIOptions get options => _options;

  int get _score => _results.where((e) => e).length;
  int get _total => _results.length;
  double get _accuracy => _total == 0 ? 0 : _score / _total;

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
                const SizedBox(height: 24),
                _buildScoreSummary(context),
                const SizedBox(height: 16),
                Expanded(child: _buildResultList(context)),
                const SizedBox(height: 16),
                _buildButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Text(
        'Wyniki gry',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: options.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScoreSummary(BuildContext context) {
    final pct = (_accuracy * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: options.secondaryColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$_score / $_total',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: options.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Skuteczność: $pct%',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: options.textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _accuracy,
              minHeight: 8,
              backgroundColor: options.secondaryColor.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                _accuracy >= 0.7 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(BuildContext context) {
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final isCorrect = _results[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: options.secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect
                  ? Colors.green.withOpacity(0.6)
                  : Colors.red.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Pytanie ${index + 1}',
                style: TextStyle(color: options.textColor),
              ),
              const Spacer(),
              Text(
                isCorrect ? 'Poprawna' : 'Błędna',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: options.mainButtonColor,
            foregroundColor: options.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => AppRoute.instance.goToSingleplayerGame(
            _category,
            options,
            _gameOptions,
          ),
          child: const Text('Zagraj ponownie', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: options.secondaryColor.withOpacity(0.5),
            foregroundColor: options.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => AppRoute.instance.goToQuizList(options),
          child: const Text('Zagraj w inną kategorię',
              style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: options.textColor,
            side: BorderSide(color: options.secondaryButtonColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => AppRoute.instance.goToMainMenu(options),
          child: const Text('Menu główne', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}