import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Labels voor de drukte-meter / check-in op de kaart (6-talig).
const Map<String, Map<String, String>> kMapUi = {
  'checkin_here': {'nl': 'Ik vis hier', 'en': "I'm fishing here", 'de': 'Ich angle hier', 'fr': 'Je pêche ici', 'es': 'Estoy pescando aquí', 'pl': 'Łowię tutaj'},
  'leave':        {'nl': 'Ik ben weg', 'en': "I've left", 'de': 'Ich bin weg', 'fr': 'Je suis parti', 'es': 'Ya no estoy', 'pl': 'Już mnie nie ma'},
  'busy':         {'nl': 'Drukte', 'en': 'Busyness', 'de': 'Andrang', 'fr': 'Affluence', 'es': 'Afluencia', 'pl': 'Ruch'},
  'busy_low':     {'nl': 'Rustig', 'en': 'Quiet', 'de': 'Ruhig', 'fr': 'Calme', 'es': 'Tranquilo', 'pl': 'Spokojnie'},
  'busy_medium':  {'nl': 'Gemiddeld', 'en': 'Moderate', 'de': 'Mittel', 'fr': 'Modéré', 'es': 'Moderado', 'pl': 'Średnio'},
  'busy_high':    {'nl': 'Druk', 'en': 'Busy', 'de': 'Voll', 'fr': 'Fréquenté', 'es': 'Concurrido', 'pl': 'Tłoczno'},
  'anglers_here': {'nl': 'vissers actief in dit gebied', 'en': 'anglers active in this area', 'de': 'Angler in diesem Gebiet', 'fr': 'pêcheurs dans cette zone', 'es': 'pescadores en esta zona', 'pl': 'wędkarzy w tym obszarze'},
  'anonymous':    {'nl': 'Anoniem — namen en exacte stekken worden nooit getoond.', 'en': 'Anonymous — names and exact spots are never shown.', 'de': 'Anonym — Namen und genaue Stellen werden nie angezeigt.', 'fr': 'Anonyme — noms et spots exacts jamais affichés.', 'es': 'Anónimo — nunca se muestran nombres ni puntos exactos.', 'pl': 'Anonimowo — nazwy i dokładne stanowiska nigdy nie są pokazywane.'},
  'checked_in':   {'nl': 'Je staat ingecheckt (verloopt vanzelf).', 'en': "You're checked in (expires automatically).", 'de': 'Du bist eingecheckt (läuft automatisch ab).', 'fr': 'Tu es enregistré (expire tout seul).', 'es': 'Has hecho check-in (caduca solo).', 'pl': 'Jesteś zameldowany (wygasa samo).'},
  'auto_on_label':  {'nl': 'Auto: aan', 'en': 'Auto: on', 'de': 'Auto: an', 'fr': 'Auto : activé', 'es': 'Auto: sí', 'pl': 'Auto: wł.'},
  'auto_off_label': {'nl': 'Auto: uit', 'en': 'Auto: off', 'de': 'Auto: aus', 'fr': 'Auto : désactivé', 'es': 'Auto: no', 'pl': 'Auto: wył.'},
  'auto_on_msg':  {'nl': 'Auto-inchecken aan — je telt anoniem mee in de drukte zodra je bij water bent.', 'en': 'Auto check-in on — you anonymously count toward busyness when at water.', 'de': 'Auto-Check-in an — du zählst anonym zum Andrang, sobald du am Wasser bist.', 'fr': 'Check-in auto activé — tu comptes anonymement dans l’affluence près de l’eau.', 'es': 'Check-in automático activado — cuentas de forma anónima cuando estás en el agua.', 'pl': 'Auto-meldowanie wł. — anonimowo liczysz się do ruchu, gdy jesteś przy wodzie.'},
  'auto_off_msg': {'nl': 'Auto-inchecken uit — je verschijnt niet meer in de drukte.', 'en': 'Auto check-in off — you no longer appear in busyness.', 'de': 'Auto-Check-in aus — du erscheinst nicht mehr im Andrang.', 'fr': 'Check-in auto désactivé — tu n’apparais plus dans l’affluence.', 'es': 'Check-in automático desactivado — ya no apareces en la afluencia.', 'pl': 'Auto-meldowanie wył. — nie pojawiasz się już w ruchu.'},
};

String _mLoc(BuildContext c) => Provider.of<I18n>(c, listen: false).locale;
String mui(BuildContext c, String key) { final m = kMapUi[key]; return m?[_mLoc(c)] ?? m?['en'] ?? key; }
String busyLevelLabel(BuildContext c, String level) => mui(c, 'busy_$level');
