import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../media/media.dart';
import '../ui/credited_photo.dart';
import '../ui/football.dart';
import '../ui/theme.dart';
import 'comics.dart';

export 'comics.dart';

/// Hele tegneserien på én side. Rutene smeller inn etter tur; trykk på en for å se den stor.
class ComicScreen extends StatefulWidget {
  const ComicScreen({super.key, this.comic = maradona86, this.title = 'Store øyeblikk'});

  final Comic comic;
  final String title;

  @override
  State<ComicScreen> createState() => _ComicScreenState();
}

class _ComicScreenState extends State<ComicScreen> with SingleTickerProviderStateMixin {
  /// Tiden hver rute får før den neste kommer.
  static const _each = 900;

  late final _clock = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _each * widget.comic.panels.length + 700))
    ..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in widget.comic.panels) {
      precacheImage(AssetImage(p.image), context);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// Hvor langt rute [i] har kommet (0–1).
  double _of(int i) {
    final ms = _clock.value * _clock.duration!.inMilliseconds - i * _each;
    return (ms / 1500).clamp(0.0, 1.0);
  }

  void _open(int index) => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          ComicViewer(panels: widget.comic.panels, title: widget.title, start: index)));

  /// Én rute i stripen: fortellerfeltet øverst og tegningen under, i samme ramme.
  Widget _cell(int i) {
    final panel = widget.comic.panels[i];
    final t = _of(i);
    return Opacity(
      opacity: t == 0 ? 0 : 1,
      child: GestureDetector(
        onTap: () => _open(i),
        child: Container(
          foregroundDecoration:
              BoxDecoration(border: Border.all(color: AppColors.ink, width: 2.5)),
          padding: const EdgeInsets.all(2.5),
          color: AppColors.ink,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // lik høyde, så radene står på linje
              Container(
                height: _band,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE27A),
                  border: Border(bottom: BorderSide(color: AppColors.ink, width: 2)),
                ),
                alignment: Alignment.center,
                child: LayoutBuilder(
                  builder: (_, c) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: c.maxWidth,
                      child: Text(panel.caption ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 10.5,
                              height: 1.15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
              AspectRatio(aspectRatio: 1, child: ComicPicture(panel, t, small: true)),
            ],
          ),
        ),
      ),
    );
  }

  static const _band = 40.0;

  @override
  Widget build(BuildContext context) => PitchScaffold(
        title: widget.title,
        // liggende (og nettbrett på tvers): hele stripen på én rad
        wide: true,
        body: LayoutBuilder(builder: (context, c) {
          const gap = 7.0, paper = 9.0, header = 34.0, margin = 10.0;
          final footer = widget.comic.player == null ? 40.0 : 90.0;
          final columns = c.maxWidth > c.maxHeight ? widget.comic.panels.length : 2;
          final rows = (widget.comic.panels.length / columns).ceil();
          final byWidth =
              (c.maxWidth - 2 * margin - 2 * paper - (columns - 1) * gap) / columns;
          final byHeight = (c.maxHeight - footer - header - 2 * paper - (rows - 1) * gap) / rows -
              _band -
              5;
          final side = math.max(110.0, math.min(math.min(byWidth, byHeight), 360.0));
          final width = columns * side + (columns - 1) * gap;
          return Center(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _clock,
                builder: (_, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // avisstripa: kremhvitt papir med overskrift og tynne mellomrom
                    Container(
                      padding: const EdgeInsets.all(paper),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6EFDC),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
                      ),
                      child: SizedBox(
                        width: width,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                            height: header,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(widget.comic.header,
                                  style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 22,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                          Wrap(spacing: gap, runSpacing: gap, children: [
                            for (var i = 0; i < widget.comic.panels.length; i++)
                              SizedBox(width: side, child: _cell(i)),
                          ]),
                        ]),
                      ),
                    ),
                    if (widget.comic.player != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                          onPressed: () => showRealPlayer(context, widget.comic.player!),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Se den virkelige spilleren'),
                        ),
                      ),
                    SizedBox(
                      height: 40,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Flexible(
                          child: Text('Trykk på en rute for å se den stor',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          tooltip: 'Se igjen'.tr,
                          onPressed: () => _clock.forward(from: 0),
                          icon: const Icon(Icons.replay, color: AppColors.gold),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
}

/// Et ekte bilde av spilleren, med fotograf og lisens bak ⓘ-knappen.
Future<void> showRealPlayer(BuildContext context, String name) async {
  final found = (await loadPlayers()).where((p) => p.name == name);
  if (found.isEmpty || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            // bildefilen er kvadratisk: vis hele, ellers kuttes ansiktet
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (_, c) => CreditedPhoto(photo: found.first.photo, height: c.maxWidth),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Bildet er ikke fra øyeblikket i tegneserien.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Lukk')),
          ]),
        ),
      ),
    ),
  );
}

/// Én rute om gangen, trykk for å gå videre.
class ComicViewer extends StatefulWidget {
  const ComicViewer(
      {super.key, required this.panels, this.title = 'Store øyeblikk', this.start = 0});

  final List<ComicPanel> panels;
  final String title;
  final int start;

  @override
  State<ComicViewer> createState() => _ComicViewerState();
}

class _ComicViewerState extends State<ComicViewer> with SingleTickerProviderStateMixin {
  late int _index = widget.start;
  late final _clock =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..forward();

  bool get _last => _index == widget.panels.length - 1;

  void _go(int index) {
    setState(() => _index = index);
    _clock.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // hent bildene på forhånd, så neste rute smeller inn uten å blinke
    for (final p in widget.panels) {
      precacheImage(AssetImage(p.image), context);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = widget.panels[_index];
    return PitchScaffold(
      title: widget.title,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_last) _go(_index + 1);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (panel.caption != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE27A),
                    border: Border.all(color: AppColors.ink, width: 3),
                  ),
                  child: Text(panel.caption!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900)),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedBuilder(
                      animation: _clock,
                      builder: (_, _) => ComicPicture(panel, _clock.value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < widget.panels.length; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _index ? AppColors.gold : Colors.white24,
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              if (_last)
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => _go(0), child: const Text('Se igjen'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Ferdig'))),
                ])
              else
                SizedBox(
                  height: 48,
                  child: Center(
                    child: const Text('Trykk for neste rute',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bildet med snakkeboble og lydord. [t] er hvor langt ruten har kommet (0–1).
class ComicPicture extends StatelessWidget {
  const ComicPicture(this.panel, this.t, {super.key, this.small = false});

  final ComicPanel panel;
  final double t;

  /// Liten rute (hele serien på én side): større tekst i forhold til bildet.
  final bool small;

  double _step(double from, double to, [Curve curve = Curves.linear]) =>
      Interval(from, to, curve: curve).transform(t);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        // ruten smeller inn, og kameraet kryper sakte nærmere
        final smack = _step(0, 0.12, Curves.easeOutBack);
        final zoom = 1 + _step(0.1, 1) * 0.06;
        final talk = _step(0.14, 0.28, Curves.elasticOut);
        final boom = _step(0.18, 0.38, Curves.elasticOut);
        return Transform.rotate(
          angle: small ? 0 : (1 - smack) * -0.05,
          child: Transform.scale(
            scale: small ? 1 : 1.18 - 0.18 * smack,
            child: Container(
              decoration: BoxDecoration(
                border: small ? null : Border.all(color: AppColors.ink, width: 4),
                color: Colors.white,
              ),
              padding: EdgeInsets.all(small ? 0 : 3),
              child: Stack(fit: StackFit.expand, children: [
                ClipRect(
                  child: Transform.scale(
                    scale: zoom,
                    child: Image.asset(panel.image, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
                if (panel.bubble != null && talk > 0) _bubble(panel, w, talk),
                if (panel.sound != null && boom > 0)
                  Align(
                    alignment: FractionalOffset(panel.soundAt!.dx, panel.soundAt!.dy),
                    child: Transform.rotate(
                      angle: -0.14,
                      child: Transform.scale(scale: boom, child: _sound(panel.sound!, w)),
                    ),
                  ),
              ]),
            ),
          ),
        );
      });

  Widget _sound(String word, double w) {
    final size = w * (word.startsWith('M') ? 0.17 : 0.13);
    final style = TextStyle(
        fontSize: size, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, height: 1);
    return Stack(children: [
      Text(word,
          style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.2
                ..strokeJoin = StrokeJoin.round
                ..color = AppColors.ink)),
      Text(word, style: style.copyWith(color: const Color(0xFFFFD23F))),
    ]);
  }

  Widget _bubble(ComicPanel panel, double w, double grow) {
    final box = panel.bubbleBox!;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: _BubblePainter(box, panel.tail!, grow)),
      Positioned(
        left: box.left * w,
        top: box.top * w,
        width: box.width * w,
        height: box.height * w,
        child: Opacity(
          opacity: math.min(1, grow),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: box.width * w * 0.80,
                child: Text(panel.bubble!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: w * (small ? 0.062 : 0.048),
                        height: 1.15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.box, this.tail, this.grow);
  final Rect box;
  final Offset tail;
  final double grow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(box.left * size.width, box.top * size.height,
        box.right * size.width, box.bottom * size.height);
    final centre = rect.center;
    final tip = Offset(tail.dx * size.width, tail.dy * size.height);
    final oval = Rect.fromCenter(
        center: centre, width: rect.width * grow, height: rect.height * grow);
    final towards = (tip - centre) / (tip - centre).distance;
    final side = Offset(-towards.dy, towards.dx) * rect.height * 0.14;
    final path = Path.combine(
        PathOperation.union,
        Path()..addOval(oval),
        Path()
          ..addPolygon([centre + side, Offset.lerp(centre, tip, grow.clamp(0, 1))!, centre - side],
              true));
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.grow != grow || old.box != box;
}
