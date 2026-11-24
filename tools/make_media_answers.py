"""Lager fasit til serverstyrt poengberegning for geografi og bildequiz.

Skriver supabase/geo_places.tsv (id, lat, lon) og supabase/photo_answers.tsv
(item, qtype, answer). Lastes inn i Supabase (tabellene geo_places og photo_answers) med en
engangsfunksjon, se docs i ODIN-LOGG. Kjør på nytt når steder/bilder endres.
"""
import json
import os

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(rel):
    return json.load(open(os.path.join(root, rel), encoding='utf8'))


places = load('assets/geo/places.json')
players = [p for p in load('assets/media/players.json') if p.get('photo')]
stadiums = [s for s in load('assets/media/stadiums.json') if s.get('photo')]

geo = ['%s\t%s\t%s' % (p['id'], p['lat'], p['lon']) for p in places]
photo = []
for p in players:
    photo.append('player:%s\tname\t%s' % (p['id'], p['name']))
    if p.get('nationality'):
        photo.append('player:%s\tcountry\t%s' % (p['id'], p['nationality']))
for s in stadiums:
    photo.append('stadium:%s\tname\t%s' % (s['id'], s['name']))
    if s.get('country'):
        photo.append('stadium:%s\tcountry\t%s' % (s['id'], s['country']))
    if s.get('club'):
        photo.append('stadium:%s\tclub\t%s' % (s['id'], s['club']))

for name, rows in (('geo_places.tsv', geo), ('photo_answers.tsv', photo)):
    with open(os.path.join(root, 'supabase', name), 'w', encoding='utf8', newline='\n') as f:
        f.write('\n'.join(rows))
print(len(geo), 'steder,', len(photo), 'bildesvar')
