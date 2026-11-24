"""Henter stadioner og spillere med fritt lisensierte bilder fra Wikimedia Commons.

Kjør:  python tools/fetch_commons.py
Skriver:
  assets/media/stadiums.json
  assets/media/players.json
  assets/media/skipped.txt   (hvilke oppføringer som ble hoppet over, og hvorfor)

Regler (bildene brukes i en app som kan bli kommersiell):
  * Bare CC BY, CC BY-SA, CC0 og public domain godtas. NC/ND/GFDL-alene/fair use avvises.
  * Bildet må ligge på Commons (ikke en lokal en.wikipedia-fil).
  * Fotograf, lisens og kildeside lagres per bilde og vises i appen (ⓘ-knapp + kreditliste).
  * Spillerbilder må være portrett (høyde ≥ 85 % av bredde) så de kan beskjæres tett om hodet.
    Klubblogoer og draktsponsorer må likevel sjekkes manuelt før lansering.

Bildene lastes ikke ned; appen henter forhåndsvisning (900 px) direkte fra upload.wikimedia.org.
"""
import html
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "media"
UA = "BallBrainDev/0.1 (football quiz app prototype)"

# (wikipedia-tittel, visningsnavn, klubb, land)
STADIUMS = [
    ("Anfield", "Anfield", "Liverpool", "England"),
    ("Old Trafford", "Old Trafford", "Manchester United", "England"),
    ("Emirates Stadium", "Emirates Stadium", "Arsenal", "England"),
    ("Stamford Bridge (stadium)", "Stamford Bridge", "Chelsea", "England"),
    ("Etihad Stadium (Manchester)", "Etihad Stadium", "Manchester City", "England"),
    ("Tottenham Hotspur Stadium", "Tottenham Hotspur Stadium", "Tottenham", "England"),
    ("St James' Park", "St James' Park", "Newcastle United", "England"),
    ("Goodison Park", "Goodison Park", "Everton", "England"),
    ("Villa Park", "Villa Park", "Aston Villa", "England"),
    ("Wembley Stadium", "Wembley Stadium", "Landslaget (England)", "England"),
    ("Celtic Park", "Celtic Park", "Celtic", "Skottland"),
    ("Ibrox Stadium", "Ibrox", "Rangers", "Skottland"),
    ("Camp Nou", "Camp Nou", "Barcelona", "Spania"),
    ("Santiago Bernabéu Stadium", "Santiago Bernabéu", "Real Madrid", "Spania"),
    ("Cívitas Metropolitano", "Metropolitano", "Atlético Madrid", "Spania"),
    ("Mestalla Stadium", "Mestalla", "Valencia", "Spania"),
    ("Allianz Arena", "Allianz Arena", "Bayern München", "Tyskland"),
    ("Signal Iduna Park", "Signal Iduna Park", "Borussia Dortmund", "Tyskland"),
    ("Veltins-Arena", "Veltins-Arena", "Schalke 04", "Tyskland"),
    ("San Siro", "San Siro", "AC Milan og Inter", "Italia"),
    ("Stadio Olimpico (Rome)", "Stadio Olimpico", "Roma og Lazio", "Italia"),
    ("Allianz Stadium (Turin)", "Allianz Stadium", "Juventus", "Italia"),
    ("Stadio Diego Armando Maradona", "Stadio Diego Armando Maradona", "Napoli", "Italia"),
    ("Parc des Princes", "Parc des Princes", "Paris Saint-Germain", "Frankrike"),
    ("Stade Vélodrome", "Stade Vélodrome", "Marseille", "Frankrike"),
    ("Johan Cruyff Arena", "Johan Cruyff Arena", "Ajax", "Nederland"),
    ("De Kuip", "De Kuip", "Feyenoord", "Nederland"),
    ("Estádio da Luz", "Estádio da Luz", "Benfica", "Portugal"),
    ("Estádio do Dragão", "Estádio do Dragão", "Porto", "Portugal"),
    ("Estádio José Alvalade", "Estádio José Alvalade", "Sporting", "Portugal"),
    ("Rams Park", "RAMS Park", "Galatasaray", "Tyrkia"),
    ("Luzhniki Stadium", "Luzhniki", "Landslaget (Russland)", "Russland"),
    ("Ullevaal Stadion", "Ullevaal stadion", "Landslaget (Norge)", "Norge"),
    ("Lerkendal Stadion", "Lerkendal", "Rosenborg", "Norge"),
    ("Brann Stadion", "Brann stadion", "Brann", "Norge"),
    ("Maracanã Stadium", "Maracanã", "Flamengo og Fluminense", "Brasil"),
    ("La Bombonera", "La Bombonera", "Boca Juniors", "Argentina"),
    ("Estadio Monumental Antonio Vespucio Liberti", "El Monumental", "River Plate", "Argentina"),
    ("Estadio Azteca", "Estadio Azteca", "Club América", "Mexico"),
    ("Estadio Centenario", "Estadio Centenario", "Landslaget (Uruguay)", "Uruguay"),
    ("Lusail Stadium", "Lusail Stadium", "VM 2022-finalen", "Qatar"),
    ("MetLife Stadium", "MetLife Stadium", "VM 2026-finalen", "USA"),
    ("FNB Stadium", "Soccer City", "VM 2010-finalen", "Sør-Afrika"),
]

# (wikipedia-tittel, visningsnavn, nasjonalitet)
PLAYERS = [
    ("Erling Haaland", "Erling Haaland", "Norge"),
    ("Martin Ødegaard", "Martin Ødegaard", "Norge"),
    ("Alexander Sørloth", "Alexander Sørloth", "Norge"),
    ("Ole Gunnar Solskjær", "Ole Gunnar Solskjær", "Norge"),
    ("Lionel Messi", "Lionel Messi", "Argentina"),
    ("Cristiano Ronaldo", "Cristiano Ronaldo", "Portugal"),
    ("Kylian Mbappé", "Kylian Mbappé", "Frankrike"),
    ("Mohamed Salah", "Mohamed Salah", "Egypt"),
    ("Kevin De Bruyne", "Kevin De Bruyne", "Belgia"),
    ("Harry Kane", "Harry Kane", "England"),
    ("Luka Modrić", "Luka Modrić", "Kroatia"),
    ("Robert Lewandowski", "Robert Lewandowski", "Polen"),
    ("Neymar", "Neymar", "Brasil"),
    ("Vinícius Júnior", "Vinícius Júnior", "Brasil"),
    ("Jude Bellingham", "Jude Bellingham", "England"),
    ("Virgil van Dijk", "Virgil van Dijk", "Nederland"),
    ("Son Heung-min", "Son Heung-min", "Sør-Korea"),
    ("Karim Benzema", "Karim Benzema", "Frankrike"),
    ("Sadio Mané", "Sadio Mané", "Senegal"),
    ("Antoine Griezmann", "Antoine Griezmann", "Frankrike"),
    ("Manuel Neuer", "Manuel Neuer", "Tyskland"),
    ("Thibaut Courtois", "Thibaut Courtois", "Belgia"),
    ("Pelé", "Pelé", "Brasil"),
    ("Diego Maradona", "Diego Maradona", "Argentina"),
    ("Zinedine Zidane", "Zinedine Zidane", "Frankrike"),
    ("Ronaldinho", "Ronaldinho", "Brasil"),
    ("Thierry Henry", "Thierry Henry", "Frankrike"),
    ("Rodri", "Rodri", "Spania"),
    ("Lamine Yamal", "Lamine Yamal", "Spania"),
    ("Bukayo Saka", "Bukayo Saka", "England"),
    ("Pedri", "Pedri", "Spania"),
    ("Phil Foden", "Phil Foden", "England"),
    ("Declan Rice", "Declan Rice", "England"),
    ("Marcus Rashford", "Marcus Rashford", "England"),
    ("Bruno Fernandes", "Bruno Fernandes", "Portugal"),
    ("Sergio Ramos", "Sergio Ramos", "Spania"),
    ("Andrés Iniesta", "Andrés Iniesta", "Spania"),
    ("Xavi", "Xavi", "Spania"),
    ("Zlatan Ibrahimović", "Zlatan Ibrahimović", "Sverige"),
    ("Luis Suárez", "Luis Suárez", "Uruguay"),
    ("Gareth Bale", "Gareth Bale", "Wales"),
    ("Wayne Rooney", "Wayne Rooney", "England"),
    ("David Beckham", "David Beckham", "England"),
    ("Steven Gerrard", "Steven Gerrard", "England"),
    ("Johan Cruyff", "Johan Cruyff", "Nederland"),
    ("Franz Beckenbauer", "Franz Beckenbauer", "Tyskland"),
    ("Alisson Becker", "Alisson", "Brasil"),
    ("Federico Valverde", "Federico Valverde", "Uruguay"),
    ("Achraf Hakimi", "Achraf Hakimi", "Marokko"),
    ("Victor Osimhen", "Victor Osimhen", "Nigeria"),
]

ALLOWED = re.compile(r"^(CC BY(-SA)?[ -]\d(\.\d)?(\s.*)?|CC0.*|Public domain.*|PDM.*|Attribution.*)$", re.I)
DENIED = re.compile(r"(NC|ND|GFDL$|fair use|non-?commercial)", re.I)
BAD_NAME = re.compile(r"(logo|map|flag|crest|icon|badge|seal|coat|plan|diagram|svg$)", re.I)

skipped = []


API_ERRORS = []


def api(host, params):
    """Kaller MediaWiki-API-et. Returnerer None (og logger) hvis det feiler etter flere forsøk."""
    params = {**params, "format": "json", "formatversion": "2"}
    url = f"https://{host}/w/api.php?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    last = ""
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.load(r)
            time.sleep(0.5)
            if "error" in data:
                last = "API-feil: " + str(data["error"].get("code"))
                time.sleep(2 * (attempt + 1))
                continue
            return data
        except urllib.error.HTTPError as e:
            last = f"HTTP {e.code}"
            wait = int(e.headers.get("Retry-After", "0") or 0) or 3 * (attempt + 1)
            time.sleep(min(wait, 30))
        except Exception as e:  # nettverk, timeout, ugyldig JSON
            last = type(e).__name__
            time.sleep(3 * (attempt + 1))
    API_ERRORS.append(f"{host} {params.get('titles') or params.get('entity')}: {last}")
    return None


def strip_html(s):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", s or ""))).strip()


def commons_info(filename):
    """Returnerer bildeinfo hvis fila ligger på Commons med tillatt lisens, ellers (None, årsak)."""
    d = api("commons.wikimedia.org", {
        "action": "query", "titles": "File:" + filename, "prop": "imageinfo",
        "iiprop": "url|extmetadata|size|mime", "iiurlwidth": 900,
    })
    if d is None:
        return None, "API-feil (Commons)"
    pages = d.get("query", {}).get("pages", [])
    if not pages or "imageinfo" not in pages[0]:
        return None, "ikke på Commons"
    ii = pages[0]["imageinfo"][0]
    if ii.get("mime") not in ("image/jpeg", "image/png"):
        return None, "ikke jpeg/png"
    meta = ii.get("extmetadata", {})
    lic = strip_html(meta.get("LicenseShortName", {}).get("value", ""))
    if not lic or DENIED.search(lic) or not ALLOWED.match(lic):
        return None, f"lisens ikke tillatt: {lic or 'ukjent'}"
    author = strip_html(meta.get("Artist", {}).get("value", "")) or "Ukjent fotograf"
    return {
        "url": ii.get("thumburl") or ii["url"],
        "title": filename.replace("_", " "),
        "author": author[:140],
        "license": lic,
        "licenseUrl": strip_html(meta.get("LicenseUrl", {}).get("value", "")),
        "pageUrl": ii.get("descriptionurl", ""),
        "width": ii.get("thumbwidth") or ii.get("width"),
        "height": ii.get("thumbheight") or ii.get("height"),
        "origWidth": ii.get("width"),
        "origHeight": ii.get("height"),
    }, ""


def wiki_page(title, with_images):
    """Henter koordinater, hovedbilde og Wikidata-id. Returnerer (side, feil)."""
    d = api("en.wikipedia.org", {
        "action": "query", "titles": title, "redirects": 1,
        "prop": "coordinates|pageimages|pageprops", "piprop": "name", "ppprop": "wikibase_item",
    })
    if d is None:
        return None, "API-feil (Wikipedia)"
    pages = d.get("query", {}).get("pages", [])
    if not pages or "missing" in pages[0]:
        return None, "fant ikke Wikipedia-side"
    page = pages[0]
    page["images_list"] = []
    if with_images:
        di = api("en.wikipedia.org", {"action": "query", "titles": title, "redirects": 1,
                                      "prop": "images", "imlimit": 60})
        if di:
            ps = di.get("query", {}).get("pages", [])
            if ps:
                page["images_list"] = [im["title"].split(":", 1)[-1] for im in ps[0].get("images", [])]
    return page, ""


def wikidata_image(page):
    """Hovedbildet (P18) fra Wikidata. Ligger alltid på Commons."""
    qid = page.get("pageprops", {}).get("wikibase_item")
    if not qid:
        return None
    d = api("www.wikidata.org", {"action": "wbgetclaims", "entity": qid, "property": "P18"})
    if not d:
        return None
    claims = d.get("claims", {}).get("P18", [])
    for c in claims:
        v = c.get("mainsnak", {}).get("datavalue", {}).get("value")
        if v:
            return v.replace(" ", "_")
    return None


def candidates(page, extra_from_page):
    out = []
    if page.get("pageimage"):
        out.append(page["pageimage"])
    p18 = wikidata_image(page)
    if p18 and p18 not in out:
        out.append(p18)
    if extra_from_page:
        for name in page.get("images_list", []):
            if name.lower().endswith((".jpg", ".jpeg")) and not BAD_NAME.search(name) and name not in out:
                out.append(name)
    # Aldri logoer/kart/merker, heller ikke når de er sidens hovedbilde (f.eks. «Logo stade …»).
    return [n for n in out if not BAD_NAME.search(n)][:7]


def slug(name):
    return re.sub(r"\W+", "-", name.lower()).strip("-")


def build_stadiums():
    result = []
    for wiki, name, club, country in STADIUMS:
        page, err = wiki_page(wiki, with_images=True)
        if not page:
            skipped.append(f"STADION {name}: {err} ({wiki})")
            continue
        if not page.get("coordinates"):
            skipped.append(f"STADION {name}: ingen koordinater på siden ({wiki})")
            continue
        photo, why = None, "ingen kandidatbilder"
        reasons = []
        for fn in candidates(page, extra_from_page=True):
            photo, why = commons_info(fn)
            if photo:
                break
            reasons.append(f"{fn}: {why}")
        if not photo:
            skipped.append(f"STADION {name}: ingen brukbart bilde ({'; '.join(reasons[:3]) or why})")
            continue
        c = page["coordinates"][0]
        result.append({"id": slug(name), "name": name, "club": club, "country": country,
                       "lat": c["lat"], "lon": c["lon"], "photo": photo})
        print("ok stadion", name, flush=True)
    return result


def build_players():
    result = []
    for wiki, name, nat in PLAYERS:
        page, err = wiki_page(wiki, with_images=False)
        if not page:
            skipped.append(f"SPILLER {name}: {err} ({wiki})")
            continue
        photo, reasons = None, []
        for fn in candidates(page, extra_from_page=False):
            info, why = commons_info(fn)
            if not info:
                reasons.append(f"{fn}: {why}")
                continue
            w, h = info["origWidth"] or 1, info["origHeight"] or 1
            if h < 0.85 * w:
                reasons.append(f"{fn}: ikke portrett ({w}x{h})")
                continue
            photo = info
            break
        if not photo:
            skipped.append(f"SPILLER {name}: ingen brukbart bilde ({'; '.join(reasons[:3]) or 'ingen kandidater'})")
            continue
        result.append({"id": slug(name), "name": name, "nationality": nat, "photo": photo,
                       "crop": {"y": -0.7, "zoom": 1.6}})
        print("ok spiller", name, flush=True)
    return result


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    stadiums = build_stadiums()
    players = build_players()
    (OUT / "stadiums.json").write_text(json.dumps(stadiums, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "players.json").write_text(json.dumps(players, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "skipped.txt").write_text("\n".join(skipped) + "\n", encoding="utf-8")
    print(f"\n{len(stadiums)} stadioner, {len(players)} spillere, {len(skipped)} hoppet over (se skipped.txt)")


if __name__ == "__main__":
    main()
