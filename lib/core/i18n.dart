import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'translations.dart';
import 'translations_app.dart';

/// Meertaligheid (NL/EN/DE/FR) — zelfde sleutels/vertalingen als de website.
class I18n extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const Map<String, String> languages = {'nl': 'Nederlands', 'en': 'English', 'de': 'Deutsch', 'fr': 'Français'};

  String _locale = 'nl';
  String get locale => _locale;
  Locale get flutterLocale => Locale(_locale);

  Future<void> load() async {
    try {
      final s = await _storage.read(key: 'yf_locale');
      if (s != null && kTranslations.containsKey(s)) _locale = s;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLocale(String l) async {
    if (!kTranslations.containsKey(l) || l == _locale) return;
    _locale = l;
    try { await _storage.write(key: 'yf_locale', value: l); } catch (_) {}
    notifyListeners();
  }

  /// Vertaal een sleutel; app-extra eerst, dan web-woordenboek, dan NL, dan de sleutel zelf.
  String t(String key) =>
      kAppScreens[_locale]?[key] ?? kAppExtra[_locale]?[key] ?? kTranslations[_locale]?[key] ??
      kAppScreens['nl']?[key] ?? kAppExtra['nl']?[key] ?? kTranslations['nl']?[key] ?? key;
}

/// App-specifieke vertalingen die niet in het web-woordenboek staan (NL/EN/DE/FR).
const Map<String, Map<String, String>> kAppExtra = {
  'nl': {
    'nav.bite': 'Bijtkans', 'nav.clubs': 'Clubs', 'nav.profile': 'Profiel',
    'sec.social': 'Sociaal', 'sec.fishing': 'Mijn visserij', 'sec.tools': 'Hulpmiddelen', 'sec.account': 'Account',
    'p.notifications': 'Meldingen', 'p.messages': 'Berichten', 'p.friends': 'Vrienden', 'p.leaderboard': 'Ranglijst',
    'p.albums': 'Albums', 'p.tackle': 'Uitrusting', 'p.tournaments': 'Toernooien', 'p.map': 'Stekkenkaart',
    'p.identify': 'Vis herkennen', 'p.species': 'Soortengids', 'p.weather': 'Visweer', 'p.docs': 'Visdocumenten',
    'p.settings': 'Instellingen', 'p.moderation': 'Moderatie', 'p.edit': 'Profiel bewerken',
    'common.save': 'Opslaan', 'common.add': 'Toevoegen', 'common.delete': 'Verwijderen', 'common.report': 'Melden',
    'catch.new': 'Nieuwe vangst', 'catch.species': 'Vissoort', 'catch.weight': 'Gewicht (kg)', 'catch.length': 'Lengte (cm)',
    'catch.bait': 'Aas / techniek', 'catch.visibility': 'Zichtbaarheid', 'catch.addloc': 'Locatie toevoegen',
    'catch.save': 'Vangst opslaan', 'catch.identify': 'Herken vis (AI)', 'catch.story': 'AI-vangstverhaal maken',
    'vis.public': 'Openbaar', 'vis.friends': 'Alleen vrienden', 'vis.private': 'Privé',
    'set.notif': 'E-mailmeldingen', 'online.now': 'online', 'feed.translate': 'Vertalen', 'feed.show_original': 'Origineel tonen', 'set.logout': 'Uitloggen', 'set.delete': 'Account verwijderen',
  },
  'en': {
    'nav.bite': 'Bite forecast', 'nav.clubs': 'Clubs', 'nav.profile': 'Profile',
    'sec.social': 'Social', 'sec.fishing': 'My fishing', 'sec.tools': 'Tools', 'sec.account': 'Account',
    'p.notifications': 'Notifications', 'p.messages': 'Messages', 'p.friends': 'Friends', 'p.leaderboard': 'Leaderboard',
    'p.albums': 'Albums', 'p.tackle': 'Gear', 'p.tournaments': 'Tournaments', 'p.map': 'Spots map',
    'p.identify': 'Identify fish', 'p.species': 'Species guide', 'p.weather': 'Fishing weather', 'p.docs': 'Fishing documents',
    'p.settings': 'Settings', 'p.moderation': 'Moderation', 'p.edit': 'Edit profile',
    'common.save': 'Save', 'common.add': 'Add', 'common.delete': 'Delete', 'common.report': 'Report',
    'catch.new': 'New catch', 'catch.species': 'Species', 'catch.weight': 'Weight (kg)', 'catch.length': 'Length (cm)',
    'catch.bait': 'Bait / technique', 'catch.visibility': 'Visibility', 'catch.addloc': 'Add location',
    'catch.save': 'Save catch', 'catch.identify': 'Identify fish (AI)', 'catch.story': 'Create AI catch story',
    'vis.public': 'Public', 'vis.friends': 'Friends only', 'vis.private': 'Private',
    'set.notif': 'E-mail notifications', 'online.now': 'online', 'feed.translate': 'Translate', 'feed.show_original': 'Show original', 'set.logout': 'Log out', 'set.delete': 'Delete account',
  },
  'de': {
    'nav.bite': 'Beißprognose', 'nav.clubs': 'Vereine', 'nav.profile': 'Profil',
    'sec.social': 'Sozial', 'sec.fishing': 'Mein Angeln', 'sec.tools': 'Werkzeuge', 'sec.account': 'Konto',
    'p.notifications': 'Mitteilungen', 'p.messages': 'Nachrichten', 'p.friends': 'Freunde', 'p.leaderboard': 'Rangliste',
    'p.albums': 'Alben', 'p.tackle': 'Ausrüstung', 'p.tournaments': 'Turniere', 'p.map': 'Spot-Karte',
    'p.identify': 'Fisch erkennen', 'p.species': 'Artenführer', 'p.weather': 'Angelwetter', 'p.docs': 'Angeldokumente',
    'p.settings': 'Einstellungen', 'p.moderation': 'Moderation', 'p.edit': 'Profil bearbeiten',
    'common.save': 'Speichern', 'common.add': 'Hinzufügen', 'common.delete': 'Löschen', 'common.report': 'Melden',
    'catch.new': 'Neuer Fang', 'catch.species': 'Fischart', 'catch.weight': 'Gewicht (kg)', 'catch.length': 'Länge (cm)',
    'catch.bait': 'Köder / Technik', 'catch.visibility': 'Sichtbarkeit', 'catch.addloc': 'Standort hinzufügen',
    'catch.save': 'Fang speichern', 'catch.identify': 'Fisch erkennen (KI)', 'catch.story': 'KI-Fanggeschichte erstellen',
    'vis.public': 'Öffentlich', 'vis.friends': 'Nur Freunde', 'vis.private': 'Privat',
    'set.notif': 'E-Mail-Benachrichtigungen', 'online.now': 'online', 'feed.translate': 'Übersetzen', 'feed.show_original': 'Original anzeigen', 'set.logout': 'Abmelden', 'set.delete': 'Konto löschen',
  },
  'fr': {
    'nav.bite': 'Prévision de touche', 'nav.clubs': 'Clubs', 'nav.profile': 'Profil',
    'sec.social': 'Social', 'sec.fishing': 'Ma pêche', 'sec.tools': 'Outils', 'sec.account': 'Compte',
    'p.notifications': 'Notifications', 'p.messages': 'Messages', 'p.friends': 'Amis', 'p.leaderboard': 'Classement',
    'p.albums': 'Albums', 'p.tackle': 'Équipement', 'p.tournaments': 'Tournois', 'p.map': 'Carte des spots',
    'p.identify': 'Identifier le poisson', 'p.species': 'Guide des espèces', 'p.weather': 'Météo de pêche', 'p.docs': 'Documents de pêche',
    'p.settings': 'Paramètres', 'p.moderation': 'Modération', 'p.edit': 'Modifier le profil',
    'common.save': 'Enregistrer', 'common.add': 'Ajouter', 'common.delete': 'Supprimer', 'common.report': 'Signaler',
    'catch.new': 'Nouvelle prise', 'catch.species': 'Espèce', 'catch.weight': 'Poids (kg)', 'catch.length': 'Longueur (cm)',
    'catch.bait': 'Appât / technique', 'catch.visibility': 'Visibilité', 'catch.addloc': 'Ajouter la localisation',
    'catch.save': 'Enregistrer la prise', 'catch.identify': 'Identifier (IA)', 'catch.story': 'Créer une histoire IA',
    'vis.public': 'Public', 'vis.friends': 'Amis seulement', 'vis.private': 'Privé',
    'set.notif': 'Notifications par e-mail', 'online.now': 'en ligne', 'feed.translate': 'Traduire', 'feed.show_original': 'Voir l\'original', 'set.logout': 'Se déconnecter', 'set.delete': 'Supprimer le compte',
  },
};

/// Korte toegang in widgets: context.tr('feed.title')
extension I18nContext on BuildContext {
  String tr(String key) => Provider.of<I18n>(this, listen: true).t(key);
}
