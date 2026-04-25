import 'dart:async';
import 'package:flutter/material.dart';
import 'package:triviaapp/audio_manager.dart';
import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/interfaces/i_user_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import 'package:triviaapp/services/user_options_service.dart';
import 'package:triviaapp/app_route.dart';

class UserOptionsScreen extends StatefulWidget {
  final UIOptions _options;
  final IUserOptionsService _userOptionsService;
  final IUIOptionsService _uiOptionsService;

  UserOptionsScreen({
    super.key,
    UIOptions? options,
    IUserOptionsService? userOptionsService,
    IUIOptionsService? uiOptionsService,
  })  : _options = options ?? UIOptions(),
        _userOptionsService = userOptionsService ?? UserOptionsService(),
        _uiOptionsService = uiOptionsService ?? UIOptionsService();

  @override
  State<UserOptionsScreen> createState() => _UserOptionsScreenState();
}

class _UserOptionsScreenState extends State<UserOptionsScreen> {
  UIOptions get options => _displayOptions;
  UIOptions get savedOptions => widget._options;
  IUIOptionsService get uiOptionsService => widget._uiOptionsService;
  IUserOptionsService get userOptionsService => widget._userOptionsService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Timer? _errorTimer;

  late UIOptions _displayOptions;
  late Map<String, UIOptions> _presets;
  late UserOptions _userOptions;
  late String _selectedPreset;
  late UserOptions _savedUserOptions;

  @override
  void initState() {
    super.initState();
    _displayOptions = widget._options;
    _load();
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = message);
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        userOptionsService.getUserOptions(),
        uiOptionsService.getUIPresets(),
        uiOptionsService.getCurrentPreset(),
      ]);
      _userOptions    = results[0] as UserOptions;
      _savedUserOptions = _userOptions;
      _presets        = results[1] as Map<String, UIOptions>;
      _selectedPreset = results[2] as String;
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Nie udało się załadować ustawień.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await Future.wait([
        userOptionsService.saveUserOptions(UserOptions(
          soundVolume: _userOptions.soundVolume,
          musicVolume: _userOptions.musicVolume,
          sfxVolume: _userOptions.sfxVolume,
        )),
        uiOptionsService.saveUIOptions(_selectedPreset),
      ]);
      if (!mounted) return;
      AppRoute.instance.goToMainMenu(_displayOptions);
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Nie udało się zapisać ustawień.');
    }
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selectedPreset = presetId;
      _displayOptions = _presets[presetId] ?? widget._options;
    });
  }

  Future<void> _onBackPressed(BuildContext context) async {
    if (_savedUserOptions == _userOptions && options == savedOptions){
      AppRoute.instance.goBack();//todo go to main menu??
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: savedOptions.mainColor,

        title: Text(
          'Niezapisane zmiany',
          textAlign: TextAlign.center,
          style: TextStyle(color: savedOptions.textColor),
        ),

        content: Text(
          'Wprowadzone zmiany nie zostały zapisane. Czy chcesz je zapisać?',
          textAlign: TextAlign.center,
          style: TextStyle(color: savedOptions.textColor),
        ),

        actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: savedOptions.mainButtonColor,
                  foregroundColor: savedOptions.textColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Zapisz ustawienia'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: savedOptions.mainButtonColor,
                  foregroundColor: savedOptions.textColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Odrzuć zmiany'),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _save();
      AppRoute.instance.goBack();
      return;
    }

    await AudioManager.instance.setMusicVolume(_savedUserOptions.musicVolume);
    await AudioManager.instance.setSfxVolume(_savedUserOptions.soundVolume);

    AppRoute.instance.goBack();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: options.textColor))
                    : _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _onBackPressed(context),
            icon: const Icon(Icons.arrow_back),
            color: options.textColor,
          ),
          Text(
            'Ustawienia',
            style: TextStyle(
              color: options.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[900]),//todo co jeśli preset z czerwonym tlem?
                textAlign: TextAlign.center,
              ),
            ),
          _buildSectionLabel(context, 'Dźwięk'),
          const SizedBox(height: 8),
          _buildSlider(
            context,
            label: 'Efekty dźwiękowe',
            value: _userOptions.soundVolume.toDouble(),
            onChanged: (v) => setState(() {
              _userOptions = _userOptions.copyWith(soundVolume: v.floor());
            }),
          ),
          const SizedBox(height: 8),
          _buildSlider(
            context,
            label: 'Muzyka',
            value: _userOptions.musicVolume.toDouble(),
            onChanged: (v) => setState(() {
              _userOptions = _userOptions.copyWith(musicVolume: v.floor());
            }),
          ),
          const SizedBox(height: 8),
          _buildSlider(
            context,
            label: 'SFX',
            value: _userOptions.sfxVolume.toDouble(),
            onChanged: (v) => setState(() {
              _userOptions = _userOptions.copyWith(sfxVolume: v.floor());
            }),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel(context, 'Motyw kolorystyczny'),
          const SizedBox(height: 12),
          _buildPresetList(context),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: options.mainButtonColor,
              foregroundColor: options.textColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: options.textColor,
              ),
            )
                : const Text('Zapisz', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: options.textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSlider(
      BuildContext context, {
        required String label,
        required double value,
        required ValueChanged<double> onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: options.textColor)),
            Text('${value.round()}%',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: options.textColor)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          activeColor: options.mainButtonColor,
          inactiveColor: options.mainButtonColor.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPresetList(BuildContext context) {
    if (_presets.isEmpty) {
      return Text(
        'Brak dostępnych motywów.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: options.textColor),
      );
    }

    return Column(
      children: _presets.entries.map((entry) {
        final presetId = entry.key;
        final preset = entry.value;
        final isSelected = _selectedPreset == presetId;

        return GestureDetector(
          onTap: () => _selectPreset(presetId),
          child: Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [preset.mainColor, preset.secondaryColor],
              ),
              border: isSelected
                  ? Border.all(color: preset.mainButtonColor, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: preset.mainButtonColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSelected ? 'Wybrany' : 'Wybierz',
                      style: TextStyle(
                        color: preset.mainButtonColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}