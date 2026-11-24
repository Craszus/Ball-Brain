import 'package:flutter/material.dart' hide Text;

import 'icon_tile.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

/// Svaralternativ: kort med gullkant, bokstavbrikke (A, B, C, D) og tekst.
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.letter,
    required this.label,
    required this.onTap,
  });

  final String letter;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconTile(
                size: 44,
                radius: 12,
                child: Text(letter, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 58), // balanserer bokstavbrikken så teksten er midtstilt
            ],
          ),
        ),
      ),
    );
  }
}
