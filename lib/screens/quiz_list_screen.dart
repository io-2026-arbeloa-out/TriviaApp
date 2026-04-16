import 'package:flutter/material.dart';
import 'package:triviaapp/interfaces/i_quiz_list_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/quiz.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';

class QuizListScreen extends StatefulWidget {
  final IQuizListService _quizListService;
  final UIOptions _options;

  const QuizListScreen({
    super.key,
    UIOptions options = const UIOptions(),
    required IQuizListService quizListService,
  }) :  _options = options,
        _quizListService = quizListService;

  @override
  State<QuizListScreen> createState() => QuizListScreenState();
}

class QuizListScreenState extends State<QuizListScreen> with SingleTickerProviderStateMixin {
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  String? _errorMessage;

  UIOptions get options => widget._options;
  IQuizListService get quizListService => widget._quizListService;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadQuizzes();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizzes = await quizListService.getQuizList();
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie udało się załadować listy quizów. Spróbuj ponownie.';
        _isLoading = false;
      });
    }
  }

  void _onQuizTap(Quiz quiz) {
    AppRoute.instance.goToSingleplayer(quiz.category);
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
              options.mainColor,
              options.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(context),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 4 / 3,
              ),
              itemBuilder: (context, index) {
                return _buildSkeletonTile();
              },
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: options.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: options.mainButtonColor,
                      foregroundColor: options.textColor,
                    ),
                    onPressed: _loadQuizzes,
                    child: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_quizzes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Text(
                'Brak dostępnych quizów.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: options.textColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final int itemCount = _quizzes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: itemCount,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 4 / 3,
            ),
            itemBuilder: (context, index) {
              final quiz = _quizzes[index];

              return InkWell(
                onTap: () => _onQuizTap(quiz),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: options.secondaryColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                            options.mainButtonColor.withOpacity(0.2),
                          ),
                          child: Icon(
                            quiz.getIcon(),
                            color: options.textColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          quiz.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            color: options.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
          'Wybierz quiz',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSkeletonTile() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: options.secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: options.mainButtonColor.withOpacity(
                      0.15 + (_shimmerController.value * 0.1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: options.mainButtonColor.withOpacity(
                      0.15 + (_shimmerController.value * 0.1),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 80,
                  decoration: BoxDecoration(
                    color: options.mainButtonColor.withOpacity(
                      0.15 + (_shimmerController.value * 0.1),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}