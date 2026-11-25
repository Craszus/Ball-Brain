# -*- coding: utf-8 -*-
"""Bygger assets/seed/packs.json (Pro-spørsmålspakker). Kjør: python tools/make_packs.py

Hver rad: (norsk, engelsk, svar, engelske svar eller None, vanskelighet). Første svar er riktig
(appen stokker). Pakkene finnes på norsk og engelsk; andre språk viser engelsk.
VIKTIG: bare fakta som ikke endrer seg med neste sesong. Bør faktasjekkes av en fotballkyndig.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

CL = [
    ('Hvilken klubb har vunnet Serievinnercupen/Champions League flest ganger?', 'Which club has won the European Cup/Champions League most times?', ['Real Madrid', 'AC Milan', 'Liverpool', 'Bayern München'], ['Real Madrid', 'AC Milan', 'Liverpool', 'Bayern Munich'], 1),
    ('Hvilket år skiftet Serievinnercupen navn til Champions League?', 'In which year was the European Cup renamed the Champions League?', ['1992', '1989', '1995', '1999'], None, 2),
    ('Hvilket lag vant den aller første Serievinnercupen i 1956?', 'Which team won the very first European Cup in 1956?', ['Real Madrid', 'Stade de Reims', 'Benfica', 'AC Milan'], None, 3),
    ('Hvem scoret det berømte vinnermålet på volley i finalen i 2002?', 'Who scored the famous winning volley in the 2002 final?', ['Zinedine Zidane', 'Raúl', 'Roberto Carlos', 'Luís Figo'], None, 2),
    ('Hvilket lag hentet inn 0–3 fra pause og vant finalen i 2005?', 'Which team came back from 0–3 at half-time to win the 2005 final?', ['Liverpool', 'AC Milan', 'Chelsea', 'Porto'], None, 1),
    ('Hvem trente Porto da de vant Champions League i 2004?', 'Who managed Porto when they won the 2004 Champions League?', ['José Mourinho', 'André Villas-Boas', 'Jorge Jesus', 'Fernando Santos'], None, 2),
    ('Hvilken norsk spiller scoret vinnermålet for Manchester United i finalen i 1999?', "Which Norwegian scored Manchester United's winner in the 1999 final?", ['Ole Gunnar Solskjær', 'Ronny Johnsen', 'Henning Berg', 'Tore André Flo'], None, 1),
    ('Hvem er tidenes toppscorer i Champions League?', 'Who is the all-time top scorer in the Champions League?', ['Cristiano Ronaldo', 'Lionel Messi', 'Robert Lewandowski', 'Karim Benzema'], None, 1),
    ('Hvilken engelsk klubb vant Serievinnercupen to år på rad i 1979 og 1980?', 'Which English club won the European Cup two years running in 1979 and 1980?', ['Nottingham Forest', 'Aston Villa', 'Liverpool', 'Leeds United'], None, 3),
    ('Hvilken skotsk klubb vant Serievinnercupen i 1967?', 'Which Scottish club won the European Cup in 1967?', ['Celtic', 'Rangers', 'Aberdeen', 'Dundee United'], None, 2),
    ('Hvem scoret etter under ett minutt i finalen i 2005?', 'Who scored inside the first minute of the 2005 final?', ['Paolo Maldini', 'Hernán Crespo', 'Kaká', 'Steven Gerrard'], None, 3),
    ('Hvilken klubb vant Champions League for første gang i 2023?', 'Which club won the Champions League for the first time in 2023?', ['Manchester City', 'Inter', 'Paris Saint-Germain', 'Arsenal'], None, 1),
    ('I hvilken by ble finalen i 2005 spilt?', 'In which city was the 2005 final played?', ['Istanbul', 'Athen', 'Moskva', 'Gelsenkirchen'], ['Istanbul', 'Athens', 'Moscow', 'Gelsenkirchen'], 2),
    ('Hvor mange lag er med i ligafasen fra sesongen 2024–25?', 'How many teams play in the league phase from the 2024–25 season?', ['36', '32', '24', '40'], None, 3),
    ('Hvilken norsk klubb slo AC Milan på San Siro i 1996?', 'Which Norwegian club beat AC Milan at the San Siro in 1996?', ['Rosenborg', 'Molde', 'Brann', 'Lillestrøm'], None, 2),
]

PL = [
    ('Hvilket år startet Premier League?', 'In which year did the Premier League start?', ['1992', '1988', '1990', '1995'], None, 1),
    ('Hvem vant den første Premier League-sesongen (1992–93)?', 'Who won the first Premier League season (1992–93)?', ['Manchester United', 'Blackburn Rovers', 'Arsenal', 'Leeds United'], None, 2),
    ('Hvilket lag gikk ubeseiret gjennom sesongen 2003–04?', 'Which team went unbeaten through the 2003–04 season?', ['Arsenal', 'Chelsea', 'Manchester United', 'Liverpool'], None, 1),
    ('Hvem er tidenes toppscorer i Premier League?', 'Who is the all-time top scorer in the Premier League?', ['Alan Shearer', 'Harry Kane', 'Wayne Rooney', 'Thierry Henry'], None, 2),
    ('Hvilken klubb vant overraskende ligaen i 2015–16?', 'Which club were the surprise champions in 2015–16?', ['Leicester City', 'Tottenham', 'West Ham', 'Southampton'], None, 1),
    ('Hvem vant Premier League i 1994–95?', 'Who won the Premier League in 1994–95?', ['Blackburn Rovers', 'Manchester United', 'Newcastle United', 'Liverpool'], None, 2),
    ('Hvem har flest målgivende pasninger i Premier League gjennom tidene?', 'Who has the most assists in Premier League history?', ['Ryan Giggs', 'Cesc Fàbregas', 'Kevin De Bruyne', 'Frank Lampard'], None, 3),
    ('Hvem scoret målet på overtid som ga Manchester City tittelen i 2012?', 'Who scored the stoppage-time goal that won Manchester City the title in 2012?', ['Sergio Agüero', 'Edin Džeko', 'David Silva', 'Mario Balotelli'], None, 1),
    ('Hvor mange poeng tok Manchester City i rekordsesongen 2017–18?', 'How many points did Manchester City take in the record 2017–18 season?', ['100', '95', '98', '106'], None, 3),
    ('Hvilken keeper har holdt nullen flest ganger i Premier League?', 'Which goalkeeper has kept the most Premier League clean sheets?', ['Petr Čech', 'David James', 'David de Gea', 'Edwin van der Sar'], None, 3),
    ('Hva heter hjemmebanen til Liverpool?', "What is the name of Liverpool's home ground?", ['Anfield', 'Goodison Park', 'Old Trafford', 'Villa Park'], None, 1),
    ('Hvem var manager for Arsenal i den ubeseirede sesongen?', 'Who managed Arsenal in the unbeaten season?', ['Arsène Wenger', 'George Graham', 'Unai Emery', 'Bruce Rioch'], None, 1),
    ('Hvor mange lag spiller i Premier League?', 'How many teams play in the Premier League?', ['20', '18', '22', '24'], None, 1),
    ('Hvilken klubb har kallenavnet «The Toffees»?', 'Which club is nicknamed "The Toffees"?', ['Everton', 'Fulham', 'Burnley', 'Brentford'], None, 2),
    ('Hvor mange ligamål scoret Erling Haaland i debutsesongen 2022–23?', 'How many league goals did Erling Haaland score in his debut season 2022–23?', ['36', '32', '34', '38'], None, 2),
]

NOR = [
    ('Hvilken klubb har vunnet flest seriemesterskap i Norge for herrer?', "Which club has won the most Norwegian men's league titles?", ['Rosenborg', 'Fredrikstad', 'Viking', 'Brann'], None, 1),
    ('Hvilket år slo Norge Brasil 2–1 i VM?', 'In which year did Norway beat Brazil 2–1 at the World Cup?', ['1998', '1994', '2002', '1990'], None, 1),
    ('Hvem satte inn straffesparket mot Brasil i VM 1998?', 'Who scored the penalty against Brazil at the 1998 World Cup?', ['Kjetil Rekdal', 'Tore André Flo', 'Øyvind Leonhardsen', 'Håvard Flo'], None, 2),
    ('Hvem trente herrelandslaget i VM 1994 og 1998?', "Who coached Norway's men at the 1994 and 1998 World Cups?", ['Egil «Drillo» Olsen', 'Nils Johan Semb', 'Ingvar Stadheim', 'Åge Hareide'], ['Egil "Drillo" Olsen', 'Nils Johan Semb', 'Ingvar Stadheim', 'Åge Hareide'], 1),
    ('Hva heter nasjonalarenaen for fotball i Norge?', "What is Norway's national football stadium called?", ['Ullevaal Stadion', 'Lerkendal Stadion', 'Brann Stadion', 'Intility Arena'], None, 1),
    ('Hvilken norsk klubb nådde semifinalen i Europaligaen i 2025?', 'Which Norwegian club reached the Europa League semi-final in 2025?', ['Bodø/Glimt', 'Molde', 'Rosenborg', 'Brann'], None, 1),
    ('Hvilken medalje tok Norge i OL-fotballen i 1936?', 'Which medal did Norway win in Olympic football in 1936?', ['Bronse', 'Sølv', 'Gull', 'Ingen medalje'], ['Bronze', 'Silver', 'Gold', 'No medal'], 3),
    ('Hvilken by kommer Brann fra?', 'Which city are Brann from?', ['Bergen', 'Stavanger', 'Trondheim', 'Drammen'], None, 1),
    ('Hva heter hjemmebanen til Bodø/Glimt?', "What is Bodø/Glimt's home ground called?", ['Aspmyra Stadion', 'Romssa Arena', 'Aker Stadion', 'Color Line Stadion'], None, 2),
    ('Hvilket år spilte Norges herrer sist i EM?', "In which year did Norway's men last play at the Euros?", ['2000', '1996', '2004', '2008'], None, 2),
    ('Hvem scoret Norges vinnermål mot Spania i EM 2000?', "Who scored Norway's winner against Spain at Euro 2000?", ['Steffen Iversen', 'Ole Gunnar Solskjær', 'John Carew', 'Tore André Flo'], None, 3),
    ('Hvem er tidenes toppscorer på herrelandslaget?', "Who is the all-time top scorer for Norway's men?", ['Erling Haaland', 'Jørgen Juve', 'Einar Gundersen', 'John Carew'], None, 1),
    ('Hvem hadde målrekorden på herrelandslaget med 33 mål i flere tiår?', "Who held the Norway men's record of 33 goals for decades?", ['Jørgen Juve', 'Einar Gundersen', 'Harald Hennum', 'Odd Iversen'], None, 3),
    ('Hvilken klubb vant både serien og cupen i 2014?', 'Which club won both the league and the cup in 2014?', ['Molde', 'Rosenborg', 'Strømsgodset', 'Odd'], None, 3),
    ('Hvilken klubb spiller hjemmekampene på Lerkendal?', 'Which club play their home matches at Lerkendal?', ['Rosenborg', 'Ranheim', 'Molde', 'Kristiansund'], None, 1),
]

REF = [
    ('Hvor langt unna ballen må motspillerne stå ved frispark?', 'How far from the ball must opponents be at a free kick?', ['9,15 meter', '7,32 meter', '11 meter', '5,5 meter'], ['9.15 metres', '7.32 metres', '11 metres', '5.5 metres'], 1),
    ('Hva er de offisielle målene på et fotballmål (bredde × høyde)?', 'What are the official goal dimensions (width × height)?', ['7,32 × 2,44 m', '7,50 × 2,50 m', '7,00 × 2,40 m', '6,32 × 2,24 m'], ['7.32 × 2.44 m', '7.50 × 2.50 m', '7.00 × 2.40 m', '6.32 × 2.24 m'], 2),
    ('Hvor få spillere kan et lag ha uten at kampen må stoppes?', 'What is the fewest players a team may have for the match to continue?', ['7', '6', '8', '9'], None, 2),
    ('Et direkte frispark sparkes rett i eget mål. Hva dømmes?', 'A direct free kick goes straight into your own goal. What is awarded?', ['Hjørnespark', 'Mål', 'Frisparket tas om', 'Indirekte frispark'], ['Corner kick', 'Goal', 'The free kick is retaken', 'Indirect free kick'], 3),
    ('Hva dømmes når keeperen holder ballen i hendene i mer enn åtte sekunder (regel fra 2025)?', 'What is awarded when the goalkeeper holds the ball for more than eight seconds (law from 2025)?', ['Hjørnespark til motstanderen', 'Indirekte frispark', 'Straffespark', 'Dommerball'], ['Corner kick to the opponents', 'Indirect free kick', 'Penalty kick', 'Dropped ball'], 3),
    ('Kan en spiller bli dømt for offside direkte fra målspark?', 'Can a player be offside directly from a goal kick?', ['Nei', 'Ja'], None, 1),
    ('Kan en spiller være i offsideposisjon på egen banehalvdel?', 'Can a player be in an offside position in their own half?', ['Nei', 'Ja'], None, 1),
    ('Ballen treffer dommeren, og motstanderen får ballen. Hva skjer?', 'The ball hits the referee and the opponents get possession. What happens?', ['Dommerball', 'Spillet fortsetter', 'Indirekte frispark', 'Innkast'], ['Dropped ball', 'Play continues', 'Indirect free kick', 'Throw-in'], 2),
    ('Hva kreves av keeperen idet et straffespark tas?', 'What is required of the goalkeeper as a penalty is taken?', ['Del av minst én fot på, på linje med eller bak mållinjen', 'Begge føtter foran mållinjen', 'Stå helt i ro', 'Stå minst en meter bak mållinjen'], ['Part of at least one foot on, in line with or behind the goal line', 'Both feet in front of the goal line', 'Stand completely still', 'Stand at least a metre behind the goal line'], 3),
    ('En spiller tar av seg trøya for å feire et mål. Hva skal dommeren gjøre?', 'A player removes their shirt to celebrate a goal. What should the referee do?', ['Gi gult kort', 'Gi rødt kort', 'Annullere målet', 'Ingenting'], ['Show a yellow card', 'Show a red card', 'Disallow the goal', 'Nothing'], 1),
    ('Hvor langt er det fra straffemerket til mållinjen?', 'How far is the penalty mark from the goal line?', ['11 meter', '9,15 meter', '12 meter', '16,5 meter'], ['11 metres', '9.15 metres', '12 metres', '16.5 metres'], 1),
    ('Keeperen tar med hendene et bevisst tilbakespill med foten fra en medspiller. Hva dømmes?', "The goalkeeper handles a ball deliberately kicked to them by a teammate. What is awarded?", ['Indirekte frispark', 'Direkte frispark', 'Straffespark', 'Hjørnespark'], ['Indirect free kick', 'Direct free kick', 'Penalty kick', 'Corner kick'], 2),
    ('En takling med overdreven kraft setter motstanderen i fare. Hva er riktig reaksjon?', 'A tackle with excessive force endangers an opponent. What is the correct sanction?', ['Rødt kort', 'Gult kort', 'Bare frispark', 'Muntlig advarsel'], ['Red card', 'Yellow card', 'Free kick only', 'Verbal warning'], 1),
    ('Kan det scores mål direkte fra et innkast?', 'Can a goal be scored directly from a throw-in?', ['Nei', 'Ja'], None, 1),
    ('Hvor høyt må hjørneflaggstangen minst være?', 'What is the minimum height of a corner flagpost?', ['1,5 meter', '1 meter', '1,2 meter', '2 meter'], ['1.5 metres', '1 metre', '1.2 metres', '2 metres'], 4),
]

PACKS = [
    ('cl', 'Champions League', 'Finaler, helter og rekorder i Europa', CL),
    ('pl', 'Premier League', 'Mestere, mål og managere', PL),
    ('nor', 'Norsk fotball', 'Landslaget, klubbene og de store øyeblikkene', NOR),
    ('ref', 'Dommerskolen', 'Vanskelige situasjoner fra regelboka', REF),
]


def english():
    """Norsk -> engelsk for alle spørsmål og svar som må oversettes (brukes av make_i18n.py)."""
    out = {}
    for _, _, _, rows in PACKS:
        for nb, en, options, en_options, _ in rows:
            out[nb] = en
            for a, b in zip(options, en_options or []):
                if a != b:
                    out[a] = b
    return out


def main():
    data = []
    for pid, title, subtitle, rows in PACKS:
        qs = []
        for i, (nb, _, options, en_options, difficulty) in enumerate(rows, 1):
            assert len(set(options)) == len(options), nb
            assert en_options is None or len(en_options) == len(options), nb
            correct = 0
            if set(options) == {'Ja', 'Nei'}:  # «Ja/Nei» står alltid i samme rekkefølge
                correct = ['Ja', 'Nei'].index(options[0])
                options = ['Ja', 'Nei']
            qs.append({'key': 'pack-%s-%02d' % (pid, i), 'prompt': nb, 'options': options,
                       'correct': correct, 'difficulty': difficulty})
        data.append({'id': pid, 'title': title, 'subtitle': subtitle, 'questions': qs})
    out = ROOT / 'assets' / 'seed' / 'packs.json'
    out.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding='utf8')
    print(sum(len(p['questions']) for p in data), 'spørsmål i', len(data), 'pakker')


if __name__ == '__main__':
    main()
