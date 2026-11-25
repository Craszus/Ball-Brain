import 'package:flutter/material.dart' hide Text;

import 'ui/football.dart';
import 'ui/theme.dart';
import 'l10n/l10n.dart';

/// Sist oppdatert (vises øverst i begge dokumentene).
const legalUpdated = '24. november 2026';

class _Section {
  const _Section(this.title, this.body);
  final String title;
  final String body;
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<_Section> sections;

  @override
  Widget build(BuildContext context) {
    return PitchScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sist oppdatert: $legalUpdated',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(intro, style: const TextStyle(color: Colors.white, height: 1.4)),
          for (final s in sections) ...[
            const SizedBox(height: 18),
            Text(s.title,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 17)),
            const SizedBox(height: 4),
            Text(s.body,
                style: const TextStyle(color: Colors.white, height: 1.4)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Personvernerklæring (GDPR). Beskriver det appen gjør i dag (alt lagres på
/// enheten) og hva som gjelder når nettbasert innlogging og rangering kommer.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalScreen(
        title: 'Personvern',
        intro: 'Ball Brain samler inn så lite som mulig. Her står det hva vi '
            'lagrer, hvorfor, og hvilke rettigheter du har.',
        sections: [
          _Section('Hva vi lagrer',
              'Spillernavn (kallenavn), land, valgt avatar, poeng, XP, nivå, '
                  'rekorder og troféer. Vi ber ikke om ekte navn, e-post, '
                  'telefonnummer, posisjon eller bilder av deg. Når du spiller 1v1, '
                  'lagres også resultatet av kampen.'),
          _Section('Hvor dataene ligger',
              'Kallenavn, land og poeng (også resultater fra 1v1, klubbkamper og dagens utfordring) lagres hos vår '
                  'databaseleverandør (Supabase) på servere i London (Storbritannia). '
                  'Avataren, XP, nivå og troféer ligger bare på din egen enhet. Appen '
                  'logger deg inn anonymt, uten e-post eller passord. «Slett all min '
                  'data» i Innstillinger sletter profilen din, poengene og kampene '
                  'dine på serveren, og alt på enheten. Slår du på varsler, lagres '
                  'også enhetens varsel-id, og varslene sendes via Google (Firebase).'),
          _Section('Hvorfor vi lagrer det',
              'For at spillet skal fungere: å vise profilen din, holde '
                  'styr på framgang og troféer, og vise deg på '
                  'rangeringslister og i kamper mot andre spillere. Grunnlaget er '
                  'at det er nødvendig for å levere tjenesten du bruker.'),
          _Section('Hva andre kan se',
              'Andre spillere kan se kallenavn, land og poeng på rangeringslister, '
                  'i grupper du er med i og i 1v1-kamper. Velg et kallenavn som ikke '
                  'avslører hvem du er.'),
          _Section('Barn',
              'Appen er laget for fotballfans i alle aldre. Barn under 13 år '
                  'bør bruke appen sammen med en voksen. Vi samler ikke inn '
                  'mer data om barn enn om andre, og de skal ikke oppgi ekte '
                  'navn.'),
          _Section('Avatarene',
              'Avatarene er tegnede figurer. Noen kan likne på ekte personer, '
                  'og er brukt med samtykke.'),
          _Section('Kartet og bilder',
              'Kartet vises fra data som ligger i appen og krever ingen '
                  'posisjon fra deg. Bilder av spillere og stadioner kommer fra '
                  'Wikimedia Commons med fri lisens (se Bildekreditering).'),
          _Section('Deling med tredjeparter',
              'Vi selger ikke data og viser ikke personrettet reklame. '
                  'Feilrapportering og ytelsesmåling (planlagt via Firebase '
                  'Crashlytics) samler tekniske data, ikke profilen din.'),
          _Section('Dine rettigheter',
              'Du kan når som helst se, rette og slette dataene dine. '
                  'I Innstillinger kan du velge «Slett all min data», som '
                  'fjerner alt fra denne enheten. Er dataene dine lastet opp, '
                  'sletter vi dem også fra serveren. Du har rett til å klage '
                  'til Datatilsynet.'),
          _Section('Lagring og sletting',
              'Data lagres så lenge du bruker appen. Slettes appen eller '
                  'dataene dine, forsvinner de lokale dataene med en gang.'),
          _Section('Kontakt',
              'Spørsmål om personvern kan sendes til utvikleren via '
                  'kontaktadressen på appens side i App Store og Google Play.'),
        ],
      );
}

/// Vilkår for bruk.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalScreen(
        title: 'Vilkår',
        intro: 'Ved å bruke Ball Brain godtar du disse vilkårene.',
        sections: [
          _Section('Bruk av appen',
              'Ball Brain er et fotballquiz-spill for underholdning. Du kan '
                  'bruke appen privat og gratis. Du må ikke forsøke å jukse, '
                  'bryte inn i systemet, eller forstyrre andre spillere.'),
          _Section('Kallenavn og oppførsel',
              'Kallenavn skal ikke være krenkende, støtende, ulovlige eller '
                  'utgi seg for å være andre. Vi kan endre eller fjerne '
                  'kallenavn og stenge brukere som bryter reglene.'),
          _Section('Poeng, XP og troféer',
              'Poeng, XP, nivåer og troféer har ingen pengeverdi og kan ikke '
                  'byttes mot noe. De kan endres hvis spillet justeres.'),
          _Section('Innhold og riktighet',
              'Vi gjør vårt beste for at spørsmål og fasit er riktige, men '
                  'kan ikke love at alt er feilfritt. Meld fra om feil.'),
          _Section('Opphavsrett og varemerker',
              'Bilder av spillere og stadioner er brukt under fri lisens fra '
                  'Wikimedia Commons. Ball Brain er ikke tilknyttet eller '
                  'godkjent av noen klubb, forbund eller spiller. Navn og '
                  'merker tilhører sine eiere.'),
          _Section('Ansvar',
              'Appen leveres «som den er». Vi er ikke ansvarlige for tap som '
                  'oppstår ved bruk, så langt loven tillater det.'),
          _Section('Endringer',
              'Vi kan oppdatere appen og disse vilkårene. Ved vesentlige '
                  'endringer varsler vi i appen.'),
          _Section('Lovvalg',
              'Norsk lov gjelder. Tvister avgjøres ved norske domstoler, '
                  'uten at dette tar bort rettigheter du har som forbruker.'),
        ],
      );
}
