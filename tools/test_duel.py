"""Ende-til-ende-test av 1v1 mot Supabase (to anonyme testbrukere som ryddes bort etterpå).

Bruk: python tools/test_duel.py   (leser URL og nøkkel fra supabase.env.json)
"""
import json
import os
import time
import urllib.request

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg = json.load(open(os.path.join(root, 'supabase.env.json'), encoding='utf8'))
U, K = cfg['SUPABASE_URL'], cfg['SUPABASE_ANON_KEY']


def call(method, path, body=None, tok=None):
    h = {'apikey': K, 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (tok or K)}
    r = urllib.request.Request(U + path, data=json.dumps(body).encode() if body is not None else None,
                               headers=h, method=method)
    try:
        x = urllib.request.urlopen(r)
        t = x.read().decode()
        return x.status, (json.loads(t) if t else None)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode()).get('message', '')
        except Exception:
            return e.code, ''


def user(name):
    r = urllib.request.Request(U + '/auth/v1/signup', data=b'{}',
                               headers={'apikey': K, 'Content-Type': 'application/json'}, method='POST')
    j = json.loads(urllib.request.urlopen(r).read())
    t, u = j['access_token'], j['user']['id']
    call('POST', '/rest/v1/profiles', {'id': u, 'username': name, 'country_code': 'NO'}, t)
    return t, u


def rpc(fn, params, tok):
    return call('POST', '/rest/v1/rpc/' + fn, params, tok)


qs = {q['key']: q for q in json.load(open(os.path.join(root, 'assets', 'seed', 'questions.json'), encoding='utf8'))}
ta, ua = user('Dueller A')
tb, ub = user('Dueller B')
ok = True
tc = uc = None


def check(label, cond, extra=''):
    global ok
    ok &= bool(cond)
    print(('OK   ' if cond else 'FEIL ') + label, extra)


try:
    s, a = rpc('duel_find', {}, ta)
    check('A hurtigmatch gir ventende kamp', s == 200 and a['status'] == 'waiting' and a['opp'] is None)
    s, a2 = rpc('duel_find', {}, ta)
    check('A får samme kamp igjen (gjenopptar)', a2['id'] == a['id'])
    s, b = rpc('duel_find', {}, tb)
    check('B hurtigmatch kobles til A', s == 200 and b['status'] == 'active' and b['id'] == a['id'] and b['opp']['name'] == 'Dueller A')
    d = b['id']
    s, qa = rpc('duel_questions', {'p_id': d}, ta)
    s, qb = rpc('duel_questions', {'p_id': d}, tb)
    check('begge får samme 10 spørsmål uten fasit', len(qa) == 10 and [q['key'] for q in qa] == [q['key'] for q in qb] and 'correct' not in qa[0])
    print('     (starter om ~4 s)')
    time.sleep(5)
    s, r = rpc('duel_answer', {'p_id': d, 'p_idx': 1, 'p_answer': 'x'}, ta)
    check('feil rekkefølge avvist', s == 400 and 'bad_index' in r)
    pa = pb = 0
    for i, q in enumerate(qa):
        right = qs[q['key']]['options'][qs[q['key']]['correct']]
        wrong = [o for o in qs[q['key']]['options'] if o != right][0]
        s, ra = rpc('duel_answer', {'p_id': d, 'p_idx': i, 'p_answer': right}, ta)          # A alltid riktig
        s2, rb = rpc('duel_answer', {'p_id': d, 'p_idx': i, 'p_answer': right if i < 6 else wrong}, tb)  # B feil de 4 siste
        assert s == 200 and s2 == 200, (ra, rb)
        pa += ra['points']; pb += rb['points']
        if i == 4:
            s, g = rpc('duel_get', {'p_id': d}, ta)
            check('A ser motstanderens fremdrift live', g['opp']['answered'] == 5 and g['me']['answered'] == 5 and g['status'] == 'active')
        time.sleep(1.1)
    s, g = rpc('duel_get', {'p_id': d}, ta)
    check('kampen er ferdig, A vinner', g['status'] == 'finished' and g['result'] == 'win', f"A={g['me']['score']} B={g['opp']['score']}")
    s, g2 = rpc('duel_get', {'p_id': d}, tb)
    check('B ser tap', g2['result'] == 'loss' and g2['me']['correct'] == 6)
    check('poeng stemmer med svarene', g['me']['score'] == pa and g2['me']['score'] == pb)
    s, r = rpc('duel_answer', {'p_id': d, 'p_idx': 0, 'p_answer': 'x'}, ta)
    check('kan ikke svare etter at kampen er ferdig', s == 400)

    # privat kamp med kode
    s, p = rpc('duel_create_private', {}, ta)
    check('A lager kode-kamp', s == 200 and p['code'] and p['status'] == 'waiting', p.get('code') if isinstance(p, dict) else p)
    s, r = rpc('duel_join', {'p_code': p['code']}, ta)
    check('A kan ikke bli med i egen kamp', s == 400)
    s, r = rpc('duel_join', {'p_code': 'ZZZZZ'}, tb)
    check('feil kode avvist', s == 400 and 'not_found' in r)
    s, r = rpc('duel_join', {'p_code': p['code'].lower()}, tb)
    check('B blir med via kode', s == 200 and r['status'] == 'active')
    tc, uc = user('Utenfor')
    check('en tredje kan ikke lese kampen', rpc('duel_get', {'p_id': r['id']}, tc)[0] == 400)
    check('direkte tabelltilgang til svar stengt', call('GET', '/rest/v1/duel_answers?select=*', None, ta)[0] == 403)
    check('A kan ikke skrive til duels direkte', call('PATCH', '/rest/v1/duels?id=eq.' + r['id'], {'winner': ua}, ta)[0] in (401, 403))

    # --- utfordringer til venner (async, som i Logica) ---
    s, g = rpc('create_group', {'p_name': 'Duellgjengen'}, ta)
    s, jr = rpc('join_group', {'p_code': g[0]['code']}, tb)
    s, c = rpc('create_challenge', {'p_user': ub}, ta)
    check('A utfordrer B (felles gruppe)', s == 200 and c['mode'] == 'challenge' and c['status'] == 'active' and c['challenger'], c.get('id') if isinstance(c, dict) else c)
    s, r = rpc('create_challenge', {'p_user': ub}, ta)
    check('ikke to åpne utfordringer til samme venn', s == 400 and 'already' in r)
    s, r = rpc('create_challenge', {'p_user': ua}, ta)
    check('kan ikke utfordre seg selv', s == 400 and 'self' in r)
    tc2, uc2 = user('Fremmed')
    s, r = rpc('create_challenge', {'p_user': uc2}, ta)
    check('kan ikke utfordre noen uten felles gruppe', s == 400 and 'not_shared' in r)
    s, ml = rpc('my_duels', {}, tb)
    inc = [x for x in ml if x['id'] == c['id']]
    check('B ser innkommende utfordring fra A', len(inc) == 1 and inc[0]['incoming'] and inc[0]['opponent'] == 'Dueller A' and not inc[0]['my_done'])
    s, r = rpc('duel_answer', {'p_id': c['id'], 'p_idx': 0, 'p_answer': 'x'}, tb)
    check('kan ikke svare før man har startet', s == 400 and 'not_started' in r)
    # B avslår
    s, _ = rpc('duel_decline', {'p_id': c['id']}, tb)
    s, ml = rpc('my_duels', {}, tb)
    check('avslått utfordring forsvinner for B', not any(x['id'] == c['id'] for x in ml))
    s, ma = rpc('my_duels', {}, ta)
    check('A ser at den ble avslått', any(x['id'] == c['id'] and x['status'] == 'declined' for x in ma))
    rpc('duel_remove', {'p_id': c['id']}, ta)
    s, ma = rpc('my_duels', {}, ta)
    check('A kan fjerne den avslåtte fra listen', not any(x['id'] == c['id'] for x in ma))
    # B slår av utfordringer
    rpc('set_accepts_challenges', {'p_on': False}, tb)
    s, r = rpc('create_challenge', {'p_user': ub}, ta)
    check('A kan ikke utfordre når B har slått av utfordringer', s == 400 and 'not_accepting' in r)
    rpc('set_accepts_challenges', {'p_on': True}, tb)
    # ny utfordring spilles til ulike tider
    s, c = rpc('create_challenge', {'p_user': ub}, ta)
    cid = c['id']
    s, q = rpc('duel_questions', {'p_id': cid}, ta)
    check('utfordring har 10 spørsmål', s == 200 and len(q) == 10)
    s, st = rpc('duel_start_mine', {'p_id': cid}, ta)
    check('A starter sin runde (nedtelling)', s == 200 and st['starts_ms'] is not None)
    time.sleep(5)
    for i, qq in enumerate(q):
        right = qs[qq['key']]['options'][qs[qq['key']]['correct']]
        rpc('duel_answer', {'p_id': cid, 'p_idx': i, 'p_answer': right}, ta)
        time.sleep(1.1)
    s, g1 = rpc('duel_get', {'p_id': cid}, ta)
    check('A er ferdig og venter på B', g1['status'] == 'active' and g1['my_done'] and g1['me']['answered'] == 10)
    s, st = rpc('duel_start_mine', {'p_id': cid}, tb)
    check('B kan starte senere', s == 200 and st['starts_ms'] is not None and not st['my_done'])
    time.sleep(5)
    s, qb2 = rpc('duel_questions', {'p_id': cid}, tb)
    check('B får de samme spørsmålene', [x['key'] for x in qb2] == [x['key'] for x in q])
    for i, qq in enumerate(qb2):
        wrong = [o for o in qs[qq['key']]['options'] if o != qs[qq['key']]['options'][qs[qq['key']]['correct']]][0]
        rpc('duel_answer', {'p_id': cid, 'p_idx': i, 'p_answer': wrong}, tb)
        time.sleep(1.1)
    s, gb = rpc('duel_get', {'p_id': cid}, tb)
    check('utfordringen er ferdig og A vant', gb['status'] == 'finished' and gb['result'] == 'loss', f"B={gb['me']['score']} A={gb['opp']['score']}")
    s, r = rpc('duel_start_mine', {'p_id': cid}, tb)
    check('kan ikke spille samme utfordring to ganger', s == 400)
    s, ml = rpc('my_duels', {}, ta)
    check('ferdig utfordring står i listen med resultat', any(x['id'] == cid and x['result'] == 'win' for x in ml))
    check('listen har motstander-id og sluttidspunkt', any(x['id'] == cid and x.get('opponent_id') == ub and x.get('finished_ms') for x in ml))
    rpc('duel_remove', {'p_id': cid}, ta)
    s, ml = rpc('my_duels', {}, ta)
    s2, mlb = rpc('my_duels', {}, tb)
    check('A fjerner den, B beholder den', not any(x['id'] == cid for x in ml) and any(x['id'] == cid for x in mlb))
    s, c = rpc('create_challenge', {'p_user': ub}, ta)
    rpc('duel_remove', {'p_id': c['id']}, ta)
    s, mlb = rpc('my_duels', {}, tb)
    check('A avbryter en åpen utfordring, og den forsvinner for B', not any(x['id'] == c['id'] for x in mlb))
    for t, u in ((tc2, uc2),):
        call('DELETE', '/rest/v1/profiles?id=eq.' + u, None, t)

    # avbrutt kamp: A fullfører, B svarer aldri -> avsluttes etter 60 s (vi tester bare at A kan avbryte ventende)
    s, w = rpc('duel_create_private', {}, ta)
    rpc('duel_cancel', {'p_id': w['id']}, ta)
    s, r = rpc('duel_join', {'p_code': w['code']}, tb)
    check('avbrutt kamp kan ikke tas', s == 400)
finally:
    for t, u in ((ta, ua), (tb, ub), (tc, uc)):
        if t:
            call('DELETE', '/rest/v1/profiles?id=eq.' + u, None, t)
print('\nALT OK' if ok else '\nNOE FEILET')
