/// Huisregel en zelf-waarschuwing bij privéberichten.
///
/// Privéberichten mogen we niet meelezen: het communicatiegeheim (ePrivacy art. 5) beschermt ze,
/// en de DSA zondert onderlinge communicatie uit van de moderatieplicht. We doen dus twee dingen
/// die wél mogen: we zeggen eerlijk dat we niet meelezen en hoe je iets meldt, en we geven de
/// verzender een duwtje als zijn eigen bericht op verboden handel lijkt. Die controle draait op
/// het toestel zelf — de tekst gaat niet naar de server (21-09-2026).
library;

const _woorden = [
  'wiet', 'weed', 'hasj', 'hash', 'coke', 'cocaine', 'cocaïne', 'xtc', 'mdma', 'speed',
  'amfetamine', 'ketamine', 'lsd', 'heroine', 'heroïne', 'lachgas', 'nitrous',
  'vuurwapen', 'pistool', 'handgun', 'munitie', 'patronen', 'stroomstootwapen', 'taser',
];
const _handel = ['te koop', 'for sale', 'zu verkaufen', 'na sprzedaż', 'gram', 'pillen', 'deal'];

/// Alleen de combinatie telt: een visser praat over gram lood en over een deal bij de winkel.
bool lijktOpHandel(String tekst) {
  final t = ' ${tekst.toLowerCase()} ';
  final middel = _woorden.any((w) => t.contains(w));
  final handel = _handel.any((w) => t.contains(w));
  return middel && handel;
}

const privacyRegel = {
  'nl': 'Privé gesprek. Wij lezen niet mee. Klopt er iets niet? Houd het bericht ingedrukt en meld het — een moderator ziet dan precies dat bericht.',
  'en': 'Private conversation. We do not read along. Something wrong? Press and hold the message to report it — a moderator then sees exactly that message.',
  'de': 'Privates Gespräch. Wir lesen nicht mit. Stimmt etwas nicht? Nachricht gedrückt halten und melden — ein Moderator sieht dann genau diese Nachricht.',
  'fr': 'Conversation privée. Nous ne lisons pas. Un problème ? Appuie longuement sur le message pour le signaler — un modérateur verra exactement ce message.',
  'es': 'Conversación privada. No leemos tus mensajes. ¿Algo no va bien? Mantén pulsado el mensaje para denunciarlo: un moderador verá exactamente ese mensaje.',
  'pl': 'Rozmowa prywatna. Nie czytamy jej. Coś nie tak? Przytrzymaj wiadomość i zgłoś ją — moderator zobaczy dokładnie tę wiadomość.',
};

const waarschuwingTitel = {
  'nl': 'Even checken', 'en': 'One moment', 'de': 'Kurz prüfen',
  'fr': 'Un instant', 'es': 'Un momento', 'pl': 'Chwila',
};

const waarschuwingTekst = {
  'nl': 'Dit bericht lijkt op een aanbod dat hier niet mag. Handel in drugs, wapens of andere verboden zaken leidt tot verwijdering van je account. Wij lezen je berichten niet mee, maar wie jouw bericht ontvangt kan het melden.',
  'en': 'This message looks like an offer that is not allowed here. Trading drugs, weapons or other banned goods gets your account removed. We do not read your messages, but whoever receives it can report it.',
  'de': 'Diese Nachricht sieht nach einem Angebot aus, das hier nicht erlaubt ist. Handel mit Drogen, Waffen oder anderen verbotenen Dingen führt zur Löschung deines Kontos. Wir lesen deine Nachrichten nicht mit, aber der Empfänger kann sie melden.',
  'fr': 'Ce message ressemble à une offre interdite ici. Le commerce de drogues, d’armes ou d’autres produits interdits entraîne la suppression de ton compte. Nous ne lisons pas tes messages, mais le destinataire peut les signaler.',
  'es': 'Este mensaje parece una oferta que aquí no se permite. Comerciar con drogas, armas u otros artículos prohibidos supone la eliminación de tu cuenta. No leemos tus mensajes, pero quien lo reciba puede denunciarlo.',
  'pl': 'Ta wiadomość wygląda na ofertę, która jest tu zabroniona. Handel narkotykami, bronią lub innymi zakazanymi rzeczami kończy się usunięciem konta. Nie czytamy twoich wiadomości, ale odbiorca może je zgłosić.',
};

const waarschuwingDoor = {
  'nl': 'Toch versturen', 'en': 'Send anyway', 'de': 'Trotzdem senden',
  'fr': 'Envoyer quand même', 'es': 'Enviar igualmente', 'pl': 'Wyślij mimo to',
};

const waarschuwingTerug = {
  'nl': 'Aanpassen', 'en': 'Edit', 'de': 'Ändern',
  'fr': 'Modifier', 'es': 'Editar', 'pl': 'Popraw',
};

String br(Map<String, String> m, String taal) => m[taal] ?? m['en'] ?? m['nl']!;

/// Wie met een kind chat hoort te weten dat een ouder kan meelezen. Het kind zet die koppeling
/// zelf aan, maar de gesprekspartner weet dat niet — en denkt anders onder vier ogen te praten.
const toezichtRegel = {
  'nl': 'Dit account staat onder ouderlijk toezicht: een ouder kan dit gesprek lezen.',
  'en': 'This account is under parental supervision: a parent can read this conversation.',
  'de': 'Dieses Konto steht unter Elternaufsicht: Ein Elternteil kann dieses Gespräch lesen.',
  'fr': 'Ce compte est sous contrôle parental : un parent peut lire cette conversation.',
  'es': 'Esta cuenta está bajo control parental: un progenitor puede leer esta conversación.',
  'pl': 'To konto jest pod kontrolą rodzicielską: rodzic może czytać tę rozmowę.',
};

/// En het kind zelf hoort het ook te blijven zien, niet alleen op de dag dat het de koppelcode
/// aanmaakte.
const eigenToezichtRegel = {
  'nl': 'Je ouder kan je gesprekken lezen (ouderlijk toezicht staat aan).',
  'en': 'Your parent can read your conversations (parental supervision is on).',
  'de': 'Dein Elternteil kann deine Gespräche lesen (Elternaufsicht ist aktiv).',
  'fr': 'Ton parent peut lire tes conversations (le contrôle parental est actif).',
  'es': 'Tu madre o padre puede leer tus conversaciones (el control parental está activado).',
  'pl': 'Twój rodzic może czytać twoje rozmowy (kontrola rodzicielska jest włączona).',
};

/// Zelf je berichten beheren: bewaren, downloaden, weggooien.
const beheerBewaren = {'nl': 'Bewaren', 'en': 'Keep', 'de': 'Behalten', 'fr': 'Conserver', 'es': 'Conservar', 'pl': 'Zachowaj'};
const beheerBewaard = {'nl': 'Wordt bewaard', 'en': 'Kept', 'de': 'Wird behalten', 'fr': 'Conservé', 'es': 'Conservada', 'pl': 'Zachowana'};
const beheerWis = {'nl': 'Gesprek verwijderen', 'en': 'Delete conversation', 'de': 'Gespräch löschen', 'fr': 'Supprimer la conversation', 'es': 'Eliminar conversación', 'pl': 'Usuń rozmowę'};
const beheerWisVraag = {
  'nl': 'Dit gesprek uit jouw lijst verwijderen? Bij de ander blijft het staan.',
  'en': 'Remove this conversation from your list? It stays with the other person.',
  'de': 'Dieses Gespräch aus deiner Liste entfernen? Beim anderen bleibt es stehen.',
  'fr': 'Retirer cette conversation de ta liste ? Elle reste chez l’autre personne.',
  'es': '¿Quitar esta conversación de tu lista? A la otra persona le sigue apareciendo.',
  'pl': 'Usunąć tę rozmowę z twojej listy? U drugiej osoby zostanie.',
};
const beheerWisBericht = {
  'nl': 'Dit bericht verwijderen? Het verdwijnt ook bij de ander.',
  'en': 'Delete this message? It disappears for the other person too.',
  'de': 'Diese Nachricht löschen? Sie verschwindet auch beim anderen.',
  'fr': 'Supprimer ce message ? Il disparaît aussi chez l’autre.',
  'es': '¿Eliminar este mensaje? También desaparece para la otra persona.',
  'pl': 'Usunąć tę wiadomość? Zniknie także u drugiej osoby.',
};
const beheerUitleg = {
  'nl': 'Stille gesprekken ruimen we na verloop van tijd op. Zet Bewaren aan en dit gesprek blijft staan; je krijgt altijd eerst een melding.',
  'en': 'Quiet conversations get cleaned up after a while. Switch Keep on and this one stays; you always get a warning first.',
  'de': 'Stille Gespräche räumen wir nach einiger Zeit auf. Schalte Behalten ein und dieses bleibt; du wirst immer vorher gewarnt.',
  'fr': 'Les conversations silencieuses sont nettoyées au bout d’un temps. Active Conserver et celle-ci reste ; tu es toujours prévenu avant.',
  'es': 'Las conversaciones inactivas se limpian pasado un tiempo. Activa Conservar y esta se queda; siempre avisamos antes.',
  'pl': 'Ciche rozmowy po jakimś czasie sprzątamy. Włącz Zachowaj, a ta zostanie; zawsze najpierw ostrzegamy.',
};
const beheerVerwijderd = {'nl': 'Verwijderd', 'en': 'Deleted', 'de': 'Gelöscht', 'fr': 'Supprimé', 'es': 'Eliminado', 'pl': 'Usunięto'};
