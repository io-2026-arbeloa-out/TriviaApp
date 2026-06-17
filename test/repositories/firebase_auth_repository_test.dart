import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';

void main() {
  const tEmail = 'test@test.com';
  const tPassword = 'password123';
  const tUsername = 'TestUser';
  const tUid = 'uid1';

  final tUser = MockUser(
    uid: tUid,
    email: tEmail,
    displayName: tUsername,
  );

  // ── registerWithEmail ───────────────────────────────────────────────────────

  group('registerWithEmail', () {
    late MockFirebaseAuth mockAuth;
    late FirebaseAuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth(mockUser: tUser);
      repo = FirebaseAuthRepository(auth: mockAuth);
    });

    test('returns ProfileData with uid from Firebase credential', () async {
      final result =
          await repo.registerWithEmail(tEmail, tPassword, tUsername);

      expect(result, isNotNull);
    });

    test('returns ProfileData with provided username', () async {
      final result =
          await repo.registerWithEmail(tEmail, tPassword, tUsername);

      expect(result.username, tUsername);
    });

    test('creates Firebase user so currentUser is non-null afterwards',
        () async {
      await repo.registerWithEmail(tEmail, tPassword, tUsername);

      expect(mockAuth.currentUser, isNotNull);
    });
  });

  // ── signInWithEmail ─────────────────────────────────────────────────────────

  group('signInWithEmail', () {
    late MockFirebaseAuth mockAuth;
    late FirebaseAuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: false);
      repo = FirebaseAuthRepository(auth: mockAuth);
    });

    test('returns ProfileData with correct uid', () async {
      final result = await repo.signInWithEmail(tEmail, tPassword);

      expect(result.uid, tUid);
    });

    test('returns ProfileData with displayName as username', () async {
      final result = await repo.signInWithEmail(tEmail, tPassword);

      expect(result.username, tUsername);
    });

    test('sets currentUser after sign in', () async {
      expect(mockAuth.currentUser, isNull);

      await repo.signInWithEmail(tEmail, tPassword);

      expect(mockAuth.currentUser, isNotNull);
    });
  });

  // ── signOut ─────────────────────────────────────────────────────────────────

  group('signOut', () {
    late MockFirebaseAuth mockAuth;
    late FirebaseAuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: true);
      repo = FirebaseAuthRepository(auth: mockAuth);
    });

    test('clears currentUser', () async {
      expect(mockAuth.currentUser, isNotNull);

      await repo.signOut();

      expect(mockAuth.currentUser, isNull);
    });
  });

  // ── authStateChanges ────────────────────────────────────────────────────────

  group('authStateChanges', () {
    test('emits ProfileData with correct uid when user is signed in', () {
      final mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: true);
      final repo = FirebaseAuthRepository(auth: mockAuth);

      final stream = repo.authStateChanges();

      expect(
        stream,
        emits(predicate<dynamic>((p) => p?.uid == tUid)),
      );
    });

    test('emits ProfileData with correct username when signed in', () {
      final mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: true);
      final repo = FirebaseAuthRepository(auth: mockAuth);

      final stream = repo.authStateChanges();

      expect(
        stream,
        emits(predicate<dynamic>((p) => p?.username == tUsername)),
      );
    });

    test('emits null when no user is signed in', () {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final repo = FirebaseAuthRepository(auth: mockAuth);

      final stream = repo.authStateChanges();

      expect(stream, emits(null));
    });

    test('emits null after sign out', () async {
      final mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: true);
      final repo = FirebaseAuthRepository(auth: mockAuth);

      await mockAuth.signOut();

      expect(repo.authStateChanges(), emitsThrough(null));
    });
  });
}
