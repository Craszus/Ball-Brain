import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../services/profile.dart';
import 'avatar_view.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

enum _Filter { all, adults, kids }

/// Bla gjennom avatarene i en karusell: den midterste er valgt, og vokser mens du blar.
/// Filter for voksne/barn og en «Tilfeldig»-knapp.
class AvatarCarousel extends StatefulWidget {
  const AvatarCarousel({
    super.key,
    required this.paths,
    required this.selected,
    required this.onChanged,
    this.height = 260,
  });

  final List<String> paths;
  final String? selected;
  final ValueChanged<String> onChanged;
  final double height;

  @override
  State<AvatarCarousel> createState() => _AvatarCarouselState();
}

class _AvatarCarouselState extends State<AvatarCarousel> {
  _Filter _filter = _Filter.all;
  late PageController _ctrl;
  double _page = 0;
  static const _loops = 1000; // «uendelig» karusell: starter midt i en lang liste

  static int _number(String path) =>
      int.tryParse(RegExp(r'avatar_(\d+)').firstMatch(path)?.group(1) ?? '') ?? 0;

  List<String> get _items => switch (_filter) {
        _Filter.all => widget.paths,
        _Filter.adults => [for (final p in widget.paths) if (_number(p) < 33) p],
        _Filter.kids => [for (final p in widget.paths) if (_number(p) >= 33) p],
      };

  @override
  void initState() {
    super.initState();
    final int i = widget.selected == null ? 0 : math.max(0, _items.indexOf(widget.selected!)).toInt();
    final int start = _items.isEmpty ? 0 : _items.length * _loops + i;
    _page = start.toDouble();
    _ctrl = PageController(viewportFraction: 0.5, initialPage: start)
      ..addListener(() => setState(() => _page = _ctrl.page ?? _page));
    if (widget.selected == null && _items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_items[0]);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setFilter(_Filter f) {
    setState(() => _filter = f);
    _page = _items.isEmpty ? 0 : (_items.length * _loops).toDouble();
    _ctrl.jumpToPage(_page.toInt());
    if (_items.isNotEmpty) widget.onChanged(_items[0]);
  }

  void _shuffle() {
    final items = _items;
    if (items.length < 2) return;
    final target = (_ctrl.page ?? _page).round() +
        items.length +
        1 +
        math.Random().nextInt(items.length);
    _ctrl.animateToPage(target,
        duration: const Duration(milliseconds: 650), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final int n = items.length;
    if (n == 0) return const SizedBox.shrink();
    final int pageNow = _page.round();
    final int current = n == 0 ? 0 : pageNow % n;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final (f, label) in const [
              (_Filter.all, 'Alle'),
              (_Filter.adults, 'Voksne'),
              (_Filter.kids, 'Barn'),
            ])
              ChoiceChip(
                label: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _filter == f ? AppColors.ink : Colors.white)),
                selected: _filter == f,
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.card,
                showCheckmark: false,
                side: BorderSide(
                    color: _filter == f
                        ? AppColors.goldLighter
                        : AppColors.gold.withValues(alpha: 0.4)),
                onSelected: (_) => _setFilter(f),
              ),
          ],
        ),
        SizedBox(
          height: widget.height,
          child: ShaderMask(
            // Toner avatarene ut mot kantene, så de ser ut til å komme fra intet
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              colors: [
                Color(0x00FFFFFF),
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [0.0, 0.25, 0.75, 1.0],
            ).createShader(r),
            child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => widget.onChanged(items[i % n]),
            itemBuilder: (context, i) {
              final d = (_page - i).abs().clamp(0.0, 1.0);
              final scale = 1.0 - 0.38 * d;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _ctrl.animateToPage(i,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut),
                child: Center(
                  child: Opacity(
                    opacity: 1.0 - 0.3 * d,
                    child: AvatarView(
                      const Avatar().withArt(items[i % n]),
                      size: widget.height * 0.86 * scale,
                    ),
                  ),
                ),
              );
            },
          ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Forrige'.tr,
              onPressed: n > 1
                  ? () => _ctrl.animateToPage(pageNow - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut)
                  : null,
              icon: const Icon(Icons.chevron_left, color: AppColors.gold, size: 34),
            ),
            Text('${current + 1} / $n',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            IconButton(
              tooltip: 'Neste'.tr,
              onPressed: n > 1
                  ? () => _ctrl.animateToPage(pageNow + 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut)
                  : null,
              icon: const Icon(Icons.chevron_right, color: AppColors.gold, size: 34),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _shuffle,
              icon: const Icon(Icons.casino_outlined, size: 20),
              label: const Text('Tilfeldig'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
