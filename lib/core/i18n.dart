import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'translations.dart';
import 'translations_app.dart';
import 'api.dart';

/// Meertaligheid (NL/EN/DE/FR) — zelfde sleutels/vertalingen als de website.
class I18n extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const Map<String, String> languages = {'nl': 'Nederlands', 'en': 'English', 'de': 'Deutsch', 'fr': 'Français', 'es': 'Español', 'pl': 'Polski'};

  String _locale = 'nl';
  String get locale => _locale;
  Locale get flutterLocale => Locale(_locale);

  // Globale referentie zodat AuthState na login de gebruikerstaal kan toepassen.
  static I18n? instance;
  I18n() { instance = this; }

  Future<void> load() async {
    try {
      // Eenmalige migratie: oude 'yf_locale' (bevatte ook auto-waarden) wissen, zodat een
      // vastgelopen taal weer plaatsmaakt voor de apparaat-taal. Voortaan bewaren we ONDER
      // 'yf_lang' alleen een BEWUSTE keuze.
      final legacy = await _storage.read(key: 'yf_locale');
      if (legacy != null) { try { await _storage.delete(key: 'yf_locale'); } catch (_) {} }

      final s = await _storage.read(key: 'yf_lang'); // alleen een bewuste keuze
      if (s != null && kTranslations.containsKey(s)) {
        _locale = s;
      } else {
        // Geen bewuste keuze: volg de apparaat-taal (indien ondersteund), anders Engels.
        final dev = ui.PlatformDispatcher.instance.locale.languageCode;
        _locale = kTranslations.containsKey(dev) ? dev : 'en';
      }
    } catch (_) {}
    Api.lang = _locale;
    notifyListeners();
  }

  Future<void> setLocale(String l) async {
    if (!kTranslations.containsKey(l) || l == _locale) return;
    _locale = l;
    Api.lang = l;
    try { await _storage.write(key: 'yf_lang', value: l); } catch (_) {}
    notifyListeners();
    // Bewuste keuze: op de server VERGRENDELEN, zodat 't na herinstall/op een ander toestel blijft.
    if (Api.token != null) {
      try { await Api.put('/profile/settings', {'language': l, 'language_locked': true}); } catch (_) {}
    }
  }

  // Na inloggen: server-voorkeur toepassen. Bewust gekozen (locked) wint van de apparaat-taal.
  // Niet vergrendeld = "auto": we houden de apparaat-taal aan en synchroniseren die naar de
  // server (voor mail-/melding-taal), zonder de gebruiker op een oude default vast te zetten.
  Future<void> applyServerLocale(String? serverLang, {bool locked = false}) async {
    if (locked && serverLang != null && kTranslations.containsKey(serverLang)) {
      if (serverLang != _locale) {
        _locale = serverLang;
        Api.lang = serverLang;
        try { await _storage.write(key: 'yf_lang', value: serverLang); } catch (_) {}
        notifyListeners();
      }
      return;
    }
    if (!locked && Api.token != null && serverLang != _locale) {
      try { await Api.put('/profile/settings', {'language': _locale, 'language_locked': false}); } catch (_) {}
    }
  }

  /// Vertaal een sleutel; app-extra eerst, dan web-woordenboek, dan NL, dan de sleutel zelf.
  String t(String key) =>
      kAppScreens[_locale]?[key] ?? kAppExtra[_locale]?[key] ?? kTranslations[_locale]?[key] ??
      kAppScreens['en']?[key] ?? kAppExtra['en']?[key] ?? kTranslations['en']?[key] ??
      kAppScreens['nl']?[key] ?? kAppExtra['nl']?[key] ?? kTranslations['nl']?[key] ?? key;
}

/// App-specifieke vertalingen die niet in het web-woordenboek staan (NL/EN/DE/FR).
const Map<String, Map<String, String>> kAppExtra = {
  'nl': {
    "login.remember": "Ingelogd blijven",
    "login.forgot": "Wachtwoord vergeten?",
    "forgot.title": "Wachtwoord vergeten",
    "forgot.intro": "Vul je e-mailadres in, dan sturen we je een link om een nieuw wachtwoord in te stellen.",
    "forgot.submit": "Stuur resetlink",
    "forgot.done": "Als er een account bestaat met dit e-mailadres, hebben we je een e-mail gestuurd met een link om je wachtwoord opnieuw in te stellen. Check ook je spam-map.",
    "forgot.back": "Terug naar inloggen",
    "forgot.error": "Er ging iets mis. Probeer het later opnieuw.",

    'nav.bite': 'Bijtkans', 'nav.clubs': 'Clubs', 'nav.profile': 'Profiel',
    'nav.map': 'Kaart',
    'nav.menu': 'Menu', 'stats.catches': 'Vangsten', 'stats.this_month': 'Deze maand', 'stats.species': 'Soorten', 'stats.biggest': 'Grootste',
    'sec.social': 'Sociaal', 'sec.fishing': 'Mijn visserij', 'sec.tools': 'Hulpmiddelen', 'sec.account': 'Account',
    'verify.banner': 'Bevestig je e-mailadres om te kunnen posten en reageren.', 'verify.resend': 'Opnieuw versturen', 'verify.sent': 'Bevestigingsmail verstuurd — check je inbox (en spam).',
    'p.notifications': 'Meldingen', 'p.messages': 'Berichten', 'p.friends': 'Vrienden', 'p.leaderboard': 'Ranglijst',
    'p.albums': 'Albums', 'p.tackle': 'Uitrusting', 'p.tournaments': 'Toernooien', 'p.map': 'Viskaart',
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
    "login.remember": "Stay logged in",
    "login.forgot": "Forgot password?",
    "forgot.title": "Forgot password",
    "forgot.intro": "Enter your email and we’ll send you a link to set a new password.",
    "forgot.submit": "Send reset link",
    "forgot.done": "If an account exists with this email address, we’ve sent you an email with a link to reset your password. Check your spam folder too.",
    "forgot.back": "Back to login",
    "forgot.error": "Something went wrong. Please try again later.",

    'nav.bite': 'Bite forecast', 'nav.clubs': 'Clubs', 'nav.profile': 'Profile',
    'nav.map': 'Map',
    'nav.menu': 'Menu', 'stats.catches': 'Catches', 'stats.this_month': 'This month', 'stats.species': 'Species', 'stats.biggest': 'Biggest',
    'sec.social': 'Social', 'sec.fishing': 'My fishing', 'sec.tools': 'Tools', 'sec.account': 'Account',
    'verify.banner': 'Confirm your email address to post and comment.', 'verify.resend': 'Resend', 'verify.sent': 'Confirmation email sent — check your inbox (and spam).',
    'p.notifications': 'Notifications', 'p.messages': 'Messages', 'p.friends': 'Friends', 'p.leaderboard': 'Leaderboard',
    'p.albums': 'Albums', 'p.tackle': 'Gear', 'p.tournaments': 'Tournaments', 'p.map': 'Viskaart',
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
    "login.remember": "Angemeldet bleiben",
    "login.forgot": "Passwort vergessen?",
    "forgot.title": "Passwort vergessen",
    "forgot.intro": "Gib deine E-Mail-Adresse ein, dann senden wir dir einen Link, um ein neues Passwort festzulegen.",
    "forgot.submit": "Reset-Link senden",
    "forgot.done": "Falls ein Konto mit dieser E-Mail-Adresse existiert, haben wir dir eine E-Mail mit einem Link zum Zurücksetzen deines Passworts geschickt. Sieh auch im Spam-Ordner nach.",
    "forgot.back": "Zurück zur Anmeldung",
    "forgot.error": "Etwas ist schiefgelaufen. Bitte versuche es später erneut.",

    'nav.bite': 'Beißprognose', 'nav.clubs': 'Vereine', 'nav.profile': 'Profil',
    'nav.map': 'Karte',
    'nav.menu': 'Menü', 'stats.catches': 'Fänge', 'stats.this_month': 'Diesen Monat', 'stats.species': 'Arten', 'stats.biggest': 'Größter',
    'sec.social': 'Sozial', 'sec.fishing': 'Mein Angeln', 'sec.tools': 'Werkzeuge', 'sec.account': 'Konto',
    'verify.banner': 'Bestätige deine E-Mail-Adresse, um posten und kommentieren zu können.', 'verify.resend': 'Erneut senden', 'verify.sent': 'Bestätigungs-E-Mail gesendet – sieh in deinem Posteingang (und Spam) nach.',
    'p.notifications': 'Mitteilungen', 'p.messages': 'Nachrichten', 'p.friends': 'Freunde', 'p.leaderboard': 'Rangliste',
    'p.albums': 'Alben', 'p.tackle': 'Ausrüstung', 'p.tournaments': 'Turniere', 'p.map': 'Viskaart',
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
    "login.remember": "Rester connecté",
    "login.forgot": "Mot de passe oublié ?",
    "forgot.title": "Mot de passe oublié",
    "forgot.intro": "Saisissez votre e-mail et nous vous enverrons un lien pour définir un nouveau mot de passe.",
    "forgot.submit": "Envoyer le lien",
    "forgot.done": "Si un compte existe avec cette adresse e-mail, nous vous avons envoyé un e-mail avec un lien pour réinitialiser votre mot de passe. Vérifiez aussi vos spams.",
    "forgot.back": "Retour à la connexion",
    "forgot.error": "Une erreur s’est produite. Réessayez plus tard.",

    'nav.bite': 'Prévision de touche', 'nav.clubs': 'Clubs', 'nav.profile': 'Profil',
    'nav.map': 'Carte',
    'nav.menu': 'Menu', 'stats.catches': 'Prises', 'stats.this_month': 'Ce mois', 'stats.species': 'Espèces', 'stats.biggest': 'Le plus gros',
    'sec.social': 'Social', 'sec.fishing': 'Ma pêche', 'sec.tools': 'Outils', 'sec.account': 'Compte',
    'verify.banner': 'Confirme ton adresse e-mail pour publier et commenter.', 'verify.resend': 'Renvoyer', 'verify.sent': 'E-mail de confirmation envoyé — vérifie ta boîte (et les spams).',
    'p.notifications': 'Notifications', 'p.messages': 'Messages', 'p.friends': 'Amis', 'p.leaderboard': 'Classement',
    'p.albums': 'Albums', 'p.tackle': 'Équipement', 'p.tournaments': 'Tournois', 'p.map': 'Viskaart',
    'p.identify': 'Identifier le poisson', 'p.species': 'Guide des espèces', 'p.weather': 'Météo de pêche', 'p.docs': 'Documents de pêche',
    'p.settings': 'Paramètres', 'p.moderation': 'Modération', 'p.edit': 'Modifier le profil',
    'common.save': 'Enregistrer', 'common.add': 'Ajouter', 'common.delete': 'Supprimer', 'common.report': 'Signaler',
    'catch.new': 'Nouvelle prise', 'catch.species': 'Espèce', 'catch.weight': 'Poids (kg)', 'catch.length': 'Longueur (cm)',
    'catch.bait': 'Appât / technique', 'catch.visibility': 'Visibilité', 'catch.addloc': 'Ajouter la localisation',
    'catch.save': 'Enregistrer la prise', 'catch.identify': 'Identifier (IA)', 'catch.story': 'Créer une histoire IA',
    'vis.public': 'Public', 'vis.friends': 'Amis seulement', 'vis.private': 'Privé',
    'set.notif': 'Notifications par e-mail', 'online.now': 'en ligne', 'feed.translate': 'Traduire', 'feed.show_original': 'Voir l\'original', 'set.logout': 'Se déconnecter', 'set.delete': 'Supprimer le compte',
  },
  'es': {
    "login.remember": "Mantener sesión iniciada",
    "login.forgot": "¿Olvidaste tu contraseña?",
    "forgot.title": "Olvidaste tu contraseña",
    "forgot.intro": "Introduce tu correo y te enviaremos un enlace para establecer una nueva contraseña.",
    "forgot.submit": "Enviar enlace",
    "forgot.done": "Si existe una cuenta con este correo, te hemos enviado un email con un enlace para restablecer tu contraseña. Revisa también tu carpeta de spam.",
    "forgot.back": "Volver a iniciar sesión",
    "forgot.error": "Algo salió mal. Inténtalo de nuevo más tarde.",

    "nav.bite": "Previsión de picadas",
    "nav.clubs": "Clubes",
    "nav.profile": "Perfil",
    "nav.map": "Mapa",
    "nav.menu": "Menú",
    "stats.catches": "Capturas",
    "stats.this_month": "Este mes",
    "stats.species": "Especies",
    "stats.biggest": "El mayor",
    "sec.social": "Social",
    "sec.fishing": "Mi pesca",
    "sec.tools": "Herramientas",
    "sec.account": "Cuenta",
    "verify.banner": "Confirma tu correo para publicar y comentar.",
    "verify.resend": "Reenviar",
    "verify.sent": "Correo de confirmación enviado — revisa tu bandeja (y spam).",
    "p.notifications": "Notificaciones",
    "p.messages": "Mensajes",
    "p.friends": "Amigos",
    "p.leaderboard": "Clasificación",
    "p.albums": "Álbumes",
    "p.tackle": "Equipo",
    "p.tournaments": "Torneos",
    "p.map": "Mapa de spots",
    "p.identify": "Identificar pez",
    "p.species": "Guía de especies",
    "p.weather": "Tiempo de pesca",
    "p.docs": "Documentos de pesca",
    "p.settings": "Ajustes",
    "p.moderation": "Moderación",
    "p.edit": "Editar perfil",
    "common.save": "Guardar",
    "common.add": "Añadir",
    "common.delete": "Eliminar",
    "common.report": "Denunciar",
    "catch.new": "Nueva captura",
    "catch.species": "Especie",
    "catch.weight": "Peso (kg)",
    "catch.length": "Longitud (cm)",
    "catch.bait": "Cebo / técnica",
    "catch.visibility": "Visibilidad",
    "catch.addloc": "Añadir ubicación",
    "catch.save": "Guardar captura",
    "catch.identify": "Identificar pez (IA)",
    "catch.story": "Crear historia de captura con IA",
    "vis.public": "Pública",
    "vis.friends": "Solo amigos",
    "vis.private": "Privada",
    "set.notif": "Notificaciones por correo",
    "online.now": "en línea",
    "feed.translate": "Traducir",
    "feed.show_original": "Ver original",
    "set.logout": "Cerrar sesión",
    "set.delete": "Eliminar cuenta",
  },
  'pl': {
    "login.remember": "Pozostań zalogowany",
    "login.forgot": "Nie pamiętasz hasła?",
    "forgot.title": "Nie pamiętasz hasła",
    "forgot.intro": "Podaj swój adres e-mail, a wyślemy Ci link do ustawienia nowego hasła.",
    "forgot.submit": "Wyślij link",
    "forgot.done": "Jeśli istnieje konto z tym adresem e-mail, wysłaliśmy wiadomość z linkiem do zresetowania hasła. Sprawdź także folder spam.",
    "forgot.back": "Powrót do logowania",
    "forgot.error": "Coś poszło nie tak. Spróbuj ponownie później.",

    "nav.bite": "Prognoza brań",
    "nav.clubs": "Kluby",
    "nav.profile": "Profil",
    "nav.map": "Mapa",
    "nav.menu": "Menu",
    "stats.catches": "Połowy",
    "stats.this_month": "W tym miesiącu",
    "stats.species": "Gatunki",
    "stats.biggest": "Największy",
    "sec.social": "Społeczność",
    "sec.fishing": "Moje wędkarstwo",
    "sec.tools": "Narzędzia",
    "sec.account": "Konto",
    "verify.banner": "Potwierdź swój adres e-mail, aby publikować i komentować.",
    "verify.resend": "Wyślij ponownie",
    "verify.sent": "Wysłano e-mail potwierdzający — sprawdź skrzynkę (i spam).",
    "p.notifications": "Powiadomienia",
    "p.messages": "Wiadomości",
    "p.friends": "Znajomi",
    "p.leaderboard": "Ranking",
    "p.albums": "Albumy",
    "p.tackle": "Sprzęt",
    "p.tournaments": "Turnieje",
    "p.map": "Mapa łowisk",
    "p.identify": "Rozpoznaj rybę",
    "p.species": "Atlas gatunków",
    "p.weather": "Pogoda wędkarska",
    "p.docs": "Dokumenty wędkarskie",
    "p.settings": "Ustawienia",
    "p.moderation": "Moderacja",
    "p.edit": "Edytuj profil",
    "common.save": "Zapisz",
    "common.add": "Dodaj",
    "common.delete": "Usuń",
    "common.report": "Zgłoś",
    "catch.new": "Nowy połów",
    "catch.species": "Gatunek",
    "catch.weight": "Waga (kg)",
    "catch.length": "Długość (cm)",
    "catch.bait": "Przynęta / technika",
    "catch.visibility": "Widoczność",
    "catch.addloc": "Dodaj lokalizację",
    "catch.save": "Zapisz połów",
    "catch.identify": "Rozpoznaj rybę (AI)",
    "catch.story": "Stwórz opis połowu (AI)",
    "vis.public": "Publiczny",
    "vis.friends": "Tylko znajomi",
    "vis.private": "Prywatny",
    "set.notif": "Powiadomienia e-mail",
    "online.now": "online",
    "feed.translate": "Przetłumacz",
    "feed.show_original": "Pokaż oryginał",
    "set.logout": "Wyloguj się",
    "set.delete": "Usuń konto",
  },
};

/// Korte toegang in widgets: context.tr('feed.title')
extension I18nContext on BuildContext {
  String tr(String key) => Provider.of<I18n>(this, listen: true).t(key);
}
