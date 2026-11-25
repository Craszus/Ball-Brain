import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cloud.dart';

/// Feil fra klubbserveren (se supabase/clubs.sql). [key] er f.eks. `too_few`, `locked`, `offline`.
class ClubError implements Exception {
  const ClubError(this.key);
  final String key;
}

String clubError(String key) => switch (key) {
      'not_found' => 'Fant ingen klubb med den koden.',
      'own_club' => 'Du kan ikke utfordre din egen klubb.',
      'too_few' => 'Klubben din har ikke nok medlemmer til denne lagstørrelsen.',
      'opp_too_few' => 'Motstanderen har ikke nok medlemmer til denne lagstørrelsen.',
      'already' => 'Dere har allerede en kamp på gang.',
      'too_many' => 'Klubben har for mange åpne utfordringer.',
      'bad_time' => 'Avsparket må være frem i tid, senest om en uke.',
      'team_full' => 'Laget er fullt.',
      'locked' => 'Du har spilt for en annen klubb denne uken.',
      'closed' => 'Kampen er ikke åpen lenger.',
      'not_started' => 'Kampen har ikke startet ennå.',
      'not_owner' => 'Bare den som laget klubben kan endre skjoldet.',
      _ => 'Kunne ikke nå serveren. Sjekk nettet.',
    };

class ClubInfo {
  const ClubInfo(
      {required this.id,
      required this.name,
      this.color1 = 0,
      this.color2 = 1,
      this.emblem = 0,
      this.matchCode = '',
      this.members = 0,
      this.canEdit = false,
      this.wins = 0,
      this.draws = 0,
      this.losses = 0,
      this.mine = true});

  final String id;
  final String name;
  final int color1;
  final int color2;
  final int emblem;

  /// Koden andre klubber bruker for å utfordre (ikke det samme som invitasjonskoden).
  final String matchCode;
  final int members;
  final bool canEdit;
  final int wins;
  final int draws;
  final int losses;
  final bool mine;

  factory ClubInfo.fromJson(Map<String, dynamic> j) {
    int n(String k, [int d = 0]) => (j[k] as num?)?.toInt() ?? d;
    return ClubInfo(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '?',
        color1: n('color1'),
        color2: n('color2', 1),
        emblem: n('emblem'),
        matchCode: (j['match_code'] as String?) ?? '',
        members: n('members'),
        canEdit: j['can_edit'] == true,
        wins: n('wins'),
        draws: n('draws'),
        losses: n('losses'),
        mine: j['mine'] != false);
  }
}

class ClubPlayer {
  const ClubPlayer(
      {required this.name,
      required this.club,
      this.score = 0,
      this.answered = 0,
      this.isMe = false});
  final String name;
  final String club;
  final int score;
  final int answered;
  final bool isMe;

  factory ClubPlayer.fromJson(Map<String, dynamic> j) => ClubPlayer(
      name: (j['name'] as String?) ?? '?',
      club: j['club'] as String,
      score: (j['score'] as num?)?.toInt() ?? 0,
      answered: (j['answered'] as num?)?.toInt() ?? 0,
      isMe: j['me'] == true);
}

class ClubGame {
  const ClubGame(
      {required this.id,
      required this.status,
      required this.size,
      required this.windowMin,
      required this.kickoffMs,
      required this.endsMs,
      required this.home,
      required this.away,
      this.players = const [],
      this.winner,
      this.skewMs = 0});

  final String id;
  final String status;
  final int size;
  final int windowMin;
  final int kickoffMs;
  final int endsMs;
  final ClubInfo home;
  final ClubInfo away;
  final List<ClubPlayer> players;
  final String? winner;

  /// Serverens klokke minus telefonens, så nedtellingen blir riktig.
  final int skewMs;

  int get nowMs => DateTime.now().millisecondsSinceEpoch + skewMs;
  List<ClubPlayer> team(String clubId) => [for (final p in players) if (p.club == clubId) p];
  int pot(String clubId) => team(clubId).fold(0, (a, p) => a + p.score);
  ClubPlayer? get me {
    for (final p in players) {
      if (p.isMe) return p;
    }
    return null;
  }

  bool get invited => status == 'invited';
  bool get finished => status == 'finished';
  bool get over => status != 'invited' && status != 'accepted';
  bool get live => status == 'accepted' && nowMs >= kickoffMs && nowMs < endsMs;

  /// Jeg er på laget, kampen pågår og jeg har spørsmål igjen.
  bool get canPlay => live && me != null && me!.answered < 10;

  factory ClubGame.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num).toInt();
    return ClubGame(
        id: j['id'] as String,
        status: j['status'] as String,
        size: n('size'),
        windowMin: n('window_min'),
        kickoffMs: n('kickoff_ms'),
        endsMs: n('ends_ms'),
        home: ClubInfo.fromJson(j['home'] as Map<String, dynamic>),
        away: ClubInfo.fromJson(j['away'] as Map<String, dynamic>),
        players: [
          for (final p in (j['players'] as List? ?? const []))
            ClubPlayer.fromJson(p as Map<String, dynamic>)
        ],
        winner: j['winner'] as String?,
        skewMs: n('now_ms') - DateTime.now().millisecondsSinceEpoch);
  }
}

class ClubQuestion {
  const ClubQuestion(
      {required this.idx,
      required this.total,
      required this.prompt,
      required this.options,
      required this.remainingMs,
      this.era});
  final int idx;
  final int total;
  final String prompt;
  final String? era;
  final List<String> options;
  final int remainingMs;

  factory ClubQuestion.fromJson(Map<String, dynamic> j) => ClubQuestion(
      idx: (j['idx'] as num).toInt(),
      total: (j['total'] as num).toInt(),
      prompt: j['prompt'] as String,
      era: j['era'] as String?,
      options: [for (final o in j['options'] as List) o.toString()],
      remainingMs: (j['remaining_ms'] as num).toInt());
}

class ClubAnswer {
  const ClubAnswer(this.correct, this.points, this.right);
  final bool correct;
  final int points;
  final String right;
}

class ClubApi {
  static const _known = [
    'not_found', 'own_club', 'too_few', 'opp_too_few', 'already', 'too_many', 'bad_time',
    'team_full', 'locked', 'closed', 'not_started', 'not_owner',
  ];

  static Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    final c = Cloud.client;
    if (c == null) throw const ClubError('offline');
    try {
      await Cloud.ensureSignedIn();
      return await c.rpc(fn, params: params).timeout(const Duration(seconds: 8));
    } catch (e) {
      final m = e is PostgrestException ? e.message : '';
      throw ClubError(_known.firstWhere((k) => m == k, orElse: () => 'offline'));
    }
  }

  static Future<List<ClubInfo>> myClubs() async => [
        for (final j in await _rpc('club_my_clubs') as List)
          ClubInfo.fromJson(j as Map<String, dynamic>)
      ];

  static Future<List<ClubGame>> games() async => [
        for (final j in await _rpc('club_game_list') as List)
          ClubGame.fromJson(j as Map<String, dynamic>)
      ];

  static Future<void> setLook(String club, int color1, int color2, int emblem) => _rpc(
      'club_set_look', {'p_club': club, 'p_color1': color1, 'p_color2': color2, 'p_emblem': emblem});

  static Future<String> challenge(
          {required String club,
          required String code,
          required int size,
          required DateTime kickoff,
          required int window}) async =>
      await _rpc('club_challenge', {
        'p_club': club,
        'p_code': code,
        'p_size': size,
        'p_kickoff': kickoff.toUtc().toIso8601String(),
        'p_window': window,
      }) as String;

  static Future<void> respond(String game, bool accept) =>
      _rpc('club_respond', {'p_game': game, 'p_accept': accept});
  static Future<void> cancel(String game) => _rpc('club_cancel', {'p_game': game});
  static Future<void> join(String game, String club) =>
      _rpc('club_join', {'p_game': game, 'p_club': club});
  static Future<void> leave(String game) => _rpc('club_leave_game', {'p_game': game});

  /// Neste spørsmål, eller null når jeg er ferdig eller kampen er over.
  static Future<ClubQuestion?> next(String game) async {
    final j = await _rpc('club_next', {'p_game': game}) as Map<String, dynamic>;
    return j['done'] == true ? null : ClubQuestion.fromJson(j);
  }

  static Future<ClubAnswer> answer(String game, int idx, String? answer) async {
    final j = await _rpc('club_answer', {'p_game': game, 'p_idx': idx, 'p_answer': answer})
        as Map<String, dynamic>;
    return ClubAnswer(j['correct'] == true, (j['points'] as num).toInt(), j['right'] as String);
  }
}
