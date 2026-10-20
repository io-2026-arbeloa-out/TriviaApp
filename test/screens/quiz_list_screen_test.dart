import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/quiz.dart';
import 'package:triviaapp/repositories/quiz_repository.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';

class _Quizzes extends Fake implements QuizRepository {
  bool fail = false;
  int calls = 0;
  @override
  Future<List<Quiz>> getQuizList() async {
    calls++;
    if (fail) throw Exception('Unavailable');
    return [const Quiz(category: 'science', title: 'Science')];
  }
}

void main() {
  testWidgets(
    'loads quizzes through a repository and opens the chosen category',
    (tester) async {
      final repo = _Quizzes();
      Map<String, dynamic>? arguments;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppRoute.instance.navigatorKey,
          home: QuizListScreen(quizRepository: repo),
          routes: {
            AppRoute.singleplayerOptionsScreen: (context) {
              arguments =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return const Scaffold(body: Text('Options'));
            },
          },
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Science'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(arguments!['category'], 'science');
      expect(repo.calls, 1);
    },
  );

  testWidgets('a load failure can be retried using the same repository', (
    tester,
  ) async {
    final repo = _Quizzes()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: QuizListScreen(quizRepository: repo)),
    );
    await tester.pump();
    expect(
      find.text('Nie udało się załadować listy quizów. Spróbuj ponownie.'),
      findsOneWidget,
    );
    repo.fail = false;
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pump();
    expect(find.text('Science'), findsOneWidget);
    expect(repo.calls, 2);
  });
}
