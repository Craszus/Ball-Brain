"""Ende-til-ende-test av quizkveld mot Supabase (testbrukere ryddes bort etterpå).

Bruk: python tools/test_quiznight.py
"""
import os
import sys
import time

# gjenbruker hjelpefunksjonene (call, user, rpc, check) fra klubbtesten
_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'test_clubs.py'), encoding='utf8').read()
exec(_src.split('\nusers = []')[0])

users = []
try:
    host, a, b, outsider = (user('Quiztest%d' % i) for i in range(4))
    users = [host, a, b, outsider]

    s, night = rpc('quiz_create', {'p_count': 5, 'p_seconds': 10, 'p_eras': ['Regler'], 'p_host_plays': False}, host[0])
    check('verten lager en quizkveld', s == 200 and night['status'] == 'lobby' and night['total'] == 5, night)
    nid, code = night['id'], night['code']
    s, r = rpc('quiz_next', {'p_id': nid, 'p_status': 'lobby', 'p_idx': 0}, host[0])
    check('kan ikke starte uten deltakere', s != 200 and 'no_players' in str(r), r)
    for p in (a, b):
        s, r = rpc('quiz_join', {'p_code': code.lower()}, p[0])
        check('deltaker blir med med kode', s == 200 and r['playing'] and not r['host'], r)
    s, r = rpc('quiz_state', {'p_id': nid}, outsider[0])
    check('utenforstående får ikke se', s != 200, r)
    s, r = rpc('quiz_next', {'p_id': nid, 'p_status': 'lobby', 'p_idx': 0}, a[0])
    check('bare verten kan starte', s != 200, r)
    s, r = call('GET', '/rest/v1/quiz_nights?select=questions', tok=a[0])
    check('tabellen med fasit kan ikke leses', s != 200 or r == [], r)

    s, r = rpc('quiz_next', {'p_id': nid, 'p_status': 'lobby', 'p_idx': 0}, host[0])
    check('første spørsmål', s == 200 and r['status'] == 'question' and r['right'] is None, r)
    s, r2 = rpc('quiz_next', {'p_id': nid, 'p_status': 'lobby', 'p_idx': 0}, host[0])
    check('dobbelttrykk hopper ikke videre', r2['status'] == 'question' and r2['idx'] == 0, r2)
    options = r['question']['options']

    s, ra = rpc('quiz_answer', {'p_id': nid, 'p_idx': 0, 'p_answer': options[0]}, a[0])
    check('svar mottas uten at fasiten røpes', s == 200 and ra['right'] is None and ra['my_answered']
          and ra['standings'] == [] and ra['my_points'] is None, ra)
    s, rb = rpc('quiz_answer', {'p_id': nid, 'p_idx': 0, 'p_answer': options[1]}, b[0])
    check('svaret vises når alle har svart', rb['status'] == 'reveal' and rb['right'] in options, rb)
    right = rb['right']
    s, ra = rpc('quiz_state', {'p_id': nid}, a[0])
    check('riktig svar gir 10-15 poeng, feil gir 0',
          (10 <= ra['my_points'] <= 15) if options[0] == right else ra['my_points'] == 0, ra)
    check('resultatlisten har begge', len(ra['standings']) == 2, ra)
    s, r = rpc('quiz_answer', {'p_id': nid, 'p_idx': 0, 'p_answer': right}, a[0])
    check('kan ikke svare etter at spørsmålet er stengt', s != 200, r)

    for i in range(1, 5):
        s, r = rpc('quiz_next', {'p_id': nid, 'p_status': 'reveal', 'p_idx': i - 1}, host[0])
        check('spørsmål %d' % (i + 1), r['status'] == 'question' and r['idx'] == i, r)
        if i == 1:
            time.sleep(12)
            s, r = rpc('quiz_state', {'p_id': nid}, a[0])
            check('stenges av seg selv når tiden er ute', r['status'] == 'reveal', r)
        else:
            s, r = rpc('quiz_next', {'p_id': nid, 'p_status': 'question', 'p_idx': i}, host[0])
            check('verten kan vise svaret tidlig', r['status'] == 'reveal', r)
    s, r = rpc('quiz_mine', {}, b[0])
    check('pågående kveld kan gjenopptas', r and r['id'] == nid, r)
    s, r = rpc('quiz_next', {'p_id': nid, 'p_status': 'reveal', 'p_idx': 4}, host[0])
    check('ferdig etter siste', r['status'] == 'finished' and r['standings'][0]['rank'] == 1, r)
    s, r = rpc('quiz_join', {'p_code': code}, outsider[0])
    check('kan ikke bli med i en ferdig kveld', s != 200, r)
    s, r = rpc('quiz_mine', {}, b[0])
    check('ferdig kveld regnes ikke som pågående', r is None or r['id'] != nid, r)
finally:
    for t, u in users:
        call('DELETE', '/rest/v1/profiles?id=eq.' + u, tok=t)

print('ALT OK' if ok else 'NOE FEILET')
sys.exit(0 if ok else 1)
