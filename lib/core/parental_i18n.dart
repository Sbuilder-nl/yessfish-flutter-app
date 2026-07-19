import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Self-contained teksten voor het ouderlijk-toezicht-scherm (NL/EN/DE/FR/ES/PL),
/// net als onboarding_i18n.dart. Grotendeels gespiegeld aan de web-/ouder-pagina.
const Map<String, Map<String, String>> kParUi = {
  'title': {'nl': 'Ouderlijk toezicht', 'en': 'Parental controls', 'de': 'Kindersicherung', 'fr': 'Contrôle parental', 'es': 'Control parental', 'pl': 'Kontrola rodzicielska'},
  'intro': {'nl': 'Beheer de veiligheid van gekoppelde jeugd-accounts. Jeugd-accounts ontvangen alleen berichten van vrienden.', 'en': 'Manage the safety of linked youth accounts. Youth accounts only receive messages from friends.', 'de': 'Verwalte die Sicherheit verknüpfter Jugendkonten. Jugendkonten erhalten nur Nachrichten von Freunden.', 'fr': 'Gérez la sécurité des comptes jeunes liés. Les comptes jeunes ne reçoivent des messages que de leurs amis.', 'es': 'Gestiona la seguridad de las cuentas juveniles vinculadas. Las cuentas juveniles solo reciben mensajes de amigos.', 'pl': 'Zarządzaj bezpieczeństwem powiązanych kont młodzieżowych. Konta młodzieżowe otrzymują wiadomości tylko od znajomych.'},
  'loading': {'nl': 'Laden…', 'en': 'Loading…', 'de': 'Laden…', 'fr': 'Chargement…', 'es': 'Cargando…', 'pl': 'Ładowanie…'},
  'none': {'nl': 'Nog geen kind gekoppeld. Vraag je kind om een koppelcode aan te maken en voer die hieronder in.', 'en': 'No child linked yet. Ask your child to create a link code and enter it below.', 'de': 'Noch kein Kind verknüpft. Bitte dein Kind, einen Kopplungscode zu erstellen, und gib ihn unten ein.', 'fr': "Aucun enfant lié. Demandez à votre enfant de créer un code de liaison et saisissez-le ci-dessous.", 'es': 'Aún no hay ningún niño vinculado. Pide a tu hijo que cree un código e introdúcelo abajo.', 'pl': 'Brak powiązanego dziecka. Poproś dziecko o utworzenie kodu i wpisz go poniżej.'},
  'youth': {'nl': 'Jeugd-account', 'en': 'Youth account', 'de': 'Jugendkonto', 'fr': 'Compte jeune', 'es': 'Cuenta juvenil', 'pl': 'Konto młodzieżowe'},
  'profile_to': {'nl': 'Profiel zichtbaar voor', 'en': 'Profile visible to', 'de': 'Profil sichtbar für', 'fr': 'Profil visible pour', 'es': 'Perfil visible para', 'pl': 'Profil widoczny dla'},
  'only_me': {'nl': 'Alleen ikzelf', 'en': 'Only me', 'de': 'Nur ich', 'fr': 'Moi seulement', 'es': 'Solo yo', 'pl': 'Tylko ja'},
  'friends': {'nl': 'Vrienden', 'en': 'Friends', 'de': 'Freunde', 'fr': 'Amis', 'es': 'Amigos', 'pl': 'Znajomi'},
  'everyone': {'nl': 'Iedereen', 'en': 'Everyone', 'de': 'Alle', 'fr': 'Tout le monde', 'es': 'Todos', 'pl': 'Wszyscy'},
  'loc': {'nl': 'Locatie openbaar tonen', 'en': 'Show location publicly', 'de': 'Standort öffentlich zeigen', 'fr': 'Afficher la position publiquement', 'es': 'Mostrar ubicación públicamente', 'pl': 'Pokazuj lokalizację publicznie'},
  'auto': {'nl': 'Automatisch inchecken (drukte)', 'en': 'Auto check-in (busyness)', 'de': 'Auto-Check-in (Andrang)', 'fr': 'Check-in auto (affluence)', 'es': 'Check-in automático (afluencia)', 'pl': 'Auto-meldowanie (ruch)'},
  'share': {'nl': 'Vangsten in de openbare feed', 'en': 'Catches in the public feed', 'de': 'Fänge im öffentlichen Feed', 'fr': 'Prises dans le fil public', 'es': 'Capturas en el feed público', 'pl': 'Połowy w publicznym feedzie'},
  'rec': {'nl': 'Aanbevolen voor jeugd: profiel op Vrienden, locatie & auto-inchecken uit, vangsten niet openbaar.', 'en': 'Recommended for youth: profile set to Friends, location & auto check-in off, catches not public.', 'de': 'Empfohlen für Jugendliche: Profil auf Freunde, Standort & Auto-Check-in aus, Fänge nicht öffentlich.', 'fr': 'Recommandé pour les jeunes : profil sur Amis, position & check-in auto désactivés, prises non publiques.', 'es': 'Recomendado para jóvenes: perfil en Amigos, ubicación y check-in automático desactivados, capturas no públicas.', 'pl': 'Zalecane dla młodzieży: profil na Znajomi, lokalizacja i auto-meldowanie wył., połowy niepubliczne.'},
  'view_msgs': {'nl': 'Berichten bekijken', 'en': 'View messages', 'de': 'Nachrichten ansehen', 'fr': 'Voir les messages', 'es': 'Ver mensajes', 'pl': 'Zobacz wiadomości'},
  'unlink': {'nl': 'Ontkoppelen', 'en': 'Unlink', 'de': 'Trennen', 'fr': 'Dissocier', 'es': 'Desvincular', 'pl': 'Odłącz'},
  'unlink_confirm': {'nl': 'Dit kind ontkoppelen?', 'en': 'Unlink this child?', 'de': 'Dieses Kind trennen?', 'fr': 'Dissocier cet enfant ?', 'es': '¿Desvincular a este niño?', 'pl': 'Odłączyć to dziecko?'},
  'link_title': {'nl': 'Kind koppelen', 'en': 'Link a child', 'de': 'Kind verknüpfen', 'fr': 'Lier un enfant', 'es': 'Vincular un niño', 'pl': 'Powiąż dziecko'},
  'link_intro': {'nl': 'Voer de koppelcode in die je kind heeft aangemaakt.', 'en': 'Enter the link code your child created.', 'de': 'Gib den Code ein, den dein Kind erstellt hat.', 'fr': "Saisissez le code de liaison créé par votre enfant.", 'es': 'Introduce el código que creó tu hijo.', 'pl': 'Wpisz kod utworzony przez dziecko.'},
  'code_ph': {'nl': 'Koppelcode', 'en': 'Link code', 'de': 'Kopplungscode', 'fr': 'Code de liaison', 'es': 'Código', 'pl': 'Kod'},
  'link_btn': {'nl': 'Koppelen', 'en': 'Link', 'de': 'Verknüpfen', 'fr': 'Lier', 'es': 'Vincular', 'pl': 'Powiąż'},
  'link_fail': {'nl': 'Koppelen mislukt.', 'en': 'Linking failed.', 'de': 'Verknüpfen fehlgeschlagen.', 'fr': 'Échec de la liaison.', 'es': 'No se pudo vincular.', 'pl': 'Nie udało się powiązać.'},
  'linked_with': {'nl': 'Gekoppeld met', 'en': 'Linked with', 'de': 'Verknüpft mit', 'fr': 'Lié à', 'es': 'Vinculado con', 'pl': 'Powiązano z'},
  'msgs_of': {'nl': 'Berichten van', 'en': 'Messages from', 'de': 'Nachrichten von', 'fr': 'Messages de', 'es': 'Mensajes de', 'pl': 'Wiadomości od'},
  'readonly': {'nl': 'Alleen-lezen — als ouder kun je de gesprekken van je kind inzien.', 'en': "Read-only — as a parent you can view your child's conversations.", 'de': 'Nur lesen — als Elternteil kannst du die Gespräche deines Kindes einsehen.', 'fr': "Lecture seule — en tant que parent, vous pouvez consulter les conversations de votre enfant.", 'es': 'Solo lectura — como padre puedes ver las conversaciones de tu hijo.', 'pl': 'Tylko do odczytu — jako rodzic możesz przeglądać rozmowy dziecka.'},
  'no_convs': {'nl': 'Geen gesprekken.', 'en': 'No conversations.', 'de': 'Keine Gespräche.', 'fr': 'Aucune conversation.', 'es': 'Sin conversaciones.', 'pl': 'Brak rozmów.'},
  'no_msgs': {'nl': 'Geen berichten.', 'en': 'No messages.', 'de': 'Keine Nachrichten.', 'fr': 'Aucun message.', 'es': 'Sin mensajes.', 'pl': 'Brak wiadomości.'},
  // Kind-sectie: eigen koppelcode maken
  'child_section': {'nl': 'Ben je zelf jonger dan 16?', 'en': 'Are you under 16 yourself?', 'de': 'Bist du selbst unter 16?', 'fr': 'As-tu moins de 16 ans ?', 'es': '¿Eres menor de 16 años?', 'pl': 'Masz mniej niż 16 lat?'},
  'child_intro': {'nl': 'Maak een koppelcode en geef die aan je ouder/verzorger zodat die kan meekijken voor je veiligheid.', 'en': 'Create a link code and give it to your parent/guardian so they can help keep you safe.', 'de': 'Erstelle einen Kopplungscode und gib ihn deinen Eltern, damit sie auf deine Sicherheit achten können.', 'fr': 'Crée un code de liaison et donne-le à ton parent pour qu\'il veille sur ta sécurité.', 'es': 'Crea un código y dáselo a tu padre/madre para que cuide tu seguridad.', 'pl': 'Utwórz kod i przekaż go rodzicowi, aby zadbał o Twoje bezpieczeństwo.'},
  'make_code': {'nl': 'Maak koppelcode', 'en': 'Create link code', 'de': 'Kopplungscode erstellen', 'fr': 'Créer un code', 'es': 'Crear código', 'pl': 'Utwórz kod'},
  'your_code': {'nl': 'Jouw koppelcode', 'en': 'Your link code', 'de': 'Dein Kopplungscode', 'fr': 'Ton code de liaison', 'es': 'Tu código', 'pl': 'Twój kod'},
  'code_valid': {'nl': '24 uur geldig', 'en': 'Valid for 24 hours', 'de': '24 Stunden gültig', 'fr': 'Valable 24 heures', 'es': 'Válido 24 horas', 'pl': 'Ważny 24 godziny'},
  'copied': {'nl': 'Gekopieerd', 'en': 'Copied', 'de': 'Kopiert', 'fr': 'Copié', 'es': 'Copiado', 'pl': 'Skopiowano'},
  'copy': {'nl': 'Kopiëren', 'en': 'Copy', 'de': 'Kopieren', 'fr': 'Copier', 'es': 'Copiar', 'pl': 'Kopiuj'},
  'cancel': {'nl': 'Annuleren', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar', 'pl': 'Anuluj'},
};

String _ploc(BuildContext c) => Provider.of<I18n>(c, listen: false).locale;

/// Ouderlijk-toezicht-string in de huidige taal (val terug op EN, dan key).
String pt(BuildContext c, String key) {
  final m = kParUi[key];
  return m?[_ploc(c)] ?? m?['en'] ?? key;
}
