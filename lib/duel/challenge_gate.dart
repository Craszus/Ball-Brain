import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/push.dart';
import '../services/cloud.dart';
import 'duel_api.dart';
import 'duel_prefs.dart';
import 'duel_screen.dart';
import 'duel_sync.dart';

/// «Du er utfordret»-dialogen: [names] er de som venter på svar fra deg.
Future<String?> showChallengeDialog(BuildContext context, List<String> names) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Du er utfordret!'),
      content: Text('${names.take(3).join(', ')} har utfordret deg til 1v1.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, 'decline'), child: const Text('Avslå')),
        TextButton(onPressed: () => Navigator.pop(ctx, 'later'), child: const Text('Senere')),
        FilledButton(onPressed: () => Navigator.pop(ctx, 'play'), child: const Text('Spill nå')),
      ],
    ),
  );
}

/// Legges rundt hovedmenyen: sjekker ved oppstart om noen har utfordret deg (dialog), og gir
/// beskjed når det skjer noe mens appen er åpen (ny utfordring, eller resultatet er klart).
class ChallengeGate extends ConsumerStatefulWidget {
  const ChallengeGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChallengeGate> createState() => _ChallengeGateState();
}

class _ChallengeGateState extends ConsumerState<ChallengeGate> {
  static bool _shownThisStart = false;

  void Function()? _unwatch;
  Timer? _debounce;
  final Set<String> _known = {}; // innkommende vi allerede har sagt fra om
  final Set<String> _announced = {}; // resultater/avslag vi allerede har sagt fra om
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    _start();
    Push.start();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _unwatch?.call();
    super.dispose();
  }

  Future<void> _start() async {
    final c = Cloud.client;
    if (c == null) return;
    await Cloud.ensureSignedIn();
    final me = c.auth.currentUser?.id;
    if (me == null || !mounted) return;
    DuelApi.setAcceptsChallenges(await readAcceptsChallenges()); // holder serveren i synk
    _unwatch = DuelApi.watchMine(me, () {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _check);
    });
    await _check();
  }

  Future<void> _check() async {
    List<DuelListItem> items;
    try {
      items = await DuelApi.myDuels();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    await recordFinished(ref, items);
    if (!mounted) return;

    final incoming = [for (final i in items) if (i.needsMyAnswer) i];
    final fresh = [for (final i in incoming) if (!_known.contains(i.id)) i];
    _known.addAll(incoming.map((i) => i.id));

    final results = [
      for (final i in items)
        if ((i.isFinished || i.isDeclined) && !_announced.contains(i.id)) i
    ];
    _announced.addAll(results.map((i) => i.id));

    if (!_primed) {
      // Første sjekk etter oppstart: dialog for ventende utfordringer, ingen banner for gammelt
      _primed = true;
      if (incoming.isNotEmpty && !_shownThisStart) {
        _shownThisStart = true;
        await _ask(incoming);
      }
      return;
    }
    if (fresh.isNotEmpty) {
      _banner('${fresh.first.opponent} har utfordret deg til 1v1.');
    } else if (results.isNotEmpty && ModalRoute.of(context)?.isCurrent != false) {
      final r = results.first;
      _banner(r.isDeclined ? '${r.opponent} avslo utfordringen.' : 'Resultatet mot ${r.opponent} er klart.');
    }
  }

  Future<void> _ask(List<DuelListItem> incoming) async {
    final choice = await showChallengeDialog(context, [for (final i in incoming) i.opponent]);
    if (!mounted) return;
    if (choice == 'play') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DuelScreen()));
    } else if (choice == 'decline') {
      for (final i in incoming) {
        await DuelApi.decline(i.id);
      }
    }
  }

  void _banner(String text) {
    final nav = Navigator.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 7),
      action: SnackBarAction(
        label: 'Se'.tr,
        onPressed: () => nav.push(MaterialPageRoute(builder: (_) => const DuelScreen())),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
