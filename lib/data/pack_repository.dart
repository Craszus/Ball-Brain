import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';

/// Ekstra spørsmålspakker (Pro). Følger med appen (tools/make_packs.py) og brukes bare til
/// øving – de sendes aldri til serveren og teller ikke på rangeringene.
class QuestionPack {
  const QuestionPack(this.id, this.title, this.subtitle, this.questions);

  final String id;
  final String title;
  final String subtitle;
  final List<Question> questions;
}

Future<List<QuestionPack>> loadPacks() async {
  try {
    final raw = await rootBundle.loadString('assets/seed/packs.json');
    var n = -5000;
    return [
      for (final p in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
        QuestionPack(p['id'] as String, p['title'] as String, p['subtitle'] as String, [
          for (final q in (p['questions'] as List).cast<Map<String, dynamic>>())
            Question.fromJson({...q, 'id': n--, 'type': 'rules_quiz', 'era': p['title']}),
        ]),
    ];
  } catch (_) {
    return const [];
  }
}

final packsProvider = FutureProvider<List<QuestionPack>>((ref) => loadPacks());
