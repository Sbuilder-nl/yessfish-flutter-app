import 'package:flutter/material.dart';
import '../core/api.dart';

/// Melden van een bericht, post, reactie of gebruiker.
///
/// Stond eerst alleen in het Nederlands, terwijl de app in zes talen draait — een Poolse visser
/// kreeg dus een Nederlands keuzemenu te zien op het moment dat hij juist hulp nodig had
/// (21-09-2026). Bij een melding legt de server een kopie van precies dát bericht vast, zodat
/// een moderator het kan beoordelen zonder het hele gesprek te lezen.
const _t = {
  'titel': {
    'nl': 'Melden', 'en': 'Report', 'de': 'Melden',
    'fr': 'Signaler', 'es': 'Denunciar', 'pl': 'Zgłoś',
  },
  'spam': {
    'nl': 'Spam', 'en': 'Spam', 'de': 'Spam', 'fr': 'Spam', 'es': 'Spam', 'pl': 'Spam',
  },
  'abuse': {
    'nl': 'Misbruik of intimidatie', 'en': 'Abuse or harassment', 'de': 'Missbrauch oder Belästigung',
    'fr': 'Abus ou harcèlement', 'es': 'Abuso o acoso', 'pl': 'Nadużycie lub nękanie',
  },
  'illegal': {
    'nl': 'Handel in verboden spullen', 'en': 'Trading banned goods', 'de': 'Handel mit verbotenen Waren',
    'fr': 'Commerce de produits interdits', 'es': 'Comercio de artículos prohibidos', 'pl': 'Handel zakazanymi rzeczami',
  },
  'inappropriate': {
    'nl': 'Ongepaste inhoud', 'en': 'Inappropriate content', 'de': 'Unangemessene Inhalte',
    'fr': 'Contenu inapproprié', 'es': 'Contenido inapropiado', 'pl': 'Nieodpowiednia treść',
  },
  'minor': {
    'nl': 'Gevaar voor een kind', 'en': 'Danger to a child', 'de': 'Gefahr für ein Kind',
    'fr': 'Danger pour un enfant', 'es': 'Peligro para un menor', 'pl': 'Zagrożenie dla dziecka',
  },
  'other': {
    'nl': 'Anders', 'en': 'Something else', 'de': 'Sonstiges',
    'fr': 'Autre chose', 'es': 'Otra cosa', 'pl': 'Coś innego',
  },
  'dank': {
    'nl': 'Bedankt, je melding is ontvangen en wordt bekeken.',
    'en': 'Thanks, your report has been received and will be reviewed.',
    'de': 'Danke, deine Meldung ist angekommen und wird geprüft.',
    'fr': 'Merci, ton signalement a bien été reçu et sera examiné.',
    'es': 'Gracias, hemos recibido tu denuncia y la revisaremos.',
    'pl': 'Dzięki, zgłoszenie dotarło i zostanie sprawdzone.',
  },
  'mislukt': {
    'nl': 'Melden lukte even niet. Probeer het zo nog eens.',
    'en': 'Reporting did not work just now. Please try again shortly.',
    'de': 'Das Melden hat gerade nicht geklappt. Bitte gleich noch einmal versuchen.',
    'fr': 'Le signalement n’a pas fonctionné. Réessaie dans un instant.',
    'es': 'La denuncia no se ha podido enviar. Inténtalo de nuevo en un momento.',
    'pl': 'Zgłoszenie się nie powiodło. Spróbuj jeszcze raz za chwilę.',
  },
};

String _tt(BuildContext c, String sleutel) {
  final taal = Localizations.localeOf(c).languageCode;
  final m = _t[sleutel]!;
  return m[taal] ?? m['en'] ?? m['nl']!;
}

Future<void> showReportSheet(BuildContext context, {required String type, required int targetId}) async {
  const redenen = ['spam', 'abuse', 'illegal', 'inappropriate', 'minor', 'other'];
  final reason = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Text(_tt(ctx, 'titel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      ...redenen.map((r) => ListTile(title: Text(_tt(ctx, r)), onTap: () => Navigator.pop(ctx, r))),
    ])),
  );
  if (reason == null) return;
  try {
    await Api.post('/reports', {'type': type, 'target_id': targetId, 'reason': reason});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tt(context, 'dank'))));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tt(context, 'mislukt'))));
    }
  }
}
