import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import '../media/media.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

/// Bilde med gullkant og liten ⓘ-knapp som viser tittel, fotograf og lisens (krav ved CC-lisens).
class CreditedPhoto extends StatelessWidget {
  const CreditedPhoto({super.key, required this.photo, this.height = 260});

  final Photo photo;
  final double height;

  Widget _error() => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Kunne ikke laste bildet.\nSjekk nettforbindelsen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );

  Widget _image(double w, double h) {
    final file = photo.file;
    if (file != null) {
      return SizedBox(
        width: w,
        height: h,
        child: Image.asset(file,
            fit: BoxFit.cover,
            // Skulle filen mangle, hent bildet fra nett i stedet
            errorBuilder: (context, error, stack) => _networkImage(w, h)),
      );
    }
    return _networkImage(w, h);
  }

  Widget _networkImage(double w, double h) {
    Widget load(Widget Function(Widget) wrap, {BoxFit fit = BoxFit.cover}) =>
        wrap(Image.network(
          photo.url,
          fit: fit,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          errorBuilder: (context, error, stack) => _error(),
        ));

    final cx = photo.cx, cy = photo.cy, side = photo.side;
    if (cx == null || cy == null || side == null || photo.width == 0) {
      return load((i) => SizedBox(width: w, height: h, child: i));
    }
    // Vis nøyaktig utsnittet rundt ansiktet: skalér bildet og flytt så utsnittet fyller rammen.
    final scale = w / (side * photo.width);
    final imgW = photo.width * scale;
    final imgH = photo.height * scale;
    var left = -(cx * photo.width - side * photo.width / 2) * scale;
    var top = -(cy * photo.height - (h / scale) / 2) * scale;
    left = left.clamp(w - imgW, 0.0);
    top = top.clamp(h - imgH, 0.0);
    return load((i) => Stack(children: [
          Positioned(left: left, top: top, width: imgW, height: imgH, child: i),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.5),
        color: AppColors.tile,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(builder: (context, c) => _image(c.maxWidth, c.maxHeight)),
          Positioned(
            right: 6,
            top: 6,
            child: GestureDetector(
              onTap: () => showCredit(context, photo),
              behavior: HitTestBehavior.opaque,
              child: Tooltip(
                message: 'Bildekreditering',
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline,
                      color: Colors.white, size: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showCredit(BuildContext context, Photo p) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bildekreditering',
              style: TextStyle(
                  color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Foto: ${p.author}',
              style: const TextStyle(color: AppColors.textSecondary)),
          Text('Lisens: ${p.license}',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (p.pageUrl.isNotEmpty)
              OutlinedButton(
                  onPressed: () => _open(p.pageUrl), child: const Text('Bildesiden')),
            if (p.licenseUrl.isNotEmpty)
              OutlinedButton(
                  onPressed: () => _open(p.licenseUrl), child: const Text('Lisensen')),
          ]),
        ],
      ),
    ),
  );
}

Future<void> _open(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}
