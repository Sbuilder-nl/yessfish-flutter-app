import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/rondleiding.dart';

/// Wedstrijd (trui-actie): stand, ranglijst en het geheime woord uit video's/berichten.
/// Losse vertalingen in dit bestand — bewust niet in de gedeelde woordenboeken, want dit
/// scherm hoort bij één tijdelijke actie.
String _t(BuildContext c, Map<String, String> m) {
  final l = c.read<I18n>().locale;
  return m[l] ?? m['en'] ?? m['nl'] ?? '';
}

class WedstrijdScreen extends StatefulWidget {
  const WedstrijdScreen({super.key});
  @override
  State<WedstrijdScreen> createState() => _WedstrijdScreenState();
}

class _WedstrijdScreenState extends State<WedstrijdScreen> {
  final TextEditingController _woordVeld = TextEditingController();

  Map<String, dynamic>? _stand;
  bool _laden = true;
  bool _bezig = false;
  String? _fout;

  @override
  void initState() {
    super.initState();
    _haalStand();
  }

  @override
  void dispose() {
    _woordVeld.dispose();
    super.dispose();
  }

  Future<void> _haalStand() async {
    try {
      final r = await Api.get('/contest');
      if (!mounted) return;
      setState(() {
        _stand = r is Map ? Map<String, dynamic>.from(r) : null;
        _fout = null;
        _laden = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fout = e is ApiException ? e.message : _t(context, _fLaden);
        _laden = false;
      });
    }
  }

  Future<void> _stuurWoord() async {
    final woord = _woordVeld.text.trim();
    if (woord.isEmpty || _bezig) return;
    final melder = ScaffoldMessenger.of(context);
    // Teksten vooraf ophalen: na het wachten op de server mag de context weg zijn.
    final terugvalGoed = _t(context, _wGoed);
    final terugvalFout = _t(context, _fLaden);
    setState(() => _bezig = true);
    try {
      final r = await Api.post('/contest/word', {'word': woord});
      final melding = (r is Map && r['message'] != null) ? r['message'].toString() : terugvalGoed;
      _woordVeld.clear();
      await _haalStand();
      melder.showSnackBar(SnackBar(content: Text(melding)));
    } catch (e) {
      // De server is bewust vaag bij een fout woord; we tonen precies wat hij zegt.
      melder.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : terugvalFout)));
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  /// ISO-datum uit de API naar dd-mm-jjjj; bij twijfel liever niets dan een rare string.
  String? _datum(dynamic iso) {
    if (iso == null) return null;
    final d = DateTime.tryParse(iso.toString());
    if (d == null) return null;
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}-${l.month.toString().padLeft(2, '0')}-${l.year}';
  }

  bool get _loopt => _stand?['active'] == true;
  bool get _afgelopen => _stand?['ended'] == true;

  @override
  Widget build(BuildContext context) {
    final onder = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(title: Text('🏆 ${_t(context, _titel)}')),
      body: _laden
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _haalStand,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + onder),
                children: [
                  if (_fout != null) _foutKaart(_fout!),
                  if (_stand != null) ...[
                    _looptijdKaart(),
                    const SizedBox(height: 12),
                    _mijnKaart(),
                    const SizedBox(height: 12),
                    TourAnker(id: 'wedstrijd-woord', child: _woordKaart()),
                    const SizedBox(height: 12),
                    TourAnker(id: 'wedstrijd-stand', child: _standKaart()),
                    const SizedBox(height: 12),
                    TourAnker(id: 'wedstrijd-punten', child: _puntenKaart()),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _foutKaart(String tekst) => Card(
        color: const Color(0xFFFFF1F2),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.wifi_off_outlined, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(tekst, style: const TextStyle(fontSize: 13))),
            TextButton(onPressed: _haalStand, child: Text(_t(context, _opnieuw))),
          ]),
        ),
      );

  Widget _looptijdKaart() {
    final start = _datum(_stand?['starts_at']);
    final eind = _datum(_stand?['ends_at']);

    String kop;
    String uitleg;
    Color kleur;
    IconData icoon;
    if (_loopt) {
      kop = _t(context, _sLoopt);
      uitleg = eind == null ? _t(context, _sLooptUit) : '${_t(context, _totEnMet)} $eind';
      kleur = AppColors.teal;
      icoon = Icons.emoji_events_outlined;
    } else if (_afgelopen) {
      kop = _t(context, _sKlaar);
      uitleg = eind == null ? _t(context, _sKlaarUit) : '${_t(context, _geeindigdOp)} $eind';
      kleur = AppColors.navy;
      icoon = Icons.flag_outlined;
    } else {
      kop = _t(context, _sNogNiet);
      uitleg = start == null ? _t(context, _sNogNietUit) : '${_t(context, _startOp)} $start';
      kleur = AppColors.navy2;
      icoon = Icons.schedule_outlined;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icoon, color: kleur, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kop, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kleur)),
              const SizedBox(height: 3),
              Text(uitleg, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _mijnKaart() {
    final mijn = _stand?['me'];
    // 'me' ontbreekt als je niet ingelogd bent — de ranglijst zelf is wel openbaar.
    if (mijn is! Map) {
      return Card(
        color: const Color(0xFFFFF7E0),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(_t(context, _nietIngelogd), style: const TextStyle(fontSize: 13)),
        ),
      );
    }
    final punten = (mijn['points'] as num?)?.toInt() ?? 0;
    final plek = (mijn['rank'] as num?)?.toInt();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Expanded(
            child: Column(children: [
              Text(_t(context, _mijnPunten), style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$punten', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ]),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: Column(children: [
              Text(_t(context, _mijnPlek), style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(plek == null ? '—' : '#$plek',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.navy)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _woordKaart() {
    final kanMeedoen = _loopt && _stand?['me'] is Map;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🤫 ${_t(context, _wTitel)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(_t(context, _wUitleg), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _woordVeld,
                enabled: kanMeedoen && !_bezig,
                textInputAction: TextInputAction.done,
                maxLength: 60,
                onSubmitted: (_) => _stuurWoord(),
                decoration: InputDecoration(
                  hintText: _t(context, _wHint),
                  counterText: '',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: kanMeedoen && !_bezig ? _stuurWoord : null,
              child: _bezig
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_t(context, _wKnop)),
            ),
          ]),
          if (!_loopt)
            Text(_t(context, _wDicht), style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ]),
      ),
    );
  }

  Widget _standKaart() {
    final lijst = _stand?['leaderboard'];
    final rijen = lijst is List ? lijst : const [];
    final mijnPlek = (_stand?['me'] is Map) ? (_stand!['me']['rank'] as num?)?.toInt() : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📊 ${_t(context, _rTitel)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
          const SizedBox(height: 8),
          if (rijen.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_t(context, _rLeeg), style: const TextStyle(fontSize: 13, color: Colors.black45)),
            ),
          for (var i = 0; i < rijen.length; i++) _standRegel(i, rijen[i], mijnPlek == i + 1),
        ]),
      ),
    );
  }

  Widget _standRegel(int i, dynamic rij, bool isIk) {
    final m = rij is Map ? rij : const {};
    final naam = (m['username'] ?? '').toString();
    final punten = (m['coins'] as num?)?.toInt() ?? 0;
    final medaille = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: isIk ? const Color(0xFFE8F6F1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        SizedBox(
          width: 30,
          child: medaille != null
              ? Text(medaille, style: const TextStyle(fontSize: 15))
              : Text('${i + 1}', style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(naam,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: isIk ? FontWeight.w800 : FontWeight.w500)),
        ),
        Text('$punten', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
      ]),
    );
  }

  Widget _puntenKaart() {
    final beloningen = _stand?['rewards'];
    if (beloningen is! Map || beloningen.isEmpty) return const SizedBox.shrink();
    final regels = <Widget>[];
    for (final sleutel in _puntNamen.keys) {
      final punten = (beloningen[sleutel] as num?)?.toInt();
      if (punten == null || punten <= 0) continue;
      regels.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(_t(context, _puntNamen[sleutel]!), style: const TextStyle(fontSize: 13))),
          Text('+$punten', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
        ]),
      ));
    }
    if (regels.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🎣 ${_t(context, _pTitel)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
          const SizedBox(height: 6),
          ...regels,
        ]),
      ),
    );
  }
}

// ---------- vertalingen (nl/en/de/fr/es/pl) ----------

const Map<String, String> _titel = {
  'nl': 'Wedstrijd', 'en': 'Contest', 'de': 'Wettbewerb', 'fr': 'Concours', 'es': 'Concurso', 'pl': 'Konkurs',
};
const Map<String, String> _sLoopt = {
  'nl': 'De wedstrijd loopt!', 'en': 'The contest is running!', 'de': 'Der Wettbewerb läuft!',
  'fr': 'Le concours est en cours !', 'es': '¡El concurso está en marcha!', 'pl': 'Konkurs trwa!',
};
const Map<String, String> _sLooptUit = {
  'nl': 'Verdien punten en maak kans op de prijs.', 'en': 'Earn points and go for the prize.',
  'de': 'Sammle Punkte und gewinne den Preis.', 'fr': 'Gagne des points et tente de remporter le prix.',
  'es': 'Gana puntos y opta al premio.', 'pl': 'Zdobywaj punkty i walcz o nagrodę.',
};
const Map<String, String> _sNogNiet = {
  'nl': 'Nog niet begonnen', 'en': 'Not started yet', 'de': 'Noch nicht gestartet',
  'fr': 'Pas encore commencé', 'es': 'Aún no ha empezado', 'pl': 'Jeszcze się nie zaczął',
};
const Map<String, String> _sNogNietUit = {
  'nl': 'Zodra de wedstrijd start zie je hier de stand.', 'en': 'Once the contest starts you’ll see the standings here.',
  'de': 'Sobald der Wettbewerb startet, siehst du hier den Stand.',
  'fr': 'Dès le début du concours, le classement s’affichera ici.',
  'es': 'Cuando empiece el concurso verás aquí la clasificación.',
  'pl': 'Gdy konkurs wystartuje, zobaczysz tu wyniki.',
};
const Map<String, String> _sKlaar = {
  'nl': 'De wedstrijd is afgelopen', 'en': 'The contest has ended', 'de': 'Der Wettbewerb ist beendet',
  'fr': 'Le concours est terminé', 'es': 'El concurso ha terminado', 'pl': 'Konkurs zakończony',
};
const Map<String, String> _sKlaarUit = {
  'nl': 'Hieronder zie je de eindstand.', 'en': 'Below you’ll find the final standings.',
  'de': 'Unten siehst du den Endstand.', 'fr': 'Voici le classement final.',
  'es': 'Abajo está la clasificación final.', 'pl': 'Poniżej wyniki końcowe.',
};
const Map<String, String> _startOp = {
  'nl': 'Start op', 'en': 'Starts on', 'de': 'Startet am', 'fr': 'Début le', 'es': 'Empieza el', 'pl': 'Start',
};
const Map<String, String> _totEnMet = {
  'nl': 'Nog mee te doen t/m', 'en': 'You can join until', 'de': 'Mitmachen bis',
  'fr': 'Participation jusqu’au', 'es': 'Puedes participar hasta el', 'pl': 'Możesz brać udział do',
};
const Map<String, String> _geeindigdOp = {
  'nl': 'Geëindigd op', 'en': 'Ended on', 'de': 'Beendet am', 'fr': 'Terminé le', 'es': 'Finalizó el', 'pl': 'Zakończony',
};
const Map<String, String> _mijnPunten = {
  'nl': 'Jouw punten', 'en': 'Your points', 'de': 'Deine Punkte', 'fr': 'Tes points', 'es': 'Tus puntos', 'pl': 'Twoje punkty',
};
const Map<String, String> _mijnPlek = {
  'nl': 'Jouw plek', 'en': 'Your rank', 'de': 'Dein Platz', 'fr': 'Ton rang', 'es': 'Tu puesto', 'pl': 'Twoje miejsce',
};
const Map<String, String> _nietIngelogd = {
  'nl': 'Log in om mee te doen en je eigen stand te zien.', 'en': 'Log in to take part and see your own standing.',
  'de': 'Melde dich an, um mitzumachen und deinen Stand zu sehen.',
  'fr': 'Connecte-toi pour participer et voir ton classement.',
  'es': 'Inicia sesión para participar y ver tu posición.',
  'pl': 'Zaloguj się, aby wziąć udział i zobaczyć swój wynik.',
};
const Map<String, String> _wTitel = {
  'nl': 'Geheim woord', 'en': 'Secret word', 'de': 'Geheimes Wort', 'fr': 'Mot secret', 'es': 'Palabra secreta', 'pl': 'Tajne słowo',
};
const Map<String, String> _wUitleg = {
  'nl': 'In onze video’s en berichten verstoppen we geheime woorden. Vul er één in en verdien punten.',
  'en': 'We hide secret words in our videos and posts. Enter one and earn points.',
  'de': 'In unseren Videos und Beiträgen verstecken wir geheime Wörter. Gib eines ein und sammle Punkte.',
  'fr': 'Nous cachons des mots secrets dans nos vidéos et publications. Saisis-en un et gagne des points.',
  'es': 'Escondemos palabras secretas en nuestros vídeos y publicaciones. Escribe una y gana puntos.',
  'pl': 'W naszych filmach i postach ukrywamy tajne słowa. Wpisz jedno i zdobądź punkty.',
};
const Map<String, String> _wHint = {
  'nl': 'Vul het woord in', 'en': 'Enter the word', 'de': 'Wort eingeben', 'fr': 'Saisis le mot', 'es': 'Escribe la palabra', 'pl': 'Wpisz słowo',
};
const Map<String, String> _wKnop = {
  'nl': 'Insturen', 'en': 'Submit', 'de': 'Absenden', 'fr': 'Envoyer', 'es': 'Enviar', 'pl': 'Wyślij',
};
const Map<String, String> _wGoed = {
  'nl': 'Gelukt — punten bijgeschreven!', 'en': 'Done — points added!', 'de': 'Geschafft — Punkte gutgeschrieben!',
  'fr': 'C’est fait — points ajoutés !', 'es': '¡Listo — puntos añadidos!', 'pl': 'Gotowe — punkty dodane!',
};
const Map<String, String> _wDicht = {
  'nl': 'Insturen kan alleen zolang de wedstrijd loopt.', 'en': 'You can only submit while the contest is running.',
  'de': 'Einsenden ist nur während des Wettbewerbs möglich.',
  'fr': 'L’envoi n’est possible que pendant le concours.',
  'es': 'Solo puedes enviar mientras dure el concurso.',
  'pl': 'Możesz wysyłać tylko w czasie trwania konkursu.',
};
const Map<String, String> _rTitel = {
  'nl': 'Ranglijst', 'en': 'Leaderboard', 'de': 'Rangliste', 'fr': 'Classement', 'es': 'Clasificación', 'pl': 'Ranking',
};
const Map<String, String> _rLeeg = {
  'nl': 'Nog geen punten gescoord — jij kunt de eerste zijn.', 'en': 'No points scored yet — you could be first.',
  'de': 'Noch keine Punkte — du kannst der Erste sein.', 'fr': 'Aucun point pour l’instant — sois le premier.',
  'es': 'Todavía no hay puntos: puedes ser el primero.', 'pl': 'Nikt jeszcze nie zdobył punktów — możesz być pierwszy.',
};
const Map<String, String> _pTitel = {
  'nl': 'Zo verdien je punten', 'en': 'How to earn points', 'de': 'So sammelst du Punkte',
  'fr': 'Comment gagner des points', 'es': 'Cómo ganar puntos', 'pl': 'Jak zdobywać punkty',
};
const Map<String, String> _opnieuw = {
  'nl': 'Opnieuw', 'en': 'Retry', 'de': 'Erneut', 'fr': 'Réessayer', 'es': 'Reintentar', 'pl': 'Ponów',
};
const Map<String, String> _fLaden = {
  'nl': 'De wedstrijdstand kon niet worden geladen.', 'en': 'The contest standings could not be loaded.',
  'de': 'Der Wettbewerbsstand konnte nicht geladen werden.',
  'fr': 'Impossible de charger le classement du concours.',
  'es': 'No se ha podido cargar la clasificación del concurso.',
  'pl': 'Nie udało się wczytać wyników konkursu.',
};

/// Namen bij de punt-sleutels uit 'rewards'; de aantallen komen van de server,
/// zodat een regelwijziging daar meteen goed in de app staat.
const Map<String, Map<String, String>> _puntNamen = {
  'contest_depth': {
    'nl': 'Water in kaart brengen (dieptemeter, openbaar)', 'en': 'Map a water (sonar, shared publicly)',
    'de': 'Gewässer kartieren (Echolot, öffentlich)', 'fr': 'Cartographier une eau (sondeur, public)',
    'es': 'Cartografiar un agua (sonda, público)', 'pl': 'Zmapuj wodę (echosonda, publicznie)',
  },
  'contest_word': {
    'nl': 'Geheim woord invullen', 'en': 'Enter a secret word', 'de': 'Geheimes Wort eingeben',
    'fr': 'Saisir un mot secret', 'es': 'Introducir una palabra secreta', 'pl': 'Wpisz tajne słowo',
  },
  'contest_invite': {
    'nl': 'Vismaat aanbrengen', 'en': 'Bring in a fishing buddy', 'de': 'Angelkumpel werben',
    'fr': 'Parrainer un copain de pêche', 'es': 'Traer a un compañero de pesca', 'pl': 'Przyprowadź kumpla wędkarza',
  },
  'contest_referral': {
    'nl': 'Nieuw lid via jouw deellink', 'en': 'New member via your share link',
    'de': 'Neues Mitglied über deinen Link', 'fr': 'Nouveau membre via ton lien',
    'es': 'Nuevo miembro por tu enlace', 'pl': 'Nowy członek z twojego linku',
  },
  'contest_newwater': {
    'nl': 'Nieuw water aanmelden', 'en': 'Add a new water', 'de': 'Neues Gewässer melden',
    'fr': 'Ajouter une nouvelle eau', 'es': 'Añadir un agua nueva', 'pl': 'Zgłoś nową wodę',
  },
  'contest_streak': {
    'nl': 'Dag 7 van je reeks', 'en': 'Day 7 of your streak', 'de': 'Tag 7 deiner Serie',
    'fr': 'Jour 7 de ta série', 'es': 'Día 7 de tu racha', 'pl': 'Dzień 7 serii',
  },
  'contest_catch': {
    'nl': 'Openbare vangst met water erbij', 'en': 'Public catch with a water',
    'de': 'Öffentlicher Fang mit Gewässer', 'fr': 'Prise publique avec l’eau',
    'es': 'Captura pública con agua', 'pl': 'Publiczny połów z wodą',
  },
  'contest_photo': {
    'nl': 'Foto bij je vangst', 'en': 'Photo with your catch', 'de': 'Foto zum Fang',
    'fr': 'Photo avec ta prise', 'es': 'Foto con tu captura', 'pl': 'Zdjęcie przy połowie',
  },
  'contest_share': {
    'nl': 'Bezoekers op je gedeelde bericht', 'en': 'Visitors on your shared post',
    'de': 'Besucher auf deinem geteilten Beitrag', 'fr': 'Visiteurs sur ta publication partagée',
    'es': 'Visitas en tu publicación compartida', 'pl': 'Odwiedziny udostępnionego posta',
  },
  'contest_schoon': {
    'nl': 'Visplek schoon achtergelaten', 'en': 'Left your spot clean', 'de': 'Angelplatz sauber hinterlassen',
    'fr': 'Poste laissé propre', 'es': 'Dejar el puesto limpio', 'pl': 'Czyste stanowisko po sobie',
  },
};
