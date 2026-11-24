import 'package:flutter/material.dart' hide Text;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'avatar_picker_screen.dart';
import 'home_screen.dart';
import 'l10n/l10n.dart';
import 'services/cloud.dart';
import 'services/language.dart';
import 'services/profile.dart';
import 'ui/theme.dart';

// Gis ved kjøring: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
    await Cloud.ensureSignedIn();
  }
  var onboarded = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    ProfileController.preloaded = ProfileController.fromPrefs(prefs);
    final chosen = prefs.getString('settings.lang');
    LanguageController.preloaded =
        chosen != null && L10n.supported.contains(chosen) ? chosen : null;
    onboarded = prefs.getBool('profile.onboarded') ?? false;
  } catch (_) {}
  Cloud.syncProfile(ProfileController.preloaded ?? const Profile()); // best effort
  // Språket er klart før første bilde, så det ikke blinker mellom språk
  final container = ProviderContainer();
  await L10n.load(container.read(effectiveLangProvider));
  runApp(UncontrolledProviderScope(
      container: container, child: BallBrainApp(onboarded: onboarded)));
}

class BallBrainApp extends ConsumerStatefulWidget {
  const BallBrainApp({super.key, this.onboarded = true});

  /// Falsk første gang appen åpnes: da vises «Velg din avatar» før hovedmenyen.
  final bool onboarded;

  @override
  ConsumerState<BallBrainApp> createState() => _BallBrainAppState();
}

class _BallBrainAppState extends ConsumerState<BallBrainApp> {
  late String _lang = L10n.lang;

  Future<void> _switchTo(String code) async {
    await L10n.load(code);
    if (mounted) setState(() => _lang = L10n.lang);
  }

  @override
  void initState() {
    super.initState();
    final wanted = ref.read(effectiveLangProvider);
    if (wanted != L10n.lang) Future.microtask(() => _switchTo(wanted));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(effectiveLangProvider, (_, next) => _switchTo(next));
    return L10nScope(
      lang: _lang,
      child: MaterialApp(
        title: 'Ball Brain',
        theme: buildTheme(),
        locale: Locale(_lang == 'nb' ? 'nb' : _lang),
        supportedLocales: [for (final c in L10n.supported) Locale(c)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: widget.onboarded
            ? const HomeScreen()
            : const AvatarPickerScreen(onboarding: true),
      ),
    );
  }
}
