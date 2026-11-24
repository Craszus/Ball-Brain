"""Legger bildene inn i appen (offline): beskjærer spillerbilder rundt ansiktet og lagrer alt som
JPEG i assets/media/img/. Oppdaterer players.json / stadiums.json med feltet «file».

Kjør (trenger opencv-python-headless, numpy; kjør etter tools/face_crops.py):
  python tools/bundle_media.py
Bildene er fritt lisensiert (CC BY / CC BY-SA / CC0 / PD). Kreditering vises i appen (ⓘ og
Bildekreditering). Beskjæring er en tilpasning, og CC BY-SA-bilder deles videre på samme lisens.
"""
import json
import sys
import unicodedata
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from face_crops import fetch  # noqa: E402  (bruker samme cache og ventetid)

ROOT = Path(__file__).resolve().parent.parent
MEDIA = ROOT / "assets" / "media"
PLAYER_SIZE = 640   # kvadrat, px
STADIUM_WIDTH = 900  # px


def ascii_id(s):
    """Filnavn uten æøå/aksenter (cv2 og asset-stier takler ikke alltid slike tegn)."""
    s = s.replace("ø", "o").replace("Ø", "O").replace("æ", "ae").replace("å", "a")
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return "".join(c if c.isalnum() or c in "-_" else "-" for c in s).strip("-").lower()


def save_jpg(path, img, quality):
    ok, buf = cv2.imencode(".jpg", img, [cv2.IMWRITE_JPEG_QUALITY, quality])
    if not ok:
        raise RuntimeError(f"kunne ikke kode {path}")
    Path(path).write_bytes(buf.tobytes())


def done(item):
    """Allerede pakket inn (fila finnes). Med --alle lages alle på nytt."""
    return "--alle" not in sys.argv and item.get("file") and (ROOT / item["file"]).exists()


def load(url):
    return cv2.imdecode(np.frombuffer(fetch(url), np.uint8), cv2.IMREAD_COLOR)


def players():
    out_dir = MEDIA / "img" / "players"
    out_dir.mkdir(parents=True, exist_ok=True)
    f = MEDIA / "players.json"
    data = json.loads(f.read_text(encoding="utf-8"))
    for p in data:
        if "cx" not in p.get("crop", {}) or done(p):
            continue
        try:
            img = load(p["photo"]["url"])
        except Exception as e:  # noqa: BLE001
            print("FEIL spiller", p["id"], e)
            continue
        h, w = img.shape[:2]
        c = p["crop"]
        side = int(round(min(c["s"] * w, h)))
        x0 = int(max(0, min(w - side, c["cx"] * w - side / 2)))
        y0 = int(max(0, min(h - side, c["cy"] * h - side / 2)))
        tile = img[y0:y0 + side, x0:x0 + side]
        tile = cv2.resize(tile, (PLAYER_SIZE, PLAYER_SIZE), interpolation=cv2.INTER_AREA)
        name = f"assets/media/img/players/{ascii_id(p['id'])}.jpg"
        save_jpg(ROOT / name, tile, 82)
        p["file"] = name
        print("spiller", p["id"])
    f.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")


def stadiums():
    out_dir = MEDIA / "img" / "stadiums"
    out_dir.mkdir(parents=True, exist_ok=True)
    f = MEDIA / "stadiums.json"
    data = json.loads(f.read_text(encoding="utf-8"))
    for s in data:
        if not s.get("photo") or done(s):
            continue
        try:
            img = load(s["photo"]["url"])
        except Exception as e:  # noqa: BLE001
            print("FEIL stadion", s["id"], e)
            continue
        h, w = img.shape[:2]
        if w > STADIUM_WIDTH:
            img = cv2.resize(img, (STADIUM_WIDTH, int(h * STADIUM_WIDTH / w)), interpolation=cv2.INTER_AREA)
        name = f"assets/media/img/stadiums/{ascii_id(s['id'])}.jpg"
        save_jpg(ROOT / name, img, 80)
        s["file"] = name
        print("stadion", s["id"])
    f.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    players()
    stadiums()
