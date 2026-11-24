"""Finner ansiktet i hvert spillerbilde og lagrer utsnittet i assets/media/players.json.

Kjør (trenger opencv-python-headless og numpy):
  python tools/face_crops.py
Laster ned bildene (960 px) midlertidig, finner største ansikt (Haar), og skriver
crop = {cx, cy, s}: senter (andel av bildebredde/-høyde) og sidelengde (andel av bildebredden).
Bilder uten funnet ansikt får et standardutsnitt og listes som «sjekk» (se tools/face_review.txt).
"""
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
PLAYERS = ROOT / "assets" / "media" / "players.json"
UA = {"User-Agent": "BallBrainFaceCrops/1.0 (educational app; contact: app owner)"}

frontal = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
alt = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_alt2.xml")
profile = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_profileface.xml")


CACHE = Path(os.environ.get("FACE_CACHE", ROOT / "tools" / ".face_cache"))
CACHE.mkdir(parents=True, exist_ok=True)


def fetch(url):
    """Henter bildet (med disk-cache og ventetid ved 429 fra Wikimedia)."""
    f = CACHE / (hashlib.md5(url.encode()).hexdigest() + ".jpg")
    if f.exists():
        return f.read_bytes()
    for attempt in range(8):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            f.write_bytes(data)
            time.sleep(1.5)
            return data
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            time.sleep(10 * (attempt + 1))
    raise RuntimeError("for mange forespørsler (429)")


def biggest(faces):
    return max(faces, key=lambda f: f[2] * f[3]) if len(faces) else None


def detect(img):
    gray = cv2.equalizeHist(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY))
    h, w = gray.shape
    min_side = max(30, w // 14)
    for cas in (frontal, alt):
        f = biggest(cas.detectMultiScale(gray, 1.1, 5, minSize=(min_side, min_side)))
        if f is not None:
            return f
    f = biggest(profile.detectMultiScale(gray, 1.1, 4, minSize=(min_side, min_side)))
    if f is not None:
        return f
    flipped = cv2.flip(gray, 1)
    f = biggest(profile.detectMultiScale(flipped, 1.1, 4, minSize=(min_side, min_side)))
    if f is not None:
        x, y, fw, fh = f
        return (w - x - fw, y, fw, fh)
    return None


def main():
    data = json.loads(PLAYERS.read_text(encoding="utf-8"))
    review = []
    redo = "--alle" in sys.argv  # uten dette får bare spillere uten utsnitt nytt
    for p in data:
        if not redo and "cx" in p.get("crop", {}):
            continue
        url = p["photo"]["url"]
        try:
            img = cv2.imdecode(np.frombuffer(fetch(url), np.uint8), cv2.IMREAD_COLOR)
        except Exception as e:  # noqa: BLE001
            review.append(f"{p['name']}: kunne ikke hente ({e})")
            continue
        h, w = img.shape[:2]
        f = detect(img)
        if f is None:
            crop = {"cx": 0.5, "cy": 0.25, "s": 0.7}
            review.append(f"{p['name']}: fant ikke ansikt, standardutsnitt")
        else:
            x, y, fw, fh = [float(v) for v in f]
            cx = (x + fw / 2) / w
            cy = (y + fh / 2) / h
            # Ansiktet fyller ca. 45 % av utsnittet; litt luft over hodet.
            side = min(1.0, (fw / w) / 0.45)
            side = max(side, 0.35)
            cx = min(max(cx, side / 2), 1 - side / 2)
            half_h = side * w / h / 2
            cy = min(max(cy, half_h), 1 - half_h) if half_h < 0.5 else 0.5
            crop = {"cx": round(cx, 4), "cy": round(cy, 4), "s": round(side, 4)}
        p["crop"] = crop
        print(p["name"], crop, "OK" if f is not None else "STANDARD")
    PLAYERS.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    (ROOT / "tools" / "face_review.txt").write_text("\n".join(review), encoding="utf-8")
    print(len(review), "må sjekkes")


if __name__ == "__main__":
    sys.exit(main())
