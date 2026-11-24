"""Legger til flere stadioner i assets/media/stadiums.json uten å røre de som finnes
(filer og manuelle rettelser beholdes).

Kjør:  python tools/more_stadiums.py
Bruker samme regler som tools/fetch_commons.py (bare CC BY / CC BY-SA / CC0 / offentlig eiendom,
aldri NC/ND/GFDL). Mangler Wikipedia-siden koordinater, brukes Wikidata (P625).
Etterpå: python tools/bundle_media.py (bare nye får fil) og python tools/make_geo.py
(byen må da stå i CITY i tools/make_geo.py).
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fetch_commons as fc  # noqa: E402

# (wikipedia-tittel, visningsnavn, klubb, land)
EXTRA = [
    # --- England / Skottland / Wales / Irland
    ("Elland Road", "Elland Road", "Leeds United", "England"),
    ("Craven Cottage", "Craven Cottage", "Fulham", "England"),
    ("London Stadium", "London Stadium", "West Ham United", "England"),
    ("Selhurst Park", "Selhurst Park", "Crystal Palace", "England"),
    ("Molineux Stadium", "Molineux", "Wolverhampton Wanderers", "England"),
    ("King Power Stadium", "King Power Stadium", "Leicester City", "England"),
    ("City Ground", "City Ground", "Nottingham Forest", "England"),
    ("Bramall Lane", "Bramall Lane", "Sheffield United", "England"),
    ("Hillsborough Stadium", "Hillsborough", "Sheffield Wednesday", "England"),
    ("Stadium of Light", "Stadium of Light", "Sunderland", "England"),
    ("Riverside Stadium", "Riverside Stadium", "Middlesbrough", "England"),
    ("St Mary's Stadium", "St Mary's Stadium", "Southampton", "England"),
    ("Falmer Stadium", "Amex Stadium", "Brighton & Hove Albion", "England"),
    ("Turf Moor", "Turf Moor", "Burnley", "England"),
    ("Ewood Park", "Ewood Park", "Blackburn Rovers", "England"),
    ("Portman Road", "Portman Road", "Ipswich Town", "England"),
    ("Carrow Road", "Carrow Road", "Norwich City", "England"),
    ("Dean Court", "Dean Court", "Bournemouth", "England"),
    ("Hampden Park", "Hampden Park", "Landslaget (Skottland)", "Skottland"),
    ("Tynecastle Park", "Tynecastle Park", "Hearts", "Skottland"),
    ("Pittodrie Stadium", "Pittodrie", "Aberdeen", "Skottland"),
    ("Millennium Stadium", "Millennium Stadium", "Landslaget (Wales)", "Wales"),
    ("Aviva Stadium", "Aviva Stadium", "Landslaget (Irland)", "Irland"),
    # --- Spania
    ("Ramón Sánchez Pizjuán Stadium", "Ramón Sánchez Pizjuán", "Sevilla", "Spania"),
    ("Benito Villamarín Stadium", "Benito Villamarín", "Real Betis", "Spania"),
    ("San Mamés Stadium", "San Mamés", "Athletic Bilbao", "Spania"),
    ("Anoeta Stadium", "Anoeta", "Real Sociedad", "Spania"),
    ("Estadio de la Cerámica", "Estadio de la Cerámica", "Villarreal", "Spania"),
    ("Mestalla Stadium", "Mestalla", "Valencia", "Spania"),
    ("Riazor", "Riazor", "Deportivo La Coruña", "Spania"),
    ("Balaídos", "Balaídos", "Celta Vigo", "Spania"),
    # --- Tyskland
    ("Olympiastadion (Berlin)", "Olympiastadion Berlin", "Hertha BSC", "Tyskland"),
    ("Volksparkstadion", "Volksparkstadion", "Hamburger SV", "Tyskland"),
    ("BayArena", "BayArena", "Bayer Leverkusen", "Tyskland"),
    ("Deutsche Bank Park", "Deutsche Bank Park", "Eintracht Frankfurt", "Tyskland"),
    ("MHPArena", "MHPArena", "VfB Stuttgart", "Tyskland"),
    ("Red Bull Arena (Leipzig)", "Red Bull Arena", "RB Leipzig", "Tyskland"),
    ("RheinEnergieStadion", "RheinEnergieStadion", "1. FC Köln", "Tyskland"),
    ("Borussia-Park", "Borussia-Park", "Borussia Mönchengladbach", "Tyskland"),
    ("Weserstadion", "Weserstadion", "Werder Bremen", "Tyskland"),
    ("Volkswagen Arena", "Volkswagen Arena", "VfL Wolfsburg", "Tyskland"),
    ("Millerntor-Stadion", "Millerntor-Stadion", "St. Pauli", "Tyskland"),
    ("Stadion An der Alten Försterei", "Stadion An der Alten Försterei", "Union Berlin", "Tyskland"),
    ("Olympiastadion (Munich)", "Olympiastadion München", "VM-finalen 1974", "Tyskland"),
    # --- Italia
    ("Stadio Olimpico", "Stadio Olimpico", "Roma og Lazio", "Italia"),
    ("Stadio Artemio Franchi", "Stadio Artemio Franchi", "Fiorentina", "Italia"),
    ("Stadio Luigi Ferraris", "Stadio Luigi Ferraris", "Genoa og Sampdoria", "Italia"),
    ("Gewiss Stadium", "Gewiss Stadium", "Atalanta", "Italia"),
    ("Stadio Renato Dall'Ara", "Stadio Renato Dall'Ara", "Bologna", "Italia"),
    ("Stadio Olimpico Grande Torino", "Stadio Olimpico Grande Torino", "Torino", "Italia"),
    ("Stadio Marc'Antonio Bentegodi", "Stadio Marc'Antonio Bentegodi", "Hellas Verona", "Italia"),
    # --- Frankrike / Monaco
    ("Parc des Princes", "Parc des Princes", "Paris Saint-Germain", "Frankrike"),
    ("Stade de France", "Stade de France", "Landslaget (Frankrike)", "Frankrike"),
    ("Parc Olympique Lyonnais", "Parc Olympique Lyonnais", "Lyon", "Frankrike"),
    ("Stade Pierre-Mauroy", "Stade Pierre-Mauroy", "Lille", "Frankrike"),
    ("Allianz Riviera", "Allianz Riviera", "Nice", "Frankrike"),
    ("Stade Geoffroy-Guichard", "Stade Geoffroy-Guichard", "Saint-Étienne", "Frankrike"),
    ("Stade Bollaert-Delelis", "Stade Bollaert-Delelis", "Lens", "Frankrike"),
    ("Stade de la Beaujoire", "Stade de la Beaujoire", "Nantes", "Frankrike"),
    ("Stade Louis II", "Stade Louis II", "AS Monaco", "Monaco"),
    # --- Nederland / Belgia / Portugal
    ("Philips Stadion", "Philips Stadion", "PSV Eindhoven", "Nederland"),
    ("AFAS Stadion", "AFAS Stadion", "AZ Alkmaar", "Nederland"),
    ("Estádio José Alvalade", "Estádio José Alvalade", "Sporting", "Portugal"),
    ("Estádio Municipal de Braga", "Estádio Municipal de Braga", "Braga", "Portugal"),
    ("Jan Breydel Stadium", "Jan Breydel Stadion", "Club Brugge og Cercle Brugge", "Belgia"),
    ("King Baudouin Stadium", "Kong Baudouin-stadion", "Landslaget (Belgia)", "Belgia"),
    ("Constant Vanden Stock Stadium", "Constant Vanden Stock Stadion", "Anderlecht", "Belgia"),
    # --- Tyrkia / Hellas / Øst-Europa
    ("Şükrü Saracoğlu Stadium", "Şükrü Saracoğlu", "Fenerbahçe", "Tyrkia"),
    ("Beşiktaş Stadium", "Tüpraş Stadium", "Beşiktaş", "Tyrkia"),
    ("Atatürk Olympic Stadium", "Atatürk olympiske stadion", "Champions League-finalen 2005", "Tyrkia"),
    ("Karaiskakis Stadium", "Karaiskakis", "Olympiakos", "Hellas"),
    ("Krestovsky Stadium", "Krestovskij-stadion", "Zenit St. Petersburg", "Russland"),
    ("NSC Olimpiyskiy Stadium", "Olimpijskyj", "Landslaget (Ukraina)", "Ukraina"),
    ("Stadion Maksimir", "Maksimir", "Dinamo Zagreb", "Kroatia"),
    ("Rajko Mitić Stadium", "Rajko Mitić", "Crvena zvezda", "Serbia"),
    ("Ernst-Happel-Stadion", "Ernst-Happel-Stadion", "Landslaget (Østerrike)", "Østerrike"),
    ("St. Jakob-Park", "St. Jakob-Park", "Basel", "Sveits"),
    ("National Stadium, Warsaw", "Nasjonalstadion i Warszawa", "Landslaget (Polen)", "Polen"),
    ("Puskás Aréna", "Puskás Aréna", "Landslaget (Ungarn)", "Ungarn"),
    # --- Norden
    ("Strawberry Arena", "Strawberry Arena", "Landslaget (Sverige)", "Sverige"),
    ("Parken Stadium", "Parken", "FC København", "Danmark"),
    ("Aker Stadion", "Aker stadion", "Molde", "Norge"),
    ("Viking Stadion", "Viking stadion", "Viking", "Norge"),
    ("Intility Arena", "Intility Arena", "Vålerenga", "Norge"),
    ("Aspmyra Stadion", "Aspmyra stadion", "Bodø/Glimt", "Norge"),
    ("Åråsen Stadion", "Åråsen stadion", "Lillestrøm", "Norge"),
    ("Fredrikstad Stadion", "Fredrikstad stadion", "Fredrikstad", "Norge"),
    ("Marienlyst Stadion", "Marienlyst stadion", "Strømsgodset", "Norge"),
    ("Alfheim Stadion", "Alfheim stadion", "Tromsø", "Norge"),
    # --- Amerika
    ("Estádio do Morumbi", "Morumbi", "São Paulo FC", "Brasil"),
    ("Arena Corinthians", "Arena Corinthians", "Corinthians", "Brasil"),
    ("Mineirão", "Mineirão", "Cruzeiro", "Brasil"),
    ("La Bombonera", "La Bombonera", "Boca Juniors", "Argentina"),
    ("Estadio Centenario", "Estadio Centenario", "Landslaget (Uruguay)", "Uruguay"),
    ("Estadio Nacional Julio Martínez Prádanos", "Estadio Nacional", "Landslaget (Chile)", "Chile"),
    ("Estadio Hernando Siles", "Estadio Hernando Siles", "Landslaget (Bolivia)", "Bolivia"),
    ("Rose Bowl (stadium)", "Rose Bowl", "VM-finalen 1994", "USA"),
    ("Estadio BBVA", "Estadio BBVA", "Monterrey", "Mexico"),
    ("BMO Field", "BMO Field", "Toronto FC", "Canada"),
    # --- Asia / Afrika / Oseania
    ("International Stadium Yokohama", "Nissan Stadium", "VM-finalen 2002", "Japan"),
    ("Saitama Stadium 2002", "Saitama Stadium 2002", "Urawa Red Diamonds", "Japan"),
    ("Seoul World Cup Stadium", "Seoul World Cup Stadium", "FC Seoul", "Sør-Korea"),
    ("King Fahd International Stadium", "King Fahd International Stadium", "Landslaget (Saudi-Arabia)", "Saudi-Arabia"),
    ("Al-Awwal Park", "Al-Awwal Park", "Al-Nassr", "Saudi-Arabia"),
    ("Khalifa International Stadium", "Khalifa International Stadium", "Landslaget (Qatar)", "Qatar"),
    ("Cairo International Stadium", "Cairo International Stadium", "Landslaget (Egypt)", "Egypt"),
    ("Stade Mohammed V", "Stade Mohammed V", "Wydad og Raja", "Marokko"),
    ("Cape Town Stadium", "Cape Town Stadium", "VM 2010", "Sør-Afrika"),
    ("Stadium Australia", "Stadium Australia", "Landslaget (Australia)", "Australia"),
]


def wikidata_coords(page):
    qid = page.get("pageprops", {}).get("wikibase_item")
    if not qid:
        return None
    d = fc.api("www.wikidata.org", {"action": "wbgetclaims", "entity": qid, "property": "P625"})
    for c in (d or {}).get("claims", {}).get("P625", []):
        v = c.get("mainsnak", {}).get("datavalue", {}).get("value")
        if v and "latitude" in v:
            return {"lat": v["latitude"], "lon": v["longitude"]}
    return None


def build_one(wiki, name, club, country):
    page, err = fc.wiki_page(wiki, with_images=True)
    if not page:
        fc.skipped.append(f"STADION {name}: {err} ({wiki})")
        return None
    coords = (page.get("coordinates") or [None])[0] or wikidata_coords(page)
    if not coords:
        fc.skipped.append(f"STADION {name}: ingen koordinater (Wikipedia/Wikidata) ({wiki})")
        return None
    photo, reasons = None, []
    for fn in fc.candidates(page, extra_from_page=True):
        info, why = fc.commons_info(fn)
        if not info:
            reasons.append(f"{fn}: {why}")
            continue
        w, h = info["origWidth"] or 1, info["origHeight"] or 1
        if w < 800 or h > w:  # stadionbilder skal være liggende og store nok
            reasons.append(f"{fn}: for lite/stående ({w}x{h})")
            continue
        photo = info
        break
    if not photo:
        fc.skipped.append(f"STADION {name}: ingen brukbart bilde ({'; '.join(reasons[:3]) or 'ingen kandidater'})")
        return None
    print("ok stadion", name, flush=True)
    return {"id": fc.slug(name), "name": name, "club": club, "country": country,
            "lat": coords["lat"], "lon": coords["lon"], "photo": photo}


def main():
    f = fc.OUT / "stadiums.json"
    existing = json.loads(f.read_text(encoding="utf-8"))
    have = {s["id"] for s in existing}
    added = 0
    for wiki, name, club, country in EXTRA:
        if fc.slug(name) in have:
            continue
        item = build_one(wiki, name, club, country)
        if item:
            existing.append(item)
            have.add(item["id"])
            added += 1
            f.write_text(json.dumps(existing, ensure_ascii=False, indent=1), encoding="utf-8")
    f.write_text(json.dumps(existing, ensure_ascii=False, indent=1), encoding="utf-8")
    (fc.OUT / "skipped_stadiums.txt").write_text("\n".join(fc.skipped) + "\n", encoding="utf-8")
    print(f"\n{added} nye stadioner; totalt {len(existing)}; {len(fc.skipped)} hoppet over (skipped_stadiums.txt)")
    if fc.API_ERRORS:
        print("API-feil:", *fc.API_ERRORS, sep="\n  ")


if __name__ == "__main__":
    main()
