import 'dart:convert';
import 'dart:io';

import 'package:ball_brain/geo/geo_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('XP etter avstand', () {
    test('grensene følger briefen', () {
      expect(geoXp(0), 5);
      expect(geoXp(25), 5);
      expect(geoXp(25.1), 3);
      expect(geoXp(100), 3);
      expect(geoXp(100.1), 2);
      expect(geoXp(500), 2);
      expect(geoXp(500.1), 1);
      expect(geoXp(1500), 1);
      expect(geoXp(1500.1), -1);
      expect(geoXp(15000), -1);
    });
  });

  group('avstand', () {
    test('Madrid–Barcelona er ca. 505 km', () {
      final km = distanceKm(const LatLng(40.4168, -3.7038), const LatLng(41.3874, 2.1686));
      expect(km, closeTo(505, 5));
    });

    test('samme punkt gir 0, og avstanden er symmetrisk', () {
      const a = LatLng(53.43, -2.96);
      const b = LatLng(-26.23, 27.98);
      expect(distanceKm(a, a), 0);
      expect(distanceKm(a, b), closeTo(distanceKm(b, a), 1e-9));
    });

    test('sirkelpunktene ligger riktig avstand fra sentrum', () {
      const c = LatLng(40.0, -3.0);
      for (final p in circlePoints(c, 300)) {
        expect(distanceKm(c, p), closeTo(300, 0.5));
      }
    });
  });

  group('formatering', () {
    test('meter, kilometer og tusenskille', () {
      expect(formatDistance(0.34), '340 m');
      expect(formatDistance(4.2), '4,2 km');
      expect(formatDistance(12.4), '12 km');
      expect(formatDistance(1234), '1 234 km');
    });
  });

  test('places.json er gyldig', () {
    final list = (jsonDecode(File('assets/geo/places.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    expect(list.length, greaterThanOrEqualTo(30));
    final ids = <String>{};
    for (final j in list) {
      final p = GeoPlace.fromJson(j);
      expect(ids.add(p.id), isTrue, reason: 'dobbel id ${p.id}');
      expect(p.prompt, startsWith('Hvor ligger '));
      expect(p.question, startsWith('Hvor ligger '));
      if (p.kind == 'club') expect(p.question, contains('klubben'));
      expect(p.city, isNotEmpty);
      expect(p.country, isNotEmpty);
      expect(p.position.latitude, inInclusiveRange(-90, 90));
      expect(p.position.longitude, inInclusiveRange(-180, 180));
      expect(p.answerLabel, '${p.city}, ${p.country}');
    }
    // Stikkprøve: Real Madrid skal ligge i Madrid
    final rm = list.firstWhere((j) => j['subject'] == 'Real Madrid');
    final p = GeoPlace.fromJson(rm);
    expect(p.answerLabel, 'Madrid, Spania');
    expect(distanceKm(p.position, const LatLng(40.4168, -3.7038)), lessThan(5));
  });
}
