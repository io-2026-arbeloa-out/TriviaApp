import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/auth_repository.dart';
import 'package:triviaapp/repositories/profile_repository.dart';
import 'package:triviaapp/interfaces/i_register_auth_service.dart';

// ---------------------------------------------------------------------------
// Fakes for repositories
// Uses repository contracts without constructing Firebase clients.
// ---------------------------------------------------------------------------

class FakeAuthRepository extends Fake
    implements AuthRepository {
  // Configurable behaviour — set these before each test.
  ProfileData? signInResult;
  Exception? signInError;

  ProfileData? registerResult;
  Exception? registerError;
  int registerCallCount = 0;
  int displayNameCallCount = 0;
  Exception? displayNameError;
  String? updatedDisplayName;

  bool signOutCalled = false;
  bool signedIn = false;
  int signInCallCount = 0;
  Stream<ProfileData?> authStream = const Stream.empty();

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<ProfileData> signInWithEmail(String email, String password) async {
    signInCallCount++;
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<ProfileData> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    registerCallCount++;
    if (registerError != null) throw registerError!;
    return registerResult!;
  }

  @override
  Future<void> updateDisplayName(String uid, String username) async {
    displayNameCallCount++;
    if (displayNameError != null) throw displayNameError!;
    updatedDisplayName = username;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    signedIn = false;
  }

  @override
  Stream<ProfileData?> authStateChanges() => authStream;
}

class FakeProfileRepository extends Fake
    implements ProfileRepository {
  ProfileData? getResult;
  Exception? getError;

  bool updateCalled = false;
  ProfileData? lastUpdatedProfile;
  String uiPreset = 'default';
  Exception? updateError;

  @override
  Future<String> getUIPreset() async => uiPreset;

  @override
  Future<ProfileData> getProfileData() async {
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

class FakeRegisterAuthService extends Fake implements IRegisterAuthService {
  ProfileData? registerResult;
  Exception? registerError;
  int registerCallCount = 0;

  @override
  Future<ProfileData> register(
      String email, String password, String username) async {
    registerCallCount++;
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
