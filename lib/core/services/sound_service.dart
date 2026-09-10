import 'package:flutter/services.dart';

class SoundService {
  static void successFeedback() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void warningFeedback() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void errorFeedback() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.alert);
  }

  // Compatibility helpers
  void playSuccess() => successFeedback();
  void playError() => errorFeedback();
  void playWarning() => warningFeedback();
  void playClick() => lightImpact();
}
