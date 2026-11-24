import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile.dart';

class LeaderboardRow {
  const LeaderboardRow(
      {required this.rank,
      required this.username,
      required this.country,
      required this.total,
      required this.isMe});
  final int rank;
  final String username;
  final String country;
  final int total;
  final bool isMe;
}

class LeaderboardData {
  const LeaderboardData(this.rows, this.me);
  final List<LeaderboardRow> rows;
  final LeaderboardRow? me;
}

class GroupInfo {
  const GroupInfo(
      {required this.id, required this.name, required this.code, this.members = 0});
  final String id;
  final String name;
  final String code;
  final int members;
}

/// Resultat av å lage/bli med i gruppe: enten gruppen eller en feilnøkkel
/// (`not_found`, `too_many_groups`, `group_full`, `bad_name`, `no_profile`, `offline`).
class GroupResult {
  const GroupResult.ok(this.group) : error = null;
  const GroupResult.fail(this.error) : group = null;
  final GroupInfo? group;
  final String? error;
}

/// Tynt lag mot Supabase. Alt er «best effort»: uten nøkler, uten nett eller ved feil
/// fungerer appen som før (lokalt), og ingenting kaster videre.
class Cloud {
  /// Klienten, eller null når Supabase ikke er satt opp.
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Sørger for en anonym bruker (ingen e-post eller passord).
  static Future<void> ensureSignedIn() async {
    final c = client;
    if (c == null || c.auth.currentSession != null) return;
    try {
      await c.auth.signInAnonymously().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Lagrer kallenavn og land på serveren (trengs for at poeng kan lagres og rangeres).
  static Future<void> syncProfile(Profile p) async {
    final c = client;
    if (c == null || !p.saved) return;
    try {
      await ensureSignedIn();
      final user = c.auth.currentUser;
      if (user == null) return;
      await c.from('profiles').upsert({
        'id': user.id,
        'username': p.name.isEmpty ? 'Spiller' : p.name,
        'country_code': p.country.length == 2 ? p.country : null,
      });
    } catch (_) {}
  }

  /// Sletter alt som er lagret om brukeren på serveren (profil og poeng), og logger ut.
  static Future<void> deleteMyData() async {
    final c = client;
    final user = c?.auth.currentUser;
    if (c == null || user == null) return;
    try {
      await c.from('scores').delete().eq('user_id', user.id);
      await c.from('profiles').delete().eq('id', user.id);
      await c.auth.signOut();
    } catch (_) {}
  }

  /// Sender svarene fra en regler-/sorteringsrunde; serveren regner ut poengene selv.
  /// [answers]: {'key': spørsmålsnøkkel, 'answer': valgt tekst (regler) eller liste med
  /// tekster i valgt rekkefølge (sortering)}. Spørsmål uten nøkkel (reservedata) hoppes over.
  static Future<bool> submitRound(String mode, List<Map<String, Object?>> answers) async {
    final c = client;
    final valid = [for (final a in answers) if (a['key'] != null) a];
    if (c == null || valid.isEmpty) return false;
    try {
      await ensureSignedIn();
      if (c.auth.currentUser == null) return false;
      await c.rpc('submit_round', params: {'p_mode': mode, 'p_answers': valid});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _rpcRound(String fn, Map<String, Object?> params) async {
    final c = client;
    if (c == null) return false;
    try {
      await ensureSignedIn();
      if (c.auth.currentUser == null) return false;
      await c.rpc(fn, params: params);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Geografi: [guesses] er {'id': stedets id, 'lat': nålen (eller null), 'lon': ...}.
  /// Serveren regner ut avstand og poeng selv.
  static Future<bool> submitGeo(List<Map<String, Object?>> guesses) =>
      guesses.isEmpty ? Future.value(false) : _rpcRound('submit_geo', {'p_answers': guesses});

  /// Bildequiz: [answers] er {'item': 'player:ID' / 'stadium:ID', 'q': 'name' | 'country' | 'club',
  /// 'answer': valgt tekst}. [mode] er f.eks. 'photo_player'.
  static Future<bool> submitPhoto(String mode, List<Map<String, Object?>> answers) =>
      answers.isEmpty
          ? Future.value(false)
          : _rpcRound('submit_photo', {'p_mode': mode, 'p_answers': answers});

  /// Topp 50 etter samlet poengsum, for ett land ([country]) eller hele verden (null).
  /// Gir null hvis serveren ikke kan nås.
  static Future<LeaderboardData?> leaderboard({String? country}) async {
    final c = client;
    if (c == null) return null;
    try {
      await ensureSignedIn();
      final me = c.auth.currentUser?.id;
      LeaderboardRow row(Map<String, dynamic> j) => LeaderboardRow(
          rank: (j['rank'] as num).toInt(),
          username: j['username'] as String,
          country: (j['country_code'] as String?) ?? '',
          total: (j['total'] as num).toInt(),
          isMe: j['user_id'] == me);
      final top = await c.rpc('leaderboard', params: {'p_country': country, 'p_limit': 50});
      final mine = await c.rpc('leaderboard_me', params: {'p_country': country});
      return LeaderboardData(
        [for (final j in (top as List)) row(j as Map<String, dynamic>)],
        (mine as List).isEmpty ? null : row(mine.first as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  static String _err(Object e) {
    final m = e is PostgrestException ? e.message : '';
    for (final k in ['not_found', 'too_many_groups', 'group_full', 'bad_name', 'no_profile']) {
      if (m.contains(k)) return k;
    }
    return 'offline';
  }

  static GroupInfo _group(dynamic j) => GroupInfo(
      id: j['id'] as String,
      name: j['name'] as String,
      code: j['code'] as String,
      members: ((j['member_count'] ?? 0) as num).toInt());

  static Future<GroupResult> _groupCall(String fn, Map<String, dynamic> params) async {
    final c = client;
    if (c == null) return const GroupResult.fail('offline');
    try {
      await ensureSignedIn();
      final r = await c.rpc(fn, params: params) as List;
      return GroupResult.ok(_group(r.first));
    } catch (e) {
      return GroupResult.fail(_err(e));
    }
  }

  static Future<GroupResult> createGroup(String name) =>
      _groupCall('create_group', {'p_name': name});

  static Future<GroupResult> joinGroup(String code) =>
      _groupCall('join_group', {'p_code': code});

  static Future<bool> leaveGroup(String id) async {
    try {
      await client?.rpc('leave_group', params: {'p_group': id});
      return client != null;
    } catch (_) {
      return false;
    }
  }

  /// Gruppene mine, eller null hvis serveren ikke kan nås.
  static Future<List<GroupInfo>?> myGroups() async {
    final c = client;
    if (c == null) return null;
    try {
      await ensureSignedIn();
      final r = await c.rpc('my_groups') as List;
      return [for (final j in r) _group(j)];
    } catch (_) {
      return null;
    }
  }

  static Future<List<LeaderboardRow>?> groupLeaderboard(String id) async {
    final c = client;
    if (c == null) return null;
    try {
      final me = c.auth.currentUser?.id;
      final r = await c.rpc('group_leaderboard', params: {'p_group': id}) as List;
      return [
        for (final j in r)
          LeaderboardRow(
              rank: (j['rank'] as num).toInt(),
              username: j['username'] as String,
              country: (j['country_code'] as String?) ?? '',
              total: (j['total'] as num).toInt(),
              isMe: j['user_id'] == me)
      ];
    } catch (_) {
      return null;
    }
  }
}
