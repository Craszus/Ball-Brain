import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart' show rootBundle;

/// Språksystem uten kodegenerering: norsk bokmål er kildespråket (teksten i koden),
/// og de andre språkene ligger som `assets/i18n/<språk>.json` (norsk tekst → oversettelse).
///
/// Tekster slås opp på selve teksten. Maler med `{}` håndterer tekster med tall og navn
/// («Du var {} unna!»). Mangler en oversettelse, brukes engelsk, og til sist norsk.
class L10n {
  static const supported = ['nb', 'en', 'sv', 'da', 'de', 'es', 'fr'];

  static const nativeNames = {
    'nb': 'Norsk',
    'en': 'English',
    'sv': 'Svenska',
    'da': 'Dansk',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
  };

  /// Valgt språk akkurat nå (leses av alle tekster).
  static String lang = 'nb';

  /// Tekster uten oversettelse som er slått opp (kun i feilsøking/tester).
  static final Set<String> misses = {};

  static Map<String, String> _exact = {};
  static Map<String, String> _upper = {};
  static List<_Template> _templates = [];
  static final Map<String, String> _cache = {};

  /// Språk ut fra land (ISO-3166 alfa-2).
  static String langForCountry(String code) => switch (code.toUpperCase()) {
        'NO' => 'nb',
        'SE' => 'sv',
        'DK' => 'da',
        'DE' || 'AT' || 'CH' => 'de',
        'ES' || 'MX' || 'AR' || 'CO' || 'CL' => 'es',
        'FR' => 'fr',
        _ => 'en',
      };

  /// Språk ut fra telefonens språkkode (brukes før landet er valgt).
  static String langForDevice(String languageCode) {
    final c = languageCode.toLowerCase();
    if (c == 'no' || c == 'nn') return 'nb';
    return supported.contains(c) ? c : 'en';
  }

  static Future<Map<String, String>> _read(String code) async {
    try {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Laster oversettelsene for [code] (og engelsk som reserve).
  static Future<void> load(String code) async {
    final target = supported.contains(code) ? code : 'en';
    final merged = <String, String>{};
    if (target != 'nb') {
      merged.addAll(await _read('en'));
      if (target != 'en') merged.addAll(await _read(target));
    }
    setData(target, merged);
  }

  /// Setter data direkte (brukes av [load] og i tester).
  static void setData(String code, Map<String, String> data) {
    lang = code;
    _cache.clear();
    _exact = {};
    _upper = {};
    final tpl = <_Template>[];
    data.forEach((k, v) {
      if (k.contains('{}')) {
        tpl.add(_Template(k, v));
      } else {
        _exact[k] = v;
        _upper[k.toUpperCase()] = v.toUpperCase();
      }
    });
    tpl.sort((a, b) => b.literalLength.compareTo(a.literalLength));
    _templates = tpl;
  }

  static final _letters = RegExp(r'[A-Za-zÆØÅæøåÄÖÜäöüß]{2,}');

  /// Oversetter [s] til valgt språk.
  static String tr(String s) {
    if (lang == 'nb' || s.isEmpty) return s;
    final hit = _cache[s];
    if (hit != null) return hit;
    final out = _translate(s);
    if (!_found && _letters.hasMatch(s) && kDebugMode) misses.add(s);
    _cache[s] = out;
    return out;
  }

  static bool _found = false;

  static String _translate(String s) {
    _found = true;
    final e = _exact[s];
    if (e != null) return e;
    final isUpper = s == s.toUpperCase() && s != s.toLowerCase();
    if (isUpper) {
      final u = _upper[s];
      if (u != null) return u;
    }
    for (final t in _templates) {
      final r = t.apply(s, tr);
      if (r != null) {
        _found = true;
        return isUpper ? r.toUpperCase() : r;
      }
    }
    _found = false;
    return s;
  }
}

class _Template {
  _Template(this.key, this.value)
      : regex = RegExp(
            '^${key.split('{}').map(RegExp.escape).join('(.+?)')}\$',
            caseSensitive: false,
            dotAll: true);

  final String key;
  final String value;
  final RegExp regex;

  int get literalLength => key.replaceAll('{}', '').length;

  String? apply(String s, String Function(String) tr) {
    final match = regex.firstMatch(s);
    if (match == null) return null;
    var i = 1;
    return value.replaceAllMapped('{}', (_) {
      final g = i <= match.groupCount ? match.group(i++) ?? '' : '';
      return tr(g);
    });
  }
}

extension TrString on String {
  /// Oversatt tekst (norsk er kilden).
  String get tr => L10n.tr(this);
}

/// Ligger over appen og får alle [Text] til å bygges på nytt når språket byttes.
class L10nScope extends m.InheritedWidget {
  const L10nScope({super.key, required this.lang, required super.child});

  final String lang;

  @override
  bool updateShouldNotify(L10nScope old) => old.lang != lang;
}

/// Erstatter Flutters [m.Text]: samme parametere, men teksten oversettes automatisk.
class Text extends m.StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  final String data;
  final m.TextStyle? style;
  final m.StrutStyle? strutStyle;
  final m.TextAlign? textAlign;
  final m.TextDirection? textDirection;
  final bool? softWrap;
  final m.TextOverflow? overflow;
  final m.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final m.TextWidthBasis? textWidthBasis;
  final m.TextHeightBehavior? textHeightBehavior;

  @override
  m.Widget build(m.BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<L10nScope>();
    return m.Text(
      L10n.tr(data),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}
