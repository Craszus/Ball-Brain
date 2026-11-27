/// Hvilken leksjon i Fotballskolen som passer til et bommet regelspørsmål.
/// Rekkefølgen betyr noe: det mest spesifikke først.
const _words = <(String, List<String>)>[
  ('var', []),
  ('offside', ['offside']),
  ('hands', ['hands', 'med hånden', 'armen']),
  ('keeper', ['keeper', 'målvakt']),
  ('fouls', ['straffespark', 'frispark', 'kort', 'fordel', 'muren', 'utvis']),
  ('out', ['innkast', 'hjørnespark', 'målspark', 'dommerball', 'mållinj', 'sidelinj']),
  ('pitch', ['banen', 'straffefelt', 'målfelt', 'omgang', 'minutter']),
];

/// Leksjonens id, eller null når ingen passer.
String? lessonFor(String prompt) {
  final text = '${prompt.toLowerCase()} ';
  for (final (id, words) in _words) {
    // «VAR» må stå med store bokstaver, ellers treffer ordet «var»
    if (id == 'var') {
      if (RegExp(r'\bVAR\b').hasMatch(prompt)) return id;
      continue;
    }
    if (words.any(text.contains)) return id;
  }
  return null;
}
