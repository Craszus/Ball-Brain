import '../models/question.dart';
import 'cloud.dart';

/// Dagens spørsmål fra serveren. [token] finnes bare på første forsøk; uten det teller ikke
/// resultatet i rangeringen.
class DailyStart {
  const DailyStart(this.questions, this.token);
  final List<Question> questions;
  final String? token;
}

class DailyRow {
  const DailyRow(
      {required this.rank,
      required this.username,
      required this.country,
      required this.correct,
      required this.ms,
      required this.days,
      required this.isMe});

  final int rank;
  final String username;
  final String country;
  final int correct;
  final int ms;
  final int days;
  final bool isMe;

  factory DailyRow.fromJson(Map<String, dynamic> j, String? myId) => DailyRow(
      rank: (j['rank'] as num).toInt(),
      username: (j['username'] as String?) ?? '?',
      country: (j['country_code'] as String?) ?? '',
      correct: (j['correct'] as num).toInt(),
      ms: (j['ms'] as num).toInt(),
      days: (j['days'] as num).toInt(),
      isMe: j['user_id'] == myId);

  /// Samlet tid som «m:ss».
  String get time {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

/// Dagens utfordring mot Supabase (se supabase/daily.sql). Alt er «best effort»: null ved feil.
class DailyApi {
  static Future<DailyStart?> start() async {
    final c = Cloud.client;
    if (c == null) return null;
    try {
      await Cloud.ensureSignedIn();
      final r = await c.rpc('daily_start').timeout(const Duration(seconds: 6))
          as Map<String, dynamic>;
      return DailyStart(
        [for (final q in r['questions'] as List) Question.fromJson(q as Map<String, dynamic>)],
        r['token'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Leverer svarene. Gir antall riktige hvis resultatet ble med i rangeringen, ellers null.
  static Future<int?> submit(String token, List<Map<String, Object?>> answers) async {
    final c = Cloud.client;
    if (c == null) return null;
    try {
      final r = await c.rpc('daily_submit',
          params: {'p_token': token, 'p_answers': answers}) as Map<String, dynamic>;
      return r['counted'] == true ? (r['correct'] as num).toInt() : null;
    } catch (_) {
      return null;
    }
  }

  /// [period]: 'day' eller 'week'. [scope]: 'country', 'world' eller 'friends'.
  static Future<List<DailyRow>?> board(String period, String scope) async {
    final c = Cloud.client;
    if (c == null) return null;
    try {
      await Cloud.ensureSignedIn();
      final r = await c.rpc('daily_board', params: {'p_period': period, 'p_scope': scope}) as List;
      final me = c.auth.currentUser?.id;
      return [for (final j in r) DailyRow.fromJson(j as Map<String, dynamic>, me)];
    } catch (_) {
      return null;
    }
  }
}
