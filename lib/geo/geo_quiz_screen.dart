import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../profile_screen.dart' show ResultPanel, ScoreChipText;
import '../services/cloud.dart';
import '../services/feedback.dart';
import '../services/scoring.dart';
import '../services/seen_history.dart';
import '../services/stats.dart';
import '../ui/football.dart';
import '../ui/icon_tile.dart';
import '../ui/tablet.dart';
import '../ui/theme.dart';
import 'geo_logic.dart';
import 'map_widgets.dart';
import 'world_map.dart';
import '../l10n/l10n.dart';

/// Sekunder per spørsmål. Klokka går også mens spilleren zoomer og drar i kartet.
const geoSecondsPerQuestion = 60;
const geoQuestions = 10;
const _maxZoom = 9.0; // innebygd kart: nok til å se byer og regioner, ikke gater

enum _Phase { loading, guess, result, finished }

class GeoQuizScreen extends ConsumerStatefulWidget {
  const GeoQuizScreen({super.key, this.kind});

  /// 'club', 'stadium' eller null (alle).
  final String? kind;

  @override
  ConsumerState<GeoQuizScreen> createState() => _GeoQuizScreenState();
}

class _GeoQuizScreenState extends ConsumerState<GeoQuizScreen>
    with SingleTickerProviderStateMixin {
  final _map = MapController();
  final _mapKey = GlobalKey();
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  VoidCallback? _animListener;

  List<GeoPlace> _places = [];
  int _index = 0;
  int _totalXp = 0;
  final _guesses = <Map<String, Object?>>[];
  _Phase _phase = _Phase.loading;

  LatLng? _pin;
  int _remaining = geoSecondsPerQuestion;
  Timer? _clock;

  double? _distance;
  int _lastXp = 0;
  bool _timedOut = false;

  WorldMapData _world = WorldMapData.empty;
  double _minZoom = 0.6;
  bool _zoomedIn = false;

  Timer? _tapTimer;
  DateTime? _lastTap;

  GeoPlace get _place => _places[_index];

  @override
  void initState() {
    super.initState();
    _load();
    loadWorldMap().then((b) {
      if (mounted) setState(() => _world = b);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _tapTimer?.cancel();
    _anim.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var all = await loadGeoPlaces();
    if (widget.kind != null) {
      all = all.where((p) => p.kind == widget.kind).toList();
    }
    // Steder som ikke er spurt om før kommer først (huskes lokalt mellom rundene).
    final picked = await ref
        .read(seenHistoryProvider)
        .pick('geo', all, geoQuestions, (p) => p.id);
    if (!mounted) return;
    setState(() {
      _places = picked;
      _index = 0;
      _totalXp = 0;
      _guesses.clear();
    });
    _startQuestion();
  }

  void _startQuestion() {
    _clock?.cancel();
    setState(() {
      _phase = _Phase.guess;
      _pin = null;
      _distance = null;
      _timedOut = false;
      _remaining = geoSecondsPerQuestion;
    });
    // Klokka er helt uavhengig av kartet, så zoom og panorering pauser den ikke.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _Phase.guess) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _onTimeUp();
    });
    _animateTo(const LatLng(6, 10), _minZoom);
  }

  void _onTimeUp() {
    if (_pin != null) {
      _confirm(); // plasseringen som står regnes med
    } else {
      _timedOut = true;
      _finishGuess(null);
    }
  }

  void _confirm() {
    final pin = _pin;
    if (pin == null || _phase != _Phase.guess) return;
    _finishGuess(pin);
  }

  void _finishGuess(LatLng? pin) {
    _clock?.cancel();
    _tapTimer?.cancel();
    _guesses.add({'id': _place.id, 'lat': pin?.latitude, 'lon': pin?.longitude});
    final km = pin == null ? null : distanceKm(pin, _place.position);
    final xp = km == null ? Scoring.wrongPoints : geoXp(km);
    setState(() {
      _distance = km;
      _lastXp = xp;
      _totalXp += xp;
      _phase = _Phase.result;
    });
    ref.read(feedbackProvider).play(switch (xp) {
      >= 5 => Effect.geoPerfect,
      >= 3 => Effect.geoGood,
      >= 2 => Effect.geoOk,
      >= 1 => Effect.geoLow,
      _ => Effect.wrong,
    });
    _zoomToResult(pin);
  }

  void _next() {
    if (_index + 1 >= _places.length) {
      Cloud.submitGeo(List.of(_guesses));
      ref.read(statsProvider.notifier).record('geo', _totalXp, max: geoQuestions * 5).then((up) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(feedbackProvider).play(up ? Effect.levelUp : Effect.finish);
          }
        });
      });
      setState(() => _phase = _Phase.finished);
    } else {
      setState(() => _index++);
      _startQuestion();
    }
  }

  // --- Kamera -------------------------------------------------------------

  void _animateTo(LatLng center, double zoom,
      {Duration duration = const Duration(milliseconds: 600)}) {
    if (_animListener != null) {
      _anim.removeListener(_animListener!);
      _animListener = null;
    }
    late final MapCamera cam;
    try {
      cam = _map.camera;
    } catch (_) {
      return; // kartet er ikke bygget ennå
    }
    final startLat = cam.center.latitude;
    final startLng = cam.center.longitude;
    final startZoom = cam.zoom;
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);
    void listener() {
      final t = curve.value;
      _map.move(
        LatLng(startLat + (center.latitude - startLat) * t,
            startLng + (center.longitude - startLng) * t),
        startZoom + (zoom - startZoom) * t,
      );
    }

    _animListener = listener;
    _anim
      ..duration = duration
      ..addListener(listener)
      ..forward(from: 0);
  }

  void _zoomBy(double delta) {
    final cam = _map.camera;
    final target = (cam.zoom + delta).clamp(_minZoom, _maxZoom);
    _animateTo(cam.center, target, duration: const Duration(milliseconds: 250));
  }

  void _zoomToResult(LatLng? pin) {
    final correct = _place.position;
    if (pin == null) {
      _animateTo(correct, 5, duration: const Duration(milliseconds: 900));
      return;
    }
    final fit = CameraFit.coordinates(
      coordinates: [pin, correct],
      padding: const EdgeInsets.fromLTRB(70, 110, 70, 70),
      maxZoom: 15,
      minZoom: _minZoom,
    ).fit(_map.camera);
    _animateTo(fit.center, fit.zoom, duration: const Duration(milliseconds: 900));
  }

  // --- Trykk på kartet: ett trykk = nål, to trykk = zoom (ingen nål) ---------

  void _onMapTap(LatLng point) {
    if (_phase != _Phase.guess) return;
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 320)) {
      _tapTimer?.cancel();
      _lastTap = null; // dobbelttrykk: kartet zoomer, nålen røres ikke
      return;
    }
    _lastTap = now;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _phase == _Phase.guess) setState(() => _pin = point);
    });
  }

  // --- Bygging ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.loading) {
      return const PitchScaffold(
          title: 'Geografi-quiz',
          body: Center(child: CircularProgressIndicator()));
    }
    if (_phase == _Phase.finished) {
      return PitchScaffold(
        title: 'Geografi-quiz',
        body: ResultPanel(
          score: _totalXp,
          note: '$geoQuestions plasseringer fullført.',
          onAgain: _load,
        ),
      );
    }

    final guessing = _phase == _Phase.guess;
    return PitchScaffold(
      title: '${_index + 1}/${_places.length}',
      wide: true, // kartet får hele bredden
      actions: [_TimerPill(seconds: _remaining, urgent: _remaining <= 10 && guessing)],
      body: Column(
        children: [
          if (guessing) CenteredContent(child: _QuestionCard(place: _place)),
          Expanded(key: _mapKey, child: _buildMap()),
          CenteredContent(child: guessing ? _guessFooter() : _resultCard()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(builder: (context, c) {
      // Minste zoom = hele verden i bredden
      _minZoom = math.max(0.0, math.log(c.maxWidth / 256) / math.ln2);
      final result = _phase == _Phase.result;
      final correct = _place.position;
      final user = _pin;

      return ClipRRect(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: const LatLng(6, 10),
                initialZoom: _minZoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                backgroundColor: const Color(0xFF061A13),
                cameraConstraint: CameraConstraint.containCenter(
                    bounds: LatLngBounds(const LatLng(-85, -180), const LatLng(85, 180))),
                interactionOptions: const InteractionOptions(
                  // Dra = panorering, knip = zoom, dobbelttrykk = zoom inn. Ingen rotasjon.
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.pinchMove |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.scrollWheelZoom,
                ),
                onTap: (_, point) => _onMapTap(point),
                onPositionChanged: (camera, _) {
                  final zoomed = camera.zoom > _minZoom + 0.6;
                  if (zoomed != _zoomedIn) setState(() => _zoomedIn = zoomed);
                },
              ),
              children: [
                // Eget mørkt verdenskart (Natural Earth, fritt): land + gull grenser.
                WorldMapLayer(data: _world),
                if (result && user != null) ..._resultOverlays(user, correct),
                MarkerLayer(markers: [
                  if (user != null)
                    Marker(
                      point: user,
                      width: MapPin.width,
                      height: MapPin.height,
                      alignment: Alignment.topCenter,
                      child: MapPin(
                          color: AppColors.gold, label: result ? 'Deg' : null),
                    ),
                  if (result)
                    Marker(
                      point: correct,
                      width: MapPin.width,
                      height: MapPin.height,
                      alignment: Alignment.topCenter,
                      child: const MapPin(color: AppColors.grass, label: 'Riktig'),
                    ),
                ]),
              ],
            ),
            // +/- nederst midt
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MapButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom ut'.tr,
                      onTap: () => _zoomBy(-1)),
                  const SizedBox(width: 14),
                  MapButton(
                      icon: Icons.add, tooltip: 'Zoom inn'.tr, onTap: () => _zoomBy(1)),
                ],
              ),
            ),
            // Vis hele verden
            if (_zoomedIn)
              Positioned(
                left: 12,
                top: 12,
                child: Material(
                  color: AppColors.card,
                  shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.gold, width: 1.5)),
                  elevation: 6,
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => _animateTo(const LatLng(6, 10), _minZoom,
                        duration: const Duration(milliseconds: 700)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.public, color: AppColors.gold, size: 22),
                        SizedBox(width: 8),
                        Text('Vis hele verden',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  List<Widget> _resultOverlays(LatLng user, LatLng correct) {
    final km = _distance ?? 0;
    return [
      PolylineLayer(polylines: [
        Polyline(
          points: [user, correct],
          strokeWidth: 3,
          color: AppColors.goldLighter,
          pattern: StrokePattern.dashed(segments: const [10, 8]),
        ),
        if (km > 0.01)
          Polyline(
            points: circlePoints(correct, km),
            strokeWidth: 3,
            color: AppColors.grass,
            pattern: StrokePattern.dashed(segments: const [12, 9]),
          ),
      ]),
    ];
  }

  Widget _guessFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: FilledButton(
        onPressed: _pin == null ? null : _confirm,
        child: const Text('Bekreft plassering'),
      ),
    );
  }

  Widget _resultCard() {
    final km = _distance;
    final headline = km == null
        ? (_timedOut ? 'Tiden gikk ut!' : 'Ingen plassering')
        : 'Du var ${formatDistance(km)} unna!';
    final last = _index + 1 >= _places.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gold),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Riktig svar: ${_place.answerLabel}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ScoreChipText('${signed(_lastXp)} XP'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: _next,
              child: Text(last ? 'Se resultat' : 'Neste spørsmål')),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.place});
  final GeoPlace place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Klubblogoer er varemerker/opphavsrettsbeskyttet: vi viser hele navnet som tekst.
              const IconTile(size: 56, child: Icon(Icons.place_outlined, size: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(place.kindLabel.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold)),
                    const SizedBox(height: 2),
                    Text(place.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900, height: 1.2)),
                    if (place.kind == 'club')
                      Text('Hjemmebane: ${place.stadium}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.seconds, required this.urgent});
  final int seconds;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final s = math.max(0, seconds);
    final text =
        '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    final color = urgent ? Colors.redAccent : AppColors.gold;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tile,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_outlined, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ),
    );
  }
}
