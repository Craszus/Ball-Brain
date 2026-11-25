import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cloud.dart';

/// Feil fra quizkveld-serveren: `not_found`, `no_profile`, `no_players`, `full`, `daily_limit`,
/// `bad_setup`, `not_active` eller `offline`.
class NightError implements Exception {
  const NightError(this.key);
  final String key;
  @override
  String toString() => 'NightError($key)';
}

class NightRow {
  const NightRow(
      {required this.rank, required this.name, required this.score, this.me = false});
  final int rank;
  final String name;
  final int score;
  final bool me;

  factory NightRow.fromJson(Map<String, dynamic> j) => NightRow(
      rank: (j['rank'] as num).toInt(),
      name: (j['name'] as String?) ?? '?',
      score: (j['score'] as num).toInt(),
      me: j['me'] == true);
}

/// Alt jeg ser av en quizkveld akkurat nå. Fasiten ([right]) kommer først når spørsmålet er stengt.
class NightState {
  const NightState({
    required this.id,
    required this.code,
    required this.status,
    this.idx = 0,
    this.total = 0,
    this.seconds = 20,
    this.host = false,
    this.playing = false,
    this.players = 0,
    this.answered = 0,
    this.leftMs,
    this.prompt,
    this.era,
    this.options = const [],
    this.right,
    this.myAnswer,
    this.myAnswered = false,
    this.myPoints,
    this.myRank,
    this.standings = const [],
  });

  final String id;
  final String code;

  /// `lobby`, `question`, `reveal`, `finished` eller `cancelled`.
  final String status;
  final int idx;
  final int total;
  final int seconds;
  final bool host;
  final bool playing;
  final int players;
  final int answered;
  final int? leftMs;
  final String? prompt;
  final String? era;
  final List<String> options;
  final String? right;
  final String? myAnswer;
  final bool myAnswered;
  final int? myPoints;
  final int? myRank;
  final List<NightRow> standings;

  bool get over => status == 'finished' || status == 'cancelled';

  factory NightState.fromJson(Map<String, dynamic> j) {
    final q = j['question'] as Map?;
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return NightState(
      id: j['id'] as String,
      code: j['code'] as String,
      status: j['status'] as String,
      idx: n('idx'),
      total: n('total'),
      seconds: n('seconds'),
      host: j['host'] == true,
      playing: j['playing'] == true,
      players: n('players'),
      answered: n('answered'),
      leftMs: (j['left_ms'] as num?)?.toInt(),
      prompt: q?['prompt'] as String?,
      era: q?['era'] as String?,
      options: [for (final o in (q?['options'] as List?) ?? const []) o.toString()],
      right: j['right'] as String?,
      myAnswer: j['my_answer'] as String?,
      myAnswered: j['my_answered'] == true,
      myPoints: (j['my_points'] as num?)?.toInt(),
      myRank: (j['my_rank'] as num?)?.toInt(),
      standings: [
        for (final r in (j['standings'] as List?) ?? const [])
          NightRow.fromJson(Map<String, dynamic>.from(r as Map))
      ],
    );
  }
}

/// Kall mot quizkveld-funksjonene (supabase/quiznight.sql). Egen klasse så testene kan bytte den ut.
class QuizNightApi {
  const QuizNightApi();

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    final c = Cloud.client;
    if (c == null) throw const NightError('offline');
    try {
      await Cloud.ensureSignedIn();
      if (c.auth.currentUser == null) throw const NightError('offline');
      return await c.rpc(fn, params: params).timeout(const Duration(seconds: 10));
    } on NightError {
      rethrow;
    } on PostgrestException catch (e) {
      for (final k in [
        'not_found',
        'no_profile',
        'no_players',
        'full',
        'daily_limit',
        'bad_setup',
        'not_active'
      ]) {
        if (e.message.contains(k)) throw NightError(k);
      }
      throw const NightError('offline');
    } catch (_) {
      throw const NightError('offline');
    }
  }

  NightState _state(dynamic r) => NightState.fromJson(Map<String, dynamic>.from(r as Map));

  Future<NightState> create(
          {required int count,
          required int seconds,
          required List<String> eras,
          required bool hostPlays}) async =>
      _state(await _rpc('quiz_create', {
        'p_count': count,
        'p_seconds': seconds,
        'p_eras': eras.isEmpty ? null : eras,
        'p_host_plays': hostPlays,
      }));

  Future<NightState> join(String code) async => _state(await _rpc('quiz_join', {'p_code': code}));

  /// Kvelden jeg er midt i, eller null.
  Future<NightState?> mine() async {
    final r = await _rpc('quiz_mine');
    return r == null ? null : _state(r);
  }

  Future<NightState> state(String id) async => _state(await _rpc('quiz_state', {'p_id': id}));

  /// Verten går videre fra det [from] viser.
  Future<NightState> next(NightState from) async => _state(
      await _rpc('quiz_next', {'p_id': from.id, 'p_status': from.status, 'p_idx': from.idx}));

  Future<NightState> answer(String id, int idx, String answer) async =>
      _state(await _rpc('quiz_answer', {'p_id': id, 'p_idx': idx, 'p_answer': answer}));

  Future<void> leave(String id) async {
    try {
      await _rpc('quiz_leave', {'p_id': id});
    } catch (_) {}
  }
}
