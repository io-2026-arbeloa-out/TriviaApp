import 'package:audioplayers/audioplayers.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/app_route.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  final AudioPlayer _musicPlayer = AudioPlayer();

  double _musicVolume = 0.6;
  double _sfxVolume = 0.8;
  String? _currentTrack;

  // ---------------------------------------------------------------------------
  // Screen -> music track mapping.
  // Screens not listed here will silence the music.
  // ---------------------------------------------------------------------------
  static const Map<String, String> _screenMusic = {
    AppRoute.mainMenuScreen:    'audio/music/main_menu.mp3',
    AppRoute.profileScreen:     'audio/music/ambient.mp3',
    AppRoute.quizListScreen:    'audio/music/ambient.mp3',
    AppRoute.leaderboardScreen: 'audio/music/ambient.mp3',
    AppRoute.achievementScreen: 'audio/music/ambient.mp3',
    AppRoute.privateLobbyScreen:'audio/music/lobby.mp3',
    AppRoute.singleplayerScreen:'audio/music/game.mp3',
    AppRoute.multiplayerScreen: 'audio/music/game.mp3',
  };

  // ---------------------------------------------------------------------------
  // SFX keys — use AudioManager.sfx.* constants when calling playSfx().
  // ---------------------------------------------------------------------------
  static const String sfxClick      = 'click';
  static const String sfxCorrect    = 'correct';
  static const String sfxWrong      = 'wrong';
  static const String sfxGameStart  = 'game_start';
  static const String sfxCountdown  = 'countdown';
  static const String sfxWin        = 'win';
  static const String sfxLose       = 'lose';

  static const Map<String, String> _sfxPaths = {
    sfxClick:     'audio/sfx/click.mp3',
    sfxCorrect:   'audio/sfx/correct.mp3',
    sfxWrong:     'audio/sfx/wrong.mp3',
    sfxGameStart: 'audio/sfx/game_start.mp3',
    sfxCountdown: 'audio/sfx/countdown.mp3',
    sfxWin:       'audio/sfx/win.mp3',
    sfxLose:      'audio/sfx/lose.mp3',
  };

  // ---------------------------------------------------------------------------
  // Initialization — call once at app start, after loading UserOptions.
  // ---------------------------------------------------------------------------
  Future<void> init(UserOptions options) async {
    _musicVolume = options.musicVolume / 100.0;
    _sfxVolume   = options.soundVolume  / 100.0;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_musicVolume);
  }

  // ---------------------------------------------------------------------------
  // Music
  // ---------------------------------------------------------------------------

  /// Called on every screen transition. Pass the route constant from AppRoute.
  Future<void> playMusicForScreen(String route) async {
    final track = _screenMusic[route];

    if (track == null) {
      await _musicPlayer.stop();
      _currentTrack = null;
      return;
    }

    // Guard: do not restart the track if it is already playing.
    if (track == _currentTrack) return;

    _currentTrack = track;
    await _musicPlayer.stop();
    await _musicPlayer.play(AssetSource(track));
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
    _currentTrack = null;
  }

  Future<void> pauseMusic() => _musicPlayer.pause();

  Future<void> resumeMusic() => _musicPlayer.resume();

  // ---------------------------------------------------------------------------
  // SFX
  //
  // A new AudioPlayer is created per sound so that rapid clicks or overlapping
  // effects (e.g. countdown ticks) do not cancel each other. Each player
  // disposes itself after playback completes.
  // ---------------------------------------------------------------------------
  Future<void> playSfx(String key) async {
    final path = _sfxPaths[key];
    if (path == null) return;

    final player = AudioPlayer();
    await player.setVolume(_sfxVolume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(path));

    // Dispose the player as soon as the sound finishes.
    player.onPlayerComplete.listen((_) => player.dispose());
  }

  // ---------------------------------------------------------------------------
  // Volume control — accepts 0-100 (from UserOptions / sliders).
  // ---------------------------------------------------------------------------
  Future<void> setMusicVolume(int volume) async {
    _musicVolume = volume.clamp(0, 100) / 100.0;
    await _musicPlayer.setVolume(_musicVolume);
  }

  Future<void> setSfxVolume(int volume) async {
    _sfxVolume = volume.clamp(0, 100) / 100.0;
    // Applied to future SFX players; in-flight players are unaffected.
  }

  int get musicVolumeInt => (_musicVolume * 100).round();
  int get sfxVolumeInt   => (_sfxVolume   * 100).round();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  Future<void> dispose() async {
    await _musicPlayer.dispose();
  }
}