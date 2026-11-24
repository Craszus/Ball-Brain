"""Genererer seed-spørsmål til Ball Brain.

Kjør:  python tools/make_seed.py
Skriver:
  assets/seed/questions.json   (leses av appen i offline-modus)
  supabase/seed.sql            (kjøres i Supabase SQL Editor når databasen er klar)

Rediger spørsmålene her, ikke i de genererte filene.
quiz-format: (spørsmål, riktig svar, [gale svar], vanskelighet 1-5, kategori)
sort-format: (oppgave, [elementer i RIKTIG rekkefølge], vanskelighet, kategori)
"""
import hashlib
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

QUIZ = [
    # --- Regler ---
    ("Kan en spiller bli satt offside direkte fra et innkast?", "Nei", ["Ja"], 1, "Regler"),
    ("Kan en spiller bli satt offside direkte fra et målspark?", "Nei", ["Ja"], 1, "Regler"),
    ("Kan en spiller bli satt offside direkte fra et hjørnespark?", "Nei", ["Ja"], 1, "Regler"),
    ("Kan det scores direkte mål på avspark?", "Ja", ["Nei"], 2, "Regler"),
    ("Kan det scores direkte mål på hjørnespark?", "Ja", ["Nei"], 1, "Regler"),
    ("Kan en spiller være i offside-posisjon i sin egen banehalvdel?", "Nei", ["Ja"], 2, "Regler"),
    ("Hvor mange spillere må et lag minst ha på banen for at kampen skal kunne spilles?", "7", ["6", "8", "9"], 2, "Regler"),
    ("Hvor bredt er et fotballmål (innvendig)?", "7,32 meter", ["7,00 meter", "7,50 meter", "8,00 meter"], 2, "Regler"),
    ("Hvor høyt er et fotballmål (innvendig)?", "2,44 meter", ["2,30 meter", "2,50 meter", "2,60 meter"], 2, "Regler"),
    ("Hvor langt fra mållinja ligger straffemerket?", "11 meter", ["9 meter", "10 meter", "12 meter"], 1, "Regler"),
    ("Hvor langt unna ballen må muren stå ved et frispark?", "9,15 meter", ["7 meter", "8 meter", "10 meter"], 2, "Regler"),
    ("Hvor stort er målfeltet ut fra mållinja?", "5,5 meter", ["4,5 meter", "6,5 meter", "7,5 meter"], 3, "Regler"),
    ("Hvor langt ut fra mållinja går straffefeltet?", "16,5 meter", ["11 meter", "18 meter", "20 meter"], 3, "Regler"),
    ("Hva er tillatt banelengde i internasjonale kamper?", "100–110 meter", ["90–100 meter", "110–120 meter", "85–95 meter"], 4, "Regler"),
    ("Hvor lang er ordinær spilletid i en seniorkamp?", "2 × 45 minutter", ["2 × 40 minutter", "2 × 50 minutter", "3 × 30 minutter"], 1, "Regler"),
    ("Hvor lang er hver omgang av forlengning?", "15 minutter", ["10 minutter", "20 minutter", "5 minutter"], 1, "Regler"),
    ("Hvor lang kan pausen mellom omgangene maksimalt være?", "15 minutter", ["10 minutter", "20 minutter", "25 minutter"], 3, "Regler"),
    ("Hvor mange spillere har hvert lag på banen, inkludert keeper?", "11", ["10", "12", "9"], 1, "Regler"),
    ("Hvor mange spark får hvert lag først i en straffesparkkonkurranse?", "5", ["3", "4", "7"], 1, "Regler"),
    ("Hva skjer når en spiller får to gule kort i samme kamp?", "Utvisning (rødt kort)", ["Bare en ny advarsel", "Frispark mot laget", "Spilleren må bytte plass med keeperen"], 1, "Regler"),
    ("Hvilken farge har kortet for advarsel?", "Gult", ["Rødt", "Grønt", "Oransje"], 1, "Regler"),
    ("Hva er straffen når en utespiller bevisst håndsfeste ballen i eget straffefelt?", "Straffespark", ["Indirekte frispark", "Dommerball", "Innkast"], 1, "Regler"),
    ("Hvem får innkast når ballen går ut over sidelinjen?", "Motstanderen til laget som berørte ballen sist", ["Laget som berørte ballen sist", "Hjemmelaget", "Laget med færrest spillere"], 1, "Regler"),
    ("Hva er straffen når keeperen tar opp en bevisst tilbakepasning fra en medspiller med foten?", "Indirekte frispark", ["Direkte frispark", "Straffespark", "Gult kort"], 3, "Regler"),
    ("Hva kreves av keeperen ved et straffespark?", "Minst én fot på eller over mållinja", ["Begge føttene på mållinja", "Stå i målfeltet", "Stå én meter foran mållinja"], 3, "Regler"),
    ("Hva kjennetegner et indirekte frispark?", "Ballen må berøres av en annen spiller før det kan bli mål", ["Bare keeperen kan ta det", "Det kan bare tas i straffefeltet", "Muren kan stå nærmere enn 5 meter"], 2, "Regler"),
    ("Hva får en spiller som tar av seg trøya under målfeiring?", "Gult kort", ["Rødt kort", "Ingenting", "Frispark mot laget"], 2, "Regler"),
    ("Hvor mange motstandere må være like nær eller nærmere mållinja enn en angriper, for at angriperen ikke skal være i offside-posisjon?", "To", ["En", "Tre", "Ingen"], 3, "Regler"),
    ("Hva brukes for å gjenoppta spillet når dommeren stanser det uten at det har skjedd et regelbrudd?", "Dommerball", ["Frispark", "Innkast", "Straffespark"], 2, "Regler"),
    ("Ballen går ut over mållinja etter at en forsvarsspiller berørte den sist. Hva dømmes?", "Hjørnespark", ["Målspark", "Innkast", "Dommerball"], 1, "Regler"),
    ("Ballen går ut over mållinja etter at en angriper berørte den sist. Hva dømmes?", "Målspark", ["Hjørnespark", "Innkast", "Frispark"], 1, "Regler"),
    ("Hvem tar avspark etter at et lag har scoret?", "Laget som slapp inn målet", ["Laget som scoret", "Det avgjøres ved myntkast", "Keeperen til laget som scoret"], 1, "Regler"),
    ("Kan et lag erstatte en spiller som er vist rødt kort?", "Nei, laget må spille med færre", ["Ja, med en innbytter", "Ja, etter ti minutter"], 1, "Regler"),
    ("Hvilket kort får en spiller som i eget straffefelt hindrer en åpenbar målsjanse ved å felle en motspiller, mens han forsøker å spille ballen?", "Gult kort", ["Rødt kort", "Ingen kort", "Grønt kort"], 4, "Regler"),
    ("Når regnes en ball som mål?", "Hele ballen har passert hele mållinja mellom stolpene og under tverrliggeren", ["Ballen har rørt nettet", "Halve ballen har passert mållinja", "Ballen har rørt stolpen"], 1, "Regler"),
    ("Må et straffespark sparkes fremover?", "Ja", ["Nei"], 2, "Regler"),
    ("Hvilken situasjon kan VAR ikke gripe inn i?", "Vanlig gult kort", ["Mål", "Straffespark", "Direkte rødt kort"], 3, "Regler"),
    ("Hvem tar den endelige avgjørelsen etter en VAR-sjekk?", "Kampens hoveddommer", ["VAR-dommeren", "Fjerdedommeren", "Ligaens kampleder"], 2, "Regler"),
    ("Når er ballen i spill ved et frispark?", "Når den er sparket og beveger seg", ["Når dommeren fløyter", "Når ballen har rørt en annen spiller", "Etter tre sekunder"], 3, "Regler"),
    ("Kan keeperen ta ballen med hendene utenfor eget straffefelt?", "Nei, da er det håndsregelbrudd", ["Ja, så lenge han er i egen banehalvdel", "Ja, hvis ingen motstander er nær"], 2, "Regler"),
    ("Kan dommeren vise gult kort til en innbytter på benken?", "Ja", ["Nei"], 2, "Regler"),
    ("Må ballen ligge i ro når et frispark tas?", "Ja", ["Nei"], 1, "Regler"),
    ("Hva betyr «fordel» (advantage) når dommeren viser det?", "Spillet får gå videre fordi laget som ble utsatt for regelbrudd har nytte av det", ["Laget får et ekstra frispark", "Laget får en ekstra innbytter", "Dommeren stopper klokka"], 2, "Regler"),
    ("Hvordan skal et innkast utføres?", "Med begge hender, bak og over hodet, med begge føtter på bakken", ["Med én hånd fra siden", "Med foten", "Med hodet"], 1, "Regler"),
    ("Må ballen forlate straffefeltet etter et målspark før en lagkamerat kan røre den?", "Nei", ["Ja"], 3, "Regler"),
    ("Hva er riktig om hjørnespark og offside?", "Det er ingen offside direkte fra hjørnespark", ["Offside gjelder alltid", "Bare keeperen kan stå offside", "Offside gjelder bare i andre omgang"], 2, "Regler"),
    # --- VM-historie ---
    ("Hvem vant VM i fotball for menn i 2022?", "Argentina", ["Frankrike", "Kroatia", "Marokko"], 1, "VM-historie"),
    ("Hvem vant VM i 2018?", "Frankrike", ["Kroatia", "Belgia", "England"], 1, "VM-historie"),
    ("Hvem vant VM i 2014?", "Tyskland", ["Argentina", "Nederland", "Brasil"], 1, "VM-historie"),
    ("Hvem vant VM i 2010?", "Spania", ["Nederland", "Tyskland", "Uruguay"], 1, "VM-historie"),
    ("Hvem vant VM i 2006?", "Italia", ["Frankrike", "Tyskland", "Portugal"], 1, "VM-historie"),
    ("Hvem vant VM i 2002?", "Brasil", ["Tyskland", "Tyrkia", "Sør-Korea"], 2, "VM-historie"),
    ("Hvem vant VM i 1998?", "Frankrike", ["Brasil", "Kroatia", "Italia"], 1, "VM-historie"),
    ("Hvem vant VM i 1990?", "Vest-Tyskland", ["Argentina", "Italia", "England"], 3, "VM-historie"),
    ("Hvem vant VM i 1986?", "Argentina", ["Vest-Tyskland", "Belgia", "England"], 2, "VM-historie"),
    ("Hvem vant VM i 1966?", "England", ["Vest-Tyskland", "Brasil", "Portugal"], 2, "VM-historie"),
    ("Hvilket land vant det første VM i 1930?", "Uruguay", ["Argentina", "Brasil", "Italia"], 3, "VM-historie"),
    ("Hvilket land har flest VM-titler hos menn?", "Brasil", ["Tyskland", "Italia", "Argentina"], 1, "VM-historie"),
    ("Hvem er VM-historiens toppscorer hos menn med 16 mål?", "Miroslav Klose", ["Ronaldo Nazário", "Gerd Müller", "Lionel Messi"], 3, "VM-historie"),
    ("Hvem scoret 13 mål i VM 1958, en rekord for én turnering?", "Just Fontaine", ["Pelé", "Gerd Müller", "Eusébio"], 4, "VM-historie"),
    ("Hvilke land er VM-verter i 2026?", "USA, Canada og Mexico", ["Mexico, Brasil og Argentina", "USA, Canada og Costa Rica", "Spania, Portugal og Marokko"], 2, "VM-historie"),
    ("Hvem scoret «Guds hånd»-målet mot England i VM 1986?", "Diego Maradona", ["Jorge Valdano", "Mario Kempes", "Diego Simeone"], 1, "VM-historie"),
    ("Hvem ble utvist for et hodestøt mot Marco Materazzi i VM-finalen 2006?", "Zinedine Zidane", ["Thierry Henry", "Patrick Vieira", "Franck Ribéry"], 1, "VM-historie"),
    ("Hvilket land slo Brasil i den avgjørende VM-kampen i 1950 på Maracanã?", "Uruguay", ["Argentina", "Italia", "Sverige"], 3, "VM-historie"),
    ("Brasil tapte 1–7 i VM-semifinalen 2014. Mot hvem?", "Tyskland", ["Argentina", "Nederland", "Frankrike"], 1, "VM-historie"),
    # --- EM-historie ---
    ("Hvem vant EM i 2024?", "Spania", ["England", "Frankrike", "Tyskland"], 1, "EM-historie"),
    ("Hvem vant EM som ble spilt i 2021 (EM 2020)?", "Italia", ["England", "Spania", "Danmark"], 1, "EM-historie"),
    ("Hvem vant EM i 2016?", "Portugal", ["Frankrike", "Tyskland", "Wales"], 1, "EM-historie"),
    ("Hvem vant EM i 2004?", "Hellas", ["Portugal", "Tsjekkia", "Frankrike"], 2, "EM-historie"),
    ("Hvem vant EM i 1992?", "Danmark", ["Tyskland", "Sverige", "Nederland"], 3, "EM-historie"),
    ("Hvem vant EM i 1988?", "Nederland", ["Sovjetunionen", "Italia", "Vest-Tyskland"], 4, "EM-historie"),
    # --- Klubb- og spillerhistorie ---
    ("Hvilket lag vant Champions League-finalen 2005 etter å ha ligget under 0–3 i pausen?", "Liverpool", ["AC Milan", "Chelsea", "Barcelona"], 2, "Klubbfotball"),
    ("Hvilket lag vant Champions League-finalen 1999 med to mål på tilleggstid?", "Manchester United", ["Bayern München", "Juventus", "Real Madrid"], 2, "Klubbfotball"),
    ("Hvilket lag gikk ubeseiret gjennom Premier League-sesongen 2003–04?", "Arsenal", ["Chelsea", "Manchester United", "Liverpool"], 1, "Klubbfotball"),
    ("Hvilket lag sensasjonsvant Premier League i 2015–16?", "Leicester City", ["Tottenham", "Everton", "Southampton"], 1, "Klubbfotball"),
    ("Hvilken klubb signerte Erling Haaland fra Borussia Dortmund i 2022?", "Manchester City", ["Real Madrid", "Manchester United", "Chelsea"], 1, "Klubbfotball"),
    ("Hvor mange Premier League-mål scoret Haaland i sesongen 2022–23 (rekord)?", "36", ["34", "32", "38"], 3, "Klubbfotball"),
    ("Hvilken klubb har flest Champions League-/europacuptitler?", "Real Madrid", ["AC Milan", "Liverpool", "Bayern München"], 1, "Klubbfotball"),
    ("Hvem har vunnet flest Ballon d'Or hos menn?", "Lionel Messi", ["Cristiano Ronaldo", "Michel Platini", "Johan Cruyff"], 1, "Klubbfotball"),
    ("Hvem vant Ballon d'Or i 2024?", "Rodri", ["Vinícius Júnior", "Jude Bellingham", "Erling Haaland"], 2, "Klubbfotball"),
    ("Hvem vant Ballon d'Or i 2022?", "Karim Benzema", ["Kylian Mbappé", "Sadio Mané", "Robert Lewandowski"], 3, "Klubbfotball"),
    ("Hvilken italiensk klubb vant Serie A med Maradona i 1987 og 1990?", "Napoli", ["Juventus", "AC Milan", "Roma"], 3, "Klubbfotball"),
    ("Hvem er tidenes toppscorer på landslagsnivå blant menn?", "Cristiano Ronaldo", ["Lionel Messi", "Ali Daei", "Robert Lewandowski"], 2, "Klubbfotball"),
    ("Hvilken klubb vant Champions League i 2016, 2017 og 2018?", "Real Madrid", ["Barcelona", "Bayern München", "Juventus"], 2, "Klubbfotball"),
    # --- Norge ---
    ("Norge slo Brasil 2–1 i VM i Frankrike. Hvilket år var det?", "1998", ["1994", "2002", "1990"], 2, "Norge"),
    # Rettet 2026-11-24: kampen ble spilt på San Siro i Milano (ikke Lerkendal).
    ("Rosenborg slo et storlag 2–1 på bortebane i Champions League i 1996 og gikk videre til kvartfinalen. Hvilket lag?", "AC Milan", ["Juventus", "Real Madrid", "Barcelona"], 4, "Norge"),
    ("Hvilken nordmann scoret vinnermålet i Champions League-finalen 1999?", "Ole Gunnar Solskjær", ["Tore André Flo", "Ronny Johnsen", "Henning Berg"], 2, "Norge"),
    ("Hvilken klubb har flest norske seriemesterskap i herrenes toppdivisjon?", "Rosenborg", ["Brann", "Vålerenga", "Lillestrøm"], 2, "Norge"),
    # --- Stadioner og byer ---
    ("Hvor ligger Lerkendal stadion?", "Trondheim", ["Bergen", "Oslo", "Stavanger"], 1, "Stadioner"),
    ("Hvor ligger Brann stadion?", "Bergen", ["Trondheim", "Stavanger", "Tromsø"], 1, "Stadioner"),
    ("I hvilken by ligger Ullevaal stadion?", "Oslo", ["Bergen", "Drammen", "Lillestrøm"], 1, "Stadioner"),
    ("Hvilken klubb spiller på Anfield?", "Liverpool", ["Everton", "Manchester United", "Newcastle"], 1, "Stadioner"),
    ("Hvilken klubb spiller på Camp Nou?", "Barcelona", ["Real Madrid", "Atlético Madrid", "Valencia"], 1, "Stadioner"),
    ("Hvilken klubb spiller på Santiago Bernabéu?", "Real Madrid", ["Barcelona", "Atlético Madrid", "Sevilla"], 1, "Stadioner"),
    ("Hvilken klubb spiller på Old Trafford?", "Manchester United", ["Manchester City", "Liverpool", "Leeds"], 1, "Stadioner"),
    ("Hvilken klubb spiller på Allianz Arena?", "Bayern München", ["Borussia Dortmund", "Schalke 04", "RB Leipzig"], 1, "Stadioner"),
    ("Hvilken klubb spiller på Signal Iduna Park?", "Borussia Dortmund", ["Schalke 04", "Bayer Leverkusen", "VfB Stuttgart"], 2, "Stadioner"),
    ("Hvilken klubb spiller på La Bombonera?", "Boca Juniors", ["River Plate", "Independiente", "Racing"], 2, "Stadioner"),
    ("I hvilken by ligger Maracanã?", "Rio de Janeiro", ["São Paulo", "Brasília", "Buenos Aires"], 2, "Stadioner"),
    ("Hvilke to klubber deler San Siro?", "AC Milan og Inter", ["Juventus og Torino", "Roma og Lazio", "Napoli og Salernitana"], 2, "Stadioner"),
    ("Hvilken by hører Galatasaray til?", "Istanbul", ["Ankara", "Izmir", "Bursa"], 2, "Stadioner"),
    ("Hvilken by hører Benfica til?", "Lisboa", ["Porto", "Braga", "Faro"], 1, "Stadioner"),
    ("Hvilken by hører Celtic til?", "Glasgow", ["Edinburgh", "Dublin", "Belfast"], 1, "Stadioner"),
    ("Hvilken by hører Ajax til?", "Amsterdam", ["Rotterdam", "Utrecht", "Eindhoven"], 1, "Stadioner"),
]

# Ingen årstall i svaralternativene: man skal kunne fotballhistorien, ikke bare sortere tall.
SORT = [
    ("Sorter VM-finalene fra eldst til nyest",
     ["Brasil – Italia", "Frankrike – Brasil", "Italia – Frankrike", "Spania – Nederland", "Tyskland – Argentina"], 2, "VM-historie"),
    ("Sorter VM-finalene fra eldst til nyest",
     ["England – Vest-Tyskland", "Vest-Tyskland – Nederland", "Argentina – Vest-Tyskland", "Frankrike – Brasil", "Spania – Nederland"], 3, "VM-historie"),
    ("Sorter EM-finalene fra eldst til nyest",
     ["Danmark – Tyskland", "Hellas – Portugal", "Spania – Tyskland", "Portugal – Frankrike", "Italia – England"], 3, "EM-historie"),
    ("Sorter Champions League-finalene fra eldst til nyest",
     ["Liverpool – Tottenham", "Bayern – PSG", "Chelsea – Man City", "Real Madrid – Liverpool", "Man City – Inter"], 3, "Klubbfotball"),
    ("Sorter Ballon d'Or-vinnerne fra eldst til nyest",
     ["Kaká", "Cristiano Ronaldo", "Lionel Messi", "Luka Modrić", "Karim Benzema"], 3, "Klubbfotball"),
    ("Sorter Premier League-mesterne fra eldst til nyest",
     ["Man United (Ferguson tar farvel)", "Chelsea (Mourinho)", "Leicester (eventyret)", "Liverpool (Klopp)", "Man City (Guardiola)"], 3, "Klubbfotball"),
    ("Sorter VM-vertene fra eldst til nyest",
     ["USA", "Frankrike", "Tyskland", "Sør-Afrika", "Russland"], 2, "VM-historie"),
    ("Sorter stadionene fra størst til minst kapasitet",
     ["Camp Nou", "Wembley", "Old Trafford", "Anfield"], 3, "Stadioner"),
    ("Sorter klubbene fra flest til færrest Premier League-titler",
     ["Man United", "Man City", "Chelsea", "Arsenal"], 3, "Klubbfotball"),
    ("Sorter fra kortest til lengst avstand",
     ["Målfeltet fra mållinja", "Muren fra ballen ved frispark", "Straffemerket fra mållinja", "Straffefeltet fra mållinja"], 3, "Regler"),
    ("Sorter hendelsene fra eldst til nyest",
     ["Maracanazo", "«Guds hånd»", "Norge slår Brasil", "Zidanes hodestøt", "Argentina vinner VM i Qatar"], 3, "VM-historie"),
]


# =====================================================================================
# Runde 2 (2026-11-24): flere spørsmål og nye kategorier.
# Mange spørsmål lages fra maler (samme setning, ulike år/navn), så oversettelsen er én
# malrad i tools/i18n_questions.py. Feilsvarene er skrevet for hånd og er garantert gale.
# =====================================================================================


def series(template, rows, era):
    """rows: (verdi i malen, riktig, [gale], vanskelighet). Malen har ett {}."""
    return [(template.format(v), right, wrong, diff, era) for v, right, wrong, diff in rows]


VM2 = series("Hvem vant VM i {}?", [
    (1934, "Italia", ["Tsjekkoslovakia", "Ungarn", "Vest-Tyskland"], 4),
    (1938, "Italia", ["Ungarn", "Brasil", "Sverige"], 4),
    (1950, "Uruguay", ["Brasil", "Sverige", "Spania"], 4),
    (1954, "Vest-Tyskland", ["Ungarn", "Østerrike", "Uruguay"], 3),
    (1958, "Brasil", ["Sverige", "Frankrike", "Vest-Tyskland"], 3),
    (1962, "Brasil", ["Tsjekkoslovakia", "Chile", "Jugoslavia"], 4),
    (1970, "Brasil", ["Italia", "Vest-Tyskland", "Uruguay"], 2),
    (1974, "Vest-Tyskland", ["Nederland", "Polen", "Brasil"], 3),
    (1978, "Argentina", ["Nederland", "Brasil", "Italia"], 3),
    (1982, "Italia", ["Vest-Tyskland", "Polen", "Frankrike"], 3),
    (1994, "Brasil", ["Italia", "Sverige", "Bulgaria"], 2),
], "VM-historie") + series("Hvilket land arrangerte VM i {}?", [
    (1934, "Italia", ["Frankrike", "Sveits", "Spania"], 4),
    (1954, "Sveits", ["Østerrike", "Sverige", "Vest-Tyskland"], 4),
    (1958, "Sverige", ["Norge", "Danmark", "England"], 3),
    (1962, "Chile", ["Argentina", "Peru", "Mexico"], 4),
    (1970, "Mexico", ["Brasil", "Argentina", "Spania"], 3),
    (1974, "Vest-Tyskland", ["Nederland", "Østerrike", "Italia"], 3),
    (1978, "Argentina", ["Uruguay", "Chile", "Brasil"], 3),
    (1982, "Spania", ["Italia", "Frankrike", "Portugal"], 3),
    (1990, "Italia", ["Spania", "Vest-Tyskland", "Frankrike"], 2),
    (1994, "USA", ["Mexico", "Canada", "Brasil"], 1),
    (2006, "Tyskland", ["Frankrike", "Italia", "Nederland"], 1),
    (2014, "Brasil", ["Argentina", "Mexico", "Colombia"], 1),
], "VM-historie") + series("Hvem ble toppscorer i VM {}?", [
    (2022, "Kylian Mbappé", ["Lionel Messi", "Olivier Giroud", "Julián Álvarez"], 2),
    (2018, "Harry Kane", ["Romelu Lukaku", "Antoine Griezmann", "Cristiano Ronaldo"], 2),
    (2014, "James Rodríguez", ["Thomas Müller", "Neymar", "Lionel Messi"], 3),
    (2006, "Miroslav Klose", ["Hernán Crespo", "Thierry Henry", "Ronaldo Nazário"], 3),
    (2002, "Ronaldo Nazário", ["Rivaldo", "Miroslav Klose", "Christian Vieri"], 2),
    (1998, "Davor Šuker", ["Gabriel Batistuta", "Christian Vieri", "Ronaldo Nazário"], 3),
    (1990, "Salvatore Schillaci", ["Gary Lineker", "Lothar Matthäus", "Roberto Baggio"], 4),
    (1986, "Gary Lineker", ["Diego Maradona", "Emilio Butragueño", "Careca"], 4),
    (1982, "Paolo Rossi", ["Karl-Heinz Rummenigge", "Zico", "Zbigniew Boniek"], 4),
    (1970, "Gerd Müller", ["Pelé", "Jairzinho", "Teófilo Cubillas"], 4),
    (1966, "Eusébio", ["Bobby Charlton", "Geoff Hurst", "Pelé"], 4),
], "VM-historie") + series("Hvem ble kåret til turneringens beste spiller i VM {}?", [
    (2022, "Lionel Messi", ["Kylian Mbappé", "Luka Modrić", "Antoine Griezmann"], 2),
    (2018, "Luka Modrić", ["Eden Hazard", "Antoine Griezmann", "Kylian Mbappé"], 2),
    (2014, "Lionel Messi", ["Thomas Müller", "Arjen Robben", "James Rodríguez"], 3),
    (2010, "Diego Forlán", ["Wesley Sneijder", "David Villa", "Andrés Iniesta"], 4),
    (2006, "Zinedine Zidane", ["Fabio Cannavaro", "Andrea Pirlo", "Miroslav Klose"], 3),
    (2002, "Oliver Kahn", ["Ronaldo Nazário", "Rivaldo", "Hong Myung-bo"], 4),
    (1998, "Ronaldo Nazário", ["Davor Šuker", "Lilian Thuram", "Zinedine Zidane"], 4),
], "VM-historie") + series("Hvem scoret vinnermålet i VM-finalen {}?", [
    (2010, "Andrés Iniesta", ["David Villa", "Fernando Torres", "Xavi"], 1),
    (2014, "Mario Götze", ["Thomas Müller", "André Schürrle", "Miroslav Klose"], 2),
    (1990, "Andreas Brehme", ["Lothar Matthäus", "Rudi Völler", "Jürgen Klinsmann"], 4),
    (1986, "Jorge Burruchaga", ["Diego Maradona", "Jorge Valdano", "José Luis Brown"], 5),
], "VM-historie") + series("Hvor mange VM-titler har {} for menn?", [
    ("Brasil", "5", ["3", "4", "6"], 1),
    ("Tyskland", "4", ["2", "3", "5"], 2),
    ("Italia", "4", ["2", "3", "5"], 2),
    ("Argentina", "3", ["1", "2", "4"], 2),
    ("Frankrike", "2", ["1", "3", "4"], 2),
    ("Uruguay", "2", ["0", "1", "3"], 3),
    ("England", "1", ["0", "2", "3"], 1),
    ("Spania", "1", ["0", "2", "3"], 1),
], "VM-historie") + [
    ("Hvem scoret hattrick i VM-finalen 1966?", "Geoff Hurst", ["Bobby Charlton", "Roger Hunt", "Martin Peters"], 4, "VM-historie"),
    ("Hvem scoret hattrick i VM-finalen 2022?", "Kylian Mbappé", ["Lionel Messi", "Ángel Di María", "Olivier Giroud"], 1, "VM-historie"),
    ("Hvem scoret to mål for Frankrike i VM-finalen 1998?", "Zinedine Zidane", ["Thierry Henry", "Emmanuel Petit", "Youri Djorkaeff"], 2, "VM-historie"),
    ("Hvem scoret det avgjørende straffesparket da Italia vant VM-finalen i 2006?", "Fabio Grosso", ["Andrea Pirlo", "Alessandro Del Piero", "Francesco Totti"], 3, "VM-historie"),
    ("Hvem bommet på det siste, avgjørende straffesparket i VM-finalen 1994?", "Roberto Baggio", ["Paolo Maldini", "Alessandro Del Piero", "Gianfranco Zola"], 3, "VM-historie"),
    ("Hvilken målvakt fikk prisen som turneringens beste målvakt i VM 2022?", "Emiliano Martínez", ["Hugo Lloris", "Yassine Bounou", "Dominik Livaković"], 3, "VM-historie"),
    ("Hvilken spiller har vunnet VM tre ganger?", "Pelé", ["Diego Maradona", "Franz Beckenbauer", "Cafu"], 2, "VM-historie"),
    ("Hvor gammel var Pelé da han vant VM i 1958?", "17", ["16", "19", "21"], 3, "VM-historie"),
    ("Hvem ble den første spilleren som scoret i fem ulike VM-sluttspill?", "Cristiano Ronaldo", ["Lionel Messi", "Miroslav Klose", "Pelé"], 3, "VM-historie"),
    ("Hvem var Spanias kaptein da de vant VM i 2010?", "Iker Casillas", ["Carles Puyol", "Xavi", "Sergio Ramos"], 2, "VM-historie"),
    ("Hvilket land har deltatt i alle VM-sluttspill for menn?", "Brasil", ["Tyskland", "Italia", "Argentina"], 2, "VM-historie"),
    ("Hvilket land ble i 2026 det første som har vært VM-vert for menn tre ganger?", "Mexico", ["Italia", "Brasil", "Tyskland"], 3, "VM-historie"),
]

EM2 = series("Hvem vant EM i {}?", [
    (1960, "Sovjetunionen", ["Jugoslavia", "Tsjekkoslovakia", "Frankrike"], 4),
    (1964, "Spania", ["Sovjetunionen", "Ungarn", "Danmark"], 4),
    (1968, "Italia", ["Jugoslavia", "England", "Sovjetunionen"], 4),
    (1972, "Vest-Tyskland", ["Sovjetunionen", "Belgia", "Ungarn"], 4),
    (1976, "Tsjekkoslovakia", ["Vest-Tyskland", "Nederland", "Jugoslavia"], 4),
    (1980, "Vest-Tyskland", ["Belgia", "Italia", "Tsjekkoslovakia"], 4),
    (1984, "Frankrike", ["Spania", "Portugal", "Danmark"], 3),
    (1996, "Tyskland", ["Tsjekkia", "England", "Frankrike"], 2),
    (2000, "Frankrike", ["Italia", "Nederland", "Portugal"], 2),
    (2008, "Spania", ["Tyskland", "Russland", "Tyrkia"], 1),
    (2012, "Spania", ["Italia", "Tyskland", "Portugal"], 1),
], "EM-historie") + series("Hvilket land arrangerte EM i {}?", [
    (1964, "Spania", ["Italia", "Frankrike", "Sovjetunionen"], 5),
    (1976, "Jugoslavia", ["Italia", "Belgia", "Vest-Tyskland"], 5),
    (1984, "Frankrike", ["Spania", "Italia", "Vest-Tyskland"], 3),
    (1988, "Vest-Tyskland", ["Nederland", "Italia", "Sverige"], 3),
    (1992, "Sverige", ["Danmark", "Norge", "England"], 2),
    (1996, "England", ["Frankrike", "Nederland", "Spania"], 2),
    (2004, "Portugal", ["Spania", "Hellas", "Italia"], 1),
    (2016, "Frankrike", ["Tyskland", "Italia", "Belgia"], 1),
    (2024, "Tyskland", ["Frankrike", "England", "Italia"], 1),
], "EM-historie") + series("Hvem scoret vinnermålet i EM-finalen {}?", [
    (2024, "Mikel Oyarzabal", ["Nico Williams", "Lamine Yamal", "Dani Olmo"], 3),
    (2016, "Éder", ["Cristiano Ronaldo", "Nani", "Ricardo Quaresma"], 2),
    (2008, "Fernando Torres", ["David Villa", "Xavi", "Cesc Fàbregas"], 2),
    (2004, "Angelos Charisteas", ["Theodoros Zagorakis", "Traianos Dellas", "Giorgos Karagounis"], 3),
    (2000, "David Trezeguet", ["Sylvain Wiltord", "Thierry Henry", "Robert Pires"], 4),
    (1996, "Oliver Bierhoff", ["Jürgen Klinsmann", "Matthias Sammer", "Andreas Möller"], 4),
], "EM-historie") + series("Hvor mange EM-titler har {} for menn?", [
    ("Spania", "4", ["2", "3", "5"], 3),
    ("Tyskland", "3", ["1", "2", "4"], 3),
    ("Italia", "2", ["1", "3", "4"], 3),
    ("Frankrike", "2", ["1", "3", "0"], 3),
    ("Portugal", "1", ["0", "2", "3"], 2),
], "EM-historie") + [
    ("Hvem har scoret flest mål i EM-sluttspill for menn?", "Cristiano Ronaldo", ["Michel Platini", "Antoine Griezmann", "Alan Shearer"], 2, "EM-historie"),
    ("Hvem scoret ni mål i EM 1984, rekord for ett sluttspill?", "Michel Platini", ["Marco van Basten", "Karl-Heinz Rummenigge", "Preben Elkjær"], 3, "EM-historie"),
    ("Hvem ble EM-historiens yngste målscorer i 2024?", "Lamine Yamal", ["Jude Bellingham", "Jamal Musiala", "Arda Güler"], 2, "EM-historie"),
    ("Hvilken spiller ga navn til det myke «Panenka»-straffesparket i EM-finalen 1976?", "Antonín Panenka", ["Pavel Nedvěd", "Josef Masopust", "Ivo Viktor"], 3, "EM-historie"),
    ("Hvor mange lag deltok i EM 2024?", "24", ["16", "20", "32"], 2, "EM-historie"),
    ("Danmark vant EM i 1992 selv om de først ikke var kvalifisert. Hvilket land tok de plassen til?", "Jugoslavia", ["Sovjetunionen", "Tsjekkoslovakia", "Norge"], 4, "EM-historie"),
]

KLUBB2 = series("Hvem vant Champions League i {}?", [
    (1993, "Marseille", ["AC Milan", "Barcelona", "Ajax"], 4),
    (1995, "Ajax", ["AC Milan", "Bayern München", "Juventus"], 3),
    (1997, "Borussia Dortmund", ["Juventus", "Ajax", "Manchester United"], 3),
    (2003, "AC Milan", ["Juventus", "Real Madrid", "Inter"], 3),
    (2004, "Porto", ["Monaco", "Chelsea", "Deportivo La Coruña"], 2),
    (2006, "Barcelona", ["Arsenal", "AC Milan", "Villarreal"], 2),
    (2008, "Manchester United", ["Chelsea", "Liverpool", "Barcelona"], 2),
    (2010, "Inter", ["Bayern München", "Barcelona", "Lyon"], 2),
    (2012, "Chelsea", ["Bayern München", "Real Madrid", "Barcelona"], 2),
    (2013, "Bayern München", ["Borussia Dortmund", "Real Madrid", "Barcelona"], 2),
    (2014, "Real Madrid", ["Atlético Madrid", "Bayern München", "Chelsea"], 2),
    (2015, "Barcelona", ["Juventus", "Real Madrid", "Bayern München"], 2),
    (2019, "Liverpool", ["Tottenham", "Ajax", "Barcelona"], 1),
    (2020, "Bayern München", ["Paris Saint-Germain", "Lyon", "RB Leipzig"], 2),
    (2021, "Chelsea", ["Manchester City", "Real Madrid", "Paris Saint-Germain"], 2),
    (2022, "Real Madrid", ["Liverpool", "Manchester City", "Villarreal"], 1),
    (2023, "Manchester City", ["Inter", "Real Madrid", "AC Milan"], 1),
    (2024, "Real Madrid", ["Borussia Dortmund", "Bayern München", "Paris Saint-Germain"], 1),
    (2025, "Paris Saint-Germain", ["Inter", "Arsenal", "Barcelona"], 1),
], "Klubbfotball") + series("Hvem vant Europa League i {}?", [
    (2025, "Tottenham", ["Manchester United", "Athletic Bilbao", "Bodø/Glimt"], 2),
    (2024, "Atalanta", ["Bayer Leverkusen", "Roma", "Marseille"], 2),
], "Klubbfotball") + series("Hvem vant Conference League i {}?", [
    (2022, "Roma", ["Feyenoord", "Leicester City", "Marseille"], 2),
    (2023, "West Ham United", ["Fiorentina", "AZ Alkmaar", "Basel"], 2),
    (2024, "Olympiakos", ["Fiorentina", "Aston Villa", "Club Brugge"], 3),
    (2025, "Chelsea", ["Real Betis", "Fiorentina", "Djurgården"], 2),
], "Klubbfotball") + series("I hvilket land spiller klubben {}?", [
    ("Galatasaray", "Tyrkia", ["Hellas", "Bulgaria", "Kroatia"], 1),
    ("Olympiakos", "Hellas", ["Tyrkia", "Bulgaria", "Romania"], 2),
    ("Crvena zvezda", "Serbia", ["Kroatia", "Bulgaria", "Tsjekkia"], 3),
    ("Dinamo Zagreb", "Kroatia", ["Serbia", "Slovenia", "Ungarn"], 2),
    ("Club Brugge", "Belgia", ["Nederland", "Frankrike", "Danmark"], 2),
    ("Boca Juniors", "Argentina", ["Uruguay", "Brasil", "Chile"], 1),
    ("Flamengo", "Brasil", ["Argentina", "Portugal", "Colombia"], 2),
    ("Al-Hilal", "Saudi-Arabia", ["Qatar", "Egypt", "Marokko"], 2),
    ("Shakhtar Donetsk", "Ukraina", ["Russland", "Polen", "Romania"], 2),
    ("Ferencváros", "Ungarn", ["Østerrike", "Slovenia", "Tsjekkia"], 3),
    ("Sparta Praha", "Tsjekkia", ["Polen", "Ungarn", "Østerrike"], 2),
    ("Malmö FF", "Sverige", ["Danmark", "Norge", "Finland"], 1),
    ("FC Midtjylland", "Danmark", ["Sverige", "Norge", "Nederland"], 2),
    ("Peñarol", "Uruguay", ["Argentina", "Chile", "Paraguay"], 3),
    ("Al Ahly", "Egypt", ["Marokko", "Saudi-Arabia", "Algerie"], 3),
    ("Ludogorets", "Bulgaria", ["Romania", "Serbia", "Hellas"], 4),
], "Klubbfotball") + [
    ("Hvilken klubb vant VM for klubblag i USA i 2025?", "Chelsea", ["Paris Saint-Germain", "Real Madrid", "Bayern München"], 2, "Klubbfotball"),
    ("Hvilken klubb kjøpte Neymar fra Barcelona for 222 millioner euro i 2017?", "Paris Saint-Germain", ["Real Madrid", "Manchester City", "Chelsea"], 1, "Klubbfotball"),
    ("Hvilket lag snudde 0–3 til 4–0 mot Barcelona i Champions League-semifinalen 2019?", "Liverpool", ["Tottenham", "Ajax", "Roma"], 2, "Klubbfotball"),
    ("Hvilket lag tapte 2–8 for Bayern München i Champions League-kvartfinalen 2020?", "Barcelona", ["Chelsea", "Lyon", "Real Madrid"], 2, "Klubbfotball"),
    ("Hvilket engelsk lag vant europacupen to år på rad i 1979 og 1980?", "Nottingham Forest", ["Liverpool", "Aston Villa", "Leeds United"], 4, "Klubbfotball"),
    ("Hvilket lag ble i 1967 det første britiske som vant europacupen?", "Celtic", ["Manchester United", "Liverpool", "Rangers"], 4, "Klubbfotball"),
    ("Hvilket lag vant de fem første europacupene (1956–1960)?", "Real Madrid", ["Benfica", "AC Milan", "Barcelona"], 3, "Klubbfotball"),
    ("Hvilken klubb har vunnet UEFA-cupen/Europa League flest ganger?", "Sevilla", ["Inter", "Liverpool", "Atlético Madrid"], 3, "Klubbfotball"),
    ("Hvilken klubb kalles «La Vecchia Signora» (den gamle damen)?", "Juventus", ["AC Milan", "Inter", "Roma"], 2, "Klubbfotball"),
    ("Hvilken klubb har kallenavnet «The Toffees»?", "Everton", ["Liverpool", "Fulham", "Aston Villa"], 3, "Klubbfotball"),
    ("Hvilken klubb har kallenavnet «Die Werkself»?", "Bayer Leverkusen", ["VfL Wolfsburg", "Schalke 04", "RB Leipzig"], 3, "Klubbfotball"),
]

LIGA = "Ligaer"
LIGAER2 = series("Hvem vant Premier League i sesongen {}?", [
    ("1994–95", "Blackburn Rovers", ["Manchester United", "Newcastle United", "Liverpool"], 3),
    ("1997–98", "Arsenal", ["Manchester United", "Liverpool", "Chelsea"], 3),
    ("2001–02", "Arsenal", ["Liverpool", "Manchester United", "Newcastle United"], 3),
    ("2004–05", "Chelsea", ["Arsenal", "Manchester United", "Liverpool"], 2),
    ("2009–10", "Chelsea", ["Manchester United", "Arsenal", "Tottenham"], 3),
    ("2011–12", "Manchester City", ["Manchester United", "Arsenal", "Tottenham"], 2),
    ("2012–13", "Manchester United", ["Manchester City", "Chelsea", "Arsenal"], 2),
    ("2013–14", "Manchester City", ["Liverpool", "Chelsea", "Arsenal"], 2),
    ("2016–17", "Chelsea", ["Tottenham", "Manchester City", "Liverpool"], 2),
    ("2019–20", "Liverpool", ["Manchester City", "Manchester United", "Chelsea"], 1),
    ("2022–23", "Manchester City", ["Arsenal", "Manchester United", "Newcastle United"], 1),
    ("2024–25", "Liverpool", ["Arsenal", "Manchester City", "Chelsea"], 1),
], LIGA) + series("Hvem vant La Liga i sesongen {}?", [
    ("1999–2000", "Deportivo La Coruña", ["Barcelona", "Valencia", "Real Madrid"], 4),
    ("2003–04", "Valencia", ["Barcelona", "Deportivo La Coruña", "Real Madrid"], 4),
    ("2008–09", "Barcelona", ["Real Madrid", "Sevilla", "Atlético Madrid"], 2),
    ("2011–12", "Real Madrid", ["Barcelona", "Valencia", "Málaga"], 3),
    ("2013–14", "Atlético Madrid", ["Barcelona", "Real Madrid", "Athletic Bilbao"], 3),
    ("2020–21", "Atlético Madrid", ["Real Madrid", "Barcelona", "Sevilla"], 3),
    ("2023–24", "Real Madrid", ["Barcelona", "Girona", "Atlético Madrid"], 2),
    ("2024–25", "Barcelona", ["Real Madrid", "Atlético Madrid", "Athletic Bilbao"], 2),
], LIGA) + series("Hvem vant Serie A i sesongen {}?", [
    ("1999–2000", "Lazio", ["Juventus", "AC Milan", "Inter"], 4),
    ("2000–01", "Roma", ["Juventus", "Lazio", "Parma"], 4),
    ("2009–10", "Inter", ["Roma", "AC Milan", "Sampdoria"], 3),
    ("2019–20", "Juventus", ["Inter", "Atalanta", "Lazio"], 3),
    ("2021–22", "AC Milan", ["Inter", "Napoli", "Juventus"], 3),
    ("2022–23", "Napoli", ["Lazio", "Inter", "AC Milan"], 2),
    ("2023–24", "Inter", ["AC Milan", "Juventus", "Atalanta"], 2),
    ("2024–25", "Napoli", ["Inter", "Atalanta", "Juventus"], 2),
], LIGA) + series("Hvem vant Bundesliga i sesongen {}?", [
    ("1997–98", "1. FC Kaiserslautern", ["Bayern München", "Bayer Leverkusen", "Schalke 04"], 5),
    ("2003–04", "Werder Bremen", ["Bayern München", "Bayer Leverkusen", "VfB Stuttgart"], 4),
    ("2006–07", "VfB Stuttgart", ["Schalke 04", "Werder Bremen", "Bayern München"], 4),
    ("2008–09", "VfL Wolfsburg", ["Bayern München", "VfB Stuttgart", "Hertha BSC"], 4),
    ("2010–11", "Borussia Dortmund", ["Bayer Leverkusen", "Bayern München", "Hannover 96"], 3),
    ("2011–12", "Borussia Dortmund", ["Bayern München", "Schalke 04", "Borussia Mönchengladbach"], 3),
    ("2023–24", "Bayer Leverkusen", ["Bayern München", "VfB Stuttgart", "RB Leipzig"], 2),
    ("2024–25", "Bayern München", ["Bayer Leverkusen", "Eintracht Frankfurt", "Borussia Dortmund"], 2),
], LIGA) + series("Hvilken klubb har flest seriemesterskap i {}?", [
    ("Premier League", "Manchester United", ["Manchester City", "Chelsea", "Arsenal"], 2),
    ("La Liga", "Real Madrid", ["Barcelona", "Atlético Madrid", "Athletic Bilbao"], 1),
    ("Serie A", "Juventus", ["Inter", "AC Milan", "Roma"], 1),
    ("Bundesliga", "Bayern München", ["Borussia Dortmund", "Borussia Mönchengladbach", "Werder Bremen"], 1),
    ("Ligue 1", "Paris Saint-Germain", ["Marseille", "Lyon", "Monaco"], 3),
    ("Eredivisie", "Ajax", ["PSV Eindhoven", "Feyenoord", "AZ Alkmaar"], 2),
    ("Portugal", "Benfica", ["Porto", "Sporting", "Braga"], 3),
    ("Sverige", "Malmö FF", ["IFK Göteborg", "AIK", "Djurgården"], 3),
    ("Tyrkia", "Galatasaray", ["Fenerbahçe", "Beşiktaş", "Trabzonspor"], 3),
], LIGA) + [
    ("Hvor mange Serie A-titler på rad vant Juventus fra 2012 til 2020?", "9", ["6", "7", "11"], 3, LIGA),
    ("Hvor mange Bundesliga-titler på rad vant Bayern München fra 2013 til 2023?", "11", ["8", "9", "13"], 3, LIGA),
    ("Hvilket lag gikk ubeseiret gjennom Bundesliga-sesongen 2023–24?", "Bayer Leverkusen", ["Bayern München", "Borussia Dortmund", "RB Leipzig"], 2, LIGA),
    ("Hvilken klubb vant den franske ligaen sju ganger på rad fra 2002 til 2008?", "Lyon", ["Marseille", "Bordeaux", "Paris Saint-Germain"], 4, LIGA),
    ("Hvilket lag tok 100 poeng i Premier League-sesongen 2017–18?", "Manchester City", ["Liverpool", "Chelsea", "Manchester United"], 2, LIGA),
]

REK = "Spillere og rekorder"
REKORDER2 = series("Hvem er toppscorer gjennom tidene i {}?", [
    ("Premier League", "Alan Shearer", ["Harry Kane", "Wayne Rooney", "Thierry Henry"], 2),
    ("La Liga", "Lionel Messi", ["Cristiano Ronaldo", "Telmo Zarra", "Hugo Sánchez"], 2),
    ("Bundesliga", "Gerd Müller", ["Robert Lewandowski", "Klaus Fischer", "Jupp Heynckes"], 3),
    ("Serie A", "Silvio Piola", ["Francesco Totti", "Gunnar Nordahl", "Giuseppe Meazza"], 5),
], REK) + series("Hvem vant Ballon d'Or i {}?", [
    (2025, "Ousmane Dembélé", ["Lamine Yamal", "Vitinha", "Mohamed Salah"], 2),
    (2023, "Lionel Messi", ["Erling Haaland", "Kylian Mbappé", "Kevin De Bruyne"], 2),
    (2018, "Luka Modrić", ["Cristiano Ronaldo", "Antoine Griezmann", "Kylian Mbappé"], 2),
    (2013, "Cristiano Ronaldo", ["Lionel Messi", "Franck Ribéry", "Zlatan Ibrahimović"], 3),
    (2009, "Lionel Messi", ["Cristiano Ronaldo", "Xavi", "Andrés Iniesta"], 3),
    (2008, "Cristiano Ronaldo", ["Lionel Messi", "Fernando Torres", "Kaká"], 3),
    (2007, "Kaká", ["Cristiano Ronaldo", "Lionel Messi", "Didier Drogba"], 3),
    (2006, "Fabio Cannavaro", ["Gianluigi Buffon", "Thierry Henry", "Ronaldinho"], 3),
    (2005, "Ronaldinho", ["Frank Lampard", "Steven Gerrard", "Thierry Henry"], 3),
    (2004, "Andrij Sjevtsjenko", ["Deco", "Ronaldinho", "Thierry Henry"], 4),
    (2003, "Pavel Nedvěd", ["Thierry Henry", "Paolo Maldini", "Andrij Sjevtsjenko"], 4),
    (2002, "Ronaldo Nazário", ["Roberto Carlos", "Oliver Kahn", "Zinedine Zidane"], 3),
    (2001, "Michael Owen", ["Raúl", "Oliver Kahn", "David Beckham"], 4),
    (2000, "Luís Figo", ["Zinedine Zidane", "Andrij Sjevtsjenko", "Thierry Henry"], 4),
    (1999, "Rivaldo", ["David Beckham", "Andrij Sjevtsjenko", "Gabriel Batistuta"], 4),
    (1998, "Zinedine Zidane", ["Davor Šuker", "Ronaldo Nazário", "Michael Owen"], 3),
    (1995, "George Weah", ["Jürgen Klinsmann", "Jari Litmanen", "Alessandro Del Piero"], 4),
], REK) + [
    ("Hvem har spilt flest landskamper for et herrelandslag?", "Cristiano Ronaldo", ["Lionel Messi", "Sergio Ramos", "Luka Modrić"], 3, REK),
    ("Hvem har scoret flest mål i Champions League?", "Cristiano Ronaldo", ["Lionel Messi", "Robert Lewandowski", "Karim Benzema"], 2, REK),
    ("Hvem scoret 91 mål i kalenderåret 2012?", "Lionel Messi", ["Cristiano Ronaldo", "Radamel Falcao", "Robin van Persie"], 2, REK),
    ("Hvem scoret 50 mål i La Liga-sesongen 2011–12, en rekord?", "Lionel Messi", ["Cristiano Ronaldo", "Radamel Falcao", "Gonzalo Higuaín"], 3, REK),
    ("Hvem scoret fem mål på ni minutter i en Bundesliga-kamp i 2015?", "Robert Lewandowski", ["Thomas Müller", "Pierre-Emerick Aubameyang", "Arjen Robben"], 2, REK),
    ("Hvem er den eneste målvakten som har vunnet Ballon d'Or?", "Lev Jasjin", ["Gianluigi Buffon", "Oliver Kahn", "Dino Zoff"], 3, REK),
    ("Hvem er den eneste afrikaneren som har vunnet Ballon d'Or for menn?", "George Weah", ["Samuel Eto'o", "Didier Drogba", "Abedi Pelé"], 3, REK),
    ("Hvilket draktnummer er Johan Cruyff mest kjent for?", "14", ["10", "9", "7"], 3, REK),
    ("Hvem har vunnet flest Premier League-titler som spiller?", "Ryan Giggs", ["Paul Scholes", "Gary Neville", "Fernandinho"], 3, REK),
    ("Hvilken spiller kalles «Il Fenomeno»?", "Ronaldo Nazário", ["Rivaldo", "Romário", "Ronaldinho"], 2, REK),
    ("Hvilken spiller kalles «Der Kaiser»?", "Franz Beckenbauer", ["Gerd Müller", "Lothar Matthäus", "Karl-Heinz Rummenigge"], 2, REK),
    ("Hvilken spiller kalles «Der Bomber»?", "Gerd Müller", ["Franz Beckenbauer", "Rudi Völler", "Uwe Seeler"], 3, REK),
    ("Hvilken spiller kalles «El Pibe de Oro» (gullgutten)?", "Diego Maradona", ["Lionel Messi", "Juan Román Riquelme", "Gabriel Batistuta"], 3, REK),
    ("Hvilken spiller kalles «King Kenny»?", "Kenny Dalglish", ["Kevin Keegan", "Ian Rush", "Kenny Miller"], 3, REK),
    ("Hvilken spiller kalles «Il Divin Codino» (den guddommelige hestehalen)?", "Roberto Baggio", ["Alessandro Del Piero", "Francesco Totti", "Andrea Pirlo"], 3, REK),
    ("Hvilken spiller ble solgt for verdensrekordsummen 222 millioner euro i 2017?", "Neymar", ["Kylian Mbappé", "Philippe Coutinho", "Paul Pogba"], 1, REK),
    ("Hvilken tidligere fotballspiller ble president i Liberia i 2018?", "George Weah", ["Samuel Eto'o", "Didier Drogba", "Jay-Jay Okocha"], 2, REK),
]

TREN = "Trenere"
TRENERE2 = [
    ("Hvem trente {} da de vant Champions League i {}?".format(c, y), right, wrong, d, TREN)
    for c, y, right, wrong, d in [
        ("Liverpool", 2019, "Jürgen Klopp", ["Rafael Benítez", "Brendan Rodgers", "Arne Slot"], 1),
        ("Liverpool", 2005, "Rafael Benítez", ["Gérard Houllier", "Kenny Dalglish", "Roy Hodgson"], 3),
        ("Chelsea", 2012, "Roberto Di Matteo", ["José Mourinho", "André Villas-Boas", "Carlo Ancelotti"], 4),
        ("Chelsea", 2021, "Thomas Tuchel", ["Frank Lampard", "Antonio Conte", "Maurizio Sarri"], 2),
        ("Porto", 2004, "José Mourinho", ["André Villas-Boas", "Jesualdo Ferreira", "Sérgio Conceição"], 2),
        ("Inter", 2010, "José Mourinho", ["Roberto Mancini", "Simone Inzaghi", "Leonardo"], 2),
        ("Barcelona", 2006, "Frank Rijkaard", ["Pep Guardiola", "Louis van Gaal", "Johan Cruyff"], 3),
        ("Barcelona", 2009, "Pep Guardiola", ["Frank Rijkaard", "Luis Enrique", "Tito Vilanova"], 2),
        ("Manchester City", 2023, "Pep Guardiola", ["Manuel Pellegrini", "Roberto Mancini", "Mikel Arteta"], 1),
        ("Bayern München", 2013, "Jupp Heynckes", ["Pep Guardiola", "Louis van Gaal", "Carlo Ancelotti"], 3),
        ("Bayern München", 2020, "Hansi Flick", ["Niko Kovač", "Julian Nagelsmann", "Thomas Tuchel"], 3),
        ("Paris Saint-Germain", 2025, "Luis Enrique", ["Mauricio Pochettino", "Thomas Tuchel", "Christophe Galtier"], 2),
        ("Manchester United", 1999, "Alex Ferguson", ["Ron Atkinson", "Ole Gunnar Solskjær", "David Moyes"], 1),
        ("Real Madrid", 2016, "Zinedine Zidane", ["Carlo Ancelotti", "Rafael Benítez", "José Mourinho"], 2),
        ("Real Madrid", 2024, "Carlo Ancelotti", ["Zinedine Zidane", "Xabi Alonso", "Santiago Solari"], 2),
        ("AC Milan", 1994, "Fabio Capello", ["Arrigo Sacchi", "Carlo Ancelotti", "Cesare Maldini"], 4),
        ("Borussia Dortmund", 1997, "Ottmar Hitzfeld", ["Jürgen Klopp", "Matthias Sammer", "Thomas Tuchel"], 4),
        ("Ajax", 1995, "Louis van Gaal", ["Johan Cruyff", "Rinus Michels", "Leo Beenhakker"], 4),
    ]
] + [
    ("Hvem var {}s landslagstrener da de vant VM i {}?".format(c, y), right, wrong, d, TREN)
    for c, y, right, wrong, d in [
        ("Spania", 2010, "Vicente del Bosque", ["Luis Aragonés", "Luis Enrique", "Javier Clemente"], 3),
        ("Argentina", 2022, "Lionel Scaloni", ["Jorge Sampaoli", "Diego Maradona", "Gerardo Martino"], 2),
        ("Frankrike", 2018, "Didier Deschamps", ["Laurent Blanc", "Zinedine Zidane", "Raymond Domenech"], 1),
        ("Tyskland", 2014, "Joachim Löw", ["Jürgen Klinsmann", "Hansi Flick", "Rudi Völler"], 2),
        ("Italia", 2006, "Marcello Lippi", ["Giovanni Trapattoni", "Roberto Donadoni", "Cesare Prandelli"], 3),
        ("Frankrike", 1998, "Aimé Jacquet", ["Roger Lemerre", "Michel Platini", "Raymond Domenech"], 4),
        ("Brasil", 2002, "Luiz Felipe Scolari", ["Carlos Alberto Parreira", "Dunga", "Mário Zagallo"], 3),
    ]
] + [
    ("Hvem trente {} da de vant EM i {}?".format(c, y), right, wrong, d, TREN)
    for c, y, right, wrong, d in [
        ("Hellas", 2004, "Otto Rehhagel", ["Fernando Santos", "Felix Magath", "Berti Vogts"], 3),
        ("Danmark", 1992, "Richard Møller Nielsen", ["Sepp Piontek", "Morten Olsen", "Åge Hareide"], 4),
        ("Portugal", 2016, "Fernando Santos", ["Luiz Felipe Scolari", "Paulo Bento", "Roberto Martínez"], 3),
        ("Spania", 2024, "Luis de la Fuente", ["Luis Enrique", "Vicente del Bosque", "Julen Lopetegui"], 3),
        ("Italia", 2021, "Roberto Mancini", ["Antonio Conte", "Gian Piero Ventura", "Luciano Spalletti"], 2),
    ]
] + [
    ("Hvem var Arsenals manager i den ubeseirede sesongen 2003–04?", "Arsène Wenger", ["George Graham", "Bruce Rioch", "Unai Emery"], 1, TREN),
    ("Hvem var Leicesters manager da klubben vant Premier League i 2016?", "Claudio Ranieri", ["Nigel Pearson", "Brendan Rodgers", "Craig Shakespeare"], 2, TREN),
    ("Hvem trente Bayer Leverkusen da de gikk ubeseiret gjennom Bundesliga 2023–24?", "Xabi Alonso", ["Gerardo Seoane", "Peter Bosz", "Roger Schmidt"], 2, TREN),
    ("Hvem var Manchester Uniteds manager fra 1986 til 2013?", "Alex Ferguson", ["Matt Busby", "Ron Atkinson", "David Moyes"], 1, TREN),
    ("Hvilken manager har vunnet flest Premier League-titler?", "Alex Ferguson", ["Pep Guardiola", "Arsène Wenger", "José Mourinho"], 1, TREN),
    ("Hvilken trener har vunnet flest Champions League-/europacuptitler?", "Carlo Ancelotti", ["Pep Guardiola", "Zinedine Zidane", "Bob Paisley"], 3, TREN),
    ("Hvilken trener kalte seg selv «The Special One»?", "José Mourinho", ["Pep Guardiola", "Jürgen Klopp", "Antonio Conte"], 1, TREN),
    ("Hvem vant VM som kaptein i 1998 og som landslagstrener i 2018?", "Didier Deschamps", ["Zinedine Zidane", "Laurent Blanc", "Marcel Desailly"], 2, TREN),
    ("Hvem vant VM som kaptein i 1974 og som landslagstrener i 1990?", "Franz Beckenbauer", ["Berti Vogts", "Sepp Maier", "Jupp Derwall"], 3, TREN),
    ("Hvilken tysker ble Englands landslagssjef fra januar 2025?", "Thomas Tuchel", ["Jürgen Klopp", "Hansi Flick", "Julian Nagelsmann"], 2, TREN),
    ("Hvem tok over som Liverpool-manager etter Jürgen Klopp i 2024?", "Arne Slot", ["Xabi Alonso", "Ruben Amorim", "Roberto De Zerbi"], 2, TREN),
    ("Hvilket landslag ble Carlo Ancelotti trener for i 2025?", "Brasil", ["Italia", "Portugal", "Argentina"], 2, TREN),
]

NORGE2 = series("Hvem ble norsk seriemester for herrer i {}?", [
    (2024, "Bodø/Glimt", ["Brann", "Molde", "Viking"], 1),
    (2023, "Bodø/Glimt", ["Brann", "Tromsø", "Viking"], 1),
    (2022, "Molde", ["Bodø/Glimt", "Rosenborg", "Lillestrøm"], 2),
    (2020, "Bodø/Glimt", ["Molde", "Vålerenga", "Rosenborg"], 2),
    (2018, "Rosenborg", ["Molde", "Brann", "Haugesund"], 2),
    (2013, "Strømsgodset", ["Rosenborg", "Haugesund", "Aalesund"], 3),
    (2011, "Molde", ["Tromsø", "Rosenborg", "Brann"], 3),
    (2008, "Stabæk", ["Fredrikstad", "Tromsø", "Brann"], 3),
    (2007, "Brann", ["Stabæk", "Viking", "Lillestrøm"], 3),
    (2005, "Vålerenga", ["Start", "Lyn", "Rosenborg"], 4),
], "Norge") + [
    ("Hvem var Norges landslagstrener i VM 1994 og VM 1998?", "Egil Olsen", ["Nils Johan Semb", "Åge Hareide", "Ståle Solbakken"], 1, "Norge"),
    ("Hvem ble Norges landslagssjef for herrer i 2020?", "Ståle Solbakken", ["Lars Lagerbäck", "Åge Hareide", "Per-Mathias Høgmo"], 1, "Norge"),
    ("Hvilket år spilte Norges herrer sitt første VM-sluttspill?", "1938", ["1954", "1966", "1994"], 3, "Norge"),
    ("Hvilket land tapte Norge mot etter ekstraomganger i VM 1938?", "Italia", ["Frankrike", "Tyskland", "Brasil"], 4, "Norge"),
    ("Norge tok bronse i fotball i OL 1936. Hvilket vertsland slo Norge 2–0 i kvartfinalen?", "Tyskland", ["Italia", "Østerrike", "Sverige"], 3, "Norge"),
    ("Hvem scoret på straffe da Norge slo Brasil 2–1 i VM 1998?", "Kjetil Rekdal", ["Tore André Flo", "Ole Gunnar Solskjær", "Øyvind Leonhardsen"], 2, "Norge"),
    ("Hvem scoret Norges første mål da Norge slo Brasil 2–1 i VM 1998?", "Tore André Flo", ["Kjetil Rekdal", "Håvard Flo", "Stig Inge Bjørnebye"], 3, "Norge"),
    ("Hvilket år slo Norge England 2–1 på Ullevaal, kampen med «Your boys took a hell of a beating»?", "1981", ["1977", "1985", "1993"], 3, "Norge"),
    ("Hvilken kommentator ropte «Your boys took a hell of a beating»?", "Bjørge Lillelien", ["Arne Scheie", "Knut Bjørnsen", "Davy Wathne"], 2, "Norge"),
    ("Hvilket år spilte Norges herrer sitt første VM-sluttspill siden 1998?", "2026", ["2010", "2018", "2022"], 2, "Norge"),
    ("Hvilken norsk klubb nådde semifinalen i Europa League 2024–25?", "Bodø/Glimt", ["Molde", "Rosenborg", "Brann"], 1, "Norge"),
    ("Bodø/Glimt slo et italiensk storlag 6–1 i Conference League i 2021. Hvilket lag?", "Roma", ["Lazio", "Juventus", "Napoli"], 2, "Norge"),
    ("Hvilken norsk klubb nådde kvartfinalen i Champions League 1996–97?", "Rosenborg", ["Molde", "Brann", "Lillestrøm"], 2, "Norge"),
    ("Hvilken norsk klubb kvalifiserte seg til Champions League-sesongen 2025–26?", "Bodø/Glimt", ["Brann", "Molde", "Rosenborg"], 2, "Norge"),
    ("Hvor mange seriegull på rad vant Rosenborg fra 1992 til 2004?", "13", ["10", "11", "15"], 3, "Norge"),
    ("Hvem er Norges mestscorende landslagsspiller for herrer?", "Erling Haaland", ["Jørgen Juve", "Ole Gunnar Solskjær", "John Carew"], 1, "Norge"),
    ("Hvem har spilt flest landskamper for Norges herrer?", "John Arne Riise", ["Thorbjørn Svenssen", "Henning Berg", "Brede Hangeland"], 3, "Norge"),
    ("Fra hvilken norsk klubb kom Martin Ødegaard til Real Madrid i 2015?", "Strømsgodset", ["Rosenborg", "Molde", "Vålerenga"], 2, "Norge"),
    ("Hvilken norsk klubb spilte Erling Haaland for rett før han gikk til Red Bull Salzburg?", "Molde", ["Bryne", "Rosenborg", "Viking"], 2, "Norge"),
    ("I hvilken by er Erling Haaland født?", "Leeds", ["Bryne", "Stavanger", "Molde"], 2, "Norge"),
    ("Hvilken klubb var Ole Gunnar Solskjær manager for fra 2018 til 2021?", "Manchester United", ["Cardiff City", "Molde", "Beşiktaş"], 1, "Norge"),
    ("Med hvilken norsk klubb vant Solskjær seriegull som trener i 2011 og 2012?", "Molde", ["Rosenborg", "Brann", "Strømsgodset"], 2, "Norge"),
    ("Hvilken nordmann ble kåret til sesongens spiller i Premier League 2022–23?", "Erling Haaland", ["Martin Ødegaard", "Alexander Sørloth", "Sander Berge"], 2, "Norge"),
    ("Hvilken nordmann ble Arsenals kaptein i 2022?", "Martin Ødegaard", ["Erling Haaland", "Sander Berge", "Alexander Sørloth"], 1, "Norge"),
    ("Hvilken nordmann spilte for Liverpool i Champions League-finalen 2005?", "John Arne Riise", ["Bjørn Tore Kvarme", "Stig Inge Bjørnebye", "Vegard Heggem"], 3, "Norge"),
    ("Hvor spiller Norges herrelandslag vanligvis hjemmekampene sine?", "Ullevaal stadion", ["Lerkendal", "Brann stadion", "Viking stadion"], 1, "Norge"),
]

STADIONER2 = series("Hvilken klubb spiller på {}?", [
    ("Emirates Stadium", "Arsenal", ["Chelsea", "Tottenham", "West Ham United"], 1),
    ("Stamford Bridge", "Chelsea", ["Fulham", "Arsenal", "Crystal Palace"], 1),
    ("Etihad Stadium", "Manchester City", ["Manchester United", "Everton", "Newcastle United"], 1),
    ("St James' Park", "Newcastle United", ["Sunderland", "Middlesbrough", "Leeds United"], 2),
    ("Villa Park", "Aston Villa", ["Wolverhampton Wanderers", "Leicester City", "Nottingham Forest"], 2),
    ("Celtic Park", "Celtic", ["Rangers", "Hearts", "Aberdeen"], 1),
    ("Ibrox", "Rangers", ["Celtic", "Hibernian", "Aberdeen"], 2),
    ("Mestalla", "Valencia", ["Villarreal", "Sevilla", "Real Betis"], 2),
    ("Veltins-Arena", "Schalke 04", ["Borussia Dortmund", "Bayer Leverkusen", "1. FC Köln"], 3),
    ("Parc des Princes", "Paris Saint-Germain", ["Marseille", "Lyon", "Monaco"], 1),
    ("Stade Vélodrome", "Marseille", ["Paris Saint-Germain", "Nice", "Lyon"], 2),
    ("Johan Cruyff Arena", "Ajax", ["PSV Eindhoven", "Feyenoord", "AZ Alkmaar"], 1),
    ("De Kuip", "Feyenoord", ["Ajax", "PSV Eindhoven", "Utrecht"], 2),
    ("Estádio da Luz", "Benfica", ["Sporting", "Porto", "Braga"], 2),
    ("Estádio do Dragão", "Porto", ["Benfica", "Sporting", "Braga"], 2),
    ("Elland Road", "Leeds United", ["Sheffield United", "Bradford City", "Huddersfield Town"], 2),
    ("Craven Cottage", "Fulham", ["Chelsea", "Brentford", "Queens Park Rangers"], 3),
    ("Philips Stadion", "PSV Eindhoven", ["Ajax", "Feyenoord", "Twente"], 2),
    ("San Mamés", "Athletic Bilbao", ["Real Sociedad", "Osasuna", "Alavés"], 2),
    ("Ramón Sánchez Pizjuán", "Sevilla", ["Real Betis", "Málaga", "Cádiz"], 3),
    ("Benito Villamarín", "Real Betis", ["Sevilla", "Málaga", "Granada"], 3),
    ("Metropolitano", "Atlético Madrid", ["Real Madrid", "Getafe", "Rayo Vallecano"], 2),
    ("BayArena", "Bayer Leverkusen", ["1. FC Köln", "Borussia Mönchengladbach", "Fortuna Düsseldorf"], 2),
    ("Aspmyra stadion", "Bodø/Glimt", ["Tromsø", "Rosenborg", "Molde"], 1),
    ("Aker stadion", "Molde", ["Aalesund", "Kristiansund", "Rosenborg"], 2),
    ("Intility Arena", "Vålerenga", ["Lyn", "Stabæk", "Lillestrøm"], 2),
    ("Molineux", "Wolverhampton Wanderers", ["Aston Villa", "West Bromwich Albion", "Birmingham City"], 3),
    ("Allianz Stadium", "Juventus", ["Torino", "Bayern München", "AC Milan"], 2),
    ("Stadio Diego Armando Maradona", "Napoli", ["Roma", "Lazio", "Juventus"], 1),
    ("Şükrü Saracoğlu", "Fenerbahçe", ["Galatasaray", "Beşiktaş", "Trabzonspor"], 3),
    ("Parken", "FC København", ["Brøndby", "FC Midtjylland", "AGF"], 2),
    ("Anoeta", "Real Sociedad", ["Athletic Bilbao", "Osasuna", "Eibar"], 3),
    ("Selhurst Park", "Crystal Palace", ["Fulham", "Brentford", "Charlton Athletic"], 3),
    ("City Ground", "Nottingham Forest", ["Notts County", "Derby County", "Leicester City"], 3),
    ("London Stadium", "West Ham United", ["Tottenham", "Arsenal", "Crystal Palace"], 2),
    ("Weserstadion", "Werder Bremen", ["Hamburger SV", "Hannover 96", "VfL Wolfsburg"], 3),
    ("El Monumental", "River Plate", ["Boca Juniors", "Independiente", "Racing Club"], 2),
], "Stadioner") + series("I hvilken by ligger {}?", [
    ("Signal Iduna Park", "Dortmund", ["Gelsenkirchen", "Essen", "Bochum"], 2),
    ("Veltins-Arena", "Gelsenkirchen", ["Dortmund", "Bochum", "Essen"], 3),
    ("Stade Vélodrome", "Marseille", ["Lyon", "Toulouse", "Bordeaux"], 2),
    ("De Kuip", "Rotterdam", ["Amsterdam", "Utrecht", "Eindhoven"], 2),
    ("Estádio do Dragão", "Porto", ["Lisboa", "Braga", "Coimbra"], 2),
    ("San Mamés", "Bilbao", ["San Sebastián", "Pamplona", "Santander"], 2),
    ("Mestalla", "Valencia", ["Alicante", "Murcia", "Zaragoza"], 2),
    ("Philips Stadion", "Eindhoven", ["Rotterdam", "Utrecht", "Amsterdam"], 2),
    ("Aspmyra stadion", "Bodø", ["Tromsø", "Narvik", "Mo i Rana"], 1),
    ("Aker stadion", "Molde", ["Ålesund", "Kristiansund", "Trondheim"], 1),
    ("Viking stadion", "Stavanger", ["Bergen", "Haugesund", "Sandnes"], 1),
    ("Alfheim stadion", "Tromsø", ["Bodø", "Alta", "Harstad"], 1),
    ("Marienlyst stadion", "Drammen", ["Sandefjord", "Tønsberg", "Skien"], 2),
    ("Estadio Centenario", "Montevideo", ["Buenos Aires", "Asunción", "Santiago"], 3),
    ("Hampden Park", "Glasgow", ["Edinburgh", "Aberdeen", "Dundee"], 2),
    ("Mineirão", "Belo Horizonte", ["São Paulo", "Porto Alegre", "Salvador"], 4),
], "Stadioner") + series("I hvilket land ligger {}?", [
    ("Estadio Azteca", "Mexico", ["Argentina", "Colombia", "Spania"], 1),
    ("Celtic Park", "Skottland", ["Irland", "England", "Wales"], 1),
    ("Luzhniki", "Russland", ["Ukraina", "Polen", "Serbia"], 2),
    ("Puskás Aréna", "Ungarn", ["Østerrike", "Tsjekkia", "Romania"], 2),
    ("Maksimir", "Kroatia", ["Serbia", "Slovenia", "Bosnia-Hercegovina"], 3),
    ("Ernst-Happel-Stadion", "Østerrike", ["Tyskland", "Sveits", "Ungarn"], 3),
    ("St. Jakob-Park", "Sveits", ["Tyskland", "Østerrike", "Frankrike"], 3),
    ("Karaiskakis", "Hellas", ["Tyrkia", "Italia", "Bulgaria"], 3),
    ("Aviva Stadium", "Irland", ["Skottland", "Wales", "England"], 2),
    ("Millennium Stadium", "Wales", ["England", "Skottland", "Irland"], 2),
    ("Estadio Hernando Siles", "Bolivia", ["Peru", "Ecuador", "Colombia"], 4),
    ("Stade Louis II", "Monaco", ["Frankrike", "Italia", "Sveits"], 3),
    ("Rose Bowl", "USA", ["Mexico", "Canada", "Brasil"], 2),
    ("BMO Field", "Canada", ["USA", "Mexico", "England"], 3),
    ("Saitama Stadium 2002", "Japan", ["Sør-Korea", "Kina", "Qatar"], 2),
    ("Soccer City", "Sør-Afrika", ["Nigeria", "Ghana", "Kamerun"], 2),
    ("Lusail Stadium", "Qatar", ["Saudi-Arabia", "Egypt", "Marokko"], 1),
    ("Rajko Mitić", "Serbia", ["Kroatia", "Bulgaria", "Romania"], 3),
], "Stadioner")

VDA = "Visste du at?"
VISSTE2 = [
    ("Hvor mange lag deltar i VM 2026?", "48", ["32", "40", "64"], 1, VDA),
    ("Hvor mange lag deltok i VM 2022?", "32", ["24", "36", "48"], 1, VDA),
    ("Hvilket år ble VAR brukt i et VM for første gang?", "2018", ["2010", "2014", "2022"], 2, VDA),
    ("Hvilket år ble mållinjeteknologi brukt i et VM for første gang?", "2014", ["2006", "2010", "2018"], 3, VDA),
    ("I hvilket VM ble gule og røde kort tatt i bruk for første gang?", "1970", ["1958", "1966", "1982"], 4, VDA),
    ("Hvilket landslag kalles «Les Bleus»?", "Frankrike", ["Italia", "Belgia", "Skottland"], 1, VDA),
    ("Hvilket landslag kalles «La Albiceleste»?", "Argentina", ["Uruguay", "Paraguay", "Chile"], 2, VDA),
    ("Hvilket landslag kalles «Oranje»?", "Nederland", ["Belgia", "Elfenbenskysten", "Danmark"], 1, VDA),
    ("Hvilket landslag kalles «Gli Azzurri»?", "Italia", ["Frankrike", "Argentina", "Uruguay"], 1, VDA),
    ("Hvilket landslag har tre løver på drakta og kalles «Three Lions»?", "England", ["Wales", "Skottland", "Nederland"], 1, VDA),
    ("Hvilket land har vunnet flest Afrikamesterskap for menn?", "Egypt", ["Kamerun", "Ghana", "Nigeria"], 3, VDA),
    ("Hvilket land har vunnet flest Copa América-titler?", "Argentina", ["Uruguay", "Brasil", "Chile"], 3, VDA),
    ("Hva kalles det når en spiller scorer tre mål i samme kamp?", "Hattrick", ["Dobbelttrekk", "Trippel", "Grand slam"], 1, VDA),
    ("Hvilket land kalles fotballens moderland, der de første moderne reglene ble skrevet i 1863?", "England", ["Skottland", "Italia", "Brasil"], 1, VDA),
] + series("Hvem vant Copa América i {}?", [
    (2024, "Argentina", ["Colombia", "Uruguay", "Canada"], 1),
    (2021, "Argentina", ["Brasil", "Colombia", "Peru"], 2),
    (2019, "Brasil", ["Peru", "Argentina", "Chile"], 2),
    (2016, "Chile", ["Argentina", "Colombia", "USA"], 3),
    (2015, "Chile", ["Argentina", "Peru", "Paraguay"], 3),
    (2011, "Uruguay", ["Paraguay", "Peru", "Venezuela"], 3),
], VDA) + series("Hvem vant Afrikamesterskapet i {}?", [
    (2019, "Algerie", ["Senegal", "Nigeria", "Tunisia"], 3),
    (2017, "Kamerun", ["Egypt", "Burkina Faso", "Ghana"], 4),
    (2015, "Elfenbenskysten", ["Ghana", "DR Kongo", "Ekvatorial-Guinea"], 4),
    (2013, "Nigeria", ["Burkina Faso", "Mali", "Ghana"], 4),
    (2012, "Zambia", ["Elfenbenskysten", "Mali", "Ghana"], 4),
], VDA)

REGLER2 = [(p, r, w, d, "Regler") for p, r, w, d in [
    ("Hvor mange innbyttere kan et lag bruke i en ordinær kamp på toppnivå i dag?", "5", ["3", "4", "6"], 1),
    ("Med fem bytter tillatt: hvor mange byttevinduer har et lag i ordinær tid (i tillegg til pausen)?", "3", ["2", "4", "5"], 4),
    ("Hvor mange ekstra vanlige bytter får et lag i forlengning når fem bytter er tillatt?", "1", ["0", "2", "3"], 4),
    ("Hvor mange sekunder kan keeperen holde ballen i hendene før dommeren griper inn (regel fra 2025)?", "8", ["6", "10", "12"], 3),
    ("Hva dømmes når keeperen holder ballen i hendene i mer enn åtte sekunder (regel fra 2025)?", "Hjørnespark", ["Indirekte frispark", "Straffespark", "Gult kort"], 4),
    ("Hva er omkretsen på en vanlig fotball (størrelse 5)?", "68–70 cm", ["60–62 cm", "64–66 cm", "72–74 cm"], 4),
    ("Kan det scores direkte mål på innkast?", "Nei", ["Ja"], 1),
    ("Hva dømmes hvis et innkast kastes direkte i motstanderens mål?", "Målspark", ["Mål", "Hjørnespark", "Nytt innkast"], 3),
    ("Hva dømmes hvis et frispark sparkes direkte i eget mål?", "Hjørnespark", ["Mål", "Målspark", "Frisparket tas på nytt"], 4),
    ("Kan det scores direkte på et indirekte frispark?", "Nei", ["Ja"], 2),
    ("Kan det scores direkte mål på målspark?", "Ja", ["Nei"], 2),
    ("Hvor langt unna ballen må motspillerne være ved et hjørnespark?", "9,15 meter", ["5 meter", "7 meter", "11 meter"], 2),
    ("Hvilken radius har midtsirkelen?", "9,15 meter", ["7,32 meter", "10 meter", "11 meter"], 3),
    ("Hvilken radius har hjørnebuen?", "1 meter", ["0,5 meter", "1,5 meter", "2 meter"], 4),
    ("Hvor høye må hjørneflaggstengene minst være?", "1,5 meter", ["1 meter", "2 meter", "2,5 meter"], 4),
    ("Hvor brede kan linjene på banen maksimalt være?", "12 cm", ["8 cm", "15 cm", "20 cm"], 4),
    ("Hva er tillatt banebredde i internasjonale kamper?", "64–75 meter", ["50–60 meter", "70–80 meter", "75–90 meter"], 4),
    ("Hva betyr det når dommeren tegner en firkant (en TV-skjerm) med hendene?", "En VAR-gjennomgang", ["Et innbytte", "Tilleggstid", "Indirekte frispark"], 1),
    ("Hva betyr det når hoveddommeren går til skjermen ved sidelinjen?", "Dommeren ser selv på situasjonen før den endelige avgjørelsen", ["Kampen er avbrutt", "Dommeren sjekker tilleggstiden", "Dommeren skal advare en trener"], 2),
    ("Hvilke situasjoner kan VAR gripe inn i?", "Mål, straffespark, direkte rødt kort og feil spiller", ["Alle frispark og innkast", "Bare mål", "Hjørnespark, gule kort og innkast"], 2),
    ("Hvor tydelig må feilen være for at VAR skal anbefale å endre en avgjørelse?", "Klar og åpenbar feil", ["Enhver liten feil", "Når publikum protesterer", "Når begge lagene ber om det"], 3),
    ("Hvilke kroppsdeler teller ikke når offside vurderes?", "Hender og armer", ["Hodet", "Føttene", "Skuldrene"], 3),
    ("Hva dømmes når en spiller straffes for offside?", "Indirekte frispark", ["Direkte frispark", "Dommerball", "Hjørnespark"], 2),
    ("Kan en trener få gult og rødt kort?", "Ja", ["Nei"], 2),
    ("Godkjennes et mål en angriper scorer direkte med hånden eller armen, selv om det var et uhell?", "Nei", ["Ja"], 3),
    ("Hva får en spiller som spytter på en motspiller?", "Rødt kort", ["Gult kort", "Ingenting", "Advarsel uten kort"], 1),
    ("Hva får en spiller som hindrer en åpenbar scoringsmulighet med bevisst håndsspill?", "Rødt kort", ["Gult kort", "Ingen kort", "Grønt kort"], 3),
    ("Hva får en spiller som filmer (simulerer) for å lure dommeren?", "Gult kort", ["Rødt kort", "Ingenting", "Grønt kort"], 2),
    ("Hvor langt unna ballen må motspillerne være ved avspark?", "9,15 meter", ["5 meter", "7 meter", "11 meter"], 2),
    ("En forsvarer løper for tidlig inn i straffefeltet ved et straffespark, men ballen går i mål. Hva skjer?", "Målet godkjennes", ["Straffesparket tas på nytt", "Indirekte frispark", "Dommerball"], 4),
    ("Keeperen går for tidlig av streken og redder straffesparket. Hva skjer?", "Straffesparket tas på nytt", ["Målspark", "Hjørnespark", "Indirekte frispark"], 3),
    ("Straffeskytteren treffer stolpen og skyter returen i mål selv, uten at noen andre har rørt ballen. Hva dømmes?", "Indirekte frispark til motstanderen", ["Mål", "Straffesparket tas på nytt", "Målspark"], 4),
    ("Hvor langt unna en mur på tre eller flere forsvarere må angripende spillere stå (regel fra 2019)?", "1 meter", ["0,5 meter", "2 meter", "9,15 meter"], 4),
    ("Ballen treffer dommeren og går rett i mål. Hva dømmes?", "Dommerball", ["Mål", "Målspark", "Hjørnespark"], 3),
    ("Spillet stoppes og skal startes med dommerball utenfor straffefeltet. Hvem får ballen?", "En spiller fra laget som sist berørte ballen", ["Begge lag kjemper om den", "Hjemmelaget", "Laget som ligger under"], 4),
    ("Må spillerne bruke leggbeskyttere?", "Ja", ["Nei"], 1),
    ("Hva får en spiller som bevisst forlater banen uten dommerens tillatelse?", "Gult kort", ["Rødt kort", "Ingenting", "Frispark mot laget"], 3),
    ("Det står likt etter fem straffespark hver. Hva skjer?", "Ett spark hver til ett lag scorer og det andre bommer", ["Myntkast avgjør", "Kampen spilles om", "Begge lag går videre"], 1),
    ("Kan dommeren endre en avgjørelse etter at spillet er satt i gang igjen?", "Nei", ["Ja"], 3),
    ("Hvilken farge må keeperdrakten ha?", "En farge som skiller seg fra de andre spillerne og dommerne", ["Alltid svart", "Alltid gul", "Samme farge som laget"], 2),
]]

QUIZ2 = VM2 + EM2 + KLUBB2 + LIGAER2 + REKORDER2 + TRENERE2 + NORGE2 + STADIONER2 + VISSTE2 + REGLER2

SORT2 = [
    ("Sorter VM-finalene fra eldst til nyest",
     ["Uruguay – Argentina", "Vest-Tyskland – Ungarn", "Brasil – Sverige", "England – Vest-Tyskland", "Argentina – Nederland"], 4, "VM-historie"),
    ("Sorter VM-finalene fra eldst til nyest",
     ["Italia – Vest-Tyskland", "Argentina – Vest-Tyskland", "Brasil – Tyskland", "Frankrike – Kroatia", "Argentina – Frankrike"], 3, "VM-historie"),
    ("Sorter EM-finalene fra eldst til nyest",
     ["Vest-Tyskland – Belgia", "Frankrike – Spania", "Nederland – Sovjetunionen", "Tyskland – Tsjekkia", "Frankrike – Italia"], 4, "EM-historie"),
    ("Sorter EM-finalene fra eldst til nyest",
     ["Hellas – Portugal", "Spania – Italia", "Portugal – Frankrike", "Italia – England", "Spania – England"], 2, "EM-historie"),
    ("Sorter Champions League-finalene fra eldst til nyest",
     ["Liverpool – AC Milan", "Inter – Bayern", "Bayern – Dortmund", "Barcelona – Juventus", "PSG – Inter"], 3, "Klubbfotball"),
    ("Sorter Champions League-finalene fra eldst til nyest",
     ["Man United – Chelsea", "Chelsea – Bayern", "Real Madrid – Juventus", "Real Madrid – Dortmund"], 3, "Klubbfotball"),
    ("Sorter Ballon d'Or-vinnerne fra eldst til nyest",
     ["George Weah", "Zinedine Zidane", "Luís Figo", "Pavel Nedvěd", "Fabio Cannavaro"], 4, "Spillere og rekorder"),
    ("Sorter Ballon d'Or-vinnerne fra eldst til nyest",
     ["Michael Owen", "Andrij Sjevtsjenko", "Ronaldinho", "Kaká", "Rodri"], 3, "Spillere og rekorder"),
    ("Sorter Premier League-mesterne fra eldst til nyest",
     ["Blackburn Rovers", "Arsenal (de ubeseirede)", "Chelsea (første tittel)", "Man City (første tittel)", "Leicester City"], 3, "Ligaer"),
    ("Sorter hendelsene i norsk fotball fra eldst til nyest",
     ["Norge tar OL-bronse i Berlin", "«Your boys took a hell of a beating»", "Norge slår Brasil", "Bodø/Glimt slår Roma 6–1", "Norge kvalifiserer seg til VM 2026"], 3, "Norge"),
    ("Sorter hendelsene fra eldst til nyest",
     ["Første VM i Uruguay", "Englands eneste VM-gull", "Leicester vinner Premier League", "VAR brukes i VM for første gang", "Messi vinner VM"], 2, "Visste du at?"),
    ("Sorter landene fra flest til færrest VM-titler",
     ["Brasil", "Argentina", "Frankrike", "Spania"], 2, "VM-historie"),
    ("Sorter klubbene fra flest til færrest Champions League-titler",
     ["Real Madrid", "AC Milan", "Barcelona", "Inter"], 3, "Klubbfotball"),
    ("Sorter spillerne fra flest til færrest Ballon d'Or",
     ["Lionel Messi", "Cristiano Ronaldo", "Michel Platini", "Luka Modrić"], 2, "Spillere og rekorder"),
    ("Sorter Premier League-toppscorerne fra flest til færrest mål",
     ["Alan Shearer", "Harry Kane", "Wayne Rooney", "Thierry Henry"], 4, "Spillere og rekorder"),
    ("Sorter stadionene fra nord til sør",
     ["Lerkendal", "Ullevaal stadion", "Parken", "Allianz Arena", "Camp Nou"], 2, "Stadioner"),
    ("Sorter stadionene fra nord til sør",
     ["Celtic Park", "Anfield", "Wembley", "Parc des Princes", "Stade Vélodrome"], 3, "Stadioner"),
    ("Sorter fra kortest til lengst avstand",
     ["Hjørnebuens radius", "Målets høyde", "Målets bredde", "Midtsirkelens radius"], 3, "Regler"),
    ("Sorter fra kortest til lengst tid",
     ["Så lenge keeperen kan holde ballen", "Én omgang i forlengning", "Én ordinær omgang", "En hel kamp med forlengning"], 2, "Regler"),
    ("Sorter VM-vertene fra eldst til nyest",
     ["Uruguay", "Sveits", "Sverige", "Chile", "Argentina"], 4, "VM-historie"),
    ("Sorter EM-vinnerne fra eldst til nyest",
     ["Sovjetunionen", "Tsjekkoslovakia", "Danmark", "Hellas", "Portugal"], 3, "EM-historie"),
    ("Sorter Manchester United-managerne fra først til sist",
     ["Matt Busby", "Alex Ferguson", "David Moyes", "José Mourinho", "Ole Gunnar Solskjær"], 2, "Trenere"),
]


def question_key(q):
    """Stabil id for et spørsmål (brukes av appen for å huske hva som er vist)."""
    raw = q["type"] + "|" + q["prompt"] + "|" + "|".join(sorted(q["options"]))
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:12]


def build():
    rng = random.Random(42)
    out = []
    for prompt, right, wrong, diff, era in QUIZ + QUIZ2:
        options = [right] + wrong
        if set(options) == {"Ja", "Nei"}:
            options = ["Ja", "Nei"]
        else:
            rng.shuffle(options)
        out.append({"type": "rules_quiz", "era": era, "prompt": prompt,
                    "options": options, "correct": options.index(right), "difficulty": diff})
    for prompt, ordered, diff, era in SORT + SORT2:
        idx = list(range(len(ordered)))
        rng.shuffle(idx)
        options = [ordered[i] for i in idx]
        correct = [options.index(item) for item in ordered]
        out.append({"type": "image_sort", "era": era, "prompt": prompt,
                    "options": options, "correct": correct, "difficulty": diff})
    for q in out:
        q["key"] = question_key(q)
    validate(out)
    return out


def validate(data):
    """Stopper hvis noe er galt: 2–4 alternativer, ingen duplikater, gyldig fasit."""
    problems, keys, prompts = [], set(), set()
    for q in data:
        opts = q["options"]
        if len(set(opts)) != len(opts):
            problems.append("like alternativer: " + q["prompt"])
        if q["type"] == "rules_quiz":
            if not 2 <= len(opts) <= 4:
                problems.append("må ha 2–4 alternativer: " + q["prompt"])
            if q["prompt"] in prompts:
                problems.append("spørsmålet finnes to ganger: " + q["prompt"])
            prompts.add(q["prompt"])
        elif sorted(q["correct"]) != list(range(len(opts))):
            problems.append("ugyldig rekkefølge: " + q["prompt"])
        if not 1 <= q["difficulty"] <= 5:
            problems.append("vanskelighet 1–5: " + q["prompt"])
        if q["key"] in keys:
            problems.append("duplikat: " + q["prompt"])
        keys.add(q["key"])
    if problems:
        raise SystemExit("\n".join(problems))


def sql_str(s):
    return "'" + s.replace("'", "''") + "'"


def main():
    data = build()
    (ROOT / "assets" / "seed").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets" / "seed" / "questions.json").write_text(
        json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    lines = ["-- Generert av tools/make_seed.py. Kjør i Supabase SQL Editor etter schema.sql.",
             "insert into public.questions (key, type, era, prompt, options, correct, difficulty) values"]
    rows = []
    for q in data:
        rows.append("  (%s, %s, %s, %s, %s::jsonb, %s::jsonb, %d)" % (
            sql_str(q["key"]), sql_str(q["type"]), sql_str(q["era"]), sql_str(q["prompt"]),
            sql_str(json.dumps(q["options"], ensure_ascii=False)),
            sql_str(json.dumps(q["correct"])), q["difficulty"]))
    lines.append(",\n".join(rows) + ";")
    (ROOT / "supabase" / "seed.sql").write_text("\n".join(lines) + "\n", encoding="utf-8")
    quiz = [q for q in data if q["type"] == "rules_quiz"]
    print(f"{len(data)} spørsmål ({len(quiz)} quiz + {len(data) - len(quiz)} sortering)")
    for era in sorted({q["era"] for q in data}):
        n = sum(1 for q in quiz if q["era"] == era)
        s = sum(1 for q in data if q["era"] == era) - n
        print(f"  {era:22} {n:4} quiz {s:3} sortering")


if __name__ == "__main__":
    main()
