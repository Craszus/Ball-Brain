import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ball Brain Pro. I `test` slås Pro på uten betaling, så alt kan prøves.
///
/// FØR PUBLISERING I BUTIKK: sett [proMode] til `off`, eller koble på ekte kjøp
/// (App Store / Google Play) som setter statusen, og oppdater vilkår og personverntekst.
const String proMode = 'test'; // 'off' | 'test'

/// Pro gir bare ekstra innhold, øving og utseende – aldri fordeler på rangeringene.
const proTitles = [
  'Taktikeren',
  'Orakelet',
  'Regelrytteren',
  'Historikeren',
  'Banesjefen',
  'Spillfordeleren',
];

class ProState {
  const ProState({this.active = false, this.title = '', this.frame = 0});

  final bool active;

  /// Valgt tittel (tom = ingen).
  final String title;

  /// Valgt avatarramme (0 = ingen), se lib/ui/pro_frame.dart.
  final int frame;

  /// Det som faktisk skal vises (ingenting uten Pro).
  String get shownTitle => active ? title : '';
  int get shownFrame => active ? frame : 0;

  ProState copyWith({bool? active, String? title, int? frame}) => ProState(
      active: active ?? this.active, title: title ?? this.title, frame: frame ?? this.frame);
}

const _activeKey = 'pro.active';

class ProController extends Notifier<ProState> {
  @override
  ProState build() {
    Future.microtask(_load);
    return const ProState();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = ProState(
        active: await isProActive(),
        title: p.getString('pro.title') ?? '',
        frame: p.getInt('pro.frame') ?? 0,
      );
    } catch (_) {}
  }

  Future<void> setActive(bool v) async {
    state = state.copyWith(active: v && proMode != 'off');
    (await SharedPreferences.getInstance()).setBool(_activeKey, v);
  }

  Future<void> setTitle(String v) async {
    state = state.copyWith(title: v);
    (await SharedPreferences.getInstance()).setString('pro.title', v);
  }

  Future<void> setFrame(int v) async {
    state = state.copyWith(frame: v);
    (await SharedPreferences.getInstance()).setInt('pro.frame', v);
  }
}

Future<bool> isProActive() async =>
    proMode != 'off' &&
    ((await SharedPreferences.getInstance()).getBool(_activeKey) ?? false);

final proProvider = NotifierProvider<ProController, ProState>(ProController.new);
