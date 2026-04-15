import 'package:flutter/material.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/ui_options.dart';

class SingleplayerGameScreen extends StatefulWidget {
  const SingleplayerGameScreen({
    super.key,
    required String category,
    UIOptions options = const UIOptions(),
    required ISingleplayerGameService singleplayerGameService,
  }) :  _options = options,
        _category = category,
        _singleplayerGameService = singleplayerGameService;

  final UIOptions _options;
  final String _category;
  final ISingleplayerGameService _singleplayerGameService;

  UIOptions get options => _options;
  String get category => _category;
  ISingleplayerGameService get singleplayerGameService => _singleplayerGameService;

  @override
  State<SingleplayerGameScreen> createState() => _SingleplayerGameScreenState();
}

class _SingleplayerGameScreenState extends State<SingleplayerGameScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.options.mainColor,
              widget.options.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Pasek górny
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: widget.options.textColor,
                    ),
                    Text(
                      'Tryb singleplayer',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        color: widget.options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Pytanie
                Text(
                  widget.singleplayerGameService.getQuestionText() as String,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: widget.options.textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Pole do wpisania odpowiedzi
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    hintText: 'Wpisz swoją odpowiedź...',
                    hintStyle: TextStyle(
                      color: widget.options.textColor.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: widget.options.textColor.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: widget.options.textColor),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 12),

                // Przycisk odpowiedz
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.options.mainButtonColor,
                      foregroundColor: widget.options.textColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final answer = _answerController.text;
                      if (answer.isNotEmpty) {
                        widget.singleplayerGameService.registerAnswer(answer);
                        _answerController.clear();
                      }
                    },
                    child: const Text('Odpowiedz'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}