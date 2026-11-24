import 'dart:math' as math;

enum QuestionType { imageSort, rulesQuiz }

class Question {
  const Question({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correct,
    this.era,
    this.imageUrl,
    this.difficulty = 1,
    this.key,
  });

  final int id;
  final QuestionType type;
  final String prompt;
  final List<String> options;

  /// rules_quiz: indeks (int) til riktig alternativ.
  /// image_sort: liste med indekser i riktig rekkefølge.
  final Object correct;
  final String? era;
  final String? imageUrl;
  final int difficulty;

  /// Stabil id fra seed-filen (tools/make_seed.py). Brukes for å huske hva som er vist.
  final String? key;

  /// Id som er lik fra gang til gang (også uten `key`).
  String get uid => key ?? '${type.name}|$prompt|${options.join('|')}';

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as int,
        type: json['type'] == 'image_sort'
            ? QuestionType.imageSort
            : QuestionType.rulesQuiz,
        prompt: json['prompt'] as String,
        options: (json['options'] as List).map((e) => e.toString()).toList(),
        correct: json['correct'] as Object,
        era: json['era'] as String?,
        imageUrl: json['image_url'] as String?,
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        key: json['key'] as String?,
      );

  /// Samme spørsmål med alternativene i ny rekkefølge (riktig svar følger med),
  /// så svaret ikke står på samme plass hver gang. «Ja/Nei» beholdes som det er.
  Question withShuffledOptions(math.Random rng) {
    if (type != QuestionType.rulesQuiz || correct is! int) return this;
    if (options.length == 2 && options.toSet().containsAll(const ['Ja', 'Nei'])) {
      return this;
    }
    final order = List.generate(options.length, (i) => i)..shuffle(rng);
    return Question(
      id: id,
      type: type,
      prompt: prompt,
      options: [for (final i in order) options[i]],
      correct: order.indexOf(correct as int),
      era: era,
      imageUrl: imageUrl,
      difficulty: difficulty,
      key: key,
    );
  }

  bool isCorrect(Object answer) {
    if (correct is List && answer is List) {
      final a = correct as List;
      if (a.length != answer.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != answer[i]) return false;
      }
      return true;
    }
    return correct == answer;
  }
}
