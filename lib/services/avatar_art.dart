import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ferdige avatarbilder (assets/avatars/avatar_01.png …). Tom liste hvis ingen er lagt inn;
/// da brukes de tegnede avatarene.
final avatarArtProvider = FutureProvider<List<String>>((ref) async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final list = manifest
        .listAssets()
        .where((a) => a.startsWith('assets/avatars/avatar_') && a.endsWith('.png'))
        .toList()
      ..sort();
    return list;
  } catch (_) {
    return const [];
  }
});
