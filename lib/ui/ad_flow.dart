import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../services/ads.dart';
import 'theme.dart';

/// Spør om samtykke første gang og viser testannonsen. Sant når den er sett ferdig.
/// En ekte annonseleverandør kobles på her, i stedet for [_TestAd].
Future<bool> showRewardedAd(BuildContext context, int xp) async {
  if (await Ads.consent() == null) {
    if (!context.mounted) return false;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vise annonser?'),
        content: const Text(
            'Du velger selv når du vil se en annonse, og får noe igjen for det. Du kan slå det av i Innstillinger.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nei takk')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ja')),
        ],
      ),
    );
    if (yes == null) return false;
    await Ads.setConsent(yes);
    if (!yes) return false;
  }
  if (!context.mounted) return false;
  final watched = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _TestAd(),
      ) ??
      false;
  if (watched) await Ads.recordWatched(xp);
  return watched;
}

class _TestAd extends StatefulWidget {
  const _TestAd();

  @override
  State<_TestAd> createState() => _TestAdState();
}

class _TestAdState extends State<_TestAd> {
  int _left = adSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Testannonse'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.campaign_outlined, size: 56, color: AppColors.gold),
          const SizedBox(height: 10),
          const Text('Her kommer annonsen. Dette er bare en test.',
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: (adSeconds - _left) / adSeconds, color: AppColors.gold),
          const SizedBox(height: 8),
          if (_left > 0) Text('$_left sek'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Avbryt')),
          FilledButton(
              onPressed: _left > 0 ? null : () => Navigator.pop(context, true),
              child: const Text('Få bonusen')),
        ],
      );
}
