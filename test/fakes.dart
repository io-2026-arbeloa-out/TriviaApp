import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/interfaces/i_login_auth_service.dart';
import 'package:triviaapp/interfaces/i_register_auth_service.dart';

// ---------------------------------------------------------------------------
// Fakes for repositories
// Uses Fake + implements to bypass Firebase constructors entirely.
// ---------------------------------------------------------------------------

class FakeFirebaseAuthRepository extends Fake
    implements FirebaseAuthRepository {
  // Configurable behaviour — set these before each test.
  ProfileData? signInResult;
  Exception? signInError;

  ProfileData? registerResult;
  Exception? registerError;

  bool signOutCalled = false;
  Stream<ProfileData?> authStream = const Stream.empty();

  @override
  Future<ProfileData> signInWithEmail(String email, String password) async {
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<ProfileData> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    if (registerError != null) throw registerError!;
    return registerResult!;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Stream<ProfileData?> authStateChanges() => authStream;
}

class FakeFirebaseProfileRepository extends Fake
    implements FirebaseProfileRepository {
  ProfileData? getResult;
  Exception? getError;

  bool updateCalled = false;
  ProfileData? lastUpdatedProfile;
  Exception? updateError;

  @override
  Future<ProfileData> getProfileData(String uid) async {
    if (getError != null) throw getError!;
    return getResult!;
  }

  @override
  Future<void> updateProfileData(ProfileData profileData) async {
    if (updateError != null) throw updateError!;
    updateCalled = true;
    lastUpdatedProfile = profileData;
  }
}

// ---------------------------------------------------------------------------
// Fakes for services (used in widget tests)
// ---------------------------------------------------------------------------

class FakeLoginAuthService extends Fake implements ILoginAuthService {
  ProfileData? signInResult;
  Exception? signInError;
  bool signOutCalled = false;

  @override
  Future<ProfileData> signInWithEmail(String email, String password) async {
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Stream<ProfileData?> authStateChanges() => const Stream.empty();
}

class FakeRegisterAuthService extends Fake implements IRegisterAuthService {
  ProfileData? registerResult;
  Exception? registerError;

  @override
  Future<ProfileData> register(
      String email, String password, String username) async {
    if (registerError != null) throw registerError!;
    return registerResult!;
  }

  @override
  Stream<ProfileData?> authStateChanges() => const Stream.empty();
}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

ProfileData makeProfile({
  String uid = 'uid-1',
  String username = 'TestUser',
}) =>
    ProfileData(uid: uid, username: username);
