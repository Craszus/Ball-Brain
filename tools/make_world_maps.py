"""Lager de to innebygde kartene (virker uten nett) fra Natural Earth (offentlig eiendom).

Last først ned (kilde: github.com/nvkelso/natural-earth-vector, mappen geojson):
  ne_50m_admin_0_countries.geojson   -> verdenskartet
  ne_10m_admin_0_countries.geojson   -> nærkartet
Valgfritt (hjelpelag i nærkartet): ne_10m_lakes, ne_10m_rivers_lake_centerlines,
  ne_10m_admin_1_states_provinces_lines og ne_10m_populated_places_simple (.geojson)
Skriver da også assets/geo/world_extra.json (innsjøer, elver, regiongrenser, store byer som prikker).

Kjør:  python -I tools/make_world_maps.py <mappe med de to filene>
Skriver assets/geo/world_far.json og assets/geo/world_near.json:
  {"rings": [[lon, lat, lon, lat, ...], ...]}   (en ring per landområde, forenklet)
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def rdp(pts, eps):
    """Douglas-Peucker (iterativ) på en liste av (x, y)."""
    n = len(pts)
    if n < 3:
        return pts
    keep = [False] * n
    keep[0] = keep[-1] = True
    stack = [(0, n - 1)]
    e2 = eps * eps
    while stack:
        a, b = stack.pop()
        ax, ay = pts[a]
        bx, by = pts[b]
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        best, idx = -1.0, -1
        for i in range(a + 1, b):
            px, py = pts[i]
            if L2 == 0:
                d = (px - ax) ** 2 + (py - ay) ** 2
            else:
                t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / L2))
                d = (px - ax - t * dx) ** 2 + (py - ay - t * dy) ** 2
            if d > best:
                best, idx = d, i
        if best > e2 and idx > 0:
            keep[idx] = True
            stack.append((a, idx))
            stack.append((idx, b))
    return [p for p, k in zip(pts, keep) if k]


def build(src, dst, eps, min_size, decimals):
    data = json.load(open(src, encoding="utf-8"))
    out = []
    for f in data["features"]:
        g = f.get("geometry")
        if not g:
            continue
        polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        for poly in polys:
            for ring in poly[:1]:  # bare ytterringen (ingen hull/innsjøer)
                pts = [(c[0], c[1]) for c in ring]
                xs = [p[0] for p in pts]
                ys = [p[1] for p in pts]
                if max(ys) < -58:  # Antarktis
                    continue
                if max(xs) - min(xs) < min_size and max(ys) - min(ys) < min_size:
                    continue
                s = rdp(pts, eps)
                if len(s) < 4:
                    continue
                flat = []
                for x, y in s:
                    flat += [round(x, decimals), round(y, decimals)]
                out.append(flat)
    json.dump({"rings": out}, open(dst, "w"), separators=(",", ":"))
    n = sum(len(r) // 2 for r in out)
    print(dst.name, len(out), "ringer,", n, "punkter,", dst.stat().st_size // 1024, "KB")


def _lines(geom):
    if not geom:
        return []
    if geom["type"] == "LineString":
        return [geom["coordinates"]]
    if geom["type"] == "MultiLineString":
        return geom["coordinates"]
    return []


def _flat(pts, eps, decimals=3):
    s = rdp([(c[0], c[1]) for c in pts], eps)
    out = []
    for x, y in s:
        out += [round(x, decimals), round(y, decimals)]
    return out


def build_extra(d, dst):
    def load(n):
        return json.load(open(d / n, encoding="utf-8"))["features"]

    lakes = []
    for f in load("ne_10m_lakes.geojson"):
        g = f["geometry"]
        if not g:
            continue
        polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        for poly in polys:
            pts = poly[0]
            xs = [c[0] for c in pts]
            ys = [c[1] for c in pts]
            if max(xs) - min(xs) < 0.12 and max(ys) - min(ys) < 0.12:
                continue
            lakes.append(_flat(pts, 0.01))

    rivers = []
    for f in load("ne_10m_rivers_lake_centerlines.geojson"):
        if f["properties"].get("scalerank", 99) > 6:  # bare de store elvene
            continue
        for ln in _lines(f["geometry"]):
            if len(ln) >= 2:
                rivers.append(_flat(ln, 0.012))

    regions = []
    for f in load("ne_10m_admin_1_states_provinces_lines.geojson"):
        for ln in _lines(f["geometry"]):
            if len(ln) >= 2:
                regions.append(_flat(ln, 0.015))

    cities = []
    for f in load("ne_10m_populated_places_simple.geojson"):
        p = f["properties"]
        if (p.get("pop_max") or 0) >= 1_000_000:
            x, y = f["geometry"]["coordinates"]
            cities += [round(x, 2), round(y, 2)]

    json.dump({"lakes": lakes, "rivers": rivers, "regions": regions, "cities": cities},
              open(dst, "w"), separators=(",", ":"))
    print(dst.name, len(lakes), "innsjøer,", len(rivers), "elver,", len(regions),
          "regiongrenser,", len(cities) // 2, "byer,", dst.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    d = Path(sys.argv[1])
    out = ROOT / "assets" / "geo"
    build(d / "ne_50m_admin_0_countries.geojson", out / "world_far.json", 0.03, 0.4, 2)
    build(d / "ne_10m_admin_0_countries.geojson", out / "world_near.json", 0.012, 0.05, 3)
    if (d / "ne_10m_lakes.geojson").exists():
        build_extra(d, out / "world_extra.json")
