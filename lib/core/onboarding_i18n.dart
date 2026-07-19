import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Self-contained teksten + landenlijst voor de verplichte onboarding-stap
/// (NL/EN/DE/FR/ES/PL). Bewust los van de centrale vertaalbestanden, net als
/// disciplines_i18n.dart, zodat de rest van de app niet wordt geraakt.

const Map<String, Map<String, String>> kOnbUi = {
  'title':          {'nl': 'Welkom bij YessFish!', 'en': 'Welcome to YessFish!', 'de': 'Willkommen bei YessFish!', 'fr': 'Bienvenue sur YessFish !', 'es': '¡Bienvenido a YessFish!', 'pl': 'Witaj w YessFish!'},
  'intro':          {'nl': 'Nog even je gegevens invullen, dan kun je los.', 'en': "Just a few details and you're ready to go.", 'de': 'Nur noch ein paar Angaben, dann kann es losgehen.', 'fr': "Encore quelques informations et c'est parti.", 'es': 'Solo unos datos y ya podrás empezar.', 'pl': 'Jeszcze kilka danych i możesz zaczynać.'},
  'birthday':       {'nl': 'Geboortedatum', 'en': 'Date of birth', 'de': 'Geburtsdatum', 'fr': 'Date de naissance', 'es': 'Fecha de nacimiento', 'pl': 'Data urodzenia'},
  'birthday_hint':  {'nl': 'Alleen om je account goed in te stellen (jonger dan 16 = veilige jeugdmodus).', 'en': 'Only to set up your account correctly (under 16 = safe youth mode).', 'de': 'Nur um dein Konto richtig einzurichten (unter 16 = sicherer Jugendmodus).', 'fr': "Uniquement pour bien configurer ton compte (moins de 16 ans = mode jeune sécurisé).", 'es': 'Solo para configurar bien tu cuenta (menores de 16 = modo juvenil seguro).', 'pl': 'Tylko do prawidłowej konfiguracji konta (poniżej 16 lat = bezpieczny tryb młodzieżowy).'},
  'pick_date':      {'nl': 'Kies datum', 'en': 'Choose date', 'de': 'Datum wählen', 'fr': 'Choisir la date', 'es': 'Elegir fecha', 'pl': 'Wybierz datę'},
  'country':        {'nl': 'Land', 'en': 'Country', 'de': 'Land', 'fr': 'Pays', 'es': 'País', 'pl': 'Kraj'},
  'select':         {'nl': 'Kies…', 'en': 'Choose…', 'de': 'Wählen…', 'fr': 'Choisir…', 'es': 'Elegir…', 'pl': 'Wybierz…'},
  'disciplines':    {'nl': 'Hoe vis jij graag?', 'en': 'How do you like to fish?', 'de': 'Wie angelst du am liebsten?', 'fr': 'Comment aimes-tu pêcher ?', 'es': '¿Cómo te gusta pescar?', 'pl': 'Jak lubisz łowić?'},
  'disc_hint':      {'nl': 'Kies één of meer visstijlen — je dashboard past zich hierop aan.', 'en': 'Pick one or more styles — your dashboard adapts to them.', 'de': 'Wähle eine oder mehrere Angelarten — dein Dashboard passt sich an.', 'fr': "Choisis une ou plusieurs techniques — ton tableau de bord s'adapte.", 'es': 'Elige uno o más estilos — tu panel se adapta a ellos.', 'pl': 'Wybierz jeden lub więcej stylów — Twój pulpit się dostosuje.'},
  'optional':       {'nl': 'Optioneel — meer over jou', 'en': 'Optional — more about you', 'de': 'Optional — mehr über dich', 'fr': 'Facultatif — en savoir plus sur toi', 'es': 'Opcional — más sobre ti', 'pl': 'Opcjonalnie — więcej o Tobie'},
  'experience':     {'nl': 'Ervaring', 'en': 'Experience', 'de': 'Erfahrung', 'fr': 'Expérience', 'es': 'Experiencia', 'pl': 'Doświadczenie'},
  'exp_beginner':   {'nl': 'Beginner', 'en': 'Beginner', 'de': 'Anfänger', 'fr': 'Débutant', 'es': 'Principiante', 'pl': 'Początkujący'},
  'exp_intermediate':{'nl': 'Gemiddeld', 'en': 'Intermediate', 'de': 'Fortgeschritten', 'fr': 'Intermédiaire', 'es': 'Intermedio', 'pl': 'Średnio zaawansowany'},
  'exp_advanced':   {'nl': 'Gevorderd', 'en': 'Advanced', 'de': 'Erfahren', 'fr': 'Confirmé', 'es': 'Avanzado', 'pl': 'Zaawansowany'},
  'exp_expert':     {'nl': 'Expert', 'en': 'Expert', 'de': 'Experte', 'fr': 'Expert', 'es': 'Experto', 'pl': 'Ekspert'},
  'gender':         {'nl': 'Geslacht', 'en': 'Gender', 'de': 'Geschlecht', 'fr': 'Genre', 'es': 'Género', 'pl': 'Płeć'},
  'g_male':         {'nl': 'Man', 'en': 'Male', 'de': 'Männlich', 'fr': 'Homme', 'es': 'Hombre', 'pl': 'Mężczyzna'},
  'g_female':       {'nl': 'Vrouw', 'en': 'Female', 'de': 'Weiblich', 'fr': 'Femme', 'es': 'Mujer', 'pl': 'Kobieta'},
  'g_other':        {'nl': 'Anders', 'en': 'Other', 'de': 'Divers', 'fr': 'Autre', 'es': 'Otro', 'pl': 'Inna'},
  'g_prefer':       {'nl': 'Zeg ik liever niet', 'en': 'Prefer not to say', 'de': 'Keine Angabe', 'fr': 'Je préfère ne pas dire', 'es': 'Prefiero no decirlo', 'pl': 'Wolę nie podawać'},
  'city':           {'nl': 'Woonplaats', 'en': 'Town / city', 'de': 'Wohnort', 'fr': 'Ville', 'es': 'Ciudad', 'pl': 'Miejscowość'},
  'save':           {'nl': 'Opslaan en beginnen', 'en': 'Save and start', 'de': 'Speichern und loslegen', 'fr': 'Enregistrer et commencer', 'es': 'Guardar y empezar', 'pl': 'Zapisz i zacznij'},
  'saving':         {'nl': 'Bezig met opslaan…', 'en': 'Saving…', 'de': 'Wird gespeichert…', 'fr': 'Enregistrement…', 'es': 'Guardando…', 'pl': 'Zapisywanie…'},
  'err_required':   {'nl': 'Vul je geboortedatum, land en minstens één visstijl in.', 'en': 'Please fill in your date of birth, country and at least one fishing style.', 'de': 'Bitte gib dein Geburtsdatum, Land und mindestens eine Angelart an.', 'fr': 'Renseigne ta date de naissance, ton pays et au moins une technique de pêche.', 'es': 'Indica tu fecha de nacimiento, país y al menos un estilo de pesca.', 'pl': 'Podaj datę urodzenia, kraj i co najmniej jeden styl wędkowania.'},
  'hr_accept':      {'nl': 'Ik ga akkoord met de huisregels', 'en': 'I agree to the community guidelines', 'de': 'Ich stimme den Verhaltensregeln zu', 'fr': 'J’accepte les règles de la communauté', 'es': 'Acepto las normas de la comunidad', 'pl': 'Akceptuję zasady społeczności'},
  'hr_link':        {'nl': 'lezen', 'en': 'read', 'de': 'lesen', 'fr': 'lire', 'es': 'leer', 'pl': 'przeczytaj'},
  'hr_required':    {'nl': 'Je moet akkoord gaan met de huisregels.', 'en': 'You must agree to the community guidelines.', 'de': 'Du musst den Verhaltensregeln zustimmen.', 'fr': 'Tu dois accepter les règles de la communauté.', 'es': 'Debes aceptar las normas de la comunidad.', 'pl': 'Musisz zaakceptować zasady społeczności.'},
  'err_generic':    {'nl': 'Er ging iets mis. Probeer het opnieuw.', 'en': 'Something went wrong. Please try again.', 'de': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.', 'fr': "Une erreur s'est produite. Réessaie.", 'es': 'Algo salió mal. Inténtalo de nuevo.', 'pl': 'Coś poszło nie tak. Spróbuj ponownie.'},
};

/// Landen (waarde = Engelse DB-naam waters.country), met vlag + 6-talige weergavenaam.
const List<Map<String, dynamic>> kOnbCountries = [
  {'v': 'Netherlands',    'flag': '\u{1F1F3}\u{1F1F1}', 'n': {'nl': 'Nederland', 'en': 'Netherlands', 'de': 'Niederlande', 'fr': 'Pays-Bas', 'es': 'Países Bajos', 'pl': 'Holandia'}},
  {'v': 'Belgium',        'flag': '\u{1F1E7}\u{1F1EA}', 'n': {'nl': 'België', 'en': 'Belgium', 'de': 'Belgien', 'fr': 'Belgique', 'es': 'Bélgica', 'pl': 'Belgia'}},
  {'v': 'Luxembourg',     'flag': '\u{1F1F1}\u{1F1FA}', 'n': {'nl': 'Luxemburg', 'en': 'Luxembourg', 'de': 'Luxemburg', 'fr': 'Luxembourg', 'es': 'Luxemburgo', 'pl': 'Luksemburg'}},
  {'v': 'Germany',        'flag': '\u{1F1E9}\u{1F1EA}', 'n': {'nl': 'Duitsland', 'en': 'Germany', 'de': 'Deutschland', 'fr': 'Allemagne', 'es': 'Alemania', 'pl': 'Niemcy'}},
  {'v': 'Austria',        'flag': '\u{1F1E6}\u{1F1F9}', 'n': {'nl': 'Oostenrijk', 'en': 'Austria', 'de': 'Österreich', 'fr': 'Autriche', 'es': 'Austria', 'pl': 'Austria'}},
  {'v': 'Switzerland',    'flag': '\u{1F1E8}\u{1F1ED}', 'n': {'nl': 'Zwitserland', 'en': 'Switzerland', 'de': 'Schweiz', 'fr': 'Suisse', 'es': 'Suiza', 'pl': 'Szwajcaria'}},
  {'v': 'France',         'flag': '\u{1F1EB}\u{1F1F7}', 'n': {'nl': 'Frankrijk', 'en': 'France', 'de': 'Frankreich', 'fr': 'France', 'es': 'Francia', 'pl': 'Francja'}},
  {'v': 'United Kingdom', 'flag': '\u{1F1EC}\u{1F1E7}', 'n': {'nl': 'Verenigd Koninkrijk', 'en': 'United Kingdom', 'de': 'Vereinigtes Königreich', 'fr': 'Royaume-Uni', 'es': 'Reino Unido', 'pl': 'Wielka Brytania'}},
  {'v': 'Ireland',        'flag': '\u{1F1EE}\u{1F1EA}', 'n': {'nl': 'Ierland', 'en': 'Ireland', 'de': 'Irland', 'fr': 'Irlande', 'es': 'Irlanda', 'pl': 'Irlandia'}},
  {'v': 'Spain',          'flag': '\u{1F1EA}\u{1F1F8}', 'n': {'nl': 'Spanje', 'en': 'Spain', 'de': 'Spanien', 'fr': 'Espagne', 'es': 'España', 'pl': 'Hiszpania'}},
  {'v': 'Poland',         'flag': '\u{1F1F5}\u{1F1F1}', 'n': {'nl': 'Polen', 'en': 'Poland', 'de': 'Polen', 'fr': 'Pologne', 'es': 'Polonia', 'pl': 'Polska'}},
];

/// Emoji per visstijl-key (parallel aan de web).
const Map<String, String> kDiscEmoji = {
  'carp': '\u{1F41F}', 'coarse': '\u{1F3A3}', 'feeder': '\u{1F3AF}', 'predator': '\u{1F988}',
  'street': '\u{1F3D9}', 'catfish': '\u{1F40B}', 'fly': '\u{1FAB0}', 'trout': '\u{1F3DE}', 'sea': '\u{1F30A}',
};

String _oloc(BuildContext c) => Provider.of<I18n>(c, listen: false).locale;

/// Onboarding-UI-string in de huidige taal (val terug op EN, dan key).
String oui(BuildContext c, String key) {
  final m = kOnbUi[key];
  return m?[_oloc(c)] ?? m?['en'] ?? key;
}

/// Landnaam in de huidige taal.
String onbCountryName(BuildContext c, Map<String, dynamic> country) {
  final n = country['n'] as Map<String, dynamic>;
  return (n[_oloc(c)] ?? n['en'] ?? country['v']) as String;
}
