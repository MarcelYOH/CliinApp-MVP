// lib/shared/store/content_report_store.dart
// Store des signalements de contenu — même principe que les autres stores
// (singleton ChangeNotifier) tant qu'aucun backend n'est branché. Collecte
// propre de l'information (motif + qui signale + quel contenu), consultable
// plus tard — aucun vrai traitement/modération à ce stade (Correction 12).

import 'package:flutter/foundation.dart';
import '../models/content_report_model.dart';

class ContentReportStore extends ChangeNotifier {
  ContentReportStore._();
  static final ContentReportStore instance = ContentReportStore._();

  final List<ContentReportModel> _reports = [];
  List<ContentReportModel> get reports => List.unmodifiable(_reports);

  void reportAction({
    required String actionId,
    required String reporterId,
    required String reason,
  }) {
    _reports.add(ContentReportModel(
      id: 'creport_${DateTime.now().millisecondsSinceEpoch}',
      actionId: actionId,
      reporterId: reporterId,
      reason: reason,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }
}
