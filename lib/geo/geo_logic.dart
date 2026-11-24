import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

/// Et sted i geografi-quizen (et stadion, spurt etter klubb eller stadion).
class GeoPlace {
  const GeoPlace({
    required this.id,
    required this.prompt,
    required this.kind,
    required this.subject,
    required this.badge,
    required this.stadium,
    required this.city,
    required this.country,
    required this.position,
  });

  final String id;
  final String prompt; // «Hvor ligger Real Madrid?»
  final String kind; // 'club' | 'stadium'
  final String subject;
  final String badge; // initialer til merket (vi har ikke lov til å bruke klubblogoer)
  final String stadium;
  final String city;
  final String country;
  final LatLng position;

  String get answerLabel => '$city, $country';

  /// «klubb», «stadion» eller «arena».
  String get kindLabel {
    if (kind == 'club') return 'klubb';
    final n = subject.toLowerCase();
    return n.contains('arena') ? 'arena' : 'stadion';
  }

  /// Spørsmålet med typen med: «Hvor ligger klubben Chelsea?».
  String get question {
    final art = switch (kindLabel) {
      'klubb' => 'klubben',
      'arena' => 'arenaen',
      _ => 'stadionet',
    };
    final n = subject.toLowerCase();
    if (kind != 'club' && (n.contains('stadi') || n.contains('arena'))) {
      return 'Hvor ligger $subject?'; // navnet sier allerede hva det er
    }
    return 'Hvor ligger $art $subject?';
  }

  factory GeoPlace.fromJson(Map<String, dynamic> j) => GeoPlace(
        id: j['id'] as String,
        prompt: j['prompt'] as String,
        kind: j['kind'] as String,
        subject: j['subject'] as String,
        badge: j['badge'] as String,
        stadium: j['stadium'] as String,
        city: j['city'] as String,
        country: j['country'] as String,
        position: LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()),
      );
}

Future<List<GeoPlace>> loadGeoPlaces() async {
  final raw = await rootBundle.loadString('assets/geo/places.json');
  return (jsonDecode(raw) as List)
      .cast<Map<String, dynamic>>()
      .map(GeoPlace.fromJson)
      .toList();
}

/// Storsirkelavstand i km (haversine).
double distanceKm(LatLng a, LatLng b) {
  const r = 6371.0088;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLon = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(h)));
}

/// XP etter avstand: 0–25 km = +5, 25–100 = +3, 100–500 = +2, 500–1500 = +1, over 1500 = −1 (helt feil).
int geoXp(double km) {
  if (km <= 25) return 5;
  if (km <= 100) return 3;
  if (km <= 500) return 2;
  if (km <= 1500) return 1;
  return -1;
}

/// «340 m», «4,2 km», «12 km», «1 234 km».
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  final value = km < 10 ? km.toStringAsFixed(1).replaceAll('.', ',') : km.round().toString();
  final grouped = value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  return '$grouped km';
}

/// Punkt [km] kilometer fra [from] i retning [bearingDeg] (til tegning av sirkel).
LatLng destination(LatLng from, double km, double bearingDeg) {
  const r = 6371.0088;
  final d = km / r;
  final b = bearingDeg * math.pi / 180;
  final lat1 = from.latitude * math.pi / 180;
  final lon1 = from.longitude * math.pi / 180;
  final lat2 = math.asin(math.sin(lat1) * math.cos(d) +
      math.cos(lat1) * math.sin(d) * math.cos(b));
  final lon2 = lon1 +
      math.atan2(math.sin(b) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2));
  return LatLng(lat2 * 180 / math.pi, ((lon2 * 180 / math.pi + 540) % 360) - 180);
}

/// Sirkel med radius [km] rundt [center] som en lukket punktliste.
List<LatLng> circlePoints(LatLng center, double km, {int steps = 96}) => [
      for (var i = 0; i <= steps; i++) destination(center, km, i * 360 / steps),
    ];
