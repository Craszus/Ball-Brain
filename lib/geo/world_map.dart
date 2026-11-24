import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../ui/theme.dart';

/// En ring eller linje med ferdig utregnet omkrets, slik at vi bare tegner det som er synlig.
class Shape {
  Shape(this.points) {
    var minLa = 90.0, maxLa = -90.0, minLo = 180.0, maxLo = -180.0;
    for (final p in points) {
      minLa = math.min(minLa, p.latitude);
      maxLa = math.max(maxLa, p.latitude);
      minLo = math.min(minLo, p.longitude);
      maxLo = math.max(maxLo, p.longitude);
    }
    minLat = minLa;
    maxLat = maxLa;
    minLon = minLo;
    maxLon = maxLo;
  }

  final List<LatLng> points;
  late final double minLat, maxLat, minLon, maxLon;

  bool intersects(LatLngBounds b) =>
      maxLat >= b.south &&
      minLat <= b.north &&
      maxLon >= b.west &&
      minLon <= b.east;
}

/// Innebygd verdenskart (Natural Earth, offentlig eiendom) som virker uten nett.
/// To detaljnivåer: «far» (50m, hele verden) og «near» (10m, når man zoomer inn).
/// Genereres av tools/make_world_maps.py.
class WorldMapData {
  const WorldMapData({
    required this.far,
    required this.near,
    this.lakes = const [],
    this.rivers = const [],
    this.regions = const [],
    this.cities = const [],
  });
  final List<Shape> far;
  final List<Shape> near;
  // Hjelpelag i nærkartet (uten navn, så quizen ikke røpes):
  final List<Shape> lakes;
  final List<Shape> rivers;
  final List<Shape> regions; // fylker/delstater
  final List<LatLng> cities; // byer over 1 million som prikker

  static const empty = WorldMapData(far: [], near: []);
}

List<LatLng> _points(List flat) => [
      for (var i = 0; i + 1 < flat.length; i += 2)
        LatLng((flat[i + 1] as num).toDouble(), (flat[i] as num).toDouble()),
    ];

List<Shape> _toShapes(Object? list) =>
    [for (final r in (list as List? ?? const [])) Shape(_points(r as List))];

Future<List<Shape>> _loadRings(String asset) async {
  final raw = await rootBundle.loadString(asset);
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return _toShapes(data['rings']);
}

Future<WorldMapData> loadWorldMap() async {
  try {
    final far = await _loadRings('assets/geo/world_far.json');
    final near = await _loadRings('assets/geo/world_near.json');
    var lakes = <Shape>[], rivers = <Shape>[], regions = <Shape>[];
    var cities = <LatLng>[];
    try {
      final raw = await rootBundle.loadString('assets/geo/world_extra.json');
      final d = jsonDecode(raw) as Map<String, dynamic>;
      lakes = _toShapes(d['lakes']);
      rivers = _toShapes(d['rivers']);
      regions = _toShapes(d['regions']);
      cities = _points(d['cities'] as List);
    } catch (_) {/* hjelpelagene er valgfrie */}
    return WorldMapData(
        far: far,
        near: near,
        lakes: lakes,
        rivers: rivers,
        regions: regions,
        cities: cities);
  } catch (_) {
    return WorldMapData.empty;
  }
}

/// Mørkegrønt land med gull landegrenser. Bytter til det detaljerte kartet ved zoom.
/// Tegner bare det som er synlig på skjermen (ellers blir kartet tregt når man zoomer inn).
class WorldMapLayer extends StatelessWidget {
  const WorldMapLayer({super.key, required this.data});
  final WorldMapData data;

  /// Zoomnivå der vi bytter fra verdenskartet til nærkartet.
  static const nearZoom = 3.5;

  /// Regiongrenser vises først ved denne zoomen.
  static const regionZoom = 5.0;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final zoom = camera.zoom;
    final isNear = zoom >= nearZoom;
    final all = isNear ? data.near : data.far;
    if (all.isEmpty) return const SizedBox.shrink();

    // Litt ekstra rundt skjermen så kanten ikke blinker under panorering.
    final vb = camera.visibleBounds;
    final padLat = (vb.north - vb.south) * 0.25;
    final padLon = (vb.east - vb.west) * 0.25;
    final view = LatLngBounds(
      LatLng(math.max(-90, vb.south - padLat), math.max(-180, vb.west - padLon)),
      LatLng(math.min(90, vb.north + padLat), math.min(180, vb.east + padLon)),
    );
    List<Shape> visible(List<Shape> l) =>
        isNear ? [for (final s in l) if (s.intersects(view)) s] : l;

    // Høyere forenkling = færre punkter å tegne. Strengere jo mer vi ser av kartet.
    final tol = zoom < 4 ? 0.6 : 1.0;

    return RepaintBoundary(
      child: Stack(
        children: [
          PolygonLayer(
            key: ValueKey(isNear),
            simplificationTolerance: tol,
            polygons: [
              for (final s in visible(all))
                Polygon(
                  points: s.points,
                  color: const Color(0xFF123F2E),
                  borderColor: AppColors.gold.withValues(alpha: 0.8),
                  borderStrokeWidth: 0.9,
                ),
            ],
          ),
          if (isNear) ...[
            PolygonLayer(
              simplificationTolerance: tol,
              polygons: [
                for (final s in visible(data.lakes))
                  Polygon(
                    points: s.points,
                    color: const Color(0xFF061A13),
                    borderColor: const Color(0xFF2F7F6A).withValues(alpha: 0.6),
                    borderStrokeWidth: 0.6,
                  ),
              ],
            ),
            if (zoom >= regionZoom)
              PolylineLayer(
                simplificationTolerance: tol,
                polylines: [
                  for (final s in visible(data.regions))
                    Polyline(
                      points: s.points,
                      strokeWidth: 0.6,
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                ],
              ),
            PolylineLayer(
              simplificationTolerance: tol,
              polylines: [
                for (final s in visible(data.rivers))
                  Polyline(
                    points: s.points,
                    strokeWidth: 1.0,
                    color: const Color(0xFF2F7F6A),
                  ),
              ],
            ),
            CircleLayer(circles: [
              for (final c in data.cities)
                if (view.contains(c))
                  CircleMarker(
                    point: c,
                    radius: 2.6,
                    color: AppColors.goldLighter,
                    borderColor: AppColors.pitch,
                    borderStrokeWidth: 1,
                  ),
            ]),
          ],
        ],
      ),
    );
  }
}
