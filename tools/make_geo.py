"""Lager stedslisten til geografi-quizen fra stadiums.json (koordinater fra Wikipedia/Wikidata).

Kjør:  python tools/make_geo.py   (etter tools/fetch_commons.py)
Skriver assets/geo/places.json

Hvert sted er et stadion. Spørsmålet blir «Hvor ligger {klubb}?» hvis stadionet har én klar
hjemmeklubb, ellers «Hvor ligger {stadion}?» (landslag, finaler og delte stadioner).
Byer er lagt inn manuelt under; skriptet feiler hvis et stadion mangler by.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

CITY = {
    "Anfield": "Liverpool",
    "Old Trafford": "Manchester",
    "Emirates Stadium": "London",
    "Stamford Bridge": "London",
    "Etihad Stadium": "Manchester",
    "Tottenham Hotspur Stadium": "London",
    "St James' Park": "Newcastle upon Tyne",
    "Goodison Park": "Liverpool",
    "Villa Park": "Birmingham",
    "Wembley Stadium": "London",
    "Celtic Park": "Glasgow",
    "Ibrox": "Glasgow",
    "Camp Nou": "Barcelona",
    "Santiago Bernabéu": "Madrid",
    "Metropolitano": "Madrid",
    "Mestalla": "Valencia",
    "Allianz Arena": "München",
    "Signal Iduna Park": "Dortmund",
    "Veltins-Arena": "Gelsenkirchen",
    "San Siro": "Milano",
    "Stadio Olimpico": "Roma",
    "Allianz Stadium": "Torino",
    "Stadio Diego Armando Maradona": "Napoli",
    "Parc des Princes": "Paris",
    "Stade Vélodrome": "Marseille",
    "Johan Cruyff Arena": "Amsterdam",
    "De Kuip": "Rotterdam",
    "Estádio da Luz": "Lisboa",
    "Estádio do Dragão": "Porto",
    "Estádio José Alvalade": "Lisboa",
    "RAMS Park": "Istanbul",
    "Luzhniki": "Moskva",
    "Ullevaal stadion": "Oslo",
    "Lerkendal": "Trondheim",
    "Brann stadion": "Bergen",
    "Maracanã": "Rio de Janeiro",
    "La Bombonera": "Buenos Aires",
    "El Monumental": "Buenos Aires",
    "Estadio Azteca": "Mexico by",
    "Estadio Centenario": "Montevideo",
    "Lusail Stadium": "Lusail",
    "MetLife Stadium": "East Rutherford",
    "Soccer City": "Johannesburg",
    # Runde 2 (2026-11-24): stadioner fra tools/more_stadiums.py
    "Elland Road": "Leeds",
    "Craven Cottage": "London",
    "London Stadium": "London",
    "Selhurst Park": "London",
    "Molineux": "Wolverhampton",
    "King Power Stadium": "Leicester",
    "City Ground": "West Bridgford",
    "Bramall Lane": "Sheffield",
    "Hillsborough": "Sheffield",
    "Stadium of Light": "Sunderland",
    "Riverside Stadium": "Middlesbrough",
    "St Mary's Stadium": "Southampton",
    "Amex Stadium": "Brighton",
    "Turf Moor": "Burnley",
    "Ewood Park": "Blackburn",
    "Portman Road": "Ipswich",
    "Carrow Road": "Norwich",
    "Dean Court": "Bournemouth",
    "Hampden Park": "Glasgow",
    "Tynecastle Park": "Edinburgh",
    "Pittodrie": "Aberdeen",
    "Millennium Stadium": "Cardiff",
    "Aviva Stadium": "Dublin",
    "Ramón Sánchez Pizjuán": "Sevilla",
    "Benito Villamarín": "Sevilla",
    "San Mamés": "Bilbao",
    "Anoeta": "San Sebastián",
    "Estadio de la Cerámica": "Villarreal",
    "Riazor": "A Coruña",
    "Balaídos": "Vigo",
    "Olympiastadion Berlin": "Berlin",
    "Volksparkstadion": "Hamburg",
    "BayArena": "Leverkusen",
    "Deutsche Bank Park": "Frankfurt",
    "MHPArena": "Stuttgart",
    "Red Bull Arena": "Leipzig",
    "RheinEnergieStadion": "Köln",
    "Borussia-Park": "Mönchengladbach",
    "Weserstadion": "Bremen",
    "Volkswagen Arena": "Wolfsburg",
    "Millerntor-Stadion": "Hamburg",
    "Stadion An der Alten Försterei": "Berlin",
    "Olympiastadion München": "München",
    "Stadio Artemio Franchi": "Firenze",
    "Stadio Luigi Ferraris": "Genova",
    "Gewiss Stadium": "Bergamo",
    "Stadio Renato Dall'Ara": "Bologna",
    "Stadio Olimpico Grande Torino": "Torino",
    "Stadio Marc'Antonio Bentegodi": "Verona",
    "Stade de France": "Saint-Denis",
    "Parc Olympique Lyonnais": "Décines-Charpieu",
    "Stade Pierre-Mauroy": "Villeneuve-d'Ascq",
    "Allianz Riviera": "Nice",
    "Stade Geoffroy-Guichard": "Saint-Étienne",
    "Stade Bollaert-Delelis": "Lens",
    "Stade de la Beaujoire": "Nantes",
    "Stade Louis II": "Monaco",
    "Philips Stadion": "Eindhoven",
    "AFAS Stadion": "Alkmaar",
    "Estádio Municipal de Braga": "Braga",
    "Jan Breydel Stadion": "Brugge",
    "Kong Baudouin-stadion": "Brussel",
    "Constant Vanden Stock Stadion": "Brussel",
    "Şükrü Saracoğlu": "Istanbul",
    "Tüpraş Stadium": "Istanbul",
    "Atatürk olympiske stadion": "Istanbul",
    "Karaiskakis": "Pireus",
    "Krestovskij-stadion": "St. Petersburg",
    "Olimpijskyj": "Kyiv",
    "Maksimir": "Zagreb",
    "Rajko Mitić": "Beograd",
    "Ernst-Happel-Stadion": "Wien",
    "St. Jakob-Park": "Basel",
    "Nasjonalstadion i Warszawa": "Warszawa",
    "Puskás Aréna": "Budapest",
    "Strawberry Arena": "Solna",
    "Parken": "København",
    "Aker stadion": "Molde",
    "Viking stadion": "Stavanger",
    "Intility Arena": "Oslo",
    "Aspmyra stadion": "Bodø",
    "Åråsen stadion": "Lillestrøm",
    "Fredrikstad stadion": "Fredrikstad",
    "Marienlyst stadion": "Drammen",
    "Alfheim stadion": "Tromsø",
    "Morumbi": "São Paulo",
    "Arena Corinthians": "São Paulo",
    "Mineirão": "Belo Horizonte",
    "Estadio Nacional": "Santiago",
    "Estadio Hernando Siles": "La Paz",
    "Rose Bowl": "Pasadena",
    "Estadio BBVA": "Guadalupe",
    "BMO Field": "Toronto",
    "Nissan Stadium": "Yokohama",
    "Saitama Stadium 2002": "Saitama",
    "Seoul World Cup Stadium": "Seoul",
    "King Fahd International Stadium": "Riyadh",
    "Al-Awwal Park": "Riyadh",
    "Khalifa International Stadium": "Al Rayyan",
    "Cairo International Stadium": "Kairo",
    "Stade Mohammed V": "Casablanca",
    "Cape Town Stadium": "Cape Town",
    "Stadium Australia": "Sydney",
}


def initials(text):
    words = [w for w in text.replace("(", " ").replace(")", " ").split() if w[0].isalpha()]
    return "".join(w[0].upper() for w in words[:2]) or "?"


def main():
    stadiums = json.loads((ROOT / "assets" / "media" / "stadiums.json").read_text(encoding="utf-8"))
    places, missing = [], []
    for s in stadiums:
        city = CITY.get(s["name"])
        if not city:
            missing.append(s["name"])
            continue
        club = s["club"]
        clear_club = not (club.startswith(("Landslaget", "VM", "Champions League")) or " og " in club)
        subject = club if clear_club else s["name"]
        places.append({
            "id": s["id"],
            "prompt": f"Hvor ligger {subject}?",
            "kind": "club" if clear_club else "stadium",
            "subject": subject,
            "badge": initials(subject),
            "stadium": s["name"],
            "city": city,
            "country": s["country"],
            "lat": s["lat"],
            "lon": s["lon"],
        })
    if missing:
        raise SystemExit("Mangler by for: " + ", ".join(missing))
    out = ROOT / "assets" / "geo"
    out.mkdir(parents=True, exist_ok=True)
    (out / "places.json").write_text(json.dumps(places, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(places)} steder skrevet til {out / 'places.json'}")


if __name__ == "__main__":
    main()
