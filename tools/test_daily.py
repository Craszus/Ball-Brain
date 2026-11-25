"""Ende-til-ende-test av dagens utfordring mot Supabase (testbrukere ryddes bort etterpå).

Bruk: python tools/test_daily.py   (leser URL og nøkkel fra supabase.env.json)
"""
import json
import os
import urllib.error
import urllib.request
import uuid

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


def user(name, country='NO'):
    r = urllib.request.Request(U + '/auth/v1/signup', data=b'{}',
                               headers={'apikey': K, 'Content-Type': 'application/json'}, method='POST')
    j = json.loads(urllib.request.urlopen(r).read())
    t, u = j['access_token'], j['user']['id']
    call('POST', '/rest/v1/profiles', {'id': u, 'username': name, 'country_code': country}, t)
    return t, u


def rpc(fn, params, tok):
    return call('POST', '/rest/v1/rpc/' + fn, params, tok)


def board(tok, period, scope):
    return rpc('daily_board', {'p_period': period, 'p_scope': scope}, tok)


ok = True


def check(label, cond, extra=''):
    global ok
    ok &= bool(cond)
    print(('OK   ' if cond else 'FEIL ') + label, extra)


users = []
try:
    ta, ua = user('Daglig A')
    users.append((ta, ua))
    tb, ub = user('Daglig B', 'SE')
    users.append((tb, ub))

    s, a = rpc('daily_start', {}, ta)
    check('A starter og får 10 spørsmål og et forsøk', s == 200 and len(a['questions']) == 10 and a['token'], a if s != 200 else '')
    s, b = rpc('daily_start', {}, tb)
    check('B får de samme spørsmålene', [q['key'] for q in b['questions']] == [q['key'] for q in a['questions']])
    check('letteste først', [q['difficulty'] for q in a['questions']] == sorted(q['difficulty'] for q in a['questions']))
    s, a2 = rpc('daily_start', {}, ta)
    check('andre start gir ikke nytt forsøk', s == 200 and a2['token'] is None)

    right = [{'key': q['key'], 'answer': q['options'][q['correct']]} for q in a['questions']]
    s, r = rpc('daily_submit', {'p_token': str(uuid.uuid4()), 'p_answers': right}, ta)
    check('feil token teller ikke', s == 200 and r['counted'] is False)
    s, r = rpc('daily_submit', {'p_token': a['token'], 'p_answers': right}, tb)
    check('B kan ikke levere med A sitt token', s == 200 and r['counted'] is False)
    s, r = rpc('daily_submit', {'p_token': a['token'], 'p_answers': right}, ta)
    check('A leverer alt riktig', s == 200 and r == {'counted': True, 'correct': 10}, r)
    s, r = rpc('daily_submit', {'p_token': a['token'], 'p_answers': right}, ta)
    check('kan ikke levere to ganger', s == 200 and r['counted'] is False)

    # B: 9 riktige svar, men ett spørsmål besvart to ganger teller ikke
    twice = right[:9] + [{'key': right[8]['key'], 'answer': 'x'}]
    s, r = rpc('daily_submit', {'p_token': b['token'], 'p_answers': twice}, tb)
    check('doble svar på samme spørsmål teller ikke', s == 200 and r == {'counted': True, 'correct': 8}, r)

    s, rows = board(ta, 'day', 'world')
    mine = {x['user_id']: x for x in rows}
    check('verdenslisten for i dag har begge, A foran', s == 200 and ua in mine and ub in mine and mine[ua]['rank'] < mine[ub]['rank'], rows if s != 200 else '')
    s, rows = board(ta, 'day', 'country')
    check('landslisten viser bare mitt land', any(x['user_id'] == ua for x in rows) and not any(x['user_id'] == ub for x in rows))
    s, rows = board(ta, 'day', 'friends')
    check('venner uten felles gruppe: bare meg', [x['user_id'] for x in rows] == [ua])
    s, g = rpc('create_group', {'p_name': 'Daglig gjeng'}, ta)
    rpc('join_group', {'p_code': g[0]['code']}, tb)
    s, rows = board(ta, 'day', 'friends')
    check('venner i samme gruppe vises', [x['user_id'] for x in rows] == [ua, ub])
    s, rows = board(tb, 'week', 'friends')
    check('ukeslisten summerer dagene', [(x['user_id'], x['correct'], x['days']) for x in rows] == [(ua, 10, 1), (ub, 8, 1)], rows)
    s, r = call('GET', '/rest/v1/daily_results?select=*', None, ta)
    check('tabellen kan ikke leses direkte', s in (401, 403), s)
finally:
    for t, u in users:
        call('DELETE', '/rest/v1/profiles?id=eq.' + u, None, t)
print('\nALT OK' if ok else '\nNOE FEILET')
