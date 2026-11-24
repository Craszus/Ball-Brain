#!/usr/bin/env python3
"""Lager en ny utgave av Ball Brain, på samme måte som i Logica: bygger APK lokalt og legger den
på GitHub med `gh`. Appen ser den nye utgaven og tilbyr «Last ned».

Bruk (fra prosjektmappen):
    python tools/release.py            # øk byggnummeret, bygg signert APK og legg den ut
    python tools/release.py --no-publish   # bare bygg (ingenting sendes ut)

Krever: android/key.properties (den faste signeringsnøkkelen), supabase.env.json og at `gh` er
logget inn. Utgaven heter «siste-bygg» og oppdateres hver gang, så QR-lenken
/releases/latest alltid gir nyeste APK. Beskrivelsen inneholder «Bygg N», som appen leser.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = 'Craszus/Ball-Brain'
TAG = 'siste-bygg'


def run(cmd, **kw):
    return subprocess.run(cmd, cwd=ROOT, **kw)


def main() -> int:
    publish = '--no-publish' not in sys.argv
    for needed in ('android/key.properties', 'supabase.env.json'):
        if not (ROOT / needed).exists():
            print(f'Mangler {needed}. Uten fast nøkkel kan ikke brukerne oppdatere over den gamle appen.')
            return 1
    flutter = shutil.which('flutter')
    gh = shutil.which('gh')
    if not flutter or (publish and not gh):
        print('Finner ikke flutter eller gh.')
        return 1
    if publish and run([gh, 'auth', 'status'], capture_output=True).returncode != 0:
        print('gh er ikke logget inn. Kjør: gh auth login')
        return 1

    pubspec = ROOT / 'pubspec.yaml'
    original = pubspec.read_text(encoding='utf-8')
    m = re.search(r'^version: (\d+\.\d+\.\d+)\+(\d+)$', original, re.M)
    name, build = m.group(1), int(m.group(2)) + 1
    pubspec.write_text(original.replace(m.group(0), f'version: {name}+{build}'), encoding='utf-8')
    print(f'Versjon {name}, bygg {build}')

    apk = ROOT / 'build/app/outputs/flutter-apk/app-release.apk'
    result = run([flutter, 'build', 'apk', '--release', '--dart-define-from-file=supabase.env.json'])
    if result.returncode != 0 or not apk.exists():
        pubspec.write_text(original, encoding='utf-8')  # behold gammelt nummer når byggingen feiler
        print('Byggingen feilet.')
        return 1
    out = ROOT / 'release' / 'BallBrain.apk'
    out.parent.mkdir(exist_ok=True)
    shutil.copyfile(apk, out)
    print(f'Bygget: {out} ({out.stat().st_size / 1_000_000:.0f} MB)')
    if not publish:
        return 0

    title = f'Ball Brain – siste bygg ({build})'
    notes = (f'Bygg {build} (versjon {name}). Last ned BallBrain.apk under Assets, åpne filen på Android og '
             'tillat installasjon fra ukjente kilder. Nye bygg kan installeres rett over den forrige.')
    exists = run([gh, 'release', 'view', TAG, '--repo', REPO], capture_output=True).returncode == 0
    if exists:
        # Last opp filen først, så ingen ser et nytt byggnummer før APK-en ligger der
        ok = run([gh, 'release', 'upload', TAG, str(out), '--clobber', '--repo', REPO]).returncode == 0
        ok = ok and run([gh, 'release', 'edit', TAG, '--title', title, '--notes', notes, '--latest',
                         '--repo', REPO]).returncode == 0
    else:
        ok = run([gh, 'release', 'create', TAG, str(out), '--title', title, '--notes', notes, '--latest',
                  '--repo', REPO]).returncode == 0
    if not ok:
        print('Opplastingen til GitHub feilet. APK-en ligger i release/.')
        return 1
    print(f'Utgitt: https://github.com/{REPO}/releases/latest')
    return 0


if __name__ == '__main__':
    sys.exit(main())
