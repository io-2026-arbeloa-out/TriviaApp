import 'package:flutter/material.dart';
import 'package:triviaapp/audio_manager.dart';

class SfxButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String sfxKey;
  final ButtonStyle? style;

  const SfxButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.sfxKey = AudioManager.sfxClick,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: onPressed == null
          ? null
          : () {
        AudioManager.instance.playSfx(sfxKey);
        onPressed!();
      },
      child: child,
    );
  }
}