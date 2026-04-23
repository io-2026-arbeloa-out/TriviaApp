import 'package:flutter/material.dart';
import 'package:triviaapp/audio_manager.dart';

class SfxTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final String sfxKey;

  const SfxTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.sfxKey = AudioManager.sfxClick,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
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