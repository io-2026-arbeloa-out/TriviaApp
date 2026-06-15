import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/session_status.dart';

void main() {
  // ─── toJson ───────────────────────────────────────────────────────────────

  group('SessionStatus.toJson', () {
    test('each value serializes to its enum name', () {
      for (final status in SessionStatus.values) {
        expect(status.toJson(), equals(status.name));
      }
    });

    test('lobby    → "lobby"',     () => expect(SessionStatus.lobby.toJson(),     'lobby'));
    test('waiting  → "waiting"',   () => expect(SessionStatus.waiting.toJson(),   'waiting'));
    test('answering → "answering"', () => expect(SessionStatus.answering.toJson(), 'answering'));
    test('resolving → "resolving"', () => expect(SessionStatus.resolving.toJson(), 'resolving'));
    test('finished → "finished"',  () => expect(SessionStatus.finished.toJson(),  'finished'));
    test('aborted  → "aborted"',   () => expect(SessionStatus.aborted.toJson(),   'aborted'));
  });

  // ─── fromJson – valid input ───────────────────────────────────────────────

  group('SessionStatus.fromJson — valid input', () {
    test('parses every value by its enum name', () {
      for (final status in SessionStatus.values) {
        expect(SessionStatus.fromJson(status.name), equals(status));
      }
    });

    test('"lobby"',     () => expect(SessionStatus.fromJson('lobby'),     SessionStatus.lobby));
    test('"waiting"',   () => expect(SessionStatus.fromJson('waiting'),   SessionStatus.waiting));
    test('"answering"', () => expect(SessionStatus.fromJson('answering'), SessionStatus.answering));
    test('"resolving"', () => expect(SessionStatus.fromJson('resolving'), SessionStatus.resolving));
    test('"finished"',  () => expect(SessionStatus.fromJson('finished'),  SessionStatus.finished));
    test('"aborted"',   () => expect(SessionStatus.fromJson('aborted'),   SessionStatus.aborted));
  });

  // ─── fromJson – invalid input → always returns aborted ───────────────────

  group('SessionStatus.fromJson — invalid input always returns aborted', () {
    test('unknown string',  () => expect(SessionStatus.fromJson('notAStatus'), SessionStatus.aborted));
    test('empty string',    () => expect(SessionStatus.fromJson(''),           SessionStatus.aborted));
    test('null',            () => expect(SessionStatus.fromJson(null),         SessionStatus.aborted));
    test('integer',         () => expect(SessionStatus.fromJson(0),            SessionStatus.aborted));
    test('boolean',         () => expect(SessionStatus.fromJson(false),        SessionStatus.aborted));
    test('list',            () => expect(SessionStatus.fromJson([]),            SessionStatus.aborted));
    test('map',             () => expect(SessionStatus.fromJson({}),            SessionStatus.aborted));

    // Case-sensitive: Dart enum names are camelCase — uppercase must not match.
    test('wrong case "Lobby"',     () => expect(SessionStatus.fromJson('Lobby'),      SessionStatus.aborted));
    test('wrong case "Answering"', () => expect(SessionStatus.fromJson('Answering'),  SessionStatus.aborted));
    test('wrong case "FINISHED"',  () => expect(SessionStatus.fromJson('FINISHED'),   SessionStatus.aborted));
    test('wrong case "ANSWERING"', () => expect(SessionStatus.fromJson('ANSWERING'),  SessionStatus.aborted));
  });

  // ─── round-trip ───────────────────────────────────────────────────────────

  group('round-trip', () {
    test('fromJson(toJson(x)) == x for every value', () {
      for (final status in SessionStatus.values) {
        expect(SessionStatus.fromJson(status.toJson()), equals(status));
      }
    });
  });
}