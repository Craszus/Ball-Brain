import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cloud.dart';

/// Feil fra 1v1-serveren. [key] er en av `not_found`, `own_duel`, `daily_limit`, `no_profile`,
/// `not_active`, `bad_index` eller `offline`.
class DuelError implements Exception {
  const DuelError(this.key);
  final String key;
  @override
  String toString() => 'DuelError($key)';
}

class DuelSide {
  const DuelSide(
      {required this.name,
      required this.country,
      required this.score,
      required this.answered,
      required this.correct});
  final String name;
  final String country;
  final int score;
  final int answered;
  final int correct;

  factory DuelSide.fromJson(Map<String, dynamic> j) => DuelSide(
        name: (j['name'] as String?) ?? '',
        country: (j['country'] as String?) ?? '',
        score: (j['score'] as num).toInt(),
        answered: (j['answered'] as num).toInt(),
        correct: (j['correct'] as num).toInt(),
      );
}

/// Status for et oppgjør, sett fra deg (`me`) og motstanderen (`opp`).
class DuelSummary {
  const DuelSummary({
    required this.id,
    required this.code,
    required this.status,
    required this.total,
    required this.me,
    required this.opp,
    required this.result,
    required this.serverOffsetMs,
    required this.startsMs,
    this.mode = 'live',
    this.challenger = false,
    this.myDone = false,
    this.expiresMs,
  });

  final String id;
  final String? code;

  /// `waiting`, `active`, `finished` eller `cancelled`.
  final String status;
  final int total;
  final DuelSide me;
  final DuelSide? opp;

  /// `win`, `loss`, `draw` eller null mens kampen pågår.
  final String? result;

  /// Serverklokke minus klokka på telefonen (ms), så begge ser samme nedtelling.
  final int serverOffsetMs;

  /// Når kampen starter (serverklokke, ms), eller null mens vi venter.
  final int? startsMs;

  /// `live` (hurtigmatch/kode, begge spiller samtidig) eller `challenge` (utfordring til en venn,
  /// spilles når det passer innen 48 timer).
  final String mode;

  /// Er det jeg som utfordret?
  final bool challenger;

  /// Har jeg spilt ferdig mine spørsmål?
  final bool myDone;

  /// Når en utfordring utløper (serverklokke, ms).
  final int? expiresMs;

  bool get isChallenge => mode == 'challenge';

  bool get isActive => status == 'active';
  bool get isFinished => status == 'finished';

  /// Millisekunder til start, målt på telefonens klokke.
  int msUntilStart() =>
      startsMs == null ? 0 : startsMs! - (DateTime.now().millisecondsSinceEpoch + serverOffsetMs);

  factory DuelSummary.fromJson(Map<String, dynamic> j) => DuelSummary(
        id: j['id'] as String,
        code: j['code'] as String?,
        status: j['status'] as String,
        total: (j['total'] as num).toInt(),
        me: DuelSide.fromJson(j['me'] as Map<String, dynamic>),
        opp: j['opp'] == null ? null : DuelSide.fromJson(j['opp'] as Map<String, dynamic>),
        result: j['result'] as String?,
        serverOffsetMs:
            (j['now_ms'] as num).toInt() - DateTime.now().millisecondsSinceEpoch,
        startsMs: (j['starts_ms'] as num?)?.toInt(),
        mode: (j['mode'] as String?) ?? 'live',
        challenger: j['challenger'] == true,
        myDone: j['my_done'] == true,
        expiresMs: (j['expires_ms'] as num?)?.toInt(),
      );
}

/// En rad i «mine utfordringer»: innkommende, utgående, ferdig eller avslått.
class DuelListItem {
  const DuelListItem({
    required this.id,
    required this.mode,
    required this.status,
    required this.incoming,
    required this.opponent,
    required this.myScore,
    required this.theirScore,
    required this.myDone,
    required this.theirDone,
    required this.result,
    required this.expiresMs,
    this.opponentId,
    this.finishedMs,
  });

  final String id;
  final String mode;
  final String status;
  final bool incoming;
  final String opponent;
  final int myScore;
  final int theirScore;
  final bool myDone;
  final bool theirDone;
  final String? result;
  final int? expiresMs;
  final String? opponentId;
  final int? finishedMs;

  bool get isActive => status == 'active';
  bool get isFinished => status == 'finished';
  bool get isDeclined => status == 'declined';

  /// En utfordring jeg har fått og ikke har spilt ennå.
  bool get needsMyAnswer => incoming && isActive && !myDone;

  /// Timer igjen til utløp (null hvis ukjent).
  Duration? timeLeft() => expiresMs == null
      ? null
      : Duration(milliseconds: expiresMs! - DateTime.now().millisecondsSinceEpoch);

  factory DuelListItem.fromJson(Map<String, dynamic> j) => DuelListItem(
        id: j['id'] as String,
        mode: (j['mode'] as String?) ?? 'challenge',
        status: j['status'] as String,
        incoming: j['incoming'] == true,
        opponent: (j['opponent'] as String?) ?? '?',
        myScore: (j['my_score'] as num?)?.toInt() ?? 0,
        theirScore: (j['their_score'] as num?)?.toInt() ?? 0,
        myDone: j['my_done'] == true,
        theirDone: j['their_done'] == true,
        result: j['result'] as String?,
        expiresMs: (j['expires_ms'] as num?)?.toInt(),
        opponentId: j['opponent_id'] as String?,
        finishedMs: (j['finished_ms'] as num?)?.toInt(),
      );
}

class DuelQuestion {
  const DuelQuestion(
      {required this.idx, required this.key, required this.era, required this.prompt, required this.options});
  final int idx;
  final String key;
  final String? era;
  final String prompt;
  final List<String> options;

  factory DuelQuestion.fromJson(Map<String, dynamic> j) => DuelQuestion(
        idx: (j['idx'] as num).toInt(),
        key: j['key'] as String,
        era: j['era'] as String?,
        prompt: j['prompt'] as String,
        options: (j['options'] as List).map((e) => e.toString()).toList(),
      );
}

class DuelAnswerResult {
  const DuelAnswerResult({required this.correct, required this.points, required this.right});
  final bool correct;
  final int points;
  final String right;
}

/// Kall mot 1v1-funksjonene i Supabase. Serveren avgjør spørsmål, tid, poeng og vinner.
class DuelApi {
  static Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    final c = Cloud.client;
    if (c == null) throw const DuelError('offline');
    try {
      await Cloud.ensureSignedIn();
      if (c.auth.currentUser == null) throw const DuelError('offline');
      return await c.rpc(fn, params: params).timeout(const Duration(seconds: 10));
    } on DuelError {
      rethrow;
    } on PostgrestException catch (e) {
      for (final k in [
        'not_found',
        'own_duel',
        'daily_limit',
        'no_profile',
        'not_active',
        'bad_index',
        'not_started',
        'self',
        'not_shared',
        'not_accepting',
        'too_many',
        'already_played',
        'already'
      ]) {
        if (e.message.contains(k)) throw DuelError(k);
      }
      throw const DuelError('offline');
    } catch (_) {
      throw const DuelError('offline');
    }
  }

  static DuelSummary _sum(dynamic r) => DuelSummary.fromJson(Map<String, dynamic>.from(r as Map));

  /// Hurtigmatch: kobler til en ventende spiller, eller venter selv. Gjenopptar en pågående kamp.
  static Future<DuelSummary> find() async => _sum(await _rpc('duel_find'));

  /// Lager en kamp med kode som en venn kan bli med i.
  static Future<DuelSummary> createPrivate() async => _sum(await _rpc('duel_create_private'));

  static Future<DuelSummary> join(String code) async =>
      _sum(await _rpc('duel_join', {'p_code': code}));

  static Future<DuelSummary> get(String id) async => _sum(await _rpc('duel_get', {'p_id': id}));

  static Future<void> cancel(String id) async {
    try {
      await _rpc('duel_cancel', {'p_id': id});
    } catch (_) {}
  }

  static Future<List<DuelQuestion>> questions(String id) async {
    final r = await _rpc('duel_questions', {'p_id': id}) as List;
    return [for (final j in r) DuelQuestion.fromJson(Map<String, dynamic>.from(j as Map))];
  }

  /// [answer] er valgt tekst, eller null når tiden gikk ut.
  static Future<DuelAnswerResult> answer(String id, int idx, String? answer) async {
    final r = Map<String, dynamic>.from(
        await _rpc('duel_answer', {'p_id': id, 'p_idx': idx, 'p_answer': answer}) as Map);
    return DuelAnswerResult(
        correct: r['correct'] as bool, points: (r['points'] as num).toInt(), right: r['right'] as String);
  }

  /// Utfordrer en venn (jeg må dele en gruppe med vedkommende).
  static Future<DuelSummary> createChallenge(String userId) async =>
      _sum(await _rpc('create_challenge', {'p_user': userId}));

  /// Starter min egen runde i en utfordring (nedtelling på 4 sekunder).
  static Future<DuelSummary> startMine(String id) async =>
      _sum(await _rpc('duel_start_mine', {'p_id': id}));

  /// Mine utfordringer og ferdige kamper siste 14 dager.
  static Future<List<DuelListItem>> myDuels() async {
    final r = await _rpc('my_duels') as List;
    return [for (final j in r) DuelListItem.fromJson(Map<String, dynamic>.from(j as Map))];
  }

  /// Avslår en utfordring jeg har fått.
  static Future<void> decline(String id) async {
    try {
      await _rpc('duel_decline', {'p_id': id});
    } catch (_) {}
  }

  /// «Avslutt/Fjern»: avbryter eller avslår en åpen utfordring, og skjuler ferdige.
  static Future<void> remove(String id) async {
    try {
      await _rpc('duel_remove', {'p_id': id});
    } catch (_) {}
  }

  /// Slår på/av om andre kan utfordre meg.
  static Future<void> setAcceptsChallenges(bool on) async {
    try {
      await _rpc('set_accepts_challenges', {'p_on': on});
    } catch (_) {}
  }

  /// Lytter på nye og endrede utfordringer som involverer meg (Realtime). [userId] er min id.
  /// Gir en funksjon som stopper lyttingen.
  static void Function() watchMine(String userId, void Function() onChange) {
    final c = Cloud.client;
    if (c == null) return () {};
    RealtimeChannel? ch;
    try {
      ch = c.channel('duels-mine-$userId');
      for (final col in ['p1', 'p2']) {
        ch.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'duels',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: col, value: userId),
          callback: (_) => onChange(),
        );
      }
      ch.subscribe();
    } catch (_) {}
    return () {
      try {
        if (ch != null) c.removeChannel(ch);
      } catch (_) {}
    };
  }

  /// Lytter på endringer i oppgjøret (Realtime). Gir en funksjon som stopper lyttingen.
  /// Endringene brukes bare som signal: skjermen henter oppdatert status selv.
  static void Function() watch(String id, void Function() onChange) {
    final c = Cloud.client;
    if (c == null) return () {};
    RealtimeChannel? ch;
    try {
      ch = c
          .channel('duel-$id')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'duels',
            filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: id),
            callback: (_) => onChange(),
          )
          .subscribe();
    } catch (_) {}
    return () {
      try {
        if (ch != null) c.removeChannel(ch);
      } catch (_) {}
    };
  }
}
