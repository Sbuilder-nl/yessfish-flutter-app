import 'api.dart';

/// Feature-flags van de backend (/app-config). Bepaalt of Vis-AI/coins zichtbaar zijn.
/// Standaard alles UIT → dormant tot de server-flags aan gaan (geen app-update nodig).
class AppConfig {
  static bool freeAi = false;
  static bool coins = false;
  static bool plus = false;
  static int freeAiDaily = 1;

  static Future<void> load() async {
    try {
      final r = await Api.get('/app-config');
      if (r is Map) {
        freeAi = r['free_ai'] == true;
        coins = r['coins'] == true;
        plus = r['plus'] == true;
        if (r['free_ai_daily'] is int) freeAiDaily = r['free_ai_daily'] as int;
      }
    } catch (_) {
      // bij fout: alles uit laten (dormant)
    }
  }

  static bool get aiVisible => freeAi || plus;
}
