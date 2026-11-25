import 'package:flutter/material.dart' hide Text;

import 'icon_tile.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

/// Fasiten etter at man har svart.
enum AnswerMark { correct, wrong }

/// Svaralternativ: kort med gullkant, bokstavbrikke (A, B, C, D) og tekst.
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.letter,
    required this.label,
    required this.onTap,
    this.mark,
  });

  final AnswerMark? mark;

  final String letter;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final marked = switch (mark) {
      AnswerMark.correct => const Color(0xFF2E9E4F),
      AnswerMark.wrong => const Color(0xFFC0392B),
      null => null,
    };
    return Card(
      color: marked,
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: mark == null ? AppColors.gold : Colors.white, width: mark == null ? 1 : 2),
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
              // balanserer bokstavbrikken så teksten er midtstilt; viser også riktig/feil
              SizedBox(
                width: 58,
                child: switch (mark) {
                  AnswerMark.correct => const Icon(Icons.check_circle, color: Colors.white),
                  AnswerMark.wrong => const Icon(Icons.cancel, color: Colors.white),
                  null => null,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
