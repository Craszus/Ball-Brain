/// Innholdet i «Fotballskolen – Forstå spillet».
///
/// Banen måles i meter: x langs banen 0–105 (blått lag angriper mot x = 105),
/// y på tvers 0–68. Norske tekster er nøkler for oversettelsene.
/// Reglene er skrevet med egne ord etter IFABs regler for 2026/27 og bør
/// gjennomgås hver sommer (nye regler gjelder fra 1. juli).
library;

import 'dart:ui' show Offset, Rect;

import 'comics.dart';

import 'lessons_more.dart';

enum Side { blue, red, keeper }

class Player {
  const Player(this.side, this.label, this.x, this.y);

  final Side side;
  final String label;
  final double x;
  final double y;

  Offset get at => Offset(x, y);
}

sealed class SchoolTask {
  const SchoolTask();
}

/// Velg ett av svarene.
class Choose extends SchoolTask {
  const Choose(this.options, this.correct);

  final List<String> options;
  final int correct;
}

/// Trykk på den riktige spilleren (nummer i spillerlisten).
class TapPlayer extends SchoolTask {
  const TapPlayer(this.correct, {this.also = const {}});

  final int correct;

  /// Flere spillere som også er riktige.
  final Set<int> also;

  bool isRight(int i) => i == correct || also.contains(i);
}

/// Sett et merke på et av punktene.
class PlaceSpot extends SchoolTask {
  const PlaceSpot(this.spots, {this.tolerance = 3.5});

  final List<Offset> spots;
  final double tolerance;
}

/// Sett merket på en linje tvers over banen.
class PlaceLine extends SchoolTask {
  const PlaceLine(this.x, {this.tolerance = 2});

  final double x;
  final double tolerance;
}

/// Sett merket inne i et område (x langs banen, y på tvers), eventuelt utenom [except].
class PlaceArea extends SchoolTask {
  const PlaceArea(this.areas, {this.except});

  /// Merket er riktig i et av områdene.
  final List<Rect> areas;
  final Rect? except;
}

/// Om merket [at] (meter) er riktig for en merke-oppgave.
bool markIsRight(SchoolTask task, Offset at) => switch (task) {
      PlaceSpot(:final spots, :final tolerance) =>
        spots.any((s) => (s - at).distance <= tolerance),
      PlaceLine(:final x, :final tolerance) => (at.dx - x).abs() <= tolerance,
      PlaceArea(:final areas, :final except) =>
        areas.any((a) => a.contains(at)) && !(except?.contains(at) ?? false),
      _ => false,
    };

class Situation {
  const Situation({
    required this.prompt,
    required this.task,
    required this.explain,
    this.players = const [],
    this.ball,
    this.shot,
    this.from = 48,
    this.line,
    this.runs = const {},
    this.pitch = true,
    this.comic,
    this.tipTitle,
    this.tip,
  });

  final String prompt;
  final SchoolTask task;

  /// Forklaringen etter svaret (kort).
  final String explain;
  final List<Player> players;
  final Offset? ball;

  /// Pil fra ballen dit den slås.
  final Offset? shot;

  /// Banen vises fra denne x-verdien og inn til målet (0 = hele banen).
  final double from;

  /// Offsidelinja (tegnes i fasiten).
  final double? line;

  /// Løp som vises i animasjonen etter svaret: spillernummer → dit spilleren løper.
  final Map<int, Offset> runs;

  /// Falsk: spørsmålet trenger ingen bane.
  final bool pitch;

  /// Tegneserien om øyeblikket, som vises når man har svart.
  final Comic? comic;

  /// Lite faktakort sammen med forklaringen.
  final String? tipTitle;
  final String? tip;
}

class Lesson {
  const Lesson(this.id, this.title, this.subtitle, this.rule, this.fact, this.situations);

  final String id;
  final String title;
  final String subtitle;

  /// Hvilken regel innholdet bygger på (for den årlige gjennomgangen).
  final String rule;

  /// «Visste du at?» til slutt.
  final String fact;
  final List<Situation> situations;
}

const _yesNo = ['Ja', 'Nei'];

const lessons = <Lesson>[
  ..._basicLessons,
  ...moreLessons,
];

const _basicLessons = <Lesson>[
  Lesson(
    'pitch',
    'Banen',
    'Linjer, felt og hvordan en kamp går',
    'Regel 1, 3 og 7',
    'Banen har ikke én fast størrelse. I internasjonale kamper er den 100–110 meter lang og 64–75 meter bred.',
    [
      Situation(
        prompt: 'Sett merket der et straffespark tas fra',
        task: PlaceSpot([Offset(94, 34)], tolerance: 3),
        explain: 'Straffemerket ligger 11 meter fra mållinja, midt foran målet.',
      ),
      Situation(
        prompt: 'Sett merket der kampen starter',
        task: PlaceSpot([Offset(52.5, 34)], tolerance: 4),
        from: 0,
        explain: 'Avsparket tas fra midten av banen, både ved start og etter hver scoring.',
      ),
      Situation(
        prompt: 'Trykk inne i målfeltet',
        task: PlaceArea([Rect.fromLTRB(99.5, 24.84, 105, 43.16)]),
        explain: 'Målfeltet er det lille feltet rett foran målet. Herfra tas målsparket.',
      ),
      Situation(
        prompt: 'Trykk i straffefeltet, men utenfor målfeltet',
        task: PlaceArea([Rect.fromLTRB(88.5, 13.84, 105, 54.16)],
            except: Rect.fromLTRB(99.5, 24.84, 105, 43.16)),
        explain: 'I straffefeltet kan keeperen bruke hendene, og her kan det bli straffespark.',
      ),
      Situation(
        prompt: 'Sett merket der et hjørnespark tas fra',
        task: PlaceSpot([Offset(105, 0), Offset(105, 68)], tolerance: 4),
        explain: 'Hjørnesparket tas fra kvartsirkelen i hjørnet, på den siden ballen gikk ut.',
      ),
      Situation(
        prompt: 'Hvor lang er en vanlig kamp?',
        task: Choose(['2 × 45 minutter', '2 × 30 minutter', '3 × 30 minutter', '90 minutter uten pause'], 0),
        from: 0,
        explain: 'To omganger på 45 minutter. Dommeren legger til tid for stopp i spillet.',
      ),
      Situation(
        prompt: 'Hvor mange spillere har hvert lag på banen?',
        task: Choose(['11, medregnet keeperen', '10 pluss keeper og kaptein', '12', '9'], 0),
        from: 0,
        explain: 'Elleve, og én av dem er keeper. Med færre enn sju kan kampen ikke spilles.',
      ),
    ],
  ),
  Lesson(
    'out',
    'Ute eller inne?',
    'Innkast, målspark, hjørnespark og mål',
    'Regel 9, 10, 12, 15–17 (2026/27)',
    'En ball som treffer dommeren kan stoppe spillet: går den i mål eller starter et angrep, blir det dommerball.',
    [
      Situation(
        prompt: 'Ballen ligger oppå sidelinja. Er den ute?',
        task: Choose(_yesNo, 1),
        ball: Offset(78, 0),
        explain: 'Nei. Ballen er ute først når hele ballen har passert hele linja.',
      ),
      Situation(
        prompt: 'Rødt lag var sist på ballen, og den gikk hit. Hva nå?',
        task: Choose(['Innkast til blått lag', 'Innkast til rødt lag', 'Hjørnespark', 'Målspark'], 0),
        ball: Offset(78, -2.5),
        players: [Player(Side.red, '4', 76, 5), Player(Side.blue, '7', 72, 10)],
        explain: 'Hele ballen er over sidelinja. Laget som ikke var sist på ballen får innkast.',
      ),
      Situation(
        prompt: 'Blått lag skyter, og ballen går utenfor målet. Hva nå?',
        task: Choose(['Målspark til rødt lag', 'Hjørnespark til blått lag', 'Innkast', 'Dommerball'], 0),
        ball: Offset(107, 22),
        players: [Player(Side.blue, '9', 90, 30), Player(Side.keeper, 'K', 103, 34)],
        explain: 'Angriperne var sist på ballen over mållinja. Da blir det målspark.',
      ),
      Situation(
        prompt: 'Keeperen slår ballen ut over egen mållinje. Hva nå?',
        task: Choose(['Hjørnespark til blått lag', 'Målspark', 'Innkast til blått lag', 'Straffespark'], 0),
        ball: Offset(107, 24),
        players: [Player(Side.keeper, 'K', 104, 29), Player(Side.blue, '9', 93, 30)],
        explain: 'Forsvarende lag var sist på ballen. Da får angriperne hjørnespark.',
      ),
      Situation(
        prompt: 'Ballen ligger på mållinja mellom stengene. Er det mål?',
        task: Choose(_yesNo, 1),
        ball: Offset(105, 34),
        players: [Player(Side.keeper, 'K', 102, 34)],
        explain: 'Nei. Hele ballen må være over hele mållinja før det er mål.',
      ),
      Situation(
        prompt: 'Keeperen holder ballen i hendene i mer enn åtte sekunder. Hva dømmes?',
        task: Choose(['Hjørnespark til motstanderen', 'Straffespark', 'Indirekte frispark', 'Ingenting'], 0),
        ball: Offset(98, 34),
        players: [Player(Side.keeper, 'K', 98, 34), Player(Side.blue, '9', 85, 30)],
        explain: 'Dommeren teller ned de siste fem sekundene med hånden. Går tiden ut, blir det hjørnespark.',
      ),
      Situation(
        prompt: 'Et lag somler med målsparket, og dommerens nedtelling på fem sekunder går ut. Hva skjer?',
        task: Choose(['Hjørnespark til motstanderen', 'Målsparket tas på nytt', 'Straffespark', 'Innkast'], 0),
        ball: Offset(100, 28),
        players: [Player(Side.keeper, 'K', 103, 32)],
        explain: 'Nytt fra 2026/27. Somles det med et innkast, får motstanderen innkastet i stedet.',
      ),
    ],
  ),
  Lesson(
    'offside',
    'Offside',
    'Den mest omdiskuterte regelen, forklart på banen',
    'Regel 11 (2026/27)',
    'Fram til 1925 måtte tre motspillere være mellom deg og mållinja. Da kravet ble to, ble det scoret mange flere mål.',
    [
      Situation(
        prompt: 'Trykk på den blå spilleren som står i offsideposisjon',
        task: TapPlayer(1),
        players: _offside1,
        ball: Offset(62, 30),
        line: 78,
        explain: 'Nummer 9 står to meter foran den nest siste motspilleren.',
        tipTitle: 'Posisjonen',
        tip: 'Offsideposisjon: på motstanderens halvdel og nærmere mållinja enn både ballen og den nest siste motspilleren. Hender og armer teller ikke.',
      ),
      Situation(
        prompt: 'Samme pasning til nummer 9. Er det offside?',
        task: Choose(_yesNo, 1),
        players: [
          Player(Side.blue, '8', 62, 30),
          Player(Side.blue, '9', 78, 40),
          Player(Side.blue, '7', 74, 20),
          Player(Side.red, '2', 78, 26),
          Player(Side.red, '3', 76, 52),
          Player(Side.red, '4', 75, 60),
          Player(Side.red, '5', 77, 14),
          Player(Side.keeper, 'K', 103, 34),
        ],
        ball: Offset(62, 30),
        shot: Offset(88, 40),
        runs: {1: Offset(88, 40)},
        line: 78,
        explain: 'På linje med den nest siste motspilleren er ikke offside.',
        tipTitle: 'Øyeblikket',
        tip: 'Det som teller er hvor du står idet medspilleren slår ballen, ikke når du får den.',
      ),
      Situation(
        prompt: 'En lang ball slås til blå nummer 9. Er det offside?',
        task: Choose(_yesNo, 1),
        from: 30,
        players: [
          Player(Side.blue, '8', 38, 30),
          Player(Side.blue, '9', 51, 38),
          Player(Side.red, '2', 57, 16),
          Player(Side.red, '3', 59, 30),
          Player(Side.red, '4', 58, 46),
          Player(Side.red, '5', 60, 56),
          Player(Side.keeper, 'K', 90, 34),
        ],
        ball: Offset(38, 30),
        shot: Offset(80, 40),
        runs: {1: Offset(80, 40)},
        explain: 'Nummer 9 sto på egen halvdel da ballen ble slått. Da kan man ikke være offside.',
      ),
      Situation(
        prompt: 'Nummer 8 legger ballen bakover, og nummer 9 scorer. Er det mål?',
        task: Choose(_yesNo, 0),
        from: 70,
        players: [
          Player(Side.blue, '8', 98, 22),
          Player(Side.blue, '9', 95, 38),
          Player(Side.red, '2', 91, 30),
          Player(Side.red, '3', 89, 46),
          Player(Side.keeper, 'K', 101, 30),
        ],
        ball: Offset(98, 22),
        shot: Offset(95, 37),
        runs: {1: Offset(97, 37)},
        explain: 'Nummer 9 er foran forsvarerne, men bak ballen. Da er det ikke offside.',
      ),
      Situation(
        prompt: 'Keeperen har løpt ut. Sett merket på offsidelinja',
        task: PlaceLine(89),
        from: 70,
        players: [
          Player(Side.blue, '8', 80, 42),
          Player(Side.blue, '9', 96, 30),
          Player(Side.keeper, 'K', 89, 36),
          Player(Side.red, '2', 104, 35),
          Player(Side.red, '3', 84, 24),
          Player(Side.red, '4', 83, 52),
        ],
        ball: Offset(80, 42),
        line: 89,
        explain: 'Linja følger den nest siste motspilleren. Her er det keeperen, så nummer 9 er offside.',
        tipTitle: 'Involvert',
        tip: 'Å stå i offsideposisjon er ikke forbudt. Det blir offside først når du spiller ballen, hindrer en motspiller eller drar nytte av en retur.',
      ),
      Situation(
        prompt: 'Nummer 8 skyter og scorer. Nummer 9 står langt ute på kanten. Er det mål?',
        task: Choose(_yesNo, 0),
        from: 70,
        players: [
          Player(Side.blue, '8', 84, 30),
          Player(Side.blue, '9', 97, 60),
          Player(Side.red, '2', 92, 30),
          Player(Side.keeper, 'K', 103, 34),
        ],
        ball: Offset(84, 30),
        shot: Offset(106, 32),
        explain: 'Nummer 9 står i offsideposisjon, men gjør ingenting og er ikke i veien.',
      ),
      Situation(
        prompt: 'Samme skudd, men nummer 9 står rett foran keeperen. Er det mål?',
        task: Choose(_yesNo, 1),
        from: 70,
        players: [
          Player(Side.blue, '8', 84, 30),
          Player(Side.blue, '9', 99, 33),
          Player(Side.red, '2', 92, 24),
          Player(Side.keeper, 'K', 103, 34),
        ],
        ball: Offset(84, 30),
        shot: Offset(106, 32),
        explain: 'Nummer 9 stenger utsikten til keeperen. Det er offside og indirekte frispark.',
      ),
      Situation(
        prompt: 'Keeperen redder, og returen går til nummer 9 som scorer. Er det mål?',
        task: Choose(_yesNo, 1),
        from: 70,
        players: [
          Player(Side.blue, '8', 86, 36),
          Player(Side.blue, '9', 98, 44),
          Player(Side.red, '2', 95, 28),
          Player(Side.keeper, 'K', 103, 35),
        ],
        ball: Offset(86, 36),
        shot: Offset(103, 36),
        explain: 'Nummer 9 sto i offsideposisjon da skuddet gikk. En redning nullstiller ikke offside.',
        tipTitle: 'Husk også',
        tip: 'Man kan ikke være offside direkte fra innkast, målspark eller hjørnespark.',
      ),
    ],
  ),
  Lesson(
    'fouls',
    'Frispark, straffe og kort',
    'Du er dommeren: hva dømmer du?',
    'Regel 12–14 (2026/27)',
    'Gule og røde kort kom først i VM i 1970. Før det ga dommeren advarsler og utvisninger muntlig.',
    [
      Situation(
        prompt: 'Rød spiller feller blå nummer 9 her. Hva dømmer du?',
        task: Choose(['Straffespark', 'Direkte frispark', 'Indirekte frispark', 'Hjørnespark'], 0),
        players: [Player(Side.blue, '9', 95, 40), Player(Side.red, '4', 93, 41), Player(Side.keeper, 'K', 103, 34)],
        ball: Offset(96, 38),
        explain: 'Fellingen skjer inne i forsvarernes straffefelt. Da blir det straffespark.',
      ),
      Situation(
        prompt: 'Den samme fellingen skjer her. Hva dømmer du nå?',
        task: Choose(['Direkte frispark', 'Straffespark', 'Indirekte frispark', 'Innkast'], 0),
        players: [Player(Side.blue, '9', 83, 40), Player(Side.red, '4', 81, 41), Player(Side.keeper, 'K', 103, 34)],
        ball: Offset(84, 38),
        explain: 'Utenfor straffefeltet blir det direkte frispark. Da kan man skyte rett i mål.',
      ),
      Situation(
        prompt: 'Frispark rett utenfor feltet. Hvor langt unna ballen må muren stå?',
        task: Choose(['9,15 meter', '5 meter', '11 meter', '16,5 meter'], 0),
        players: [
          Player(Side.blue, '10', 82, 34),
          Player(Side.red, '2', 92, 31),
          Player(Side.red, '3', 92, 34),
          Player(Side.red, '4', 92, 37),
          Player(Side.keeper, 'K', 103, 38),
        ],
        ball: Offset(83, 34),
        explain: '9,15 meter, like langt som radien i midtsirkelen.',
      ),
      Situation(
        prompt: 'Hva er spesielt med et indirekte frispark?',
        task: Choose([
          'En annen spiller må røre ballen før det kan bli mål',
          'Det må slås bakover',
          'Keeperen kan ikke ta det',
          'Det tas fra midtbanen'
        ], 0),
        explain: 'Dommeren holder armen rett opp til en annen spiller har rørt ballen.',
      ),
      Situation(
        prompt: 'Blå nummer 9 er alene med keeperen. Siste forsvarer holder igjen i trøya. Hva dømmer du?',
        task: Choose(['Rødt kort og direkte frispark', 'Gult kort og frispark', 'Bare frispark', 'Straffespark'], 0),
        players: [Player(Side.blue, '9', 82, 34), Player(Side.red, '5', 80.5, 35), Player(Side.keeper, 'K', 100, 34)],
        ball: Offset(84, 33),
        explain: 'En åpenbar målsjanse ble hindret ved å holde. Det gir rødt kort.',
      ),
      Situation(
        prompt: 'Samme sjanse inne i feltet. Forsvareren går etter ballen, men treffer beina. Hva dømmer du?',
        task: Choose(['Straffespark og gult kort', 'Straffespark og rødt kort', 'Bare gult kort', 'Direkte frispark'], 0),
        players: [Player(Side.blue, '9', 94, 34), Player(Side.red, '5', 93, 36), Player(Side.keeper, 'K', 102, 34)],
        ball: Offset(96, 33),
        explain: 'Laget får sjansen tilbake med straffesparket. Var det et ærlig forsøk på ballen, holder det med gult.',
      ),
      Situation(
        prompt: 'En spiller får sitt andre gule kort i samme kamp. Hva skjer?',
        task: Choose(['Utvisning, og laget spiller med en mindre', 'Ti minutter på benken', 'Ingenting før neste kamp', 'Spilleren kan byttes ut med en annen'], 0),
        explain: 'To gule blir rødt. Spilleren må forlate banen, og ingen kan komme inn i stedet.',
      ),
      Situation(
        prompt: 'Blått lag blir felt, men har fortsatt ballen og en god sjanse. Hva gjør en god dommer?',
        task: Choose(['Lar spillet gå', 'Blåser med en gang', 'Gir dommerball', 'Stopper for å vise kort'], 0),
        players: [Player(Side.blue, '9', 84, 30), Player(Side.blue, '7', 88, 44), Player(Side.keeper, 'K', 102, 34)],
        ball: Offset(86, 32),
        explain: 'Det kalles fordel. Et eventuelt kort kan deles ut ved neste stopp.',
      ),
    ],
  ),
  Lesson(
    'var',
    'Dommerteamet og VAR',
    'Hvem gjør hva, og når kan VAR gripe inn?',
    'Regel 5, 6 og VAR-protokollen (2026/27)',
    'VAR ble brukt i et VM-sluttspill for menn for første gang i 2018.',
    [
      Situation(
        prompt: 'Hvem tar den endelige avgjørelsen i en kamp?',
        task: Choose(['Hoveddommeren', 'VAR', 'Assistentdommeren', 'Kampdelegaten'], 0),
        from: 0,
        explain: 'VAR og assistentene gir råd. Det er alltid hoveddommeren som bestemmer.',
      ),
      Situation(
        prompt: 'Trykk på stedet langs kanten der en assistentdommer løper',
        task: PlaceArea([Rect.fromLTRB(0, -4, 105, 2.5), Rect.fromLTRB(0, 65.5, 105, 72)]),
        from: 0,
        explain: 'Assistentene løper langs sidelinjene og flagger blant annet for offside og ball ute.',
      ),
      Situation(
        prompt: 'Hvilken av disse kan VAR hjelpe dommeren med?',
        task: Choose(['Om det skulle vært straffespark', 'Et innkast på midtbanen', 'Et vanlig frispark', 'Hvem som skal ta avsparket'], 0),
        explain: 'VAR brukes ved mål, straffespark, direkte røde kort og når feil spiller får kort.',
        tipTitle: 'Nytt fra 2026/27',
        tip: 'VAR kan også se på et rødt kort som kommer av et klart feil gult kort nummer to. Turneringer kan i tillegg la VAR rette et klart feil hjørnespark.',
      ),
      Situation(
        prompt: 'Straffesparket var kanskje litt billig, men ikke klart feil. Hva skjer?',
        task: Choose(['Avgjørelsen på banen står', 'VAR omgjør den', 'Det blir dommerball', 'Kapteinene bestemmer'], 0),
        explain: 'VAR griper bare inn ved klare og åpenbare feil, eller alvorlige hendelser dommeren ikke så.',
      ),
      Situation(
        prompt: 'Et mål scores, men målscoreren var i offside. Kan VAR gripe inn?',
        task: Choose(_yesNo, 0),
        players: [Player(Side.blue, '9', 93, 30), Player(Side.red, '4', 90, 36), Player(Side.keeper, 'K', 103, 34)],
        ball: Offset(106, 33),
        line: 90,
        explain: 'Ja. Alle mål sjekkes, også for offside og forseelser i angrepet som ledet fram til målet.',
      ),
      Situation(
        prompt: 'Dommeren tegner en firkant i lufta med hendene. Hva betyr det?',
        task: Choose(['En VAR-vurdering på skjermen', 'Bytte av spiller', 'Tilleggstid', 'Drikkepause'], 0),
        explain: 'Det er TV-tegnet. Dommeren viser det når en avgjørelse vurderes på skjermen.',
      ),
    ],
  ),
];

const _offside1 = [
  Player(Side.blue, '8', 62, 30),
  Player(Side.blue, '9', 80, 40),
  Player(Side.blue, '7', 74, 20),
  Player(Side.red, '2', 78, 26),
  Player(Side.red, '3', 76, 52),
  Player(Side.red, '4', 75, 60),
  Player(Side.red, '5', 77, 14),
  Player(Side.keeper, 'K', 103, 34),
];
