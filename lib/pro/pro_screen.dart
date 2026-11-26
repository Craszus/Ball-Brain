import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pack_repository.dart';
import '../l10n/l10n.dart';
import '../quiz/quiz_controller.dart';
import '../quiz/rules_quiz_screen.dart';
import '../services/learning.dart';
import '../services/pro.dart';
import '../ui/football.dart';
import '../ui/pro_frame.dart';
import '../ui/theme.dart';

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

/// Starter en øvingsrunde (bom-trening eller spørsmålspakke).
void _practice(BuildContext context, WidgetRef ref, String selection) {
  ref.read(quizEraProvider.notifier).set(selection);
  ref.invalidate(quizControllerProvider);
  _open(context, const RulesQuizScreen());
}

/// En Pro-funksjon som rad i en meny.
Widget _proTile(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
        onTap: onTap,
      ),
    );

String _missedText(int missed) =>
    missed == 0 ? 'Du har ingen bom å øve på' : '$missed spørsmål å øve på';

/// Av/på-bryteren i Innstillinger. Skrur man på Pro, dukker innholdet opp i menyene.
class ProSwitch extends ConsumerWidget {
  const ProSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (proMode == 'off') return const SizedBox.shrink();
    final active = ref.watch(proProvider).active;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold),
      ),
      child: Column(children: [
        SwitchListTile(
          secondary: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 30),
          title: const Text('Ball Brain Pro', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: const Text('Test: ingen betaling'),
          value: active,
          onChanged: (v) => ref.read(proProvider.notifier).setActive(v),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Se hva du får med Pro'),
          trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
          onTap: () => _open(context, const ProScreen()),
        ),
      ]),
    );
  }
}

/// I Fotballquiz-menyen: verktøyene øverst når Pro er på ([whenActive]),
/// ellers én kort linje nederst om hva Pro gir.
class ProQuizTools extends ConsumerWidget {
  const ProQuizTools({super.key, required this.whenActive});

  final bool whenActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (proMode == 'off' || ref.watch(proProvider).active != whenActive) {
      return const SizedBox.shrink();
    }
    if (!whenActive) {
      return TextButton.icon(
        onPressed: () => _open(context, const ProScreen()),
        icon: const Icon(Icons.workspace_premium, color: AppColors.gold),
        label: const Text('Med Pro: tren på bommene og få spørsmålspakker',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gold)),
      );
    }
    final missed = ref.watch(learningProvider).missed.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(children: [
        _proTile(Icons.replay, 'Tren på bommene', _missedText(missed),
            () => _practice(context, ref, missedTraining)),
        _proTile(Icons.library_books, 'Spørsmålspakker', 'Champions League, Premier League og mer',
            () => _open(context, const PacksScreen())),
      ]),
    );
  }
}

/// På statistikksiden.
class ProStatsEntry extends ConsumerWidget {
  const ProStatsEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(proProvider).active) return const SizedBox.shrink();
    return _proTile(Icons.query_stats, 'Statistikk per tema', 'Hva du er god og svak på',
        () => _open(context, const TopicStatsScreen()));
  }
}

/// På profilsiden: tittel og ramme med Pro, ellers veien til Pro.
class ProProfileEntry extends ConsumerWidget {
  const ProProfileEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(proProvider).active
      ? _proTile(Icons.palette, 'Tittel og ramme', 'Vises på profilen din',
          () => _open(context, const StyleScreen()))
      : const ProButton();
}

/// Knappen som leder til Pro (skjules når Pro er slått av i bygget).
class ProButton extends ConsumerWidget {
  const ProButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (proMode == 'off') return const SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold),
      ),
      child: ListTile(
        leading: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 32),
        title: const Text('Ball Brain Pro', style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(ref.watch(proProvider).active
            ? 'Statistikk, trening og spørsmålspakker'
            : 'Se hva du får med Pro'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
        onTap: () => _open(context, const ProScreen()),
      ),
    );
  }
}

class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    return PitchScaffold(
      title: 'Ball Brain Pro',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.gold, size: 64),
          const SizedBox(height: 8),
          Text(pro.active ? 'Du har Pro' : 'Få mer ut av fotballhodet ditt',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (pro.active) ..._features(context, ref) else ..._offer(),
          const SizedBox(height: 16),
          if (pro.active)
            OutlinedButton(
                onPressed: () => ref.read(proProvider.notifier).setActive(false),
                child: const Text('Slå av Pro (test)'))
          else
            FilledButton(
                onPressed: () => ref.read(proProvider.notifier).setActive(true),
                child: const Text('Prøv Pro (test)')),
          const SizedBox(height: 8),
          const Text('Dette er en test: ingen betaling, og ingenting blir kjøpt.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  List<Widget> _offer() {
    const rows = [
      (Icons.block, 'Ingen annonser'),
      (Icons.query_stats, 'Se hva du er god og svak på, tema for tema'),
      (Icons.replay, 'Tren på spørsmålene du har bommet på'),
      (Icons.library_books, 'Ekstra spørsmålspakker'),
      (Icons.shield, 'Flere klubbskjold, avatarrammer og titler'),
    ];
    return [
      Card(
        child: Column(children: [
          for (final (icon, text) in rows)
            ListTile(leading: Icon(icon, color: AppColors.gold), title: Text(text)),
        ]),
      ),
      const SizedBox(height: 8),
      const Text('Planlagt pris: 39 kr per måned eller 249 kr per år',
          textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Pro gir aldri fordeler på rangeringene.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    ];
  }

  List<Widget> _features(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(learningProvider).missed.length;
    Widget tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
          child: ListTile(
            leading: Icon(icon, color: AppColors.gold),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
            onTap: onTap,
          ),
        );
    return [
      tile(Icons.query_stats, 'Statistikk per tema', 'Hva du er god og svak på',
          () => _open(context, const TopicStatsScreen())),
      tile(
          Icons.replay,
          'Tren på bommene',
          _missedText(missed),
          () => _practice(context, ref, missedTraining)),
      tile(Icons.library_books, 'Spørsmålspakker', 'Champions League, Premier League og mer',
          () => _open(context, const PacksScreen())),
      tile(Icons.palette, 'Tittel og ramme', 'Vises på profilen din',
          () => _open(context, const StyleScreen())),
    ];
  }
}

/// Riktige svar pr. tema, svakeste øverst.
class TopicStatsScreen extends ConsumerWidget {
  const TopicStatsScreen({super.key});

  /// Så mange svar skal til før et tema kåres til sterkest eller svakest.
  static const enough = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(learningProvider).topics.entries.toList()
      ..sort((a, b) => a.value.share.compareTo(b.value.share));
    final ranked = [for (final t in topics) if (t.value.total >= enough) t];
    return PitchScaffold(
      title: 'Statistikk per tema',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (topics.isEmpty)
            const Text('Spill noen runder med fotballquiz, så kommer statistikken her.',
                textAlign: TextAlign.center),
          if (ranked.length > 1) ...[
            Text('Sterkest: ${ranked.last.key}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Svakest: ${ranked.first.key}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
            const SizedBox(height: 12),
          ],
          for (final t in topics)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                        child: Text(t.key, style: const TextStyle(fontWeight: FontWeight.w900))),
                    Text('${(t.value.share * 100).round()} %',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: AppColors.gold)),
                  ]),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                      value: t.value.share,
                      minHeight: 8,
                      backgroundColor: Colors.black38,
                      color: AppColors.gold),
                  const SizedBox(height: 4),
                  Text('${t.value.correct} av ${t.value.total} riktige',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class PacksScreen extends ConsumerWidget {
  const PacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(packsProvider).asData?.value ?? const <QuestionPack>[];
    return PitchScaffold(
      title: 'Spørsmålspakker',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Øvingsrunder: gir ikke XP eller rangeringspoeng.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          for (final p in packs)
            Card(
              child: ListTile(
                leading: const Icon(Icons.library_books, color: AppColors.gold),
                title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(p.subtitle),
                trailing: const Icon(Icons.chevron_right, color: AppColors.gold),
                onTap: () => _practice(context, ref, '$packPrefix${p.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Velg tittel og avatarramme.
class StyleScreen extends ConsumerWidget {
  const StyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final ctrl = ref.read(proProvider.notifier);
    Widget heading(String s) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        );
    return PitchScaffold(
      title: 'Tittel og ramme',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heading('Tittel'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final t in ['', ...proTitles])
              ChoiceChip(
                label: Text(t.isEmpty ? 'Ingen' : t),
                selected: pro.title == t,
                onSelected: (_) => ctrl.setTitle(t),
              ),
          ]),
          heading('Avatarramme'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (var i = 0; i < proFrames.length; i++)
              ChoiceChip(
                avatar: i == 0
                    ? null
                    : CircleAvatar(backgroundColor: proFrames[i].$2[1]),
                label: Text(proFrames[i].$1),
                selected: pro.frame == i,
                onSelected: (_) => ctrl.setFrame(i),
              ),
          ]),
        ],
      ),
    );
  }
}
