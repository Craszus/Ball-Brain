import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/avatar_art.dart';
import 'services/levels.dart';
import 'services/profile.dart';
import 'services/stats.dart';
import 'ui/avatar_carousel.dart';
import 'ui/avatar_view.dart';
import 'ui/football.dart';
import 'ui/gold_button.dart';
import 'ui/theme.dart';
import 'l10n/l10n.dart';

/// «Min Avatar»: stor forhåndsvisning og valg av hudfarge, hår og drakt.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late Profile _draft = ref.read(profileProvider);
  late final _name = TextEditingController(text: _draft.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _avatar(Avatar a) => setState(() => _draft = _draft.copyWith(avatar: a));

  bool get _nameOk => Profile.isValidName(_name.text.trim());

  Future<void> _save() async {
    await ref
        .read(profileProvider.notifier)
        .save(_draft.copyWith(name: _name.text.trim()));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = _draft.avatar;
    final xp = ref.watch(statsProvider).totalPoints;
    final info = levelFor(xp);
    final arts = ref.watch(avatarArtProvider).asData?.value ?? const <String>[];

    return PitchScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _TopBar(title: 'Min Avatar', onBack: () => Navigator.of(context).pop()),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrandMark(width: 30),
              SizedBox(width: 8),
              Text('BALL BRAIN',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 4),
                ],
              ),
              child: AvatarView(a, size: 230),
            ),
          ),
          const SizedBox(height: 14),
          Text('Nivå ${info.level} · ${info.title} · $xp poeng',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (arts.isNotEmpty)
            _Section(
              icon: Icons.face_retouching_natural,
              title: 'Velg avatar',
              child: AvatarCarousel(
                paths: arts,
                selected: _draft.avatar.art,
                onChanged: (p) => setState(
                    () => _draft = _draft.copyWith(avatar: _draft.avatar.withArt(p))),
              ),
            )
          else ...[
          _Section(
            icon: Icons.front_hand_outlined,
            title: 'Hudfarge',
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < skinTones.length; i++)
                _swatch(
                  selected: a.skin == i,
                  fill: _dot(color: skinTones[i]),
                  onTap: () => _avatar(a.copyWith(skin: i)),
                ),
            ]),
          ),
          _Section(
            icon: Icons.face_outlined,
            title: 'Hår',
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < hairStyleNames.length; i++)
                Tooltip(
                  message: hairStyleNames[i],
                  child: _swatch(
                    selected: a.hairStyle == i,
                    size: 56,
                    fill: AvatarView(a.copyWith(hairStyle: i), size: 56),
                    onTap: () => _avatar(a.copyWith(hairStyle: i)),
                  ),
                ),
            ]),
          ),
          _Section(
            icon: Icons.palette_outlined,
            title: 'Hårfarge',
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < hairColors.length; i++)
                _swatch(
                  selected: a.hairColor == i,
                  fill: _dot(color: hairColors[i]),
                  onTap: () => _avatar(a.copyWith(hairColor: i)),
                ),
            ]),
          ),
          _Section(
            icon: Icons.checkroom_outlined,
            title: 'Drakt',
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < kits.length; i++)
                _swatch(
                  selected: a.kit == i,
                  fill: _dot(color: kits[i].primary, second: kits[i].secondary),
                  onTap: () => _avatar(a.copyWith(kit: i)),
                ),
            ]),
          ),
          _Section(
            icon: Icons.format_paint_outlined,
            title: 'Mønster',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < patternNames.length; i++)
                _chip(patternNames[i], a.pattern == i,
                    () => _avatar(a.copyWith(pattern: i))),
            ]),
          ),
          _Section(
            icon: Icons.tag,
            title: 'Draktnummer: ${a.number}',
            child: Slider(
              value: a.number.toDouble(),
              min: 1,
              max: 99,
              divisions: 98,
              label: '${a.number}',
              onChanged: (v) => _avatar(a.copyWith(number: v.round())),
            ),
          ),
          ],
          _Section(
            icon: Icons.badge_outlined,
            title: 'Spillerinfo',
            child: Column(children: [
              TextField(
                controller: _name,
                textAlign: TextAlign.center,
                maxLength: 16,
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.gold,
                decoration: InputDecoration(
                  labelText: 'Kallenavn'.tr,
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  helperMaxLines: 2,
                  helperText: '3–16 tegn: bokstaver, tall, punktum, _ og -',
                  errorText: _nameOk ? null : 'Ugyldig kallenavn',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppColors.tile.withValues(alpha: 0.55),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.goldLighter, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _draft.country,
                dropdownColor: AppColors.card,
                isExpanded: true,
                alignment: Alignment.center,
                selectedItemBuilder: (_) => [
                  for (final c in countries) Center(child: Text(c.$2)),
                ],
                decoration: InputDecoration(
                  labelText: 'Land'.tr,
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  // like mye luft på venstre side som pilen tar til høyre, så teksten står midt i feltet
                  contentPadding: const EdgeInsets.fromLTRB(40, 16, 16, 16),
                  filled: true,
                  fillColor: AppColors.tile.withValues(alpha: 0.55),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.goldLighter, width: 2),
                  ),
                ),
                items: [
                  for (final c in countries)
                    DropdownMenuItem(
                        value: c.$1, child: Center(child: Text(c.$2))),
                ],
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(country: v)),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          GoldButton(label: 'Lagre avatar', onPressed: _nameOk ? _save : null),
          const SizedBox(height: 10),
          const Text('Endringene lagres til profilen din',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _dot({required Color color, Color? second}) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: second == null ? color : null,
          gradient: second == null
              ? null
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0, 0.5, 0.5, 1],
                  colors: [color, color, second, second],
                ),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
      );

  /// Valgt = dobbel gullring (som i mockupen).
  Widget _swatch({
    required bool selected,
    required Widget fill,
    required VoidCallback onTap,
    double size = 46,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: size + 8,
          height: size + 8,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? AppColors.gold : Colors.transparent, width: 3),
          ),
          child: ClipOval(child: fill),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.ink : Colors.white)),
        selected: selected,
        selectedColor: AppColors.gold,
        backgroundColor: AppColors.card,
        showCheckmark: false,
        side: BorderSide(
            color: selected
                ? AppColors.goldLighter
                : AppColors.gold.withValues(alpha: 0.4)),
        onSelected: (_) => onTap(),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.grass.withValues(alpha: 0.5)),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              iconSize: 38,
              icon: const Icon(Icons.chevron_left, color: AppColors.gold),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: AppColors.textSecondary, size: 26),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(title,
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}
