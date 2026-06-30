import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Self-contained labels voor de visstijlen-feature (NL/EN/DE/FR/ES/PL).
/// Bewust los van de centrale vertaalbestanden zodat de live app niet wordt
/// geraakt; later eventueel te verhuizen naar translations_app.dart.
/// Uitbreidbaar met extra talen (gewoon de taalcode toevoegen).

const Map<String, Map<String, String>> kDisciplineNames = {
  'carp':     {'nl': 'Karper', 'en': 'Carp', 'de': 'Karpfen', 'fr': 'Carpe', 'es': 'Carpa', 'pl': 'Karp'},
  'coarse':   {'nl': 'Witvis', 'en': 'Coarse', 'de': 'Friedfisch', 'fr': 'Poisson blanc', 'es': 'Pesca de blancos', 'pl': 'Ryby białe'},
  'feeder':   {'nl': 'Feeder', 'en': 'Feeder', 'de': 'Feeder', 'fr': 'Feeder', 'es': 'Feeder', 'pl': 'Feeder'},
  'predator': {'nl': 'Roofvis', 'en': 'Predator', 'de': 'Raubfisch', 'fr': 'Carnassier', 'es': 'Depredadores', 'pl': 'Drapieżniki'},
  'street':   {'nl': 'Streetfishing', 'en': 'Street fishing', 'de': 'Streetfishing', 'fr': 'Street fishing', 'es': 'Street fishing', 'pl': 'Streetfishing'},
  'catfish':  {'nl': 'Meerval', 'en': 'Catfish', 'de': 'Wels', 'fr': 'Silure', 'es': 'Siluro', 'pl': 'Sum'},
  'fly':      {'nl': 'Vliegvissen', 'en': 'Fly fishing', 'de': 'Fliegenfischen', 'fr': 'Pêche à la mouche', 'es': 'Pesca con mosca', 'pl': 'Wędkarstwo muchowe'},
  'trout':    {'nl': 'Forel', 'en': 'Trout', 'de': 'Forelle', 'fr': 'Truite', 'es': 'Trucha', 'pl': 'Pstrąg'},
  'sea':      {'nl': 'Zeevissen', 'en': 'Sea fishing', 'de': 'Meeresangeln', 'fr': 'Pêche en mer', 'es': 'Pesca en el mar', 'pl': 'Wędkarstwo morskie'},
};

const Map<String, Map<String, String>> kDisciplineUi = {
  'title':    {'nl': 'Visstijlen', 'en': 'Fishing styles', 'de': 'Angelarten', 'fr': 'Styles de pêche', 'es': 'Estilos de pesca', 'pl': 'Style wędkarskie'},
  'choose':   {'nl': 'Kies je visstijlen', 'en': 'Choose your fishing styles', 'de': 'Wähle deine Angelarten', 'fr': 'Choisis tes styles de pêche', 'es': 'Elige tus estilos de pesca', 'pl': 'Wybierz swoje style wędkarskie'},
  'hint':     {'nl': 'Meerdere mogelijk — elke stijl krijgt een eigen dashboard.', 'en': 'Pick several — each style gets its own dashboard.', 'de': 'Mehrere möglich — jede Art bekommt ein eigenes Dashboard.', 'fr': 'Plusieurs possibles — chaque style a son tableau de bord.', 'es': 'Varios posibles — cada estilo tiene su propio panel.', 'pl': 'Możesz wybrać kilka — każdy styl ma własny panel.'},
  'save':     {'nl': 'Opslaan', 'en': 'Save', 'de': 'Speichern', 'fr': 'Enregistrer', 'es': 'Guardar', 'pl': 'Zapisz'},
  'saved':    {'nl': 'Visstijlen opgeslagen', 'en': 'Fishing styles saved', 'de': 'Angelarten gespeichert', 'fr': 'Styles enregistrés', 'es': 'Estilos guardados', 'pl': 'Style zapisane'},
  'empty':    {'nl': 'Kies eerst je visstijlen om je dashboards te zien.', 'en': 'Choose your styles to see your dashboards.', 'de': 'Wähle deine Angelarten, um deine Dashboards zu sehen.', 'fr': 'Choisis tes styles pour voir tes tableaux de bord.', 'es': 'Elige tus estilos para ver tus paneles.', 'pl': 'Wybierz style, aby zobaczyć swoje panele.'},
  'edit':     {'nl': 'Stijlen wijzigen', 'en': 'Edit styles', 'de': 'Arten ändern', 'fr': 'Modifier les styles', 'es': 'Editar estilos', 'pl': 'Zmień style'},
  'catches':  {'nl': 'vangsten', 'en': 'catches', 'de': 'Fänge', 'fr': 'prises', 'es': 'capturas', 'pl': 'połowy'},
  'biggest':  {'nl': 'Grootste', 'en': 'Biggest', 'de': 'Größte', 'fr': 'Plus gros', 'es': 'Mayor', 'pl': 'Największa'},
  'topbait':  {'nl': 'Top-aas', 'en': 'Top bait', 'de': 'Top-Köder', 'fr': 'Meilleur appât', 'es': 'Mejor cebo', 'pl': 'Najlepsza przynęta'},
  'toptech':  {'nl': 'Top-techniek', 'en': 'Top technique', 'de': 'Top-Technik', 'fr': 'Meilleure technique', 'es': 'Mejor técnica', 'pl': 'Najlepsza technika'},
  'species':  {'nl': 'Doelsoorten', 'en': 'Target species', 'de': 'Zielfische', 'fr': 'Espèces cibles', 'es': 'Especies objetivo', 'pl': 'Gatunki docelowe'},
  'nocatch':  {'nl': 'Nog geen vangsten in deze stijl', 'en': 'No catches yet in this style', 'de': 'Noch keine Fänge in dieser Art', 'fr': 'Pas encore de prises dans ce style', 'es': 'Aún no hay capturas en este estilo', 'pl': 'Brak połowów w tym stylu'},
  'tip':      {'nl': 'Tip', 'en': 'Tip', 'de': 'Tipp', 'fr': 'Astuce', 'es': 'Consejo', 'pl': 'Wskazówka'},
  'err':      {'nl': 'Er ging iets mis', 'en': 'Something went wrong', 'de': 'Etwas ist schiefgelaufen', 'fr': 'Une erreur est survenue', 'es': 'Algo salió mal', 'pl': 'Coś poszło nie tak'},
  'retry':    {'nl': 'Opnieuw', 'en': 'Retry', 'de': 'Erneut', 'fr': 'Réessayer', 'es': 'Reintentar', 'pl': 'Ponów'},
};

String _loc(BuildContext c) => Provider.of<I18n>(c, listen: false).locale;

/// Naam van een visstijl in de huidige taal (val terug op EN, dan key).
String discName(BuildContext c, String key) {
  final m = kDisciplineNames[key];
  return m?[_loc(c)] ?? m?['en'] ?? key;
}

/// UI-string voor de disciplines-schermen in de huidige taal.
String dui(BuildContext c, String key) {
  final m = kDisciplineUi[key];
  return m?[_loc(c)] ?? m?['en'] ?? key;
}
