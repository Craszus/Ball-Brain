import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Utfordringer som venter på svar (til varselet på «Kamper»-knappen).
class ChallengeAlerts {
  const ChallengeAlerts({this.duels = 0, this.clubs = 0});

  /// 1v1-utfordringer jeg ikke har spilt.
  final int duels;

  /// Klubbkamper klubben min er utfordret til.
  final int clubs;

  int get total => duels + clubs;

  /// Fanen i «Kamper» som skal åpnes: klubber hvis det bare er klubben som venter.
  int get tab => duels == 0 && clubs > 0 ? 1 : 0;
}

class ChallengeAlertsController extends Notifier<ChallengeAlerts> {
  @override
  ChallengeAlerts build() => const ChallengeAlerts();

  void setDuels(int n) => state = ChallengeAlerts(duels: n, clubs: state.clubs);
  void setClubs(int n) => state = ChallengeAlerts(duels: state.duels, clubs: n);
}

final challengeAlertsProvider =
    NotifierProvider<ChallengeAlertsController, ChallengeAlerts>(ChallengeAlertsController.new);
