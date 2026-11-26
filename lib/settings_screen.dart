import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'avatar_picker_screen.dart';
import 'duel/duel_prefs.dart';
import 'legal_screens.dart';
import 'media/credits_screen.dart';
import 'pro/pro_screen.dart';
import 'services/ads.dart';
import 'services/learning.dart';
import 'services/pro.dart';
import 'services/push.dart';
import 'services/feedback.dart';
import 'services/update_check.dart';
import 'share_screen.dart';
import 'update_prompt.dart';
import 'services/language.dart';
import 'services/profile.dart';
import 'services/settings.dart';
import 'services/stats.dart';
import 'ui/football.dart';
import 'ui/theme.dart';
import 'l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return PitchScaffold(
      title: 'Innstillinger',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _group('Lyd og vibrasjon', [
            SwitchListTile(
              secondary: const Icon(Icons.volume_up),
              title: const Text('Lydeffekter'),
              subtitle: const Text('Lyd ved riktig og feil svar'),
              value: s.sound,
              onChanged: (v) async {
                await ctrl.update(s.copyWith(sound: v));
                if (v) ref.read(feedbackProvider).play(Effect.correct);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibrasjon'),
              subtitle: const Text('Kort vibrasjon på svar'),
              value: s.haptics,
              onChanged: (v) => ctrl.update(s.copyWith(haptics: v)),
            ),
          ]),
          _group('Varsler og kamper', [
            const _PushSwitch(),
            SwitchListTile(
              secondary: const Icon(Icons.sports_mma),
              title: const Text('Ta imot 1v1-utfordringer'),
              subtitle: const Text('Folk i klubbene dine kan utfordre deg'),
              value: ref.watch(acceptsChallengesProvider),
              onChanged: (v) => ref.read(acceptsChallengesProvider.notifier).set(v),
            ),
          ]),
          _group('Språk', [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Språk'),
              subtitle: Text(ref.watch(languageProvider) == null
                  ? '${'Automatisk (etter land)'.tr} · ${L10n.nativeNames[ref.watch(effectiveLangProvider)]}'
                  : L10n.nativeNames[ref.watch(languageProvider)]!),
              onTap: () => _pickLanguage(context, ref),
            ),
          ]),
          if (proMode != 'off' || adMode != 'off') ...[
            const _Heading('Pro og annonser'),
            const ProSwitch(),
            if (adMode != 'off' && !ref.watch(proProvider).active)
              const Card(child: _AdSwitch()),
          ],
          _group('Om appen', [
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Del appen'),
              subtitle: const Text('Vis en QR-kode vennene kan skanne'),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ShareScreen())),
            ),
            FutureBuilder<String?>(
              future: installedVersionLabel(),
              builder: (context, snap) => ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('Se etter oppdatering'),
                subtitle: Text(snap.data == null
                    ? 'Sjekker om det finnes en ny versjon'
                    : '${'Versjon'.tr} ${snap.data}'),
                onTap: () => _checkUpdate(context),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Bildekreditering'),
              subtitle: const Text('Fotografer og lisenser for bildene i appen'),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
            ),
          ]),
          _group('Personvern og vilkår', [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Personvern'),
              subtitle: const Text('Hva vi lagrer og dine rettigheter'),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Vilkår'),
              subtitle: const Text('Regler for bruk av Ball Brain'),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const TermsScreen())),
            ),
          ]),
          // det mest ødeleggende står nederst
          _group('Nullstill og slett', [
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
              title: const Text('Nullstill fremgang'),
              subtitle: const Text('Sletter XP, rekorder og troféer på denne enheten'),
              onTap: () => _confirmReset(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Slett all min data'),
              subtitle: const Text('Fjerner profil, avatar, poeng og troféer fra denne enheten'),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
          ]),
        ],
      ),
    );
  }

  /// En overskrift med et kort under, delt med streker.
  Widget _group(String title, List<Widget> tiles) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(title),
          Card(
            child: Column(children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                tiles[i],
              ],
            ]),
          ),
        ],
      );

  Future<void> _checkUpdate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final update = await checkForUpdate(force: true);
    if (!context.mounted) return;
    if (update == null) {
      messenger.showSnackBar(SnackBar(content: Text('Du har den nyeste versjonen.')));
    } else {
      await showUpdateDialog(context, update);
    }
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(languageProvider);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            RadioGroup<String>(
              groupValue: current ?? 'auto',
              onChanged: (v) => Navigator.pop(ctx, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'auto',
                    title: const Text('Automatisk (etter land)'),
                  ),
                  for (final c in L10n.supported)
                    RadioListTile<String>(
                      value: c,
                      title: m.Text(L10n.nativeNames[c]!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await ref
        .read(languageProvider.notifier)
        .choose(picked == 'auto' ? null : picked);
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slette all data?'),
        content: const Text(
            'Profil, avatar, innstillinger, poeng, XP og troféer slettes fra '
            'denne enheten. Dette kan ikke angres, og du starter på nytt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Avbryt')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Slett alt',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(profileProvider.notifier).deleteAll();
    await ref.read(statsProvider.notifier).reset();
    await ref.read(learningProvider.notifier).reset();
    ref.invalidate(proProvider);
    await ref.read(settingsProvider.notifier).update(const Settings());
    // update() skrev innstillingene på nytt; fjern dem igjen så ingenting ligger igjen
    await ref.read(profileProvider.notifier).deleteAll();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => const AvatarPickerScreen(onboarding: true)),
      (_) => false,
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nullstille fremgang?'),
        content: const Text(
            'Alle poeng, XP, rekorder og troféer på denne enheten slettes. '
            'Dette kan ikke angres. Profil og avatar beholdes.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Avbryt')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Nullstill',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(statsProvider.notifier).reset();
      await ref.read(learningProvider.notifier).reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Fremgangen er nullstilt')));
      }
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Text(title.tr.toUpperCase(),
            style: const TextStyle(
                letterSpacing: 2,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.gold)),
      );
}

class _AdSwitch extends StatefulWidget {
  const _AdSwitch();

  @override
  State<_AdSwitch> createState() => _AdSwitchState();
}

class _AdSwitchState extends State<_AdSwitch> {
  bool _on = true;

  @override
  void initState() {
    super.initState();
    Ads.consent().then((v) {
      if (mounted) setState(() => _on = v != 'no');
    });
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: const Icon(Icons.campaign_outlined),
        title: const Text('Annonser'),
        subtitle: const Text('Frivillige annonser som gir bonus (test)'),
        value: _on,
        onChanged: (v) {
          setState(() => _on = v);
          Ads.setConsent(v);
        },
      );
}

class _PushSwitch extends StatefulWidget {
  const _PushSwitch();

  @override
  State<_PushSwitch> createState() => _PushSwitchState();
}

class _PushSwitchState extends State<_PushSwitch> {
  bool _on = true;

  @override
  void initState() {
    super.initState();
    Push.isEnabled().then((v) {
      if (mounted) setState(() => _on = v);
    });
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: const Icon(Icons.notifications_outlined),
        title: const Text('Varsler'),
        subtitle: const Text('Utfordringer og klubbkamper'),
        value: _on,
        onChanged: (v) {
          setState(() => _on = v);
          Push.setEnabled(v);
        },
      );
}
