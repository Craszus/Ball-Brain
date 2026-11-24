import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'l10n/l10n.dart';
import 'leaderboard_screen.dart';
import 'services/cloud.dart';
import 'ui/football.dart';
import 'ui/theme.dart';

String groupError(String key) => switch (key) {
      'not_found' => 'Fant ingen gruppe med den koden.',
      'too_many_groups' => 'Du kan være med i maks 10 grupper.',
      'group_full' => 'Gruppen er full (maks 50 medlemmer).',
      'bad_name' => 'Gruppenavnet må ha 2–30 tegn.',
      'no_profile' => 'Lagre profilen din først.',
      _ => 'Kunne ikke nå serveren. Sjekk nettet.',
    };

/// «Venner»-fanen: gruppene dine, med knapper for å lage en gruppe eller bli med med kode.
class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  late Future<List<GroupInfo>?> _future = Cloud.myGroups();

  void _reload() => setState(() => _future = Cloud.myGroups());

  Future<void> _ask({required bool create}) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(create ? 'Lag gruppe' : 'Bli med i gruppe'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: create ? 30 : 6,
          textCapitalization:
              create ? TextCapitalization.sentences : TextCapitalization.characters,
          decoration: InputDecoration(labelText: (create ? 'Gruppenavn' : 'Invitasjonskode').tr),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(create ? 'Lag' : 'Bli med')),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final r = create ? await Cloud.createGroup(text) : await Cloud.joinGroup(text);
    if (!mounted) return;
    if (r.group == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(groupError(r.error!))));
      return;
    }
    _reload();
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GroupScreen(group: r.group!)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GroupInfo>?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snap.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: groups == null ? null : () => _ask(create: true),
                  icon: const Icon(Icons.add),
                  label: const Text('Lag gruppe'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: groups == null ? null : () => _ask(create: false),
                  icon: const Icon(Icons.login),
                  label: const Text('Bli med'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (groups == null)
              Column(children: [
                const SizedBox(height: 24),
                Text(groupError('offline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _reload, child: const Text('Prøv igjen')),
              ])
            else if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(
                  'Lag en gruppe og del koden med vennene dine, så ser dere hvem som kan mest.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              )
            else
              for (final g in groups)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.groups_outlined, color: AppColors.gold),
                    title: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${g.members} medlemmer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => GroupScreen(group: g)));
                      if (mounted) _reload();
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Rangeringen i én gruppe, med invitasjonskode.
class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.group});
  final GroupInfo group;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late final Future<List<LeaderboardRow>?> _future = Cloud.groupLeaderboard(widget.group.id);

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forlate gruppen?'),
        content: const Text('Du kan bli med igjen med koden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Forlat')),
        ],
      ),
    );
    if (ok != true) return;
    await Cloud.leaveGroup(widget.group.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return PitchScaffold(
      title: g.name,
      body: Column(children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ListTile(
            leading: const Icon(Icons.vpn_key_outlined, color: AppColors.gold),
            title: Text(g.code,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
            subtitle: const Text('Invitasjonskode – del den med vennene dine'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Kopier'.tr,
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: '${'Bli med i gruppen min i Ball Brain!'.tr} ${'Kode'.tr}: ${g.code}'));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Kopiert')));
              },
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<LeaderboardRow>?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data;
              if (rows == null) {
                return Center(
                    child: Text(groupError('offline'),
                        style: const TextStyle(color: AppColors.textSecondary)));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [for (final r in rows) LeaderboardTile(r)],
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: _leave,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Forlat gruppen'),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
