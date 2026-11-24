import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'legal_screens.dart';
import 'services/avatar_art.dart';
import 'services/profile.dart';
import 'services/stats.dart';
import 'ui/avatar_carousel.dart';
import 'ui/avatar_view.dart';
import 'ui/football.dart';
import 'ui/gold_button.dart';
import 'ui/level_card.dart';
import 'ui/theme.dart';
import 'l10n/l10n.dart';

/// «Velg din avatar»: seks ferdige avatarer, spillernavn og nivåkort.
/// Vises første gang appen åpnes (onboarding) og kan åpnes igjen fra profilen.
class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  int? _selected;
  String? _selectedArt;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _name = TextEditingController(text: profile.name);
    if (!widget.onboarding) {
      _selectedArt = profile.avatar.art;
      final i = presetAvatars.indexWhere((a) => a.sameLook(profile.avatar));
      if (i >= 0) _selected = i;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _nameOk => Profile.isValidName(_name.text.trim());

  Future<void> _confirm() async {
    final art = _selectedArt;
    final sel = _selected;
    if ((art == null && sel == null) || !_nameOk) return;
    final current = ref.read(profileProvider);
    await ref
        .read(profileProvider.notifier)
        .save(
          current.copyWith(
            name: _name.text.trim(),
            avatar: art != null
                ? current.avatar.withArt(art)
                : presetAvatars[sel!],
          ),
        );
    if (!mounted) return;
    if (widget.onboarding) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final xp = ref.watch(statsProvider).totalPoints;
    final arts = ref.watch(avatarArtProvider).asData?.value ?? const <String>[];
    final useArt = arts.isNotEmpty;
    final canConfirm =
        (useArt ? _selectedArt != null : _selected != null) && _nameOk;

    return PitchScaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                const _BrandBar(),
                const SizedBox(height: 22),
                const Text(
                  'Velg din avatar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Velg en avatar for å fortsette',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                if (useArt)
                  AvatarCarousel(
                    paths: arts,
                    selected: _selectedArt,
                    onChanged: (p) => setState(() => _selectedArt = p),
                  )
                else
                  // 2 rader × 3 kolonner, 110 px (krymper litt på smale skjermer)
                  LayoutBuilder(
                    builder: (context, c) {
                      final size = ((c.maxWidth - 12) / 3)
                          .clamp(80.0, 110.0)
                          .toDouble();
                      Widget row(int from) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = from; i < from + 3; i++)
                            _AvatarChoice(
                              avatar: presetAvatars[i],
                              size: size,
                              selected: _selected == i,
                              onTap: () => setState(() => _selected = i),
                            ),
                        ],
                      );
                      return Column(
                        children: [row(0), const SizedBox(height: 22), row(3)],
                      );
                    },
                  ),
              ],
            ),
          ),
          // Navn, nivå og «Bekreft» ligger fast nederst, så de er alltid synlige
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Spillernavn',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _name,
                  textAlign: TextAlign.center,
                  maxLength: 16,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: AppColors.gold,
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: _nameOk
                        ? null
                        : '3–16 tegn: bokstaver, tall, . _ -'.tr,
                    filled: true,
                    fillColor: AppColors.tile.withValues(alpha: 0.55),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.gold,
                          size: 22,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.goldLighter,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LevelCard(xp: xp, dark: true),
                const SizedBox(height: 20),
                GoldButton(
                  label: 'Bekreft',
                  onPressed: canConfirm ? _confirm : null,
                ),
                if (widget.onboarding) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Ved å fortsette godtar du ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      _LegalLink('vilkårene', () => const TermsScreen()),
                      const Text(' og ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      _LegalLink('personvern', () => const PrivacyScreen()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label, this.page);
  final String label;
  final Widget Function() page;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => page())),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline)),
        ),
      );
}

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    decoration: BoxDecoration(
      color: AppColors.card.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.grass.withValues(alpha: 0.5)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandMark(width: 42),
        SizedBox(width: 10),
        Text(
          'BALL BRAIN',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.avatar,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Avatar avatar;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.65),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: AvatarView(avatar, size: size),
            ),
            if (selected)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pitch, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
