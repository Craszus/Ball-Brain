"""Ende-til-ende-test av klubbkamp 3 mot 3 mot Supabase (testbrukere ryddes bort etterpå).

Bruk: python tools/test_clubs.py   (tar vel ett minutt: venter på avspark)
"""
import datetime
import json
import os
import time
import urllib.error
import urllib.request

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg = json.load(open(os.path.join(root, 'supabase.env.json'), encoding='utf8'))
U, K = cfg['SUPABASE_URL'], cfg['SUPABASE_ANON_KEY']
qs = {q['prompt']: q for q in json.load(open(os.path.join(root, 'assets', 'seed', 'questions.json'), encoding='utf8'))
      if q['type'] == 'rules_quiz'}


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


ok = True


def check(label, cond, extra=''):
    global ok
    ok &= bool(cond)
    print(('OK   ' if cond else 'FEIL ') + label, '' if cond else extra)


def in_seconds(s):
    return (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(seconds=s)).isoformat()


users = []
try:
    home = [user('Hjemme %d' % i) for i in range(4)]
    away = [user('Borte %d' % i) for i in range(3)]
    users = home + away
    h, a = home[0][0], away[0][0]
    s, g1 = rpc('create_group', {'p_name': 'Testklubb Hjemme'}, h)
    s, g2 = rpc('create_group', {'p_name': 'Testklubb Borte'}, a)
    hid, aid = g1[0]['id'], g2[0]['id']
    s, mine = rpc('club_my_clubs', {}, a)
    check('klubbene får skjold og utfordringskode', s == 200 and mine[0]['match_code'] and mine[0]['can_edit'], mine)
    code = mine[0]['match_code']
    for t, _ in home[1:2]:
        rpc('join_group', {'p_code': g1[0]['code']}, t)

    def challenge(tok=h, size=3, kick=75, window=3, c=code, club=hid):
        return rpc('club_challenge', {'p_club': club, 'p_code': c, 'p_size': size,
                                      'p_kickoff': in_seconds(kick), 'p_window': window}, tok)

    s, r = challenge()
    check('2 medlemmer er for få', s == 400 and 'too_few' in r, r)
    rpc('join_group', {'p_code': g1[0]['code']}, home[2][0])
    rpc('join_group', {'p_code': g1[0]['code']}, home[3][0])
    s, r = challenge()
    check('motstanderen må også ha 3', s == 400 and 'opp_too_few' in r, r)
    for t, _ in away[1:]:
        rpc('join_group', {'p_code': g2[0]['code']}, t)
    s, r = challenge(size=7)
    check('7 mot 7 finnes ikke', s == 400 and 'bad_setup' in r, r)
    s, r = challenge(window=15)
    check('frist over 5 min avvises', s == 400 and 'bad_setup' in r, r)
    s, game = challenge()
    check('utfordringen opprettes', s == 200 and isinstance(game, str), game)
    s, r = challenge()
    check('ikke to åpne kamper mellom de samme', s == 400 and 'already' in r, r)
    s, r = rpc('club_respond', {'p_game': game, 'p_accept': True}, h)
    check('utfordreren kan ikke godta selv', s == 400, r)
    s, r = rpc('club_join', {'p_game': game, 'p_club': aid}, away[1][0])
    check('motstanderen kan ikke melde seg på før kampen er godtatt', s == 400 and 'closed' in r, r)
    s, r = rpc('club_respond', {'p_game': game, 'p_accept': True}, a)
    check('motstanderen godtar', s == 204 or s == 200, r)
    for t, _ in home[1:3]:
        rpc('club_join', {'p_game': game, 'p_club': hid}, t)
    s, r = rpc('club_join', {'p_game': game, 'p_club': hid}, home[3][0])
    check('fjerde spiller får ikke plass i 3 mot 3', s == 400 and 'team_full' in r, r)
    for t, _ in away:
        rpc('club_join', {'p_game': game, 'p_club': aid}, t)
    s, r = rpc('club_next', {'p_game': game}, h)
    check('ingen spørsmål før avspark', s == 400 and 'not_started' in r, r)

    print('     (venter på avspark)')
    s, games = rpc('club_game_list', {}, h)
    g = next(x for x in games if x['id'] == game)
    time.sleep(max(0, (g['kickoff_ms'] - g['now_ms']) / 1000) + 2)
    players = [(t, True) for t, _ in home[:3]] + [(t, False) for t, _ in away]
    seen = {True: [], False: []}
    firsts = []
    for n, (tok, is_home) in enumerate(players):
        mine_prompts = []
        for i in range(10):
            s, q = rpc('club_next', {'p_game': game}, tok)
            if s != 200 or q.get('done'):
                check('henter spørsmål %d for spiller %d' % (i, n), False, q)
                break
            if i == 0 and n == 0:
                check('spørsmålet kommer uten fasit, med 10 s', 'correct' not in q and 8000 < q['remaining_ms'] <= 10000, q)
            mine_prompts.append(q['prompt'])
            right = qs.get(q['prompt'])
            answer = right['options'][right['correct']] if right and is_home else 'feil svar'
            s, r = rpc('club_answer', {'p_game': game, 'p_idx': i, 'p_answer': answer}, tok)
            if s != 200:
                check('svarer på spørsmål %d for spiller %d' % (i, n), False, r)
                break
        seen[is_home].append(set(mine_prompts))
        firsts.append(mine_prompts[:1])
        if n == 0:
            s, r = rpc('club_answer', {'p_game': game, 'p_idx': 9, 'p_answer': 'x'}, tok)
            check('kan ikke svare to ganger på samme', s == 400 and 'bad_index' in r, r)
    h_sets, a_sets = seen[True], seen[False]
    check('lagkameratene får forskjellige spørsmål', len(set().union(*h_sets)) == 30, len(set().union(*h_sets)))
    check('motstanderen får de samme 30 totalt', set().union(*h_sets) == set().union(*a_sets))
    check('samme plass får samme sett', all(x == y for x, y in zip(h_sets, a_sets)))
    s, games = rpc('club_game_list', {}, h)
    g = next(x for x in games if x['id'] == game)
    home_pot = sum(p['score'] for p in g['players'] if p['club'] == hid)
    check('kampen er avgjort når alle har svart', g['status'] == 'finished' and g['winner'] == hid, g['status'])
    check('potten er summen av lagets poeng', home_pot >= 30 * 10, home_pot)
    s, mine = rpc('club_my_clubs', {}, a)
    check('tapet telles hos motstanderen', mine[0]['losses'] == 1 and mine[0]['wins'] == 0, mine)
    s, r = call('GET', '/rest/v1/club_games?select=*', None, h)
    check('tabellen kan ikke leses direkte', s in (401, 403), s)

    # Klubbtabellen (se supabase/leagues.sql)
    for period in ('month', 'all'):
        s, table = rpc('club_table', {'p_period': period}, h)
        rows = {x['id']: x for x in table} if s == 200 else {}
        check('tabellen (%s): vinneren har 3 poeng og står over taperen' % period,
              hid in rows and rows[hid]['points'] == 3 and rows[hid]['mine'] and rows[aid]['points'] == 0
              and rows[aid]['l'] == 1 and rows[hid]['rank'] < rows[aid]['rank'], table)
    check('tabellen viser ikke utfordringskoder', all('match_code' not in x for x in table))
    s, r = rpc('club_table', {'p_period': 'all'}, None)
    check('tabellen krever innlogging', s in (401, 403), s)

    # Klubbserien: to 1v1 mellom de samme samme dag teller bare én gang
    for _ in range(2):
        s, d = rpc('create_challenge', {'p_user': home[1][1]}, h)
        check('1v1 i klubben opprettes', s == 200, d)
        for t in (h, home[1][0]):
            rpc('duel_start_mine', {'p_id': d['id']}, t)
        time.sleep(5)
        for i in range(10):
            for t in (h, home[1][0]):
                rpc('duel_answer', {'p_id': d['id'], 'p_idx': i, 'p_answer': 'feil svar'}, t)
    s, league = rpc('club_league', {'p_club': hid, 'p_period': 'month'}, h)
    rows = {x['user_id']: x for x in league} if s == 200 else {}
    check('serien har alle medlemmene', len(rows) == 4, league)
    one, two = rows.get(home[0][1], {}), rows.get(home[1][1], {})
    check('bare ett oppgjør pr. par pr. dag teller', one.get('played') == 1 and two.get('played') == 1, league)
    check('seier gir 3 poeng (uavgjort 1 hver)', one.get('points', 0) + two.get('points', 0) in (2, 3), league)
    s, r = rpc('club_league', {'p_club': hid, 'p_period': 'month'}, a)
    check('utenforstående ser ikke serien', s == 400 and 'not_member' in r, r)

    # En spiller kan ikke hoppe til en annen klubb samme uke
    s, g3 = rpc('create_group', {'p_name': 'Testklubb Tredje'}, home[0][0])
    for t, _ in (home[1], home[2]):
        rpc('join_group', {'p_code': g3[0]['code']}, t)
    s, r = challenge(tok=home[0][0], club=g3[0]['id'], kick=300)
    check('kan ikke spille for to klubber samme uke', s == 400 and 'locked' in r, r)

    # avslag
    s, game2 = challenge(tok=home[3][0], kick=300)
    check('en annen i klubben kan utfordre på nytt', s == 200, game2)
    rpc('club_respond', {'p_game': game2, 'p_accept': False}, a)
    s, games = rpc('club_game_list', {}, h)
    check('avslag vises', next(x for x in games if x['id'] == game2)['status'] == 'declined')
finally:
    for t, u in users:  # forlat klubbene først, så tomme testklubber slettes
        _, groups = rpc('my_groups', {}, t)
        for g in groups if isinstance(groups, list) else []:
            rpc('leave_group', {'p_group': g['id']}, t)
        call('DELETE', '/rest/v1/profiles?id=eq.' + u, None, t)
print('\nALT OK' if ok else '\nNOE FEILET')
