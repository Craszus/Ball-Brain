import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Et fritt lisensiert bilde fra Wikimedia Commons (CC BY, CC BY-SA, CC0 eller offentlig eiendom).
class Photo {
  const Photo({
    required this.url,
    required this.title,
    required this.author,
    required this.license,
    required this.licenseUrl,
    required this.pageUrl,
    this.width = 0,
    this.height = 0,
    this.cx,
    this.cy,
    this.side,
    this.file,
  });

  final String url;
  final String title;
  final String author;
  final String license;
  final String licenseUrl;
  final String pageUrl;

  final int width;
  final int height;

  /// Utsnitt rundt ansiktet: senter (andel av bildet) og sidelengde (andel av bildebredden).
  final double? cx;
  final double? cy;
  final double? side;

  /// Bilde som ligger i appen (virker uten nett). Spillerbilder er allerede beskåret.
  final String? file;

  factory Photo.fromJson(Map<String, dynamic> j, {Map<String, dynamic>? crop, String? file}) =>
      Photo(
        url: j['url'] as String,
        title: (j['title'] as String).replaceAll('_', ' '),
        author: (j['author'] as String?)?.trim().isNotEmpty == true
            ? j['author'] as String
            : 'Ukjent fotograf',
        license: j['license'] as String? ?? '',
        licenseUrl: j['licenseUrl'] as String? ?? '',
        pageUrl: j['pageUrl'] as String? ?? '',
        width: (j['width'] as num?)?.toInt() ?? 0,
        height: (j['height'] as num?)?.toInt() ?? 0,
        cx: (crop?['cx'] as num?)?.toDouble(),
        cy: (crop?['cy'] as num?)?.toDouble(),
        side: (crop?['s'] as num?)?.toDouble(),
        file: file,
      );
}

enum MediaKind { player, stadium }

/// En spiller eller et stadion med bilde.
class MediaItem {
  const MediaItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.hint,
    required this.photo,
    this.nationality = '',
    this.goalkeeper = false,
    this.female = false,
    this.club = '',
    this.country = '',
  });

  final MediaKind kind;
  final bool goalkeeper;

  /// Kvinnelig spiller (svaralternativene blander ikke kvinner og menn).
  final bool female;

  /// Stadion: hjemmeklubb (eller f.eks. «Landslaget (Norge)») og land. Tomme for spillere.
  final String club;
  final String country;

  /// Stadion med én tydelig hjemmeklubb (ikke landslag, finaler eller delte stadioner).
  bool get hasClearClub =>
      club.isNotEmpty &&
      !club.startsWith('Landslaget') &&
      !club.startsWith('VM') &&
      !club.startsWith('Champions League') &&
      !club.contains(' og ');

  /// Land spilleren kommer fra (tom for stadioner).
  final String nationality;
  final String id;
  final String name;

  /// Nasjonalitet (spiller) eller klubb og land (stadion).
  final String hint;
  final Photo photo;
}

Future<List<MediaItem>> _load(String asset, MediaKind kind) async {
  try {
    final raw = await rootBundle.loadString(asset);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return [
      for (final j in list)
        if (j['photo'] != null)
          MediaItem(
            kind: kind,
            id: j['id'] as String,
            name: j['name'] as String,
            nationality: kind == MediaKind.player ? (j['nationality'] as String? ?? '') : '',
            goalkeeper: j['pos'] == 'GK',
            female: j['female'] == true,
            club: kind == MediaKind.stadium ? (j['club'] as String? ?? '') : '',
            country: kind == MediaKind.stadium ? (j['country'] as String? ?? '') : '',
            hint: kind == MediaKind.player
                ? (j['nationality'] as String? ?? '')
                : '${j['club'] ?? ''}${j['country'] != null ? ' · ${j['country']}' : ''}',
            photo: Photo.fromJson(j['photo'] as Map<String, dynamic>,
                crop: j['crop'] as Map<String, dynamic>?, file: j['file'] as String?),
          ),
    ];
  } catch (_) {
    return const [];
  }
}

Future<List<MediaItem>> loadPlayers() => _load('assets/media/players.json', MediaKind.player);
Future<List<MediaItem>> loadStadiums() => _load('assets/media/stadiums.json', MediaKind.stadium);
