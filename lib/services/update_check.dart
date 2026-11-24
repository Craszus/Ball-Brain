import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:package_info_plus/package_info_plus.dart';

/// Hvor «siste bygg» ligger. `python tools/release.py` bygger en ny APK og oppdaterer denne
/// utgaven (samme oppsett som i Logica).
const latestReleaseApi = 'https://api.github.com/repos/Craszus/Ball-Brain/releases/latest';

/// En nyere versjon enn den som er installert.
class AppUpdate {
  const AppUpdate({required this.build, required this.url});

  /// Byggnummeret til den nye versjonen.
  final int build;

  /// Direkte lenke til APK-en (eller utgavesiden hvis APK-en mangler).
  final String url;
}

/// Leser byggnummer og nedlastingslenke fra et svar fra GitHubs «latest release»-API.
/// Byggnummeret står som «Bygg 12» i beskrivelsen eller «(12)» i tittelen. Gir null hvis
/// utgaven ikke er nyere enn [installedBuild] eller ikke kan tolkes.
AppUpdate? parseLatestRelease(Map<String, dynamic> json, int installedBuild) {
  final text = '${json['body'] ?? ''}\n${json['name'] ?? ''}';
  final match = RegExp(r'Bygg\s+(\d+)').firstMatch(text) ?? RegExp(r'\((\d+)\)').firstMatch(text);
  final build = int.tryParse(match?.group(1) ?? '');
  if (build == null || build <= installedBuild) return null;
  var url = (json['html_url'] as String?) ?? '';
  for (final a in (json['assets'] as List? ?? const [])) {
    final m = a as Map;
    if ((m['name'] as String?)?.toLowerCase().endsWith('.apk') ?? false) {
      url = (m['browser_download_url'] as String?) ?? url;
      break;
    }
  }
  if (url.isEmpty) return null;
  return AppUpdate(build: build, url: url);
}

/// Spør GitHub om det finnes en nyere versjon. Gir null ved ingen oppdatering, ingen nett eller
/// feil, og alltid null utenfor Android (der APK-en ikke kan installeres) og i feilsøkingsmodus.
Future<AppUpdate?> checkForUpdate({bool force = false}) async {
  if (!force && (kDebugMode || !Platform.isAndroid)) return null;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final installed = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
    final req = await client.getUrl(Uri.parse(latestReleaseApi));
    req.headers.set('Accept', 'application/vnd.github+json');
    final res = await req.close().timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    return parseLatestRelease(jsonDecode(body) as Map<String, dynamic>, installed);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Installert byggnummer (for visning i Innstillinger), eller null hvis det ikke kan leses.
Future<String?> installedVersionLabel() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } catch (_) {
    return null;
  }
}
