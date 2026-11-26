import 'package:flutter/material.dart' hide Text;

import 'football.dart';
import 'rules_card.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

class Choice {
  const Choice(this.title, this.subtitle, this.value);
  final String title;
  final String subtitle;
  final String? value;
}

/// Velg hva du vil spille: alt, eller én ting for seg selv.
class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({
    super.key,
    required this.title,
    required this.heading,
    required this.choices,
    required this.onPick,
    this.rules = const [],
    this.before,
    this.after,
  });

  /// Ekstra innhold over og under valgene.
  final Widget? before;
  final Widget? after;

  final String title;
  final String heading;
  final List<Choice> choices;

  /// Regler og forklaring: ligger sammenfoldet under «Slik fungerer det».
  final List<String> rules;

  /// Kalles med valgt verdi (null = alt). Åpner selve spillet.
  final void Function(BuildContext context, String? value) onPick;

  @override
  Widget build(BuildContext context) {
    return PitchScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 20),
        children: [
          Text(heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ?before,
          for (final c in choices)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.gold),
              ),
              child: InkWell(
                onTap: () => onPick(context, c.value),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      Text(c.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                      if (c.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(c.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ?after,
          // reglene står under valgene, så man slipper å rulle for å starte
          const SizedBox(height: 8),
          if (rules.isNotEmpty) RulesCard(rules: rules),
        ],
      ),
    );
  }
}
