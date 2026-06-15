import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';

// ---------------------------------------------------------------------------
// Mocktail mocks
// ---------------------------------------------------------------------------

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

// ---------------------------------------------------------------------------
// Fakes — używane w testach difficulty (nie wymagają verify/verifyNever)
// ---------------------------------------------------------------------------

class _FakeDataSnapshot extends Fake implements DataSnapshot {
  _FakeDataSnapshot(this._value);
  final Object? _value;

  @override
  bool get exists => _value != null;

  @override
  Object? get value => _value;
}

class _FakeDatabaseReference extends Fake implements DatabaseReference {
  _FakeDatabaseReference(this._snapshot);
  final _FakeDataSnapshot _snapshot;

  @override
  Future<DataSnapshot> get() async => _snapshot;
}

/// Mapuje ścieżki RTDB (np. 'general/questions') na surowe listy danych.
class _FakeFirebaseDatabase extends Fake implements FirebaseDatabase {
  _FakeFirebaseDatabase(this._data);
  final Map<String, List<Object?>> _data;

  @override
  DatabaseReference ref([String? path]) =>
      _FakeDatabaseReference(_FakeDataSnapshot(_data[path]));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Buduje pojedynczy wpis pytania zgodny z formatem RTDB.
/// [difficulty] jest opcjonalne — pomiń tam, gdzie nie testujesz filtrowania.
Map<String, dynamic> _entry({
  String text = 'Default question?',
  List<String> correctAnswers = const ['A'],
  List<String> wrongAnswers = const ['B', 'C', 'D'],
  String difficulty = 'easy',
  String type = 'open4',
}) =>
    {
      'text': text,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'difficulty': difficulty,
      'type': type,
    };

/// Buduje listę [count] pytań z opcjonalnym [type].
List<Map<String, dynamic>> _buildList(int count, {String type = 'open4', String difficulty = 'easy'}) =>
    List.generate(count, (i) => _entry(text: 'Question $i', type: type, difficulty: difficulty));

/// Skrót do tworzenia repozytorium z fake RTDB.
FirebaseQuestionRepository _repoWith(Map<String, List<Object?>> data) =>
    FirebaseQuestionRepository(database: _FakeFirebaseDatabase(data));

/// Konfiguruje mocktail tak, żeby ref(path).get() zwracał snapshot z zadaną wartością.
void _setupSnapshot(
    MockFirebaseDatabase mockDb,
    MockDatabaseReference mockRef,
    MockDataSnapshot mockSnap, {
      required String path,
      required bool exists,
      required Object? value,
    }) {
  when(() => mockDb.ref(path)).thenReturn(mockRef);
  when(() => mockRef.get()).thenAnswer((_) async => mockSnap);
  when(() => mockSnap.exists).thenReturn(exists);
  when(() => mockSnap.value).thenReturn(value);
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _category = 'general';
const _path     = '$_category/questions';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Sekcja A — getQuestions [mocktail]
  // Granularne testy: snapshot existence, id format, QuestionType filtering,
  // skipping bad entries, RTDB path verification.
  // ══════════════════════════════════════════════════════════════════════════

  group('getQuestions [mocktail] — no data', () {
    late MockFirebaseDatabase mockDb;
    late MockDatabaseReference mockRef;
    late MockDataSnapshot mockSnap;
    late FirebaseQuestionRepository repo;

    setUp(() {
      mockDb   = MockFirebaseDatabase();
      mockRef  = MockDatabaseReference();
      mockSnap = MockDataSnapshot();
      repo     = FirebaseQuestionRepository(database: mockDb);
    });

    test('returns empty list when snapshot does not exist', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: false, value: null);

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(result, isEmpty);
    });

    test('returns empty list when snapshot.value is null (exists but empty)', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: null);

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(result, isEmpty);
    });
  });

  group('getQuestions [mocktail] — valid data', () {
    late MockFirebaseDatabase mockDb;
    late MockDatabaseReference mockRef;
    late MockDataSnapshot mockSnap;
    late FirebaseQuestionRepository repo;

    setUp(() {
      mockDb   = MockFirebaseDatabase();
      mockRef  = MockDatabaseReference();
      mockSnap = MockDataSnapshot();
      repo     = FirebaseQuestionRepository(database: mockDb);
    });

    test('returns at most `limit` questions', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: _buildList(20));

      final result = await repo.getQuestions(
        limit: 5,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(result.length, lessThanOrEqualTo(5));
    });

    test('returns all questions when count is less than limit', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: _buildList(3));

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(result.length, 3);
    });

    test('returned question ids are valid integer strings', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: _buildList(5));

      final result = await repo.getQuestions(
        limit: 5,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      for (final q in result) {
        expect(int.tryParse(q.id), isNotNull,
            reason: 'id "${q.id}" should be a valid integer string');
      }
    });

    test('returned ids are unique (no duplicates)', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: _buildList(10));

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      final ids = result.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('skips null entries in the RTDB array', () async {
      final data = <Object?>[
        null,
        _entry(text: 'Valid Q1'),
        null,
        _entry(text: 'Valid Q2'),
      ];
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: data);

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(result.length, 2);
    });

    test('skips entries that are not Maps', () async {
      final data = <Object?>[
        _entry(text: 'Valid'),
        'not a map',
        42,
        _entry(text: 'Also valid'),
      ];
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: data);

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(result.length, 2);
    });
  });

  group('getQuestions [mocktail] — QuestionType filtering', () {
    late MockFirebaseDatabase mockDb;
    late MockDatabaseReference mockRef;
    late MockDataSnapshot mockSnap;
    late FirebaseQuestionRepository repo;

    setUp(() {
      mockDb   = MockFirebaseDatabase();
      mockRef  = MockDatabaseReference();
      mockSnap = MockDataSnapshot();
      repo     = FirebaseQuestionRepository(database: mockDb);
    });

    test('returns only questions matching the requested QuestionType', () async {
      final data = [
        _entry(type: 'open4'),
        _entry(type: 'open4'),
        _entry(type: 'open4'),
      ];
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: data);

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: [QuestionType.open4],
        difficulty: Difficulty.easy,
      );

      expect(result.length, 3);
    });

    test('returns empty list when no question matches the requested type', () async {
      if (QuestionType.values.length < 2) return;

      final otherType = QuestionType.values.firstWhere(
            (t) => t != QuestionType.open4,
      );
      final data = [_entry(type: 'open4'), _entry(type: 'open4')];
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: data);

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: [otherType],
        difficulty: Difficulty.easy,
      );

      expect(result, isEmpty);
    });

    test('returns empty list when questionTypes is empty', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: _buildList(5));

      final result = await repo.getQuestions(
        limit: 10,
        category: _category,
        questionTypes: [],
        difficulty: Difficulty.easy,
      );

      expect(result, isEmpty);
    });
  });

  group('getQuestions [mocktail] — uses correct RTDB path', () {
    late MockFirebaseDatabase mockDb;
    late FirebaseQuestionRepository repo;

    setUp(() {
      mockDb = MockFirebaseDatabase();
      repo   = FirebaseQuestionRepository(database: mockDb);
    });

    test('reads from <category>/questions', () async {
      const customCategory = 'sports';
      final customRef  = MockDatabaseReference();
      final customSnap = MockDataSnapshot();

      when(() => mockDb.ref('$customCategory/questions')).thenReturn(customRef);
      when(() => customRef.get()).thenAnswer((_) async => customSnap);
      when(() => customSnap.exists).thenReturn(false);
      when(() => customSnap.value).thenReturn(null);

      await repo.getQuestions(
        limit: 10,
        category: customCategory,
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      verify(() => mockDb.ref('$customCategory/questions')).called(1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Sekcja B — getQuestions [fakes]
  // Testy filtrowania po difficulty — wymagają deterministycznego setupu danych.
  // ══════════════════════════════════════════════════════════════════════════

  group('getQuestions [fakes] — difficulty filtering', () {
    test('returns only questions matching the requested difficulty', () async {
      final repo = _repoWith({
        'general/questions': [
          _entry(text: 'Easy Q',   difficulty: 'easy'),
          _entry(text: 'Medium Q', difficulty: 'medium'),
          _entry(text: 'Hard Q',   difficulty: 'hard'),
        ],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(results.length, 1);
      expect(results.first.text, 'Easy Q');
    });

    test('returns multiple questions when several match difficulty', () async {
      final repo = _repoWith({
        'general/questions': [
          _entry(text: 'M1', difficulty: 'medium'),
          _entry(text: 'E1', difficulty: 'easy'),
          _entry(text: 'M2', difficulty: 'medium'),
        ],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.medium,
      );

      expect(results.length, 2);
      expect(results.map((q) => q.text), containsAll(['M1', 'M2']));
    });

    test('returns empty list when no question matches the difficulty', () async {
      final repo = _repoWith({
        'general/questions': [_entry(text: 'Hard Q', difficulty: 'hard')],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(results, isEmpty);
    });

    test('respects the limit parameter after difficulty filter', () async {
      final repo = _repoWith({
        'general/questions': _buildList(20, difficulty: 'medium'),
      });

      final results = await repo.getQuestions(
        limit: 7,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.medium,
      );

      expect(results.length, lessThanOrEqualTo(7));
    });

    test('returns fewer than limit when fewer questions match difficulty', () async {
      final repo = _repoWith({
        'general/questions': [_entry(text: 'Easy Q', difficulty: 'easy')],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(results.length, 1);
    });

    test('skips null entries in the raw array', () async {
      final repo = _repoWith({
        'general/questions': [
          null,
          _entry(text: 'Valid', difficulty: 'medium'),
          null,
        ],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.medium,
      );

      expect(results.length, 1);
      expect(results.first.text, 'Valid');
    });

    test('filters by QuestionType alongside difficulty', () async {
      final repo = _repoWith({
        'general/questions': [
          _entry(text: 'Open4 Medium', difficulty: 'medium', type: 'open4'),
        ],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.medium,
      );

      expect(results.any((q) => q.text == 'Open4 Medium'), isTrue);
    });
  });

  group('getQuestions [fakes] — path and id correctness', () {
    test('uses the correct RTDB path based on category', () async {
      final repo = _repoWith({
        'science/questions': [_entry(text: 'Science Q', difficulty: 'easy')],
        // 'general/questions' intentionally absent
      });

      final general = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );
      final science = await repo.getQuestions(
        limit: 10,
        category: 'science',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(general, isEmpty);
      expect(science.length, 1);
    });

    test('returns empty list when the path does not exist', () async {
      final results = await _repoWith({}).getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.medium,
      );
      expect(results, isEmpty);
    });

    test('returns empty list for an empty question array', () async {
      final repo = _repoWith({'general/questions': []});

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.medium,
      );

      expect(results, isEmpty);
    });

    test('assigns index-based string id to each question', () async {
      final repo = _repoWith({
        'general/questions': [
          _entry(text: 'Q0', difficulty: 'easy'),
          _entry(text: 'Q1', difficulty: 'easy'),
        ],
      });

      final results = await repo.getQuestions(
        limit: 10,
        category: 'general',
        questionTypes: QuestionType.values,
        difficulty: Difficulty.easy,
      );

      expect(results.map((q) => q.id).toSet(), containsAll(['0', '1']));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Sekcja C — getQuestionsByIds [mocktail]
  // Granularne testy: verifyNever dla empty ids, null snapshot, skipping bad
  // entries, path verification.
  // ══════════════════════════════════════════════════════════════════════════

  group('getQuestionsByIds [mocktail] — empty ids', () {
    late MockFirebaseDatabase mockDb;
    late FirebaseQuestionRepository repo;

    setUp(() {
      mockDb = MockFirebaseDatabase();
      repo   = FirebaseQuestionRepository(database: mockDb);
    });

    test('returns empty list without any RTDB call', () async {
      final result = await repo.getQuestionsByIds(category: _category, ids: []);

      expect(result, isEmpty);
      verifyNever(() => mockDb.ref(any()));
    });
  });

  group('getQuestionsByIds [mocktail] — no data', () {
    late MockFirebaseDatabase mockDb;
    late MockDatabaseReference mockRef;
    late MockDataSnapshot mockSnap;
    late FirebaseQuestionRepository repo;

    setUp(() {
      mockDb   = MockFirebaseDatabase();
      mockRef  = MockDatabaseReference();
      mockSnap = MockDataSnapshot();
      repo     = FirebaseQuestionRepository(database: mockDb);
    });

    test('returns empty list when snapshot does not exist', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: false, value: null);

      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['0', '1']);

      expect(result, isEmpty);
    });

    test('returns empty list when snapshot.value is null', () async {
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: null);

      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['0']);

      expect(result, isEmpty);
    });
  });

  group('getQuestionsByIds [mocktail] — valid data', () {
    late MockFirebaseDatabase mockDb;
    late MockDatabaseReference mockRef;
    late MockDataSnapshot mockSnap;
    late FirebaseQuestionRepository repo;

    final rawData = List.generate(5, (i) => _entry(text: 'Q$i'));

    setUp(() {
      mockDb   = MockFirebaseDatabase();
      mockRef  = MockDatabaseReference();
      mockSnap = MockDataSnapshot();
      repo     = FirebaseQuestionRepository(database: mockDb);
      _setupSnapshot(mockDb, mockRef, mockSnap,
          path: _path, exists: true, value: rawData);
    });

    test('returns questions with correct ids', () async {
      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['1', '3']);

      expect(result.map((q) => q.id).toList(), ['1', '3']);
    });

    test('preserves the order of the ids parameter', () async {
      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['4', '0', '2']);

      expect(result.map((q) => q.id).toList(), ['4', '0', '2']);
    });

    test('returns all questions when all ids are valid', () async {
      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['0', '1', '2', '3', '4']);

      expect(result.length, 5);
    });



    test('skips ids that are non-integer strings', () async {
      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['0', 'not_an_int', '2']);

      expect(result.map((q) => q.id).toList(), ['0', '2']);
    });

    test('skips ids that are out of bounds', () async {
      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['0', '99', '2']);

      expect(result.map((q) => q.id).toList(), ['0', '2']);
    });

    test('skips null entries at the specified index', () async {
      final dataWithNull = <Object?>[
        _entry(text: 'Q0'),
        null, // index 1 is null
        _entry(text: 'Q2'),
      ];
      when(() => mockSnap.value).thenReturn(dataWithNull);

      final result = await repo.getQuestionsByIds(
          category: _category, ids: ['0', '1', '2']);

      expect(result.map((q) => q.id).toList(), ['0', '2']);
    });

    test('reads from <category>/questions path', () async {
      await repo.getQuestionsByIds(category: _category, ids: ['0']);
      verify(() => mockDb.ref(_path)).called(1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Sekcja D — getQuestionsByIds [fakes]
  // Testy kontraktu: order preservation z text assertions, 'does not filter
  // by difficulty' (kluczowy kontrakt API), category routing.
  // ══════════════════════════════════════════════════════════════════════════

  group('getQuestionsByIds [fakes]', () {
    test('returns questions in the order of the provided ids', () async {
      final repo = _repoWith({
        'general/questions': [
          _entry(text: 'Q0', difficulty: 'easy'),
          _entry(text: 'Q1', difficulty: 'medium'),
          _entry(text: 'Q2', difficulty: 'hard'),
        ],
      });

      final results = await repo.getQuestionsByIds(
          category: 'general', ids: ['2', '0']);

      expect(results.length, 2);
      expect(results[0].text, 'Q2');
      expect(results[1].text, 'Q0');
    });

    test('skips ids that are out of array bounds', () async {
      final repo = _repoWith({
        'general/questions': [_entry(text: 'Q0', difficulty: 'easy')],
      });

      final results = await repo.getQuestionsByIds(
          category: 'general', ids: ['0', '99']);

      expect(results.length, 1);
      expect(results.first.id, '0');
    });

    test('skips non-numeric ids', () async {
      final repo = _repoWith({
        'general/questions': [_entry(text: 'Q0', difficulty: 'easy')],
      });

      final results = await repo.getQuestionsByIds(
          category: 'general', ids: ['not_a_number', '0']);

      expect(results.length, 1);
      expect(results.first.id, '0');
    });

    test('does not filter by difficulty — returns question regardless of difficulty', () async {
      // getQuestionsByIds jest używane po utworzeniu sesji, gdy pytania są już
      // ustalone. Filtrowanie po difficulty dotyczy tylko getQuestions.
      final repo = _repoWith({
        'general/questions': [
          _entry(text: 'Any Difficulty', difficulty: 'hard'),
        ],
      });

      final results = await repo.getQuestionsByIds(
          category: 'general', ids: ['0']);

      expect(results.length, 1);
      expect(results.first.text, 'Any Difficulty');
    });
  });
}