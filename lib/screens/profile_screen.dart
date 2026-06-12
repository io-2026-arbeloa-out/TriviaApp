import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_profile_data_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/services/profile_data_service.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  final UIOptions _options;
  final IProfileDataService _profileDataService;
  final bool Function() _authChecker;

  ProfileScreen({
    super.key,
    UIOptions? options,
    IProfileDataService? profileDataService,
    bool Function()? authChecker,
  })  : _options = options ?? UIOptions(),
        _profileDataService = profileDataService ?? ProfileDataService(null),
        _authChecker = authChecker ?? (() => FirebaseAuth.instance.currentUser != null);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _availableAvatars = [
    'assets/images/profile_pictures/test.png',
    'assets/images/profile_pictures/test2.png',
    'assets/images/profile_pictures/test.png',
    'assets/images/profile_pictures/test2.png',
    'assets/images/profile_pictures/test2.png',
    'assets/images/profile_pictures/test.png',
  ];

  UIOptions get options => widget._options;

  bool _isLoading = true;
  bool _isLoggedIn = false;
  ProfileData? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = widget._authChecker();
    if (!user) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoggedIn = true);
    try {
      final data = await widget._profileDataService.getProfileData();
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nie udało się załadować profilu.';
      });
    }
  }

  Future<void> _onAvatarSelected(String assetPath) async {
    if (_profileData == null) return;
    final updated = _profileData!.copyWith(profilePicture: assetPath);
    try {
      await widget._profileDataService.updateProfileData(updated);
      setState(() => _profileData = updated);
    } catch (e) {
      setState(() => _errorMessage = 'Nie udało się zapisać zdjęcia profilowego.');
    }
  }

  Future<void> _onLogoutPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: options.mainColor,
        title: Text(
          'Wylogowanie',
          textAlign: TextAlign.center,
          style: TextStyle(color: options.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy na pewno chcesz się wylogować?',
          textAlign: TextAlign.center,
          style: TextStyle(color: options.textColor),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: options.mainButtonColor,
                  foregroundColor: options.textColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: options.mainButtonColor,
                  foregroundColor: options.textColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Wyloguj'),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _profileData = null;
      _errorMessage = null;
    });
  }


  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: options.mainColor,
        title: Text(
          'Wybierz zdjęcie profilowe',
          textAlign: TextAlign.center,
          style: TextStyle(color: options.textColor, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _availableAvatars.map((path) {
              final isSelected = _profileData?.profilePicture == path;
              return GestureDetector(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _onAvatarSelected(path);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: options.mainButtonColor, width: 3)
                        : null,
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(path),
                    backgroundColor: options.secondaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: options.mainButtonColor,
                foregroundColor: options.textColor,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
          ),
        ],
      ),
    );
  }

  String get _accuracy {
    if (_profileData == null || _profileData!.totalQuestionsAnswered == 0) {
      return '0%';
    }
    final pct = (_profileData!.correctAnswers /
        _profileData!.totalQuestionsAnswered *
        100)
        .round();
    return '$pct%';
  }

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
                Expanded(
                  child: _isLoading
                      ? Center(
                      child: CircularProgressIndicator(
                          color: options.textColor))
                      : _isLoggedIn
                      ? _buildLoggedInContent(context)
                      : _buildLoggedOutContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 2,
        options: options,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: AppRoute.instance.goBack,
          icon: const Icon(Icons.arrow_back),
          color: options.textColor,
        ),
        Text(
          'Profil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: options.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        _isLoggedIn
            ? IconButton(
          onPressed: _onLogoutPressed,
          icon: const Icon(Icons.logout),
          color: options.textColor,
        )
            : const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildLoggedInContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                        options.secondaryButtonColor.withOpacity(0.2),
                        backgroundImage:
                        _profileData?.profilePicture.isNotEmpty == true
                            ? AssetImage(_profileData!.profilePicture)
                            : null,
                        child: _profileData?.profilePicture.isNotEmpty == true
                            ? null
                            : Icon(Icons.person,
                            size: 40, color: options.textColor),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: options.mainButtonColor,
                          child: Icon(Icons.edit,
                              size: 14, color: options.textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _profileData?.username ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: options.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ranga: ${_profileData?.rank.name ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: options.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Statystyki',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: options.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatCard(context, 'Odpowiedziane pytania',
              '${_profileData?.totalQuestionsAnswered ?? 0}'),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Poprawne odpowiedzi',
              '${_profileData?.correctAnswers ?? 0}'),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Skuteczność', _accuracy),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Gry rankingowe',
              '${_profileData?.rankedGamesPlayed ?? 0}'),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Wygrane gry rankingowe',
              '${_profileData?.rankedGamesWon ?? 0}'),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Punkty rankingowe',
              '${_profileData?.ratingPoints ?? 0}'),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: options.mainButtonColor,
              foregroundColor: options.textColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // TODO: przejście do AchievementScreen
            },
            child: const Text('Zobacz osiągnięcia',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.person_off, size: 64, color: options.textColor),
        const SizedBox(height: 24),
        Text(
          'Nie jesteś zalogowany. Zaloguj się na swoje konto lub zarejestruj się.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: options.textColor,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: options.mainButtonColor,
            foregroundColor: options.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => AppRoute.instance.goToLogin(options),
          child: const Text('Zaloguj się', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: options.secondaryButtonColor,
            foregroundColor: options.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () =>
              AppRoute.instance.goToRegistration(options),
          child: const Text('Zarejestruj się', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: options.secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: options.textColor),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: options.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}