import 'package:flutter/material.dart' hide Text;

import 'theme.dart';
import '../l10n/l10n.dart';

/// Gullknapp i full bredde (gullgradient, radius 14, mørk brun tekst #2A1A00).
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.goldGradient : null,
          color: enabled ? null : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: enabled
                  ? AppColors.goldLighter
                  : AppColors.gold.withValues(alpha: 0.3)),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? const Color(0xFF2A1A00) : Colors.white38,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
