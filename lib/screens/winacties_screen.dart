import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/rondleiding.dart';

/// Winacties van partners (winkels/verenigingen): bekijken en meedoen.
///
/// Dit scherm toont UITSLUITEND wat de API teruggeeft (GET /giveaways, GET /giveaways/{id}).
/// Voorwaarden, looptijd, aantal winnaars en kansen worden nooit door de app ingevuld of
/// samengevat: het gaat over echte prijzen, dus een verzonnen regel is hier een fout.

/// Tekst in de taal van het lid; inline maps zodat de gedeelde vertaalbestanden ongemoeid blijven.
String _t(BuildContext c, Map<String, String> m) {
  final l = c.read<I18n>().locale;
  return m[l] ?? m['en'] ?? m['nl'] ?? '';
}

const _tTitel = {'nl': 'Winacties', 'en': 'Giveaways', 'de': 'Gewinnspiele', 'fr': 'Jeux-concours', 'es': 'Sorteos', 'pl': 'Konkursy'};
const _tOpnieuw = {'nl': 'Kon de winacties niet laden. Tik om het opnieuw te proberen.', 'en': 'Could not load the giveaways. Tap to try again.', 'de': 'Gewinnspiele konnten nicht geladen werden. Zum erneuten Versuch tippen.', 'fr': 'Impossible de charger les jeux-concours. Touchez pour réessayer.', 'es': 'No se pudieron cargar los sorteos. Toca para volver a intentarlo.', 'pl': 'Nie udało się wczytać konkursów. Dotknij, aby spróbować ponownie.'};
const _tLeegTitel = {'nl': 'Er loopt nu geen winactie', 'en': 'No giveaway is running right now', 'de': 'Derzeit läuft kein Gewinnspiel', 'fr': 'Aucun jeu-concours en cours', 'es': 'Ahora mismo no hay ningún sorteo', 'pl': 'Obecnie nie trwa żaden konkurs'};
const _tLeegTekst = {
  'nl': 'Zodra een winkel of vereniging een prijs verloot, zie je die hier. Kijk later nog eens.',
  'en': 'As soon as a shop or club raffles a prize, you will see it here. Check back later.',
  'de': 'Sobald ein Geschäft oder Verein einen Preis verlost, siehst du es hier. Schau später wieder vorbei.',
  'fr': 'Dès qu’un magasin ou une association met un lot en jeu, il apparaîtra ici. Revenez plus tard.',
  'es': 'En cuanto una tienda o un club sortee un premio, lo verás aquí. Vuelve más tarde.',
  'pl': 'Gdy sklep lub klub rozlosuje nagrodę, zobaczysz ją tutaj. Zajrzyj później.',
};
const _tStatusLoopt = {'nl': 'Loopt', 'en': 'Running', 'de': 'Läuft', 'fr': 'En cours', 'es': 'En curso', 'pl': 'Trwa'};
const _tStatusGesloten = {'nl': 'Gesloten', 'en': 'Closed', 'de': 'Geschlossen', 'fr': 'Terminé', 'es': 'Cerrado', 'pl': 'Zamknięty'};
const _tStatusGetrokken = {'nl': 'Getrokken', 'en': 'Drawn', 'de': 'Ausgelost', 'fr': 'Tiré au sort', 'es': 'Sorteado', 'pl': 'Rozlosowany'};
const _tStartOp = {'nl': 'Start {d}', 'en': 'Starts {d}', 'de': 'Startet {d}', 'fr': 'Débute le {d}', 'es': 'Empieza el {d}', 'pl': 'Start {d}'};
const _tLooptTot = {'nl': 'Loopt tot {d}', 'en': 'Runs until {d}', 'de': 'Läuft bis {d}', 'fr': 'Jusqu’au {d}', 'es': 'Hasta el {d}', 'pl': 'Trwa do {d}'};
const _tGetrokkenOp = {'nl': 'Getrokken op {d}', 'en': 'Drawn on {d}', 'de': 'Ausgelost am {d}', 'fr': 'Tiré au sort le {d}', 'es': 'Sorteado el {d}', 'pl': 'Rozlosowano {d}'};
const _tJeDoetMee = {'nl': 'Je doet mee', 'en': 'You are entered', 'de': 'Du machst mit', 'fr': 'Vous participez', 'es': 'Estás participando', 'pl': 'Bierzesz udział'};
const _tDeelnemers = {'nl': '{n} deelnemers', 'en': '{n} entries', 'de': '{n} Teilnehmer', 'fr': '{n} participants', 'es': '{n} participantes', 'pl': 'Uczestnicy: {n}'};
const _tPrijs = {'nl': 'Prijs', 'en': 'Prize', 'de': 'Preis', 'fr': 'Lot', 'es': 'Premio', 'pl': 'Nagroda'};
const _tWaarde = {'nl': 'Waarde', 'en': 'Value', 'de': 'Wert', 'fr': 'Valeur', 'es': 'Valor', 'pl': 'Wartość'};
const _tVoorwaarden = {'nl': 'Voorwaarden van de organisator', 'en': 'Terms from the organiser', 'de': 'Bedingungen des Veranstalters', 'fr': 'Conditions de l’organisateur', 'es': 'Condiciones del organizador', 'pl': 'Warunki organizatora'};
const _tAantalWinnaars = {'nl': 'Aantal winnaars', 'en': 'Number of winners', 'de': 'Anzahl Gewinner', 'fr': 'Nombre de gagnants', 'es': 'Número de ganadores', 'pl': 'Liczba zwycięzców'};
const _tWinnaars = {'nl': 'Winnaars', 'en': 'Winners', 'de': 'Gewinner', 'fr': 'Gagnants', 'es': 'Ganadores', 'pl': 'Zwycięzcy'};
const _tAlleen18 = {'nl': 'Alleen 18+', 'en': '18+ only', 'de': 'Nur ab 18', 'fr': '18 ans et plus', 'es': 'Solo mayores de 18', 'pl': 'Tylko 18+'};
const _tAangebodenDoor = {'nl': 'Aangeboden door', 'en': 'Offered by', 'de': 'Angeboten von', 'fr': 'Proposé par', 'es': 'Ofrecido por', 'pl': 'Oferuje'};
const _tMeedoen = {'nl': 'Meedoen', 'en': 'Enter', 'de': 'Mitmachen', 'fr': 'Participer', 'es': 'Participar', 'pl': 'Weź udział'};
const _tUitschrijven = {'nl': 'Niet meer meedoen', 'en': 'Withdraw entry', 'de': 'Nicht mehr mitmachen', 'fr': 'Retirer ma participation', 'es': 'Retirar mi participación', 'pl': 'Wycofaj udział'};
const _tVraagMeedoenTitel = {'nl': 'Meedoen aan deze winactie?', 'en': 'Enter this giveaway?', 'de': 'An diesem Gewinnspiel teilnehmen?', 'fr': 'Participer à ce jeu-concours ?', 'es': '¿Participar en este sorteo?', 'pl': 'Wziąć udział w tym konkursie?'};
const _tVraagMeedoenTekst = {
  'nl': 'Je schrijft je in als deelnemer. Lees eerst de voorwaarden van de organisator. Zolang de actie loopt kun je je weer uitschrijven.',
  'en': 'You will be registered as an entrant. Please read the organiser’s terms first. You can withdraw as long as the giveaway is running.',
  'de': 'Du wirst als Teilnehmer eingetragen. Lies zuerst die Bedingungen des Veranstalters. Solange das Gewinnspiel läuft, kannst du wieder austreten.',
  'fr': 'Vous serez inscrit comme participant. Lisez d’abord les conditions de l’organisateur. Tant que le jeu-concours est en cours, vous pouvez vous retirer.',
  'es': 'Te inscribirás como participante. Lee primero las condiciones del organizador. Mientras el sorteo esté en curso puedes retirarte.',
  'pl': 'Zostaniesz zapisany jako uczestnik. Najpierw przeczytaj warunki organizatora. Dopóki konkurs trwa, możesz wycofać udział.',
};
const _tVraagUitTitel = {'nl': 'Niet meer meedoen?', 'en': 'Withdraw your entry?', 'de': 'Teilnahme zurückziehen?', 'fr': 'Retirer votre participation ?', 'es': '¿Retirar tu participación?', 'pl': 'Wycofać udział?'};
const _tVraagUitTekst = {
  'nl': 'Je deelname wordt ingetrokken. Zolang de actie loopt kun je je later opnieuw inschrijven.',
  'en': 'Your entry will be removed. You can enter again while the giveaway is running.',
  'de': 'Deine Teilnahme wird entfernt. Solange das Gewinnspiel läuft, kannst du erneut teilnehmen.',
  'fr': 'Votre participation sera retirée. Tant que le jeu-concours est en cours, vous pouvez participer à nouveau.',
  'es': 'Se retirará tu participación. Mientras el sorteo esté en curso puedes volver a participar.',
  'pl': 'Twój udział zostanie wycofany. Dopóki konkurs trwa, możesz zapisać się ponownie.',
};
const _tAnnuleren = {'nl': 'Annuleren', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar', 'pl': 'Anuluj'};
const _tJaMeedoen = {'nl': 'Ja, meedoen', 'en': 'Yes, enter', 'de': 'Ja, mitmachen', 'fr': 'Oui, participer', 'es': 'Sí, participar', 'pl': 'Tak, biorę udział'};
const _tJaUitschrijven = {'nl': 'Ja, uitschrijven', 'en': 'Yes, withdraw', 'de': 'Ja, zurückziehen', 'fr': 'Oui, retirer', 'es': 'Sí, retirar', 'pl': 'Tak, wycofaj'};
const _tGeluktMee = {'nl': 'Je doet mee aan deze winactie.', 'en': 'You are entered in this giveaway.', 'de': 'Du machst bei diesem Gewinnspiel mit.', 'fr': 'Vous participez à ce jeu-concours.', 'es': 'Estás participando en este sorteo.', 'pl': 'Bierzesz udział w tym konkursie.'};
const _tGeluktUit = {'nl': 'Je doet niet meer mee.', 'en': 'Your entry has been withdrawn.', 'de': 'Du machst nicht mehr mit.', 'fr': 'Votre participation a été retirée.', 'es': 'Ya no participas.', 'pl': 'Nie bierzesz już udziału.'};
const _tFout = {'nl': 'Er ging iets mis', 'en': 'Something went wrong', 'de': 'Etwas ist schiefgelaufen', 'fr': 'Une erreur est survenue', 'es': 'Algo ha salido mal', 'pl': 'Coś poszło nie tak'};
const _tNogDagen = {'nl': 'Nog {n} dagen', 'en': '{n} days left', 'de': 'Noch {n} Tage', 'fr': 'Encore {n} jours', 'es': 'Quedan {n} días', 'pl': 'Pozostało {n} dni'};
const _tNogUren = {'nl': 'Nog {n} uur', 'en': '{n} hours left', 'de': 'Noch {n} Stunden', 'fr': 'Encore {n} heures', 'es': 'Quedan {n} horas', 'pl': 'Pozostało {n} godz.'};
const _tNogMinuten = {'nl': 'Nog {n} minuten', 'en': '{n} minutes left', 'de': 'Noch {n} Minuten', 'fr': 'Encore {n} minutes', 'es': 'Quedan {n} minutos', 'pl': 'Pozostało {n} min'};

/// Datum in de schrijfwijze van de taal van het lid (alleen cijfers: nooit een maandnaam verzinnen).
String _datum(BuildContext c, dynamic iso, {bool metTijd = true}) {
  final d = iso == null ? null : DateTime.tryParse('$iso')?.toLocal();
  if (d == null) return '';
  String tw(int v) => v.toString().padLeft(2, '0');
  final dag = tw(d.day), maand = tw(d.month), jaar = '${d.year}';
  final taal = c.read<I18n>().locale;
  final datum = taal == 'en'
      ? '$jaar-$maand-$dag'
      : (taal == 'de' || taal == 'pl')
          ? '$dag.$maand.$jaar'
          : taal == 'nl'
              ? '$dag-$maand-$jaar'
              : '$dag/$maand/$jaar';
  return metTijd ? '$datum ${tw(d.hour)}:${tw(d.minute)}' : datum;
}

/// Resterende looptijd, berekend uit ends_at van de server. Null = niet (meer) lopend.
String? _resterend(BuildContext c, dynamic eindIso) {
  final eind = eindIso == null ? null : DateTime.tryParse('$eindIso')?.toLocal();
  if (eind == null) return null;
  final over = eind.difference(DateTime.now());
  if (over.isNegative) return null;
  if (over.inDays >= 1) return _t(c, _tNogDagen).replaceAll('{n}', '${over.inDays}');
  if (over.inHours >= 1) return _t(c, _tNogUren).replaceAll('{n}', '${over.inHours}');
  return _t(c, _tNogMinuten).replaceAll('{n}', '${over.inMinutes < 1 ? 1 : over.inMinutes}');
}

String _statusTekst(BuildContext c, Map w) {
  if (w['status'] == 'drawn') return _t(c, _tStatusGetrokken);
  if (w['is_open'] == true) return _t(c, _tStatusLoopt);
  return _t(c, _tStatusGesloten);
}

Color _statusKleur(Map w) {
  if (w['status'] == 'drawn') return AppColors.navy2;
  if (w['is_open'] == true) return AppColors.teal;
  return Colors.black45;
}

/// Lijst met lopende (en recent getrokken) winacties.
class WinactiesScreen extends StatefulWidget {
  const WinactiesScreen({super.key});
  @override
  State<WinactiesScreen> createState() => _WinactiesScreenState();
}

class _WinactiesScreenState extends State<WinactiesScreen> {
  List<dynamic>? _winacties;
  bool _fout = false;

  @override
  void initState() {
    super.initState();
    _laad();
  }

  Future<void> _laad() async {
    if (mounted) setState(() { _fout = false; });
    try {
      final r = await Api.get('/giveaways');
      if (!mounted) return;
      setState(() => _winacties = r is List ? r : ((r is Map ? r['data'] : null) ?? []) as List<dynamic>);
    } catch (_) {
      if (mounted) setState(() { _fout = true; _winacties = null; });
    }
  }

  Future<void> _open(Map winactie) async {
    final gewijzigd = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => WinactieDetailScreen(winactieId: (winactie['id'] as num).toInt(), beginwaarde: winactie)),
    );
    // Deelname gewijzigd in het detailscherm → lijst opnieuw ophalen zodat "Je doet mee" klopt.
    if (gewijzigd == true) await _laad();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<I18n>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(_t(context, _tTitel))),
      body: TourAnker(
        id: 'winacties-lijst',
        child: _fout
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextButton(onPressed: _laad, child: Text(_t(context, _tOpnieuw), textAlign: TextAlign.center)),
                ),
              )
            : _winacties == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _laad,
                    child: _winacties!.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: const [SizedBox(height: 40), _LeegKader()],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom),
                            itemCount: _winacties!.length,
                            itemBuilder: (_, i) {
                              final w = _winacties![i] as Map;
                              return _WinactieKaart(winactie: w, onTap: () => _open(w));
                            },
                          ),
                  ),
      ),
    );
  }
}

/// Rustig kader als er niets loopt — geen leeg wit scherm.
class _LeegKader extends StatelessWidget {
  const _LeegKader();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(Icons.card_giftcard_outlined, size: 44, color: AppColors.teal.withValues(alpha: 0.7)),
        const SizedBox(height: 12),
        Text(_t(context, _tLeegTitel), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
        const SizedBox(height: 8),
        Text(_t(context, _tLeegTekst), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.4)),
      ]),
    );
  }
}

class _WinactieKaart extends StatelessWidget {
  const _WinactieKaart({required this.winactie, required this.onTap});
  final Map winactie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = winactie;
    final partner = w['partner'] as Map?;
    final afbeelding = (w['image'] ?? '').toString();
    final meedoen = w['entered'] == true;
    final resterend = w['is_open'] == true ? _resterend(context, w['ends_at']) : null;
    final deelnemers = (w['entries_count'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (afbeelding.isNotEmpty)
            Image.network(afbeelding, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _Vlaggetje(tekst: _statusTekst(context, w), kleur: _statusKleur(w)),
                if (meedoen) ...[const SizedBox(width: 6), _Vlaggetje(tekst: _t(context, _tJeDoetMee), kleur: AppColors.accent)],
                if (w['adults_only'] == true) ...[const SizedBox(width: 6), _Vlaggetje(tekst: _t(context, _tAlleen18), kleur: AppColors.danger)],
              ]),
              const SizedBox(height: 8),
              Text('${w['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
              if ((w['prize'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('${w['prize']}', style: const TextStyle(color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (partner != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  if ((partner['logo'] ?? '').toString().isNotEmpty)
                    ClipOval(child: Image.network('${partner['logo']}', width: 20, height: 20, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))
                  else
                    Icon(Icons.storefront_outlined, size: 18, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${partner['name'] ?? ''}', style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.schedule, size: 15, color: Colors.black45),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    w['status'] == 'drawn' && w['drawn_at'] != null
                        ? _t(context, _tGetrokkenOp).replaceAll('{d}', _datum(context, w['drawn_at'], metTijd: false))
                        : (w['ends_at'] != null ? _t(context, _tLooptTot).replaceAll('{d}', _datum(context, w['ends_at'])) : ''),
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (resterend != null) Text(resterend, style: const TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              if (deelnemers > 0) ...[
                const SizedBox(height: 4),
                Text(_t(context, _tDeelnemers).replaceAll('{n}', '$deelnemers'), style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Vlaggetje extends StatelessWidget {
  const _Vlaggetje({required this.tekst, required this.kleur});
  final String tekst;
  final Color kleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: kleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(tekst, style: TextStyle(color: kleur, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

/// Detail van één winactie: prijs, organisator, looptijd, voorwaarden en meedoen/uitschrijven.
class WinactieDetailScreen extends StatefulWidget {
  const WinactieDetailScreen({super.key, required this.winactieId, this.beginwaarde});
  final int winactieId;

  /// Wat de lijst al wist, zodat het scherm meteen iets toont terwijl het detail laadt.
  final Map? beginwaarde;

  @override
  State<WinactieDetailScreen> createState() => _WinactieDetailScreenState();
}

class _WinactieDetailScreenState extends State<WinactieDetailScreen> {
  Map? _winactie;
  bool _fout = false, _bezig = false, _gewijzigd = false;

  @override
  void initState() {
    super.initState();
    _winactie = widget.beginwaarde;
    _laad();
  }

  Future<void> _laad() async {
    if (mounted) setState(() => _fout = false);
    try {
      final r = await Api.get('/giveaways/${widget.winactieId}');
      if (!mounted) return;
      final d = r is Map ? (r['data'] ?? r) : null;
      setState(() { if (d is Map) _winactie = d; });
    } catch (e) {
      if (!mounted) return;
      if (_winactie == null) {
        setState(() => _fout = true);
      } else {
        _melding(e is ApiException ? e.message : _t(context, _tFout));
      }
    }
  }

  void _melding(String tekst) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tekst)));
  }

  Future<bool> _bevestig(Map<String, String> titel, Map<String, String> tekst, Map<String, String> knop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(_t(ctx, titel)),
        content: Text(_t(ctx, tekst)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(ctx, _tAnnuleren))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_t(ctx, knop))),
        ],
      ),
    );
    return ok == true;
  }

  /// Meedoen is een handeling met gevolgen: eerst bevestigen, daarna melden wat de server zegt.
  Future<void> _meedoen() async {
    if (!await _bevestig(_tVraagMeedoenTitel, _tVraagMeedoenTekst, _tJaMeedoen)) return;
    await _verstuur(() => Api.post('/giveaways/${widget.winactieId}/enter'), _tGeluktMee);
  }

  Future<void> _uitschrijven() async {
    if (!await _bevestig(_tVraagUitTitel, _tVraagUitTekst, _tJaUitschrijven)) return;
    await _verstuur(() => Api.delete('/giveaways/${widget.winactieId}/enter'), _tGeluktUit);
  }

  Future<void> _verstuur(Future<dynamic> Function() oproep, Map<String, String> standaardMelding) async {
    setState(() => _bezig = true);
    try {
      final r = await oproep();
      if (!mounted) return;
      final d = r is Map ? (r['data'] ?? r) : null;
      setState(() { if (d is Map) _winactie = d; _gewijzigd = true; });
      final serverTekst = r is Map && r['message'] != null ? '${r['message']}'.trim() : '';
      _melding(serverTekst.isNotEmpty ? serverTekst : _t(context, standaardMelding));
    } catch (e) {
      if (!mounted) return;
      _melding(e is ApiException ? e.message : _t(context, _tFout));
      await _laad(); // status kan intussen veranderd zijn (actie gesloten, al meegedaan)
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<I18n>();
    final w = _winactie;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (gedaan, _) {
        if (!gedaan) Navigator.pop(context, _gewijzigd);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: Text(w != null ? '${w['title'] ?? _t(context, _tTitel)}' : _t(context, _tTitel))),
        body: w == null
            ? (_fout
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: TextButton(onPressed: _laad, child: Text(_t(context, _tOpnieuw), textAlign: TextAlign.center))))
                : const Center(child: CircularProgressIndicator()))
            : _inhoud(w),
      ),
    );
  }

  Widget _inhoud(Map w) {
    final partner = w['partner'] as Map?;
    final afbeelding = (w['image'] ?? '').toString();
    final voorwaarden = (w['terms'] ?? '').toString().trim();
    final omschrijving = (w['description'] ?? '').toString().trim();
    final prijs = (w['prize'] ?? '').toString().trim();
    final waarde = (w['prize_value'] ?? '').toString().trim();
    final winnaars = (w['winners'] is List ? w['winners'] as List : const []);
    final aantalWinnaars = (w['winners_count'] as num?)?.toInt() ?? 0;
    final deelnemers = (w['entries_count'] as num?)?.toInt() ?? 0;
    final meedoen = w['entered'] == true;
    final open = w['is_open'] == true;
    final start = DateTime.tryParse('${w['starts_at']}')?.toLocal();
    final nogNietGestart = start != null && start.isAfter(DateTime.now());
    final resterend = open ? _resterend(context, w['ends_at']) : null;

    return RefreshIndicator(
      onRefresh: _laad,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (afbeelding.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(afbeelding, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          if (afbeelding.isNotEmpty) const SizedBox(height: 14),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _Vlaggetje(tekst: _statusTekst(context, w), kleur: _statusKleur(w)),
            if (meedoen) _Vlaggetje(tekst: _t(context, _tJeDoetMee), kleur: AppColors.accent),
            if (w['adults_only'] == true) _Vlaggetje(tekst: _t(context, _tAlleen18), kleur: AppColors.danger),
          ]),
          const SizedBox(height: 10),
          Text('${w['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.navy)),
          if (partner != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              if ((partner['logo'] ?? '').toString().isNotEmpty)
                ClipOval(child: Image.network('${partner['logo']}', width: 34, height: 34, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))
              else
                CircleAvatar(radius: 17, backgroundColor: AppColors.teal.withValues(alpha: 0.12), child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.teal)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_t(context, _tAangebodenDoor), style: const TextStyle(color: Colors.black45, fontSize: 11)),
                  Text('${partner['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ],
          if (omschrijving.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(omschrijving, style: const TextStyle(fontSize: 15, height: 1.45)),
          ],
          if (prijs.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Blok(titel: _t(context, _tPrijs), child: Text(prijs, style: const TextStyle(fontSize: 15, height: 1.4))),
          ],
          if (waarde.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Regel(label: _t(context, _tWaarde), waarde: waarde),
          ],
          const SizedBox(height: 10),
          if (nogNietGestart) _Regel(label: '', waarde: _t(context, _tStartOp).replaceAll('{d}', _datum(context, w['starts_at']))),
          if (w['ends_at'] != null) _Regel(label: '', waarde: _t(context, _tLooptTot).replaceAll('{d}', _datum(context, w['ends_at']))),
          if (resterend != null) Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(resterend, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
          ),
          if (w['drawn_at'] != null) _Regel(label: '', waarde: _t(context, _tGetrokkenOp).replaceAll('{d}', _datum(context, w['drawn_at']))),
          if (aantalWinnaars > 0) _Regel(label: _t(context, _tAantalWinnaars), waarde: '$aantalWinnaars'),
          if (deelnemers > 0) _Regel(label: '', waarde: _t(context, _tDeelnemers).replaceAll('{n}', '$deelnemers')),
          if (winnaars.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Blok(
              titel: _t(context, _tWinnaars),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final n in winnaars) Padding(padding: const EdgeInsets.only(bottom: 2), child: Text('• $n', style: const TextStyle(fontSize: 15)))],
              ),
            ),
          ],
          // Voorwaarden komen letterlijk van de organisator: volledig tonen, nooit afkappen of samenvatten.
          if (voorwaarden.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Blok(titel: _t(context, _tVoorwaarden), child: Text(voorwaarden, style: const TextStyle(fontSize: 14, height: 1.5))),
          ],
          const SizedBox(height: 22),
          if (open)
            SizedBox(
              width: double.infinity,
              child: meedoen
                  ? OutlinedButton.icon(
                      onPressed: _bezig ? null : _uitschrijven,
                      icon: const Icon(Icons.close),
                      label: Text(_t(context, _tUitschrijven)),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 14)),
                    )
                  : FilledButton.icon(
                      onPressed: _bezig ? null : _meedoen,
                      icon: const Icon(Icons.card_giftcard),
                      label: Text(_t(context, _tMeedoen)),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
            ),
          if (_bezig) const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        ],
      ),
    );
  }
}

class _Blok extends StatelessWidget {
  const _Blok({required this.titel, required this.child});
  final String titel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}

class _Regel extends StatelessWidget {
  const _Regel({required this.label, required this.waarde});
  final String label;
  final String waarde;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label.isEmpty ? waarde : '$label: $waarde',
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
      ]),
    );
  }
}
