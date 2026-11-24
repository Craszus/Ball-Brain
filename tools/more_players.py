"""Legger til flere spillere (og målvakter) i assets/media/players.json uten å røre de som finnes
(beskjæring, filer og manuelle rettelser beholdes).

Kjør:  python tools/more_players.py
Bruker samme regler som tools/fetch_commons.py (bare fri lisens, portrettbilde).
Etterpå: python tools/face_crops.py  (bare nye får utsnitt) og  python tools/bundle_media.py
Hver spiller har felt «pos»: 'GK' for målvakter, ellers 'UT' (utespiller).
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fetch_commons as fc  # noqa: E402

# (wikipedia-tittel, visningsnavn, land, posisjon)
EXTRA = [
    # --- målvakter
    ("Gianluigi Donnarumma", "Gianluigi Donnarumma", "Italia", "GK"),
    ("Ederson (footballer, born 1993)", "Ederson", "Brasil", "GK"),
    ("Jan Oblak", "Jan Oblak", "Slovenia", "GK"),
    ("Marc-André ter Stegen", "Marc-André ter Stegen", "Tyskland", "GK"),
    ("Mike Maignan", "Mike Maignan", "Frankrike", "GK"),
    ("Hugo Lloris", "Hugo Lloris", "Frankrike", "GK"),
    ("Gianluigi Buffon", "Gianluigi Buffon", "Italia", "GK"),
    ("Iker Casillas", "Iker Casillas", "Spania", "GK"),
    ("Oliver Kahn", "Oliver Kahn", "Tyskland", "GK"),
    ("Peter Schmeichel", "Peter Schmeichel", "Danmark", "GK"),
    ("Kasper Schmeichel", "Kasper Schmeichel", "Danmark", "GK"),
    ("Emiliano Martínez", "Emiliano Martínez", "Argentina", "GK"),
    ("André Onana", "André Onana", "Kamerun", "GK"),
    ("David Raya", "David Raya", "Spania", "GK"),
    ("Jordan Pickford", "Jordan Pickford", "England", "GK"),
    ("Keylor Navas", "Keylor Navas", "Costa Rica", "GK"),
    ("Wojciech Szczęsny", "Wojciech Szczęsny", "Polen", "GK"),
    ("Ørjan Nyland", "Ørjan Nyland", "Norge", "GK"),
    ("Aaron Ramsdale", "Aaron Ramsdale", "England", "GK"),
    ("Kepa Arrizabalaga", "Kepa Arrizabalaga", "Spania", "GK"),
    ("Yann Sommer", "Yann Sommer", "Sveits", "GK"),
    ("Edwin van der Sar", "Edwin van der Sar", "Nederland", "GK"),
    ("Petr Čech", "Petr Čech", "Tsjekkia", "GK"),
    ("Dominik Livaković", "Dominik Livaković", "Kroatia", "GK"),
    ("Yassine Bounou", "Yassine Bounou", "Marokko", "GK"),
    ("Lev Yashin", "Lev Jasjin", "Sovjetunionen", "GK"),
    ("Dino Zoff", "Dino Zoff", "Italia", "GK"),
    # --- utespillere
    ("Kaká", "Kaká", "Brasil", "UT"),
    ("Ronaldo (Brazilian footballer)", "Ronaldo Nazário", "Brasil", "UT"),
    ("Rivaldo", "Rivaldo", "Brasil", "UT"),
    ("Roberto Carlos", "Roberto Carlos", "Brasil", "UT"),
    ("Cafu", "Cafu", "Brasil", "UT"),
    ("Rodrygo", "Rodrygo", "Brasil", "UT"),
    ("Casemiro", "Casemiro", "Brasil", "UT"),
    ("Andrea Pirlo", "Andrea Pirlo", "Italia", "UT"),
    ("Francesco Totti", "Francesco Totti", "Italia", "UT"),
    ("Paolo Maldini", "Paolo Maldini", "Italia", "UT"),
    ("Roberto Baggio", "Roberto Baggio", "Italia", "UT"),
    ("Lorenzo Insigne", "Lorenzo Insigne", "Italia", "UT"),
    ("Michel Platini", "Michel Platini", "Frankrike", "UT"),
    ("Eric Cantona", "Eric Cantona", "Frankrike", "UT"),
    ("N'Golo Kanté", "N'Golo Kanté", "Frankrike", "UT"),
    ("Paul Pogba", "Paul Pogba", "Frankrike", "UT"),
    ("Marco van Basten", "Marco van Basten", "Nederland", "UT"),
    ("Ruud Gullit", "Ruud Gullit", "Nederland", "UT"),
    ("Dennis Bergkamp", "Dennis Bergkamp", "Nederland", "UT"),
    ("Frenkie de Jong", "Frenkie de Jong", "Nederland", "UT"),
    ("Memphis Depay", "Memphis Depay", "Nederland", "UT"),
    ("Cody Gakpo", "Cody Gakpo", "Nederland", "UT"),
    ("Paul Scholes", "Paul Scholes", "England", "UT"),
    ("Frank Lampard", "Frank Lampard", "England", "UT"),
    ("John Terry", "John Terry", "England", "UT"),
    ("Alan Shearer", "Alan Shearer", "England", "UT"),
    ("Trent Alexander-Arnold", "Trent Alexander-Arnold", "England", "UT"),
    ("Jack Grealish", "Jack Grealish", "England", "UT"),
    ("Sergio Agüero", "Sergio Agüero", "Argentina", "UT"),
    ("Ángel Di María", "Ángel Di María", "Argentina", "UT"),
    ("Paulo Dybala", "Paulo Dybala", "Argentina", "UT"),
    ("Lautaro Martínez", "Lautaro Martínez", "Argentina", "UT"),
    ("Julián Álvarez", "Julián Álvarez", "Argentina", "UT"),
    ("Enzo Fernández", "Enzo Fernández", "Argentina", "UT"),
    ("Rúben Dias", "Rúben Dias", "Portugal", "UT"),
    ("Bernardo Silva", "Bernardo Silva", "Portugal", "UT"),
    ("Rafael Leão", "Rafael Leão", "Portugal", "UT"),
    ("Luís Figo", "Luís Figo", "Portugal", "UT"),
    ("Toni Kroos", "Toni Kroos", "Tyskland", "UT"),
    ("Thomas Müller", "Thomas Müller", "Tyskland", "UT"),
    ("Jamal Musiala", "Jamal Musiala", "Tyskland", "UT"),
    ("Florian Wirtz", "Florian Wirtz", "Tyskland", "UT"),
    ("Joshua Kimmich", "Joshua Kimmich", "Tyskland", "UT"),
    ("Mesut Özil", "Mesut Özil", "Tyskland", "UT"),
    ("Romelu Lukaku", "Romelu Lukaku", "Belgia", "UT"),
    ("Eden Hazard", "Eden Hazard", "Belgia", "UT"),
    ("Christian Pulisic", "Christian Pulisic", "USA", "UT"),
    ("Alphonso Davies", "Alphonso Davies", "Canada", "UT"),
    ("Takefusa Kubo", "Takefusa Kubo", "Japan", "UT"),
    ("Kaoru Mitoma", "Kaoru Mitoma", "Japan", "UT"),
    ("Alexander Isak", "Alexander Isak", "Sverige", "UT"),
    ("Dejan Kulusevski", "Dejan Kulusevski", "Sverige", "UT"),
    ("Christian Eriksen", "Christian Eriksen", "Danmark", "UT"),
    ("Rasmus Højlund", "Rasmus Højlund", "Danmark", "UT"),
    ("Joshua King (footballer)", "Joshua King", "Norge", "UT"),
    ("John Arne Riise", "John Arne Riise", "Norge", "UT"),
    ("Sander Berge", "Sander Berge", "Norge", "UT"),
    ("Riyad Mahrez", "Riyad Mahrez", "Algerie", "UT"),
    ("Didier Drogba", "Didier Drogba", "Elfenbenskysten", "UT"),
    ("Samuel Eto'o", "Samuel Eto'o", "Kamerun", "UT"),
    ("Yaya Touré", "Yaya Touré", "Elfenbenskysten", "UT"),
    ("Luis Díaz", "Luis Díaz", "Colombia", "UT"),
    ("James Rodríguez", "James Rodríguez", "Colombia", "UT"),
    ("Darwin Núñez", "Darwin Núñez", "Uruguay", "UT"),
    ("Edinson Cavani", "Edinson Cavani", "Uruguay", "UT"),
    ("Alexis Sánchez", "Alexis Sánchez", "Chile", "UT"),
    ("Robin van Persie", "Robin van Persie", "Nederland", "UT"),
    ("Xabi Alonso", "Xabi Alonso", "Spania", "UT"),
    ("Sergio Busquets", "Sergio Busquets", "Spania", "UT"),
    ("Gerard Piqué", "Gerard Piqué", "Spania", "UT"),
    ("Carles Puyol", "Carles Puyol", "Spania", "UT"),
    ("Raúl (footballer)", "Raúl", "Spania", "UT"),
    ("David Villa", "David Villa", "Spania", "UT"),
    ("Fernando Torres", "Fernando Torres", "Spania", "UT"),
    ("Dani Carvajal", "Dani Carvajal", "Spania", "UT"),
    ("Nico Williams", "Nico Williams", "Spania", "UT"),
]

# Runde 2 (2026-11-24): flere målvakter, legender, kvinner og flere land.
# Bare denne listen hentes (de gamle listene over er allerede kjørt; noen av dem er fjernet
# for hånd pga. logoer/dårlig utsnitt og skal ikke komme tilbake).
NEW = [
    # --- målvakter
    ("Unai Simón", "Unai Simón", "Spania", "GK"),
    ("Diogo Costa", "Diogo Costa", "Portugal", "GK"),
    ("Gregor Kobel", "Gregor Kobel", "Sveits", "GK"),
    ("Guglielmo Vicario", "Guglielmo Vicario", "Italia", "GK"),
    ("Bart Verbruggen", "Bart Verbruggen", "Nederland", "GK"),
    ("Nick Pope", "Nick Pope", "England", "GK"),
    ("Alex Meret", "Alex Meret", "Italia", "GK"),
    ("Andriy Lunin", "Andriy Lunin", "Ukraina", "GK"),
    ("Kevin Trapp", "Kevin Trapp", "Tyskland", "GK"),
    ("Bernd Leno", "Bernd Leno", "Tyskland", "GK"),
    ("Lukáš Hrádecký", "Lukáš Hrádecký", "Finland", "GK"),
    ("Samir Handanović", "Samir Handanović", "Slovenia", "GK"),
    ("Pepe Reina", "Pepe Reina", "Spania", "GK"),
    ("Víctor Valdés", "Víctor Valdés", "Spania", "GK"),
    ("David de Gea", "David de Gea", "Spania", "GK"),
    ("Joe Hart", "Joe Hart", "England", "GK"),
    ("David Seaman", "David Seaman", "England", "GK"),
    ("Gordon Banks", "Gordon Banks", "England", "GK"),
    ("Peter Shilton", "Peter Shilton", "England", "GK"),
    ("Rinat Dasayev", "Rinat Dasajev", "Sovjetunionen", "GK"),
    ("Sepp Maier", "Sepp Maier", "Tyskland", "GK"),
    ("Jens Lehmann", "Jens Lehmann", "Tyskland", "GK"),
    ("Fabien Barthez", "Fabien Barthez", "Frankrike", "GK"),
    ("Claudio Bravo", "Claudio Bravo", "Chile", "GK"),
    ("Guillermo Ochoa", "Guillermo Ochoa", "Mexico", "GK"),
    ("Tim Howard", "Tim Howard", "USA", "GK"),
    ("Brad Friedel", "Brad Friedel", "USA", "GK"),
    ("Mark Schwarzer", "Mark Schwarzer", "Australia", "GK"),
    ("Shay Given", "Shay Given", "Irland", "GK"),
    ("Jerzy Dudek", "Jerzy Dudek", "Polen", "GK"),
    ("Júlio César (footballer, born 1979)", "Júlio César", "Brasil", "GK"),
    ("Dida (footballer, born 1973)", "Dida", "Brasil", "GK"),
    ("Rogério Ceni", "Rogério Ceni", "Brasil", "GK"),
    ("Santiago Cañizares", "Santiago Cañizares", "Spania", "GK"),
    ("Andoni Zubizarreta", "Andoni Zubizarreta", "Spania", "GK"),
    ("René Higuita", "René Higuita", "Colombia", "GK"),
    ("José Luis Chilavert", "José Luis Chilavert", "Paraguay", "GK"),
    ("Thomas Ravelli", "Thomas Ravelli", "Sverige", "GK"),
    ("Erik Thorstvedt", "Erik Thorstvedt", "Norge", "GK"),
    ("Rune Jarstein", "Rune Jarstein", "Norge", "GK"),
    ("Frode Grodås", "Frode Grodås", "Norge", "GK"),
    ("Walter Zenga", "Walter Zenga", "Italia", "GK"),
    ("Francesco Toldo", "Francesco Toldo", "Italia", "GK"),
    ("Vincent Enyeama", "Vincent Enyeama", "Nigeria", "GK"),
    ("Rui Patrício", "Rui Patrício", "Portugal", "GK"),
    ("Steve Mandanda", "Steve Mandanda", "Frankrike", "GK"),
    ("Łukasz Fabiański", "Łukasz Fabiański", "Polen", "GK"),
    ("Édouard Mendy", "Édouard Mendy", "Senegal", "GK"),
    ("Mat Ryan", "Mat Ryan", "Australia", "GK"),
    ("Alphonse Areola", "Alphonse Areola", "Frankrike", "GK"),
    # --- utespillere: legender
    ("Bobby Charlton", "Bobby Charlton", "England", "UT"),
    ("Bobby Moore", "Bobby Moore", "England", "UT"),
    ("Gary Lineker", "Gary Lineker", "England", "UT"),
    ("Michael Owen", "Michael Owen", "England", "UT"),
    ("Rio Ferdinand", "Rio Ferdinand", "England", "UT"),
    ("George Best", "George Best", "Nord-Irland", "UT"),
    ("Kenny Dalglish", "Kenny Dalglish", "Skottland", "UT"),
    ("Ryan Giggs", "Ryan Giggs", "Wales", "UT"),
    ("Roy Keane", "Roy Keane", "Irland", "UT"),
    ("Robbie Keane", "Robbie Keane", "Irland", "UT"),
    ("Gerd Müller", "Gerd Müller", "Tyskland", "UT"),
    ("Lothar Matthäus", "Lothar Matthäus", "Tyskland", "UT"),
    ("Jürgen Klinsmann", "Jürgen Klinsmann", "Tyskland", "UT"),
    ("Miroslav Klose", "Miroslav Klose", "Tyskland", "UT"),
    ("Philipp Lahm", "Philipp Lahm", "Tyskland", "UT"),
    ("Bastian Schweinsteiger", "Bastian Schweinsteiger", "Tyskland", "UT"),
    ("Michael Ballack", "Michael Ballack", "Tyskland", "UT"),
    ("Fabio Cannavaro", "Fabio Cannavaro", "Italia", "UT"),
    ("Alessandro Del Piero", "Alessandro Del Piero", "Italia", "UT"),
    ("Alessandro Nesta", "Alessandro Nesta", "Italia", "UT"),
    ("Giorgio Chiellini", "Giorgio Chiellini", "Italia", "UT"),
    ("Gennaro Gattuso", "Gennaro Gattuso", "Italia", "UT"),
    ("Filippo Inzaghi", "Filippo Inzaghi", "Italia", "UT"),
    ("Patrick Vieira", "Patrick Vieira", "Frankrike", "UT"),
    ("Claude Makélélé", "Claude Makélélé", "Frankrike", "UT"),
    ("Franck Ribéry", "Franck Ribéry", "Frankrike", "UT"),
    ("Olivier Giroud", "Olivier Giroud", "Frankrike", "UT"),
    ("Arjen Robben", "Arjen Robben", "Nederland", "UT"),
    ("Wesley Sneijder", "Wesley Sneijder", "Nederland", "UT"),
    ("Clarence Seedorf", "Clarence Seedorf", "Nederland", "UT"),
    ("Ruud van Nistelrooy", "Ruud van Nistelrooy", "Nederland", "UT"),
    ("Eusébio", "Eusébio", "Portugal", "UT"),
    ("Deco", "Deco", "Portugal", "UT"),
    ("Romário", "Romário", "Brasil", "UT"),
    ("Zico", "Zico", "Brasil", "UT"),
    ("Sócrates (footballer)", "Sócrates", "Brasil", "UT"),
    ("Marcelo (footballer, born 1988)", "Marcelo", "Brasil", "UT"),
    ("Thiago Silva", "Thiago Silva", "Brasil", "UT"),
    ("Dani Alves", "Dani Alves", "Brasil", "UT"),
    ("Gabriel Batistuta", "Gabriel Batistuta", "Argentina", "UT"),
    ("Javier Zanetti", "Javier Zanetti", "Argentina", "UT"),
    ("Juan Román Riquelme", "Juan Román Riquelme", "Argentina", "UT"),
    ("Carlos Tevez", "Carlos Tevez", "Argentina", "UT"),
    ("Javier Mascherano", "Javier Mascherano", "Argentina", "UT"),
    ("Diego Forlán", "Diego Forlán", "Uruguay", "UT"),
    ("Davor Šuker", "Davor Šuker", "Kroatia", "UT"),
    ("Ivan Rakitić", "Ivan Rakitić", "Kroatia", "UT"),
    ("Michael Laudrup", "Michael Laudrup", "Danmark", "UT"),
    ("Brian Laudrup", "Brian Laudrup", "Danmark", "UT"),
    ("Henrik Larsson", "Henrik Larsson", "Sverige", "UT"),
    ("Andriy Shevchenko", "Andrij Sjevtsjenko", "Ukraina", "UT"),
    ("Hristo Stoichkov", "Hristo Stoitsjkov", "Bulgaria", "UT"),
    ("Gheorghe Hagi", "Gheorghe Hagi", "Romania", "UT"),
    ("Pavel Nedvěd", "Pavel Nedvěd", "Tsjekkia", "UT"),
    ("George Weah", "George Weah", "Liberia", "UT"),
    ("Jay-Jay Okocha", "Jay-Jay Okocha", "Nigeria", "UT"),
    ("Michael Essien", "Michael Essien", "Ghana", "UT"),
    ("Park Ji-sung", "Park Ji-sung", "Sør-Korea", "UT"),
    ("Hidetoshi Nakata", "Hidetoshi Nakata", "Japan", "UT"),
    ("Ali Daei", "Ali Daei", "Iran", "UT"),
    ("Hakan Şükür", "Hakan Şükür", "Tyrkia", "UT"),
    ("Jari Litmanen", "Jari Litmanen", "Finland", "UT"),
    ("Carlos Valderrama", "Carlos Valderrama", "Colombia", "UT"),
    ("Landon Donovan", "Landon Donovan", "USA", "UT"),
    ("Rafael Márquez", "Rafael Márquez", "Mexico", "UT"),
    ("Tore André Flo", "Tore André Flo", "Norge", "UT"),
    ("John Carew", "John Carew", "Norge", "UT"),
    ("Henning Berg", "Henning Berg", "Norge", "UT"),
    ("Rune Bratseth", "Rune Bratseth", "Norge", "UT"),
    ("Steffen Iversen", "Steffen Iversen", "Norge", "UT"),
    # --- utespillere: i dag
    ("Ilkay Gündoğan", "İlkay Gündoğan", "Tyskland", "UT"),
    ("Kai Havertz", "Kai Havertz", "Tyskland", "UT"),
    ("Leroy Sané", "Leroy Sané", "Tyskland", "UT"),
    ("Antonio Rüdiger", "Antonio Rüdiger", "Tyskland", "UT"),
    ("Ousmane Dembélé", "Ousmane Dembélé", "Frankrike", "UT"),
    ("Aurélien Tchouaméni", "Aurélien Tchouaméni", "Frankrike", "UT"),
    ("William Saliba", "William Saliba", "Frankrike", "UT"),
    ("Nicolò Barella", "Nicolò Barella", "Italia", "UT"),
    ("Federico Chiesa", "Federico Chiesa", "Italia", "UT"),
    ("Jordi Alba", "Jordi Alba", "Spania", "UT"),
    ("Dani Olmo", "Dani Olmo", "Spania", "UT"),
    ("Álvaro Morata", "Álvaro Morata", "Spania", "UT"),
    ("Gavi", "Gavi", "Spania", "UT"),
    ("Cole Palmer", "Cole Palmer", "England", "UT"),
    ("John Stones", "John Stones", "England", "UT"),
    ("Kyle Walker", "Kyle Walker", "England", "UT"),
    ("Raheem Sterling", "Raheem Sterling", "England", "UT"),
    ("Matthijs de Ligt", "Matthijs de Ligt", "Nederland", "UT"),
    ("Xavi Simons", "Xavi Simons", "Nederland", "UT"),
    ("João Félix", "João Félix", "Portugal", "UT"),
    ("João Cancelo", "João Cancelo", "Portugal", "UT"),
    ("Vitinha", "Vitinha", "Portugal", "UT"),
    ("Raphinha", "Raphinha", "Brasil", "UT"),
    ("Gabriel Martinelli", "Gabriel Martinelli", "Brasil", "UT"),
    ("Alexis Mac Allister", "Alexis Mac Allister", "Argentina", "UT"),
    ("Ronald Araújo", "Ronald Araújo", "Uruguay", "UT"),
    ("Joško Gvardiol", "Joško Gvardiol", "Kroatia", "UT"),
    ("Mateo Kovačić", "Mateo Kovačić", "Kroatia", "UT"),
    ("Jérémy Doku", "Jérémy Doku", "Belgia", "UT"),
    ("Viktor Gyökeres", "Viktor Gyökeres", "Sverige", "UT"),
    ("Pierre-Emile Højbjerg", "Pierre-Emile Højbjerg", "Danmark", "UT"),
    ("Antonio Nusa", "Antonio Nusa", "Norge", "UT"),
    ("Oscar Bobb", "Oscar Bobb", "Norge", "UT"),
    ("Leo Skiri Østigård", "Leo Østigård", "Norge", "UT"),
    ("Kalidou Koulibaly", "Kalidou Koulibaly", "Senegal", "UT"),
    ("Hakim Ziyech", "Hakim Ziyech", "Marokko", "UT"),
    ("Mohammed Kudus", "Mohammed Kudus", "Ghana", "UT"),
    ("Kim Min-jae", "Kim Min-jae", "Sør-Korea", "UT"),
    ("Mehdi Taremi", "Mehdi Taremi", "Iran", "UT"),
    ("Arda Güler", "Arda Güler", "Tyrkia", "UT"),
    ("Hakan Çalhanoğlu", "Hakan Çalhanoğlu", "Tyrkia", "UT"),
    ("Dušan Vlahović", "Dušan Vlahović", "Serbia", "UT"),
    ("Aleksandar Mitrović", "Aleksandar Mitrović", "Serbia", "UT"),
    ("Edin Džeko", "Edin Džeko", "Bosnia-Hercegovina", "UT"),
    ("Khvicha Kvaratskhelia", "Khvitsja Kvaratskhelia", "Georgia", "UT"),
    ("Granit Xhaka", "Granit Xhaka", "Sveits", "UT"),
    ("David Alaba", "David Alaba", "Østerrike", "UT"),
    ("Andrew Robertson", "Andrew Robertson", "Skottland", "UT"),
    ("Moisés Caicedo", "Moisés Caicedo", "Ecuador", "UT"),
    ("Pierre-Emerick Aubameyang", "Pierre-Emerick Aubameyang", "Gabon", "UT"),
    ("Hirving Lozano", "Hirving Lozano", "Mexico", "UT"),
]
# Kvinnelige spillere (feltet «female»: appen blander ikke kvinner og menn i svaralternativene)
WOMEN = {"Hope Solo", "Hedvig Lindahl", "Ada Hegerberg", "Caroline Graham Hansen", "Alexia Putellas",
         "Aitana Bonmatí", "Sam Kerr", "Megan Rapinoe", "Alex Morgan", "Marta", "Lucy Bronze",
         "Vivianne Miedema", "Pernille Harder", "Birgit Prinz"}

# Eksisterende spillere som er målvakter
EXISTING_GK = {"manuel-neuer", "thibaut-courtois", "alisson"}


def main():
    f = fc.OUT / "players.json"
    existing = json.loads(f.read_text(encoding="utf-8"))
    have = {p["id"] for p in existing}
    for p in existing:
        p.setdefault("pos", "GK" if p["id"] in EXISTING_GK else "UT")
    added = 0
    todo = EXTRA + NEW if "--gamle" in sys.argv else NEW
    for wiki, name, nat, pos in todo:
        pid = fc.slug(name)
        if pid in have:
            continue
        fc.PLAYERS[:] = [(wiki, name, nat)]  # gjenbruker byggefunksjonen for én spiller
        got = fc.build_players()
        if got:
            item = got[0]
            item["pos"] = pos
            if name in WOMEN:
                item["female"] = True
            item.pop("crop", None)  # settes av tools/face_crops.py
            existing.append(item)
            have.add(pid)
            added += 1
            f.write_text(json.dumps(existing, ensure_ascii=False, indent=1), encoding="utf-8")
    f.write_text(json.dumps(existing, ensure_ascii=False, indent=1), encoding="utf-8")
    log = fc.OUT / "skipped_extra.txt"
    log.write_text("\n".join(fc.skipped) + "\n", encoding="utf-8")
    print(f"\n{added} nye spillere; totalt {len(existing)}; {len(fc.skipped)} hoppet over (skipped_extra.txt)")


if __name__ == "__main__":
    main()
