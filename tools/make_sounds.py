"""Genererer enkle lydeffekter (WAV) til Ball Brain – ingen eksterne filer eller lisenser.

Kjør:  python tools/make_sounds.py
Skriver assets/sounds/{correct,wrong,finish,levelUp,tap}.wav
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq, dur, vol=0.5, shape="sine", decay=4.0):
    n = int(RATE * dur)
    samples = []
    for i in range(n):
        t = i / RATE
        phase = 2 * math.pi * freq * t
        if shape == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
            v *= 0.6
        else:
            v = math.sin(phase) + 0.3 * math.sin(2 * phase)
        env = math.exp(-decay * t / dur)
        attack = min(1.0, i / (RATE * 0.005))
        samples.append(v * env * attack * vol)
    return samples


def seq(parts):
    out = []
    for s in parts:
        out.extend(s)
    return out


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(x) for x in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(x * scale * 32767)) for x in samples))


C5, E5, G5, C6 = 523.25, 659.25, 783.99, 1046.5

write("correct", seq([tone(C5, 0.12, decay=3), tone(E5, 0.12, decay=3), tone(G5, 0.3, decay=5)]))
write("wrong", seq([tone(180, 0.16, 0.5, "square", 2), tone(130, 0.28, 0.5, "square", 4)]))
write("finish", seq([tone(C5, 0.14), tone(E5, 0.14), tone(G5, 0.14), tone(C6, 0.7, decay=5)]))
E6, G6, C7 = 1318.5, 1568.0, 2093.0
write("levelUp", seq([tone(f, 0.1, decay=3) for f in (C5, E5, G5, C6, E6, G6)] + [tone(C7, 0.9, decay=5)]))
write("tap", tone(900, 0.04, 0.4, decay=6))
# Geografi: jo flere poeng, jo lysere og lengre jingle
A5, B5, D6, F6 = 880.0, 987.77, 1174.66, 1396.9
write("geoPerfect", seq([tone(f, 0.08, decay=3) for f in (C5, E5, G5, C6, E6)] + [tone(G6, 0.55, decay=5)]))
write("geoGood", seq([tone(E5, 0.1, decay=3), tone(G5, 0.1, decay=3), tone(C6, 0.4, decay=5)]))
write("geoOk", seq([tone(G5, 0.1, decay=3), tone(B5, 0.3, decay=5)]))
write("geoLow", tone(A5, 0.22, 0.35, decay=5))
print("Lydene er skrevet til", OUT)
