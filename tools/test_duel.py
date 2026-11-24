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
