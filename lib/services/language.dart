import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'profile.dart';

/// Brukerens eget språkvalg (null = automatisk ut fra land).
class LanguageController extends Notifier<String?> {
  /// Settes i main() før appen starter, så første bilde får riktig språk.
  static String? preloaded;

  @override
  String? build() {
    if (preloaded == null) Future.microtask(_load);
    return preloaded;
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString('settings.lang');
      if (v != null && L10n.supported.contains(v)) state = v;
    } catch (_) {}
  }

  /// [code] null = automatisk.
  Future<void> choose(String? code) async {
    state = code;
    try {
      final p = await SharedPreferences.getInstance();
      if (code == null) {
        await p.remove('settings.lang');
      } else {
        await p.setString('settings.lang', code);
      }
    } catch (_) {}
  }
}

final languageProvider =
    NotifierProvider<LanguageController, String?>(LanguageController.new);

/// Språket appen faktisk bruker: eget valg, ellers språket til landet i profilen,
/// og før profilen er lagret: telefonens språk.
final effectiveLangProvider = Provider<String>((ref) {
  final chosen = ref.watch(languageProvider);
  if (chosen != null) return chosen;
  final profile = ref.watch(profileProvider);
  if (profile.saved) return L10n.langForCountry(profile.country);
  return L10n.langForDevice(PlatformDispatcher.instance.locale.languageCode);
});
