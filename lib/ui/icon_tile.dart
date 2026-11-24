import 'package:flutter/material.dart';

import 'theme.dart';

/// Ikonbrikke: mørk bakgrunn, 2 px gullkant, gull innhold. Aldri grønn brikke med hvitt ikon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.child,
    this.size = 64,
    this.iconSize = 36,
    this.radius = 14,
  });

  final Widget child;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.tile,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: IconTheme(
          data: IconThemeData(color: AppColors.gold, size: iconSize),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.w900),
            child: child,
          ),
        ),
      );
}
