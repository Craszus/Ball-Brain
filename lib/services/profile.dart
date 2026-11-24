import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud.dart';

const skinTones = <Color>[
  Color(0xFFFAD9C1),
  Color(0xFFF1C27D),
  Color(0xFFD9A066),
  Color(0xFFB57A4B),
  Color(0xFF8A5A3A),
  Color(0xFF5B3A26),
];

const hairColors = <Color>[
  Color(0xFF1A1411),
  Color(0xFF5A3825),
  Color(0xFFB5651D),
  Color(0xFFE6C068),
  Color(0xFFC0392B),
  Color(0xFF9AA5AD),
];

const hairStyleNames = ['Kort', 'Langt', 'Snauet', 'Krøll', 'Hanekam'];
const patternNames = ['Ensfarget', 'Striper', 'Ringer', 'Halvdelt'];

class Kit {
  const Kit(this.name, this.primary, this.secondary);
  final String name;
  final Color primary;
  final Color secondary;
}

const kits = <Kit>[
  Kit('Rød', Color(0xFFD62828), Color(0xFFFFFFFF)),
  Kit('Blå', Color(0xFF1D4ED8), Color(0xFFFFFFFF)),
  Kit('Grønn', Color(0xFF15803D), Color(0xFFFFFFFF)),
  Kit('Svart', Color(0xFF1F2937), Color(0xFFF5B301)),
  Kit('Gul', Color(0xFFF5B301), Color(0xFF1D4ED8)),
  Kit('Hvit', Color(0xFFF3F4F6), Color(0xFFD62828)),
  Kit('Lilla', Color(0xFF6D28D9), Color(0xFFFFFFFF)),
  Kit('Himmelblå', Color(0xFF38BDF8), Color(0xFFFFFFFF)),
];

const countries = <(String, String)>[
  ('NO', 'Norge'),
  ('SE', 'Sverige'),
  ('DK', 'Danmark'),
  ('FI', 'Finland'),
  ('GB', 'Storbritannia'),
  ('DE', 'Tyskland'),
  ('ES', 'Spania'),
  ('IT', 'Italia'),
  ('FR', 'Frankrike'),
  ('NL', 'Nederland'),
  ('PT', 'Portugal'),
  ('BR', 'Brasil'),
  ('AR', 'Argentina'),
  ('US', 'USA'),
  ('AT', 'Østerrike'),
  ('CH', 'Sveits'),
  ('BE', 'Belgia'),
  ('IE', 'Irland'),
  ('MX', 'Mexico'),
  ('CA', 'Canada'),
  ('AU', 'Australia'),
  ('CO', 'Colombia'),
  ('CL', 'Chile'),
];

String countryName(String code) =>
    countries.firstWhere((c) => c.$1 == code, orElse: () => (code, code)).$2;

class Avatar {
  const Avatar({
    this.skin = 1,
    this.hairStyle = 0,
    this.hairColor = 1,
    this.kit = 0,
    this.pattern = 1,
    this.number = 10,
    this.art,
  });

  /// Sti til ferdig avatarbilde (assets/avatars/avatar_NN.png). Null = tegnet avatar.
  final String? art;

  final int skin;
  final int hairStyle;
  final int hairColor;
  final int kit;
  final int pattern;
  final int number;

  bool sameLook(Avatar o) =>
      skin == o.skin &&
      hairStyle == o.hairStyle &&
      hairColor == o.hairColor &&
      kit == o.kit &&
      pattern == o.pattern &&
      number == o.number &&
      art == o.art;

  Avatar withArt(String? path) => Avatar(
        skin: skin,
        hairStyle: hairStyle,
        hairColor: hairColor,
        kit: kit,
        pattern: pattern,
        number: number,
        art: path,
      );

  Avatar copyWith({
    int? skin,
    int? hairStyle,
    int? hairColor,
    int? kit,
    int? pattern,
    int? number,
  }) =>
      Avatar(
        skin: skin ?? this.skin,
        hairStyle: hairStyle ?? this.hairStyle,
        hairColor: hairColor ?? this.hairColor,
        kit: kit ?? this.kit,
        pattern: pattern ?? this.pattern,
        number: number ?? this.number,
        art: art,
      );
}

/// Seks ferdige avatarer til «Velg din avatar»: ulik hudfarge, hår og draktfarge.
const presetAvatars = <Avatar>[
  Avatar(skin: 5, hairStyle: 0, hairColor: 0, kit: 1, pattern: 0, number: 9),
  Avatar(skin: 1, hairStyle: 1, hairColor: 0, kit: 0, pattern: 0, number: 7),
  Avatar(skin: 0, hairStyle: 0, hairColor: 3, kit: 4, pattern: 0, number: 10),
  Avatar(skin: 4, hairStyle: 3, hairColor: 1, kit: 2, pattern: 0, number: 11),
  Avatar(skin: 3, hairStyle: 2, hairColor: 0, kit: 3, pattern: 0, number: 5),
  Avatar(skin: 0, hairStyle: 1, hairColor: 4, kit: 5, pattern: 0, number: 8),
];

class Profile {
  const Profile({
    this.name = 'Spiller',
    this.country = 'NO',
    this.avatar = const Avatar(),
    this.saved = false,
  });

  /// Sann når spilleren har valgt avatar og navn (profilen er lagret).
  final bool saved;
  final String name;
  final String country; // ISO-3166 alfa-2, passer til profiles.country_code
  final Avatar avatar;

  Profile copyWith({String? name, String? country, Avatar? avatar, bool? saved}) =>
      Profile(
        name: name ?? this.name,
        country: country ?? this.country,
        avatar: avatar ?? this.avatar,
        saved: saved ?? this.saved,
      );

  /// 3–16 tegn: bokstaver (inkl. æøå), tall, punktum, understrek, bindestrek.
  static final _nameRe = RegExp(r'^[\p{L}0-9._-]{3,16}$', unicode: true);
  static bool isValidName(String n) => _nameRe.hasMatch(n);
}

class ProfileController extends Notifier<Profile> {
  /// Settes i main() før appen starter, så første bilde har riktig profil og språk.
  static Profile? preloaded;

  @override
  Profile build() {
    final pre = preloaded;
    if (pre == null) Future.microtask(_load);
    return pre ?? const Profile();
  }

  static int _clamp(int? v, int max, int fallback) =>
      (v == null || v < 0 || v >= max) ? fallback : v;

  /// Leser profilen fra lagrede innstillinger.
  static Profile fromPrefs(SharedPreferences p) {
    const d = Avatar();
    return Profile(
      saved: p.getBool('profile.onboarded') ?? false,
      name: p.getString('profile.name') ?? 'Spiller',
      country: p.getString('profile.country') ?? 'NO',
      avatar: Avatar(
        skin: _clamp(p.getInt('avatar.skin'), skinTones.length, d.skin),
        hairStyle:
            _clamp(p.getInt('avatar.hairStyle'), hairStyleNames.length, d.hairStyle),
        hairColor:
            _clamp(p.getInt('avatar.hairColor'), hairColors.length, d.hairColor),
        kit: _clamp(p.getInt('avatar.kit'), kits.length, d.kit),
        pattern: _clamp(p.getInt('avatar.pattern'), patternNames.length, d.pattern),
        number: p.getInt('avatar.number')?.clamp(1, 99) ?? d.number,
        art: p.getString('avatar.art'),
      ),
    );
  }

  Future<void> _load() async {
    try {
      state = fromPrefs(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  /// Sletter profilen og alle lokale data (profil, avatar, innstillinger, statistikk).
  Future<void> deleteAll() async {
    await Cloud.deleteMyData();
    preloaded = null;
    state = const Profile();
    try {
      final p = await SharedPreferences.getInstance();
      await p.clear();
    } catch (_) {}
  }

  Future<void> save(Profile input) async {
    final profile = input.copyWith(saved: true);
    state = profile;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('profile.onboarded', true);
      await p.setString('profile.name', profile.name);
      await p.setString('profile.country', profile.country);
      final a = profile.avatar;
      await p.setInt('avatar.skin', a.skin);
      await p.setInt('avatar.hairStyle', a.hairStyle);
      await p.setInt('avatar.hairColor', a.hairColor);
      await p.setInt('avatar.kit', a.kit);
      await p.setInt('avatar.pattern', a.pattern);
      await p.setInt('avatar.number', a.number);
      if (a.art == null) {
        await p.remove('avatar.art');
      } else {
        await p.setString('avatar.art', a.art!);
      }
    } catch (_) {}
    Cloud.syncProfile(profile); // best effort, venter ikke på nettet
  }
}

final profileProvider =
    NotifierProvider<ProfileController, Profile>(ProfileController.new);
