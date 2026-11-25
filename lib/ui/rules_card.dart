import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import 'theme.dart';

/// «Slik fungerer det»: bare en liten linje til man trykker på den.
class RulesCard extends StatefulWidget {
  const RulesCard({super.key, required this.rules});
  final List<String> rules;

  @override
  State<RulesCard> createState() => _RulesCardState();
}

class _RulesCardState extends State<RulesCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Semantics(
            expanded: _open,
            child: TextButton.icon(
              onPressed: () => setState(() => _open = !_open),
              iconAlignment: IconAlignment.end,
              icon: Icon(_open ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.gold, size: 20),
              label: const Text('SLIK FUNGERER DET',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          if (_open)
            Card(
              margin: const EdgeInsets.only(top: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    for (final r in widget.rules)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(r,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14.5, height: 1.3)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
