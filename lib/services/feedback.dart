import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

enum Effect { correct, wrong, finish, levelUp, tap, geoPerfect, geoGood, geoOk, geoLow }

/// Lyd og vibrasjon, styrt av innstillingene. Feiler stille hvis lyd ikke
/// er tilgjengelig (f.eks. i tester).
class FeedbackService {
  FeedbackService(this._ref);
  final Ref _ref;
  AudioPlayer? _player;

  Future<void> play(Effect effect) async {
    final s = _ref.read(settingsProvider);
    if (s.haptics) {
      try {
        switch (effect) {
          case Effect.correct:
          case Effect.geoPerfect:
          case Effect.geoGood:
          case Effect.geoOk:
          case Effect.geoLow:
          case Effect.finish:
          case Effect.levelUp:
            HapticFeedback.mediumImpact();
          case Effect.wrong:
            HapticFeedback.heavyImpact();
          case Effect.tap:
            HapticFeedback.selectionClick();
        }
      } catch (_) {}
    }
    if (!s.sound) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/${effect.name}.wav'), volume: 0.8);
    } catch (_) {}
  }
}

final feedbackProvider = Provider<FeedbackService>(FeedbackService.new);
