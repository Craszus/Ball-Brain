import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'l10n/l10n.dart';
import 'ui/football.dart';
import 'ui/theme.dart';

/// Lenken QR-koden peker til. Standard er appens side i Google Play; endres ved bygging med
/// `--dart-define=APP_SHARE_URL=https://...` (f.eks. en egen nettside som velger riktig butikk).
const appShareUrl = String.fromEnvironment('APP_SHARE_URL',
    defaultValue: 'https://play.google.com/store/apps/details?id=no.ballbrain.ball_brain');

/// «Del appen»: en QR-kode vennene kan skanne, og en lenke som kan kopieres.
class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key, this.url = appShareUrl});

  final String url;

  @override
  Widget build(BuildContext context) {
    return PitchScaffold(
      title: 'Del appen',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('La en venn skanne koden for å laste ned Ball Brain.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 22),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, width: 3),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.pitch),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square, color: AppColors.pitch),
                semanticsLabel: 'QR-kode til Ball Brain'.tr,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(url,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${'Spill Ball Brain med meg!'.tr} $url'));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Kopiert')));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Kopier lenke'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ],
      ),
    );
  }
}
