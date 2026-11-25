"""3D-pokaler i samme stil som de andre (blank bronse/sølv/gull), gjengitt i Blender.

1) blender --background --python tools/make_trophies.py -- UTMAPPE [navn ...]
2) python tools/compose_trophies.py UTMAPPE      (bakgrunn, glød og glitter -> assets/trophies/)
"""
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index('--') + 1:]
OUT, ONLY = args[0], args[1:]

METALS = {
    'bronze': (0.72, 0.30, 0.15),
    'silver': (0.80, 0.80, 0.82),
    'gold': (1.00, 0.60, 0.16),
}


def mat(name, color, metal=1.0, rough=0.22, emit=0.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*color, 1)
    b.inputs['Metallic'].default_value = metal
    b.inputs['Roughness'].default_value = rough
    if emit:
        b.inputs['Emission Color'].default_value = (*color, 1)
        b.inputs['Emission Strength'].default_value = emit
    return m


def finish(o, m, bevel=0.0, smooth=True):
    o.data.materials.clear()
    o.data.materials.append(m)
    if bevel:
        mod = o.modifiers.new('b', 'BEVEL')
        mod.width = bevel
        mod.segments = 4
        mod.limit_method = 'ANGLE'
    if smooth:
        for p in o.data.polygons:
            p.use_smooth = True
        try:
            o.data.set_sharp_from_angle(angle=math.radians(40))
        except AttributeError:
            pass
    return o


def link(name, mesh):
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    return o


def lathe(profile, m, at=(0, 0, 0), steps=96):
    """Dreid form: profil [(radius, høyde)] rundt z-aksen."""
    bm = bmesh.new()
    verts = [bm.verts.new((r, 0, z)) for r, z in profile]
    edges = [bm.edges.new((a, b)) for a, b in zip(verts, verts[1:])]
    bmesh.ops.spin(bm, geom=verts + edges, axis=(0, 0, 1), cent=(0, 0, 0),
                   angle=2 * math.pi, steps=steps, use_merge=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new('lathe')
    bm.to_mesh(me)
    bm.free()
    o = link('lathe', me)
    o.location = at
    return finish(o, m)


def box(size, at, m, bevel=0.04, rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    me = bpy.data.meshes.new('box')
    bm.to_mesh(me)
    bm.free()
    o = link('box', me)
    o.location, o.rotation_euler = at, rot
    return finish(o, m, bevel=bevel)


def extrude(points, depth, at, m, bevel=0.04, rot=(0, 0, 0)):
    """Flat figur i xz-planet (sett forfra) med tykkelse."""
    bm = bmesh.new()
    front = [bm.verts.new((x, -depth / 2, z)) for x, z in points]
    face = bm.faces.new(front)
    r = bmesh.ops.extrude_face_region(bm, geom=[face])
    for v in [g for g in r['geom'] if isinstance(g, bmesh.types.BMVert)]:
        v.co.y += depth
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new('flat')
    bm.to_mesh(me)
    bm.free()
    o = link('flat', me)
    o.location, o.rotation_euler = at, rot
    return finish(o, m, bevel=bevel)


def sphere(r, at, m, scale=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=r)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    me = bpy.data.meshes.new('sphere')
    bm.to_mesh(me)
    bm.free()
    o = link('sphere', me)
    o.location = at
    return finish(o, m)


def torus(R, r, at, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=at, rotation=rot,
                                     major_segments=96, minor_segments=24)
    return finish(bpy.context.object, m)


def tube(points, r, m):
    cu = bpy.data.curves.new('tube', 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = r
    cu.bevel_resolution = 8
    cu.use_fill_caps = True
    sp = cu.splines.new('BEZIER')
    sp.bezier_points.add(len(points) - 1)
    for p, co in zip(sp.bezier_points, points):
        p.co = co
        p.handle_left_type = p.handle_right_type = 'AUTO'
    o = link('tube', cu)
    cu.materials.append(m)
    return o


def text(body, size, at, m, depth=0.07, bevel=0.018):
    cu = bpy.data.curves.new('txt', 'FONT')
    cu.body = body
    cu.size = size
    cu.align_x, cu.align_y = 'CENTER', 'CENTER'
    cu.extrude = depth
    cu.bevel_depth = bevel
    cu.bevel_resolution = 4
    try:
        cu.font = bpy.data.fonts.load(r'C:\Windows\Fonts\ariblk.ttf', check_existing=True)
    except Exception:
        pass
    o = link('txt', cu)
    cu.materials.append(m)
    o.location = at
    o.rotation_euler = (math.radians(90), 0, 0)
    return o


def star_points(R, r, n=5):
    return [((R if i % 2 == 0 else r) * math.sin(i * math.pi / n),
             (R if i % 2 == 0 else r) * math.cos(i * math.pi / n)) for i in range(2 * n)]


def ball(R, at, m, seam):
    """Fotball: avkuttet ikosaeder med nedsenkede sømmer."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1)
    ico = [v.co.copy().normalized() for v in bm.verts]
    pairs = [(e.verts[0].co.copy(), e.verts[1].co.copy()) for e in bm.edges]
    bm.free()
    cut = []  # kantene i fotballen
    around = {}
    for a, b in pairs:
        p, q = a.lerp(b, 1 / 3), a.lerp(b, 2 / 3)
        cut.append((p.normalized(), q.normalized()))
        around.setdefault(tuple(round(c, 4) for c in a), []).append(p)
        around.setdefault(tuple(round(c, 4) for c in b), []).append(q)
    for key, pts in around.items():
        centre = Vector(key).normalized()
        u = (pts[0] - centre * pts[0].dot(centre)).normalized()
        w = centre.cross(u)
        pts.sort(key=lambda p: math.atan2(p.dot(w), p.dot(u)))
        cut += [(pts[i].normalized(), pts[(i + 1) % len(pts)].normalized()) for i in range(len(pts))]

    def dist(p):
        best = 9.0
        for a, b in cut:
            ab = b - a
            t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
            best = min(best, (p - (a + ab * t).normalized()).length)
        return best

    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=7, radius=1)
    depth = {}
    for v in bm.verts:
        d = dist(v.co.normalized())
        g = max(0.0, 1 - d / 0.045)
        depth[v.index] = g
        v.co = v.co.normalized() * R * (1 - 0.045 * g * g + 0.012 * min(1.0, d / 0.2))
    bm.verts.index_update()
    me = bpy.data.meshes.new('ball')
    me.materials.append(m)
    me.materials.append(seam)
    for f in bm.faces:
        f.material_index = 1 if max(depth[v.index] for v in f.verts) > 0.72 else 0
        f.smooth = True
    bm.to_mesh(me)
    bm.free()
    o = link('ball', me)
    o.location = at
    o.rotation_euler = (math.radians(18), math.radians(12), math.radians(8))
    return o


def pedestal(m, top=0.0):
    """Sokkel med toppen i høyde [top]."""
    lathe([(0, -0.62), (0.62, -0.62), (0.66, -0.58), (0.64, -0.47), (0.52, -0.42), (0.45, -0.30),
           (0.30, -0.27), (0.17, -0.18), (0.13, -0.07), (0.20, -0.02), (0.17, 0.0), (0, 0.0)],
          m, at=(0, 0, top))


def neck(m, to):
    """Stett fra sokkelen opp til figuren, så ingenting svever."""
    lathe([(0, -0.03), (0.15, -0.03), (0.085, to * 0.45), (0.10, to * 0.8), (0.17, to + 0.02),
           (0, to + 0.04)], m)


def cup(m, top=0.0):
    pedestal(m, top)
    lathe([(0, 0.0), (0.16, 0.0), (0.36, 0.14), (0.52, 0.42), (0.60, 0.80), (0.66, 1.02),
           (0.62, 1.04), (0.56, 0.98), (0.50, 0.60), (0.30, 0.30), (0, 0.22)], m, at=(0, 0, top))
    for s in (-1, 1):
        tube([(s * 0.55, 0, top + 0.90), (s * 0.90, 0, top + 0.86), (s * 0.84, 0, top + 0.50),
              (s * 0.46, 0, top + 0.34)], 0.055, m)


def shield(w, h):
    pts = [(-w, h), (w, h), (w, 0.05)]
    for i in range(1, 12):
        t = i / 12
        pts.append((w * (1 - t) ** 0.6, 0.05 - (h * 0.95 + 0.05) * t ** 1.25))
    pts.append((0, -h * 0.98))
    pts += [(-x, z) for x, z in reversed(pts[3:-1])]
    pts.append((-w, 0.05))
    return pts


def jersey():
    right = [(0.0, 0.66), (0.20, 0.80), (0.46, 0.76), (0.98, 0.44), (0.76, 0.06), (0.52, 0.18),
             (0.52, -0.72)]
    return [(-x, z) for x, z in reversed(right[1:])] + right


# --- de enkelte pokalene ---------------------------------------------------------

def geo_20(m, d, w):  # kompass
    pedestal(m)
    torus(0.70, 0.11, (0, 0, 0.84), m, rot=(math.radians(90), 0, 0))
    extrude([(0.68 * math.cos(i / 48 * 2 * math.pi), 0.68 * math.sin(i / 48 * 2 * math.pi))
             for i in range(48)], 0.12, (0, 0.05, 0.84), w, bevel=0.01)
    torus(0.52, 0.018, (0, -0.02, 0.84), m, rot=(math.radians(90), 0, 0))
    for a in range(8):
        t = a * math.pi / 4
        sphere(0.045, (0.52 * math.sin(t), -0.04, 0.84 + 0.52 * math.cos(t)), m)
    red = mat('red', (0.7, 0.02, 0.02), 0.2, 0.25)
    needle = math.radians(35)
    for colour, sign in ((red, 1), (m, -1)):
        extrude([(-0.11, 0), (0, sign * 0.56), (0.11, 0)], 0.09, (0, -0.11, 0.84), colour,
                bevel=0.02, rot=(0, needle, 0))
    sphere(0.09, (0, -0.16, 0.84), m)
    torus(0.13, 0.045, (0, 0, 1.66), m, rot=(math.radians(90), 0, 0))


def photo_perfect(m, d, w):  # kameralinse med glitrende glass
    pedestal(m)
    rot = (math.radians(90), 0, 0)
    for R, r, y in ((0.70, 0.12, 0.0), (0.54, 0.07, -0.12), (0.40, 0.055, -0.20)):
        torus(R, r, (0, y, 0.82), m, rot=rot)
    extrude([(0.68 * math.cos(i / 64 * 2 * math.pi), 0.68 * math.sin(i / 64 * 2 * math.pi))
             for i in range(64)], 0.26, (0, 0.07, 0.82), d, bevel=0.03)
    glass = mat('glass', (0.05, 0.12, 0.30), 0.9, 0.04)
    sphere(0.38, (0, -0.10, 0.82), glass, scale=(1, 0.5, 1))
    sphere(0.06, (-0.13, -0.31, 0.96), mat('glint', (1, 1, 1), 0, 0.2, emit=3.0))
    for i in range(24):
        t = i / 24 * 2 * math.pi
        box((0.035, 0.08, 0.09), (0.70 * math.sin(t), -0.10, 0.82 + 0.70 * math.cos(t)), d,
            bevel=0.01, rot=(0, t, 0))


def calendar(m, d, w, z=0.82):
    box((1.34, 0.22, 1.22), (0, 0.03, z - 0.05), m, bevel=0.09)
    box((1.12, 0.08, 0.76), (0, -0.09, z - 0.19), w, bevel=0.03)
    box((1.34, 0.28, 0.30), (0, 0.03, z + 0.46), m, bevel=0.07)
    for x in (-0.38, 0.38):
        torus(0.13, 0.045, (x, 0, z + 0.66), d, rot=(0, math.radians(90), 0))


def daily_first(m, d, w):  # kalenderblad med ball
    pedestal(m)
    neck(m, 0.18)
    calendar(m, d, w)
    ball(0.33, (0, -0.30, 0.62), m, d)


def daily_7(m, d, w):  # stort sjutall med laurbær
    pedestal(m)
    neck(m, 0.33)
    text('7', 1.75, (0, 0, 0.92), m, depth=0.13, bevel=0.035)
    for s in (-1, 1):
        pts = [(s * 0.18, 0.02, 0.06), (s * 0.78, 0.02, 0.35), (s * 0.90, 0.02, 0.95),
               (s * 0.66, 0.02, 1.52)]
        tube(pts, 0.025, m)
        for i in range(9):
            t = math.radians(-62 + i * 17)
            x, z = s * 0.84 * math.cos(t), 0.78 + 0.80 * math.sin(t)
            leaf = sphere(0.15, (x + s * 0.05, -0.02, z), m, scale=(0.48, 0.3, 1.0))
            leaf.rotation_euler = (0, s * (math.radians(40) - t * 0.9), 0)


def daily_30(m, d, w):  # kalender med 30 og krone
    pedestal(m)
    neck(m, 0.12)
    calendar(m, d, w, z=0.74)
    text('30', 0.62, (0, -0.16, 0.55), m, depth=0.04)
    crown = [(-0.38, 0), (-0.46, 0.46), (-0.2, 0.24), (0, 0.55), (0.2, 0.24), (0.46, 0.46), (0.38, 0)]
    extrude(crown, 0.18, (0, -0.1, 1.42), m, bevel=0.035)
    for x, z in ((-0.46, 1.9), (0, 1.99), (0.46, 1.9)):
        sphere(0.07, (x, -0.1, z), mat('ruby', (0.6, 0.01, 0.05), 0.4, 0.08))


def daily_perfect(m, d, w):  # stjerne med 10
    pedestal(m)
    neck(m, 0.44)
    extrude(star_points(0.98, 0.48), 0.24, (0, 0, 0.90), m, bevel=0.07)
    extrude(star_points(0.78, 0.38), 0.05, (0, -0.15, 0.90), d, bevel=0.02)
    text('10', 0.46, (0, -0.23, 0.86), m, depth=0.04)


def club_joined(m, d, w):  # skjold med penn
    pedestal(m)
    neck(m, 0.14)
    extrude(shield(0.66, 0.74), 0.20, (0, 0, 0.84), m, bevel=0.07)
    extrude(shield(0.50, 0.56), 0.05, (0, -0.13, 0.86), d, bevel=0.02)
    a, b = Vector((-0.50, -0.34, 0.34)), Vector((0.52, -0.34, 1.36))
    tube([a.lerp(b, 0.22), b], 0.10, m)
    tube([a, a.lerp(b, 0.22)], 0.035, w)
    sphere(0.12, b, m)
    torus(0.105, 0.035, a.lerp(b, 0.30), d, rot=(0, math.radians(45), 0))
    sphere(0.05, a, d)


def club_first(m, d, w):  # drakt
    pedestal(m)
    neck(m, 0.16)
    extrude(jersey(), 0.24, (0, 0, 0.86), m, bevel=0.07)
    tube([(-0.2, -0.14, 1.66), (0, -0.16, 1.50), (0.2, -0.14, 1.66)], 0.04, d)
    for x in (-0.2, 0.2):
        box((0.11, 0.05, 1.12), (x, -0.13, 0.70), d, bevel=0.015)
    ball(0.25, (0, -0.30, 0.84), m, d)


def club_win(m, d, w):  # tre baller = tre poeng
    pedestal(m)
    lathe([(0, 0.0), (0.2, 0.0), (0.72, 0.12), (0.76, 0.18), (0.70, 0.2), (0, 0.16)], m)
    ball(0.40, (-0.40, 0, 0.58), m, d)
    ball(0.40, (0.40, 0, 0.58), m, d)
    ball(0.40, (0, -0.02, 1.22), m, d)


def club_10(m, d, w):  # drakt med 10 og laurbær
    pedestal(m)
    neck(m, 0.2)
    extrude(jersey(), 0.24, (0, 0, 0.90), m, bevel=0.07)
    text('10', 0.52, (0, -0.17, 0.78), d, depth=0.04)
    extrude(star_points(0.24, 0.11), 0.12, (0, 0, 1.95), m, bevel=0.03)
    for s in (-1, 1):
        for i in range(7):
            t = math.radians(-60 + i * 17)
            x, z = s * 0.96 * math.cos(t), 0.74 + 0.80 * math.sin(t)
            leaf = sphere(0.14, (x, 0.12, z), m, scale=(0.48, 0.3, 1.0))
            leaf.rotation_euler = (0, s * (math.radians(40) - t * 0.9), 0)


def party_join(m, d, w):  # billett
    pedestal(m)
    neck(m, 0.3)
    def ticket(sx, sz):
        pts = [(-sx, -sz), (sx, -sz)]
        pts += [(sx - 0.16 * math.sin(i / 10 * math.pi), -0.16 * math.cos(i / 10 * math.pi))
                for i in range(11)]
        pts += [(sx, sz), (-sx, sz)]
        pts += [(-sx + 0.16 * math.sin(i / 10 * math.pi), 0.16 * math.cos(i / 10 * math.pi))
                for i in range(11)]
        return pts
    tilt = (0, math.radians(-11), 0)
    extrude(ticket(0.94, 0.58), 0.14, (0, 0, 0.82), m, bevel=0.035, rot=tilt)
    extrude(ticket(0.76, 0.43), 0.04, (0, -0.085, 0.82), d, bevel=0.012, rot=tilt)
    extrude(star_points(0.33, 0.15), 0.07, (0, -0.15, 0.82), m, bevel=0.02, rot=tilt)


def party_win(m, d, w):  # pokal med ball og konfetti
    cup(m)
    ball(0.36, (0, 0, 1.30), m, d)
    colours = [mat('c%d' % i, c, 0.35, 0.25) for i, c in enumerate(
        [(0.75, 0.02, 0.04), (0.02, 0.18, 0.75), (0.02, 0.55, 0.12), (0.45, 0.04, 0.6)])]
    spots = [(-0.86, 1.42, 0.5), (-0.62, 1.72, -0.6), (-0.34, 1.90, 0.9), (0.36, 1.92, -0.3),
             (0.66, 1.70, 0.7), (0.90, 1.38, -0.8), (-0.98, 1.08, -0.4), (1.00, 0.98, 0.4),
             (0.0, 2.02, 0.2)]
    for i, (x, z, a) in enumerate(spots):
        box((0.17, 0.03, 0.075), (x, -0.1, z), colours[i % 4], bevel=0.012, rot=(0.3, a, 0.4))


def party_host(m, d, w):  # mikrofon
    pedestal(m)
    lathe([(0, 0.0), (0.09, 0.0), (0.14, 0.06), (0.24, 0.82), (0.27, 0.90), (0.20, 0.94), (0, 0.94)], m)
    sphere(0.43, (0, 0, 1.30), d)
    for k in range(-3, 4):
        z = k * 0.115
        torus(math.sqrt(0.44 ** 2 - z ** 2), 0.017, (0, 0, 1.30 + z), m)
    for a in range(6):
        torus(0.44, 0.017, (0, 0, 1.30), m, rot=(math.radians(90), 0, a * math.pi / 6))
    torus(0.30, 0.07, (0, 0, 0.92), m)
    box((0.09, 0.06, 0.20), (0, -0.22, 0.52), d, bevel=0.03)


def party_host_10(m, d, w):  # krus med skum
    pedestal(m)
    lathe([(0, 0.0), (0.54, 0.0), (0.60, 0.05), (0.56, 0.14), (0.55, 1.12), (0.60, 1.20),
           (0.52, 1.24), (0, 1.20)], m)
    for z in (0.28, 0.98):
        torus(0.565, 0.035, (0, 0, z), d)
    tube([(0.52, 0, 0.98), (0.95, 0, 0.90), (0.92, 0, 0.40), (0.52, 0, 0.30)], 0.085, m)
    foam = mat('foam', (1.0, 0.86, 0.62), 0.15, 0.4)
    for x, y, z, r in ((-0.36, -0.1, 1.28, 0.24), (0.0, -0.25, 1.34, 0.28), (0.34, -0.08, 1.30, 0.25),
                       (-0.12, 0.2, 1.46, 0.26), (0.18, 0.12, 1.50, 0.22), (-0.48, -0.30, 1.12, 0.13),
                       (-0.50, -0.30, 0.94, 0.08)):
        sphere(r, (x, y, z), foam)
    extrude(star_points(0.27, 0.12), 0.10, (0, -0.57, 0.62), d, bevel=0.025)


def practice_5(m, d, w):  # manual
    pedestal(m)
    neck(m, 0.72)
    z = 0.82
    tube([(-0.62, 0, z), (0.62, 0, z)], 0.11, d)
    for s in (-1, 1):
        for x, r, h in ((0.55, 0.52, 0.20), (0.76, 0.40, 0.17), (0.92, 0.20, 0.10)):
            o = lathe([(0, -h / 2), (r - 0.05, -h / 2), (r, -h / 2 + 0.05), (r, h / 2 - 0.05),
                       (r - 0.05, h / 2), (0, h / 2)], m, at=(s * x, 0, z))
            o.rotation_euler = (0, math.radians(90), 0)
    for k in range(-3, 4):
        torus(0.115, 0.016, (k * 0.09, 0, z), m, rot=(0, math.radians(90), 0))


def practice_packs(m, d, w):  # fire bøker med ball
    pedestal(m)
    z = 0.02
    for i, (width, turn) in enumerate(((1.36, 7), (1.24, -9), (1.30, 4), (1.10, -5))):
        rot = (0, 0, math.radians(turn))
        box((width, 0.82, 0.065), (0, 0, z + 0.032), m, bevel=0.025, rot=rot)
        box((width - 0.08, 0.74, 0.12), (0.01, 0.0, z + 0.125), w, bevel=0.012, rot=rot)
        box((width, 0.82, 0.065), (0, 0, z + 0.218), m, bevel=0.025, rot=rot)
        box((0.11, 0.84, 0.25), (-width / 2 + 0.03, 0, z + 0.125), m, bevel=0.05, rot=rot)
        z += 0.252
    ball(0.37, (0.04, 0, z + 0.36), m, d)


TROPHIES = {
    'geo_20': ('silver', geo_20), 'photo_perfect': ('gold', photo_perfect),
    'daily_first': ('bronze', daily_first), 'daily_7': ('silver', daily_7),
    'daily_30': ('gold', daily_30), 'daily_perfect': ('gold', daily_perfect),
    'club_joined': ('bronze', club_joined), 'club_first': ('bronze', club_first),
    'club_win': ('silver', club_win), 'club_10': ('gold', club_10),
    'party_join': ('bronze', party_join), 'party_win': ('gold', party_win),
    'party_host': ('silver', party_host), 'party_host_10': ('gold', party_host_10),
    'practice_5': ('bronze', practice_5), 'practice_packs': ('silver', practice_packs),
}


def area(at, energy, size, color):
    li = bpy.data.lights.new('a', 'AREA')
    li.energy, li.size, li.color = energy, size, color
    o = link('a', li)
    o.location = at
    o.rotation_euler = (Vector((0, 0, 0.6)) - Vector(at)).to_track_quat('-Z', 'Y').to_euler()
    return o


def scene_setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 96
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = 768
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    # omgivelsene som speiles i metallet: mørkegrønt nede, varmt lys oppe
    world = bpy.data.worlds.new('w')
    sc.world = world
    world.use_nodes = True
    nt = world.node_tree
    coord = nt.nodes.new('ShaderNodeTexCoord')
    xyz = nt.nodes.new('ShaderNodeSeparateXYZ')
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    remap = nt.nodes.new('ShaderNodeMapRange')
    remap.inputs['From Min'].default_value = -1
    bg = nt.nodes['Background']
    nt.links.new(coord.outputs['Generated'], xyz.inputs[0])
    nt.links.new(xyz.outputs['Z'], remap.inputs['Value'])
    nt.links.new(remap.outputs['Result'], ramp.inputs['Fac'])
    nt.links.new(ramp.outputs['Color'], bg.inputs['Color'])
    stops = [(0.0, (0.02, 0.06, 0.035)), (0.40, (0.10, 0.09, 0.04)), (0.52, (0.95, 0.66, 0.30)),
             (0.62, (0.10, 0.09, 0.06)), (0.80, (0.40, 0.34, 0.24)), (1.0, (1.0, 0.94, 0.82))]
    el = ramp.color_ramp.elements
    el[0].position, el[1].position = stops[0][0], stops[-1][0]
    el[0].color, el[1].color = (*stops[0][1], 1), (*stops[-1][1], 1)
    for pos, col in stops[1:-1]:
        el.new(pos).color = (*col, 1)
    bg.inputs['Strength'].default_value = 1.0
    area((-3.0, -3.5, 3.2), 130, 1.6, (1.0, 0.93, 0.82))
    area((3.5, -2.0, 1.2), 55, 2.2, (1.0, 0.80, 0.55))
    area((1.8, 2.5, 2.8), 150, 1.2, (1.0, 0.75, 0.40))
    area((-0.5, -4.0, 0.4), 18, 3.0, (1.0, 0.96, 0.9))
    cam = bpy.data.cameras.new('c')
    cam.lens = 85
    co = link('c', cam)
    target = Vector((0, 0, 0.66))
    co.location = target + Vector((0, -7.4, 1.35))
    co.rotation_euler = (target - co.location).to_track_quat('-Z', 'Y').to_euler()
    sc.camera = co
    return sc


for name, (tier, build) in TROPHIES.items():
    if ONLY and name not in ONLY:
        continue
    sc = scene_setup()
    colour = METALS[tier]
    metal = mat(tier, colour, 1.0, 0.20)
    dark = mat(tier + '-dark', tuple(c * 0.42 for c in colour), 1.0, 0.30)
    ivory = mat('ivory', (0.85, 0.74, 0.55), 0.25, 0.35)
    build(metal, dark, ivory)
    sc.render.filepath = '%s/%s.png' % (OUT, name)
    bpy.ops.render.render(write_still=True)
    print('RENDERT', name)
