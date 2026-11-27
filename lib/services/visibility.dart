import 'package:flutter/widgets.dart';

/// Sant når appen er framme. Nettsjekker på tidtaker hoppes over ellers, for å spare strøm og data.
/// «inactive» (f.eks. varselpanelet trukket ned) regnes som framme, siden appen fortsatt synes.
bool appVisible() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;
}
