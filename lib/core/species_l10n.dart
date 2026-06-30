import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Labels voor het feiten-blad (6-talig).
const Map<String, Map<String, String>> kSpeciesUi = {
  'family':    {'nl': 'Familie', 'en': 'Family', 'de': 'Familie', 'fr': 'Famille', 'es': 'Familia', 'pl': 'Rodzina'},
  'water':     {'nl': 'Water', 'en': 'Water', 'de': 'Gewässer', 'fr': 'Eau', 'es': 'Agua', 'pl': 'Woda'},
  'maxlength': {'nl': 'Max. lengte', 'en': 'Max. length', 'de': 'Max. Länge', 'fr': 'Longueur max.', 'es': 'Longitud máx.', 'pl': 'Maks. długość'},
  'maxweight': {'nl': 'Max. gewicht', 'en': 'Max. weight', 'de': 'Max. Gewicht', 'fr': 'Poids max.', 'es': 'Peso máx.', 'pl': 'Maks. waga'},
  'facts':     {'nl': 'Kenmerken', 'en': 'Facts', 'de': 'Steckbrief', 'fr': 'Fiche', 'es': 'Ficha', 'pl': 'Cechy'},
  'wt_fresh':  {'nl': 'Zoetwater', 'en': 'Freshwater', 'de': 'Süßwasser', 'fr': 'Eau douce', 'es': 'Agua dulce', 'pl': 'Słodkowodny'},
  'wt_salt':   {'nl': 'Zoutwater', 'en': 'Saltwater', 'de': 'Salzwasser', 'fr': 'Eau de mer', 'es': 'Agua salada', 'pl': 'Słonowodny'},
  'wt_brackish': {'nl': 'Brak water', 'en': 'Brackish', 'de': 'Brackwasser', 'fr': 'Eau saumâtre', 'es': 'Agua salobre', 'pl': 'Woda słonawa'},
  'wt_both':   {'nl': 'Zoet & zout', 'en': 'Fresh & salt', 'de': 'Süß- & Salzwasser', 'fr': 'Douce & mer', 'es': 'Dulce y salada', 'pl': 'Słodko- i słonowodny'},
};

String _slLoc(BuildContext c) => Provider.of<I18n>(c, listen: false).locale;

/// Label voor het feiten-blad in de huidige taal.
String sui(BuildContext c, String key) {
  final m = kSpeciesUi[key];
  return m?[_slLoc(c)] ?? m?['en'] ?? key;
}

/// Gelokaliseerd label voor het watertype (fresh/salt/brackish/both).
String waterTypeLabel(BuildContext c, String? wt) {
  if (wt == null || wt.isEmpty) return '';
  final m = kSpeciesUi['wt_$wt'];
  return m?[_slLoc(c)] ?? m?['en'] ?? wt;
}

/// Gelokaliseerde vissoort-naam in de huidige app-taal (val terug op NL).
String speciesName(BuildContext c, Map s) {
  final loc = Provider.of<I18n>(c, listen: false).locale;
  final v = s['name_$loc'];
  if (v is String && v.trim().isNotEmpty) return v;
  return (s['name_nl'] ?? s['name'] ?? '').toString();
}

/// Gelokaliseerde beschrijving (description_<taal>, val terug op NL).
String speciesDescription(BuildContext c, Map s) {
  final loc = Provider.of<I18n>(c, listen: false).locale;
  if (loc != 'nl') {
    final v = s['description_$loc'];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return (s['description'] ?? '').toString();
}
