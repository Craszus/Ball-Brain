import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bredeste innholdet får bli (i appens egne mål). Bakgrunnen går ut til kantene.
const contentMaxWidth = 515.0;

/// Nettbrett: hele appen (tekst, knapper, luft, dialoger) tegnes større, i stedet
/// for at mobiloppsettet bare strekkes. Mobiler (under 600) er uendret.
double tabletScale(Size size) {
  final side = size.shortestSide;
  return side < 600 ? 1 : math.min(side / 560, 1.5);
}

/// Brukes som `builder` i MaterialApp.
Widget tabletBuilder(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final scale = tabletScale(mq.size);
  if (scale == 1) return child!;
  final size = mq.size / scale;
  return FittedBox(
    fit: BoxFit.fill,
    child: SizedBox.fromSize(
      size: size,
      child: MediaQuery(
        data: mq.copyWith(
          size: size,
          devicePixelRatio: mq.devicePixelRatio * scale,
          padding: mq.padding / scale,
          viewPadding: mq.viewPadding / scale,
          viewInsets: mq.viewInsets / scale,
        ),
        child: child!,
      ),
    ),
  );
}

/// Holder innholdet samlet midt på brede skjermer.
class CenteredContent extends StatelessWidget {
  const CenteredContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Padding(
          padding: EdgeInsets.symmetric(
              horizontal: math.max(0, (c.maxWidth - contentMaxWidth) / 2)),
          child: child,
        ),
      );
}
