import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import 'l10n/l10n.dart';
import 'services/update_check.dart';

/// Viser dialogen «Ny versjon tilgjengelig» med «Last ned» (åpner APK-en) og «Senere».
Future<void> showUpdateDialog(BuildContext context, AppUpdate update) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ny versjon tilgjengelig'),
      content: Text('Bygg ${update.build} er klar. Last ned og installer for å oppdatere.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Senere')),
        FilledButton(
          onPressed: () {
            launchUrl(Uri.parse(update.url), mode: LaunchMode.externalApplication);
            Navigator.pop(ctx);
          },
          child: const Text('Last ned'),
        ),
      ],
    ),
  );
}

/// Legges rundt hovedmenyen: sjekker én gang ved oppstart om det finnes en ny versjon, og
/// viser da en dialog. Gjør ingenting uten nett eller utenfor Android.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  /// Sjekk bare én gang pr. oppstart, selv om hovedmenyen bygges på nytt.
  static bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (_checked) return;
    _checked = true;
    checkForUpdate().then((update) {
      if (update != null && mounted) showUpdateDialog(context, update);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
