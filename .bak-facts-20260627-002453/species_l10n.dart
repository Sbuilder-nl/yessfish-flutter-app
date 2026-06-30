import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Gelokaliseerde vissoort-naam in de huidige app-taal (val terug op NL).
String speciesName(BuildContext c, Map s) {
  final loc = Provider.of<I18n>(c, listen: false).locale;
  final v = s['name_$loc'];
  if (v is String && v.trim().isNotEmpty) return v;
  return (s['name_nl'] ?? s['name'] ?? '').toString();
}

/// Gelokaliseerde beschrijving (description per taal, val terug op NL).
String speciesDescription(BuildContext c, Map s) {
  final loc = Provider.of<I18n>(c, listen: false).locale;
  if (loc != 'nl') {
    final v = s['description_$loc'];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return (s['description'] ?? '').toString();
}
