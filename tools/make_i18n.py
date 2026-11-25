# -*- coding: utf-8 -*-
"""Bygger assets/i18n/<språk>.json fra tools/i18n_ui.py (og tools/i18n_questions.py hvis den finnes).

Kjør fra prosjektmappen:  python tools/make_i18n.py
Norsk er kildespråket, så det lages ingen nb.json. Filene er «norsk tekst → oversettelse».
"""
import importlib.util
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ['en', 'sv', 'da', 'de', 'es', 'fr']


def load(name):
    p = ROOT / 'tools' / (name + '.py')
    if not p.exists():
        return None
    spec = importlib.util.spec_from_file_location(name, p)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def legal_nb():
    """Norske tekster fra lib/legal_screens.dart i samme rekkefølge som LEGAL_EN."""
    s = (ROOT / 'lib' / 'legal_screens.dart').read_text(encoding='utf8')
    lit = r"'(?:[^'\\\n]|\\.)*'"
    out = []

    def joined(block):
        return ''.join(p[1:-1].replace("\\'", "'") for p in re.findall(lit, block))

    for m in re.finditer(r"title: ((?:\s*%s)+)\s*,\s*intro: ((?:\s*%s)+)" % (lit, lit), s):
        out += [joined(m.group(1)), joined(m.group(2))]
    for m in re.finditer(r"_Section\(\s*((?:%s\s*)+),\s*((?:%s\s*)+)\)" % (lit, lit), s):
        out += [joined(m.group(1)), joined(m.group(2))]
    return out


def seed_check(texts):
    """Alle spørsmål og temaer i assets/seed/questions.json må ha oversettelse: enten en
    egen rad eller en mal med tekst rundt {} (ikke bare «{}, {}» o.l., som ville delt opp
    setningen). Svaralternativer kan være navn/tall og sjekkes ikke her."""
    seed = ROOT / 'assets' / 'seed' / 'questions.json'
    if not seed.exists():
        return []
    templates = []
    for k in texts:
        if '{}' in k and len(k.replace('{}', '')) >= 6:
            templates.append(re.compile('^' + '(.+?)'.join(map(re.escape, k.split('{}'))) + '$', re.S))
    missing = []
    for q in json.loads(seed.read_text(encoding='utf8')):
        for s in (q['prompt'], q['era']):
            if s not in texts and not any(t.match(s) for t in templates) and s not in missing:
                missing.append(s)
    return ['Spørsmål uten oversettelse: %r' % s for s in missing]


def main():
    ui = load('i18n_ui')
    data = {l: {} for l in LANGS}
    problems = []

    def add(row, where):
        if len(row) != 7:
            problems.append('%s: feil antall kolonner: %r' % (where, row[0]))
            return
        nb = row[0]
        for i, l in enumerate(LANGS, 1):
            if row[i].count('{}') != nb.count('{}'):
                problems.append('%s: {} stemmer ikke (%s): %r' % (where, l, nb))
            if nb in data[l]:
                problems.append('%s: duplikat nøkkel: %r' % (where, nb))
            data[l][nb] = row[i]

    for r in ui.UI + ui.LEGAL_EXTRA:
        add(r, 'UI')

    nb_legal = legal_nb()
    if len(nb_legal) != len(ui.LEGAL_EN):
        problems.append('Juridisk tekst: %d norske mot %d engelske' % (len(nb_legal), len(ui.LEGAL_EN)))
    else:
        for nb, en in zip(nb_legal, ui.LEGAL_EN):
            # kun engelsk foreløpig; de andre språkene faller tilbake til engelsk
            data['en'].setdefault(nb, en)

    q = load('i18n_questions')
    if q is not None:
        for r in q.QUESTIONS:
            add(r, 'Spørsmål')

    packs = load('make_packs')
    if packs is not None:
        # spørsmålspakkene finnes foreløpig bare på engelsk (de andre språkene viser engelsk)
        for nb, en in packs.english().items():
            data['en'].setdefault(nb, en)

    problems += seed_check(data['en'])

    for l in LANGS:
        out = ROOT / 'assets' / 'i18n' / (l + '.json')
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(data[l], ensure_ascii=False, indent=0), encoding='utf8')
        print(l, len(data[l]), 'tekster')
    if problems:
        print('\nPROBLEMER:')
        print('\n'.join(problems))
        sys.exit(1)


if __name__ == '__main__':
    main()
