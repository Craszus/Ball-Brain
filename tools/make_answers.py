"""Lager supabase/answers.sql: serverens fasit for poengvalidering.

Serveren lagrer bare de 10 første tegnene av md5(nøkkel + ':' + riktig svar), ikke svaret i klartekst. Appen sender
valgt svar (norsk originaltekst) pr. spørsmålsnøkkel, og serveren sammenligner hashene.
Kjør på nytt etter at spørsmålene er endret (python tools/make_answers.py), og kjør
supabase/answers.sql i SQL Editor (den tømmer og fyller tabellen på nytt).
"""
import hashlib
import json
import os

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
qs = json.load(open(os.path.join(root, 'assets', 'seed', 'questions.json'), encoding='utf8'))


def canonical(q):
    if q['type'] == 'image_sort':
        return '|'.join(q['options'][i] for i in q['correct'])
    return q['options'][q['correct']]


rows = []
compact = []
seen = set()
for q in qs:
    k = q['key']
    assert k not in seen, k
    seen.add(k)
    h = hashlib.md5((k + ':' + canonical(q)).encode('utf8')).hexdigest()[:10]
    rows.append("('%s','%s','%s')" % (k, q['type'], h))
    compact.append('%s%s%s' % (k, 'r' if q['type'] == 'rules_quiz' else 's', h))

out = ["-- Generert av tools/make_answers.py. Fasit som hash; kjøres i SQL Editor.",
       "truncate public.quiz_answers;",
       "insert into public.quiz_answers (key, type, answer_hash) values"]
out.append(',\n'.join(rows) + ';')
path = os.path.join(root, 'supabase', 'answers.sql')
open(path, 'w', encoding='utf8', newline='\n').write('\n'.join(out) + '\n')
print(len(rows), 'svar ->', path, os.path.getsize(path), 'byte')
open(os.path.join(root, 'supabase', 'answers.compact.txt'), 'w', encoding='utf8').write(chr(10).join(compact))
