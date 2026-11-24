import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/question.dart';
import '../services/cloud.dart';

/// Henter spørsmål. Kilden er (i rekkefølge): lagret kopi fra Supabase → spørsmålene som følger
/// med i appen (assets/seed/questions.json). Appen oppdaterer kopien fra Supabase i bakgrunnen
/// (én gang pr. oppstart), så nye og rettede spørsmål kommer uten ny apputgave.
/// Uten Supabase-nøkler eller nett brukes bare det som følger med appen.
class QuestionRepository {
  QuestionRepository(this._client);

  final SupabaseClient? _client;

  static const _cacheKey = 'questions.cache.v1';
  static List<Map<String, dynamic>>? _memory;
  static bool _refreshed = false;

  /// Tømmer minnet (brukes i tester).
  static void resetForTest() {
    _memory = null;
    _refreshed = false;
  }

  Future<List<Question>> fetchQuestions({
    QuestionType type = QuestionType.rulesQuiz,
    int limit = 10,
    String? era,
  }) async {
    final wanted = type == QuestionType.imageSort ? 'image_sort' : 'rules_quiz';
    final rows = await _rows();
    final list = <Question>[
      for (final r in rows)
        if (r['type'] == wanted && (era == null || r['era'] == era)) Question.fromJson(r)
    ]..shuffle();
    if (list.isNotEmpty) return list.take(limit).toList();
    final source = type == QuestionType.imageSort ? _sampleSort : _sample;
    return source.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> _rows() async {
    var rows = _memory;
    if (rows == null) {
      rows = await _readCache() ?? await _readSeed();
      _memory = rows;
    }
    if (!_refreshed) {
      _refreshed = true;
      _refreshFromServer(); // i bakgrunnen, venter ikke
    }
    return rows;
  }

  Future<void> _refreshFromServer() async {
    final client = _client;
    if (client == null) return;
    try {
      await Cloud.ensureSignedIn();
      if (client.auth.currentUser == null) return;
      final all = <Map<String, dynamic>>[];
      for (var from = 0;; from += 1000) {
        final page = await client
            .from('questions')
            .select('id, key, type, era, prompt, options, correct, difficulty')
            .order('id')
            .range(from, from + 999)
            .timeout(const Duration(seconds: 15));
        all.addAll(page.cast<Map<String, dynamic>>());
        if (page.length < 1000) break;
      }
      if (all.isEmpty) return; // tom tabell: behold det vi har
      _memory = all;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(all));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> _readCache() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_cacheKey);
      if (raw == null) return null;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }

  /// Spørsmålene som følger med appen. Negative id-er markerer at de er lokale.
  Future<List<Map<String, dynamic>>> _readSeed() async {
    try {
      final raw = await rootBundle.loadString('assets/seed/questions.json');
      final all = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return [
        for (var i = 0; i < all.length; i++) {...all[i], 'id': -1000 - i}
      ];
    } catch (_) {
      return const [];
    }
  }

  // Reserve-data hvis seed-filen mangler. `correct` er indeksene i riktig rekkefølge.
  static const _sampleSort = <Question>[
    Question(
      id: -101,
      type: QuestionType.imageSort,
      prompt: 'Sorter VM-vinnerne fra eldst til nyest',
      options: [
        'Italia 2006',
        'Brasil 1994',
        'Tyskland 2014',
        'Frankrike 1998',
        'Spania 2010',
      ],
      correct: [1, 3, 0, 4, 2],
      era: 'VM',
    ),
    Question(
      id: -102,
      type: QuestionType.imageSort,
      prompt: 'Sorter Champions League-vinnerne fra eldst til nyest',
      options: [
        'Man City 2023',
        'Liverpool 2019',
        'Real Madrid 2022',
        'Chelsea 2021',
        'Bayern 2020',
      ],
      correct: [1, 4, 3, 2, 0],
      difficulty: 2,
      era: 'Champions League',
    ),
  ];

  static const _sample = <Question>[
    Question(
      id: -1,
      type: QuestionType.rulesQuiz,
      prompt: 'Kan du bli satt offside direkte på en innkast?',
      options: ['Ja', 'Nei'],
      correct: 1,
      era: 'Regler',
    ),
    Question(
      id: -2,
      type: QuestionType.rulesQuiz,
      prompt: 'Hvor mange bytter er tillatt i en ordinær kamp (IFAB, i dag)?',
      options: ['3', '5', '7', 'Ubegrenset'],
      correct: 1,
      difficulty: 2,
    ),
    Question(
      id: -3,
      type: QuestionType.rulesQuiz,
      prompt: 'Hva er straffen for å håndsfeste ballen bevisst i eget straffesparkfelt (som ikke-keeper)?',
      options: ['Indirekte frispark', 'Straffespark', 'Dommerball', 'Innkast'],
      correct: 1,
    ),
  ];
}
