import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  const Settings({this.sound = true, this.haptics = true});
  final bool sound;
  final bool haptics;

  Settings copyWith({bool? sound, bool? haptics}) =>
      Settings(sound: sound ?? this.sound, haptics: haptics ?? this.haptics);
}

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() {
    Future.microtask(_load);
    return const Settings();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = Settings(
        sound: p.getBool('settings.sound') ?? true,
        haptics: p.getBool('settings.haptics') ?? true,
      );
    } catch (_) {}
  }

  Future<void> update(Settings s) async {
    state = s;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('settings.sound', s.sound);
      await p.setBool('settings.haptics', s.haptics);
    } catch (_) {}
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, Settings>(SettingsController.new);
