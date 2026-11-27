/// Tegneseriene i «Store øyeblikk». Egne tegninger laget med Krea 2 (generiske draktfarger,
/// ingen logoer). Bildene er uten tekst, så alt skrives her og kan oversettes.
/// Vurder likheten med virkelige spillere juridisk før butikklansering.
library;

import 'dart:ui' show Offset, Rect;

/// En rute i tegneserien. Plasseringer oppgis som andeler av bildet (0–1).
class ComicPanel {
  const ComicPanel(this.image, {this.caption, this.bubble, this.bubbleBox, this.tail, this.sound, this.soundAt});

  final String image;
  final String? caption;
  final String? bubble;
  final Rect? bubbleBox;

  /// Hvem som snakker (spissen på boblen).
  final Offset? tail;
  final String? sound;
  final Offset? soundAt;
}

class Comic {
  const Comic(this.header, this.panels, {this.player});

  /// Overskriften øverst på siden.
  final String header;
  final List<ComicPanel> panels;

  /// Spilleren det finnes et ekte (fritt lisensiert) bilde av i appen, eller null.
  final String? player;
}

const allComics = [maradona86, norway98, final99, panenka76, iniesta10, germany14];

const maradona86 = Comic('ÅRHUNDRETS MÅL · 1986', player: 'Diego Maradona', [
  ComicPanel('assets/comics/maradona_1.webp',
      caption: 'Mexico 1986. Raidet starter på egen halvdel …',
      sound: 'SVOSJ!',
      soundAt: Offset(0.74, 0.14)),
  ComicPanel('assets/comics/maradona_2.webp',
      caption: 'Den ene etter den andre blir stående igjen.',
      bubble: 'Hvor ble det av ballen?!',
      bubbleBox: Rect.fromLTRB(0.02, 0.03, 0.64, 0.28),
      tail: Offset(0.13, 0.60)),
  ComicPanel('assets/comics/maradona_3.webp',
      caption: 'Bare keeperen igjen …',
      bubble: 'Vent litt!',
      bubbleBox: Rect.fromLTRB(0.55, 0.30, 0.97, 0.45),
      tail: Offset(0.72, 0.63)),
  ComicPanel('assets/comics/maradona_4.webp',
      caption: 'Argentina leder 2–0 over England. Mange kaller det århundrets mål.',
      sound: 'MÅÅÅL!',
      soundAt: Offset(0.5, 0.13)),
]);

const norway98 = Comic('NORGE SLÅR BRASIL · 1998', player: 'Tore André Flo', [
  ComicPanel('assets/comics/norway98_1.webp',
      caption: 'Marseille 1998. Brasil leder, men Flo utligner til 1–1.',
      sound: 'PANG!',
      soundAt: Offset(0.66, 0.05)),
  ComicPanel('assets/comics/norway98_2.webp',
      caption: 'Like før slutt holdes Flo i trøya. Straffe!',
      bubble: 'Slipp trøya!',
      bubbleBox: Rect.fromLTRB(0.04, 0.02, 0.52, 0.20),
      tail: Offset(0.59, 0.24)),
  ComicPanel('assets/comics/norway98_3.webp',
      caption: 'Kjetil Rekdal tar ansvaret …',
      bubble: 'Rolig nå …',
      bubbleBox: Rect.fromLTRB(0.04, 0.04, 0.48, 0.21),
      tail: Offset(0.24, 0.31)),
  ComicPanel('assets/comics/norway98_4.webp',
      caption: '2–1! Norge slår Brasil.', sound: 'JAAA!', soundAt: Offset(0.22, 0.12)),
]);

const final99 = Comic('OVERTID I BARCELONA · 1999', player: 'Ole Gunnar Solskjær', [
  ComicPanel('assets/comics/final99_1.webp',
      caption: 'Barcelona 1999. Bayern leder 1–0, og det er overtid.',
      bubble: 'Tre minutter til!',
      bubbleBox: Rect.fromLTRB(0.46, 0.06, 0.98, 0.25),
      tail: Offset(0.88, 0.33)),
  ComicPanel('assets/comics/final99_2.webp',
      caption: 'Hjørnespark. Sheringham utligner!', sound: 'SVOSJ!', soundAt: Offset(0.25, 0.30)),
  ComicPanel('assets/comics/final99_3.webp',
      caption: 'Nytt hjørnespark. Solskjær strekker ut foten …',
      sound: 'PANG!',
      soundAt: Offset(0.22, 0.14)),
  ComicPanel('assets/comics/final99_4.webp',
      caption: '2–1! Manchester United vinner Champions League.',
      sound: 'MÅÅÅL!',
      soundAt: Offset(0.5, 0.07)),
]);

const panenka76 = Comic('STRAFFEN SOM FIKK ET NAVN · 1976', [
  ComicPanel('assets/comics/panenka76_1.webp',
      caption: 'Beograd 1976. EM-finalen skal avgjøres på straffer.',
      bubble: 'Se nøye på nå …',
      bubbleBox: Rect.fromLTRB(0.03, 0.02, 0.62, 0.21),
      tail: Offset(0.36, 0.27)),
  ComicPanel('assets/comics/panenka76_2.webp', caption: 'Antonín Panenka tar lang fart …'),
  ComicPanel('assets/comics/panenka76_3.webp',
      caption: '… og chipper ballen helt rolig midt i mål.',
      sound: 'PLOPP!',
      soundAt: Offset(0.72, 0.24)),
  ComicPanel('assets/comics/panenka76_4.webp',
      caption: 'Tsjekkoslovakia er europamestere!',
      bubble: 'Hva?!',
      bubbleBox: Rect.fromLTRB(0.66, 0.24, 0.98, 0.42),
      tail: Offset(0.81, 0.52)),
]);

const iniesta10 = Comic('MÅLET SOM GA VM-GULL · 2010', player: 'Andrés Iniesta', [
  ComicPanel('assets/comics/iniesta10_1.webp',
      caption: 'Johannesburg 2010. Ekstraomganger, og ingen har scoret.',
      bubble: 'Én sjanse til …',
      bubbleBox: Rect.fromLTRB(0.01, 0.03, 0.64, 0.21),
      tail: Offset(0.68, 0.25)),
  ComicPanel('assets/comics/iniesta10_2.webp',
      caption: 'Fàbregas finner Iniesta i feltet.', sound: 'SVOSJ!', soundAt: Offset(0.45, 0.14)),
  ComicPanel('assets/comics/iniesta10_3.webp',
      caption: 'Iniesta skyter på halv volley …', sound: 'PANG!', soundAt: Offset(0.5, 0.18)),
  ComicPanel('assets/comics/iniesta10_4.webp',
      caption: '1–0! Spania er verdensmester.', sound: 'MÅÅÅL!', soundAt: Offset(0.4, 0.10)),
]);

const germany14 = Comic('SJOKKET I BELO HORIZONTE · 2014', [
  ComicPanel('assets/comics/germany14_1.webp',
      caption: 'Belo Horizonte 2014. Tyskland tar tidlig ledelsen.',
      sound: 'PANG!',
      soundAt: Offset(0.28, 0.14)),
  ComicPanel('assets/comics/germany14_2.webp',
      caption: 'Så kommer fire mål på seks minutter.',
      bubble: 'Hvor mange nå?!',
      bubbleBox: Rect.fromLTRB(0.14, 0.13, 0.76, 0.32),
      tail: Offset(0.45, 0.55)),
  ComicPanel('assets/comics/germany14_3.webp', caption: 'Hjemmepublikummet tror ikke det de ser.'),
  ComicPanel('assets/comics/germany14_4.webp',
      caption: '7–1. En semifinale ingen glemmer.', sound: 'JAAA!', soundAt: Offset(0.82, 0.18)),
]);
