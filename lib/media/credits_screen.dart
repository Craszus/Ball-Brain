import 'package:flutter/material.dart' hide Text;

import '../ui/credited_photo.dart';
import '../ui/football.dart';
import '../ui/theme.dart';
import 'media.dart';
import '../l10n/l10n.dart';

/// Liste over alle bilder som brukes, med fotograf og lisens.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PitchScaffold(
      title: 'Bildekreditering',
      body: FutureBuilder<List<MediaItem>>(
        future: Future.wait([loadPlayers(), loadStadiums()])
            .then((l) => [...l[0], ...l[1]]),
        builder: (context, snap) {
          final items = snap.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Bildene kommer fra Wikimedia Commons og brukes under fri lisens '
                '(CC BY, CC BY-SA, CC0 eller offentlig eiendom).',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              for (final i in items)
                Card(
                  child: ListTile(
                    title: Text(i.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('Foto: ${i.photo.author} · ${i.photo.license}'),
                    trailing:
                        const Icon(Icons.info_outline, color: AppColors.gold),
                    onTap: () => showCredit(context, i.photo),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
