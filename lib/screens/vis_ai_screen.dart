import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api.dart';
import '../core/config.dart';

// Zelfstandige vertalingen (nl/en/de/fr); es/pl vallen terug op en.
const Map<String, Map<String, String>> _kVisAi = {
  'nl': {
    'title': 'AI-visassistent',
    'intro': 'Stel je vraag over vissen — aas, techniek, soort of stek. De gratis versie werkt met de YessFish-database.',
    'hint': 'Bijv. welk aas voor karper?', 'send': 'Vraag', 'thinking': 'Bezig…',
    'free': 'Gratis', 'left': 'gratis vragen vandaag', 'pts': 'AI-sterren',
    'earn': 'Verdien AI-punten: post openbaar en koppel vangsten aan een water.',
    'err': 'AI even niet bereikbaar, probeer zo nog eens.', 'loc': 'Locatie aan',
  },
  'en': {
    'title': 'AI fishing assistant',
    'intro': 'Ask about fishing — bait, technique, species or spot. The free version uses the YessFish database.',
    'hint': 'e.g. which bait for carp?', 'send': 'Ask', 'thinking': 'Thinking…',
    'free': 'Free', 'left': 'free questions today', 'pts': 'AI stars',
    'earn': 'Earn AI points: post publicly and link catches to a water.',
    'err': 'AI unavailable, please try again.', 'loc': 'Enable location',
  },
  'de': {
    'title': 'KI-Angelassistent',
    'intro': 'Frag rund ums Angeln — Köder, Technik, Art oder Stelle. Die Gratis-Version nutzt die YessFish-Datenbank.',
    'hint': 'z.B. welcher Köder für Karpfen?', 'send': 'Fragen', 'thinking': 'Lädt…',
    'free': 'Gratis', 'left': 'Gratisfragen heute', 'pts': 'KI-Sterne',
    'earn': 'KI-Punkte verdienen: öffentlich posten und Fänge mit einem Gewässer verknüpfen.',
    'err': 'KI nicht erreichbar, bitte nochmal.', 'loc': 'Standort an',
  },
  'fr': {
    'title': 'Assistant de pêche IA',
    'intro': 'Posez une question de pêche — appât, technique, espèce ou spot. La version gratuite utilise la base YessFish.',
    'hint': 'ex. quel appât pour la carpe ?', 'send': 'Demander', 'thinking': '…',
    'free': 'Gratuit', 'left': 'questions gratuites aujourd’hui', 'pts': 'étoiles IA',
    'earn': 'Gagnez des points IA : publiez publiquement et liez vos prises à une eau.',
    'err': 'IA indisponible, réessayez.', 'loc': 'Activer la localisation',
  },
  'es': {
    'title': 'Asistente de pesca IA',
    'intro': 'Pregunta sobre pesca — cebo, técnica, especie o puesto. La versión gratis usa la base de datos de YessFish.',
    'hint': 'p. ej. ¿qué cebo para carpa?', 'send': 'Preguntar', 'thinking': 'Pensando…',
    'free': 'Gratis', 'left': 'preguntas gratis hoy', 'pts': 'estrellas IA',
    'earn': 'Gana puntos IA: publica en público y vincula capturas a un agua.',
    'err': 'IA no disponible, inténtalo de nuevo.', 'loc': 'Activar ubicación',
  },
  'pl': {
    'title': 'Asystent wędkarski AI',
    'intro': 'Zapytaj o wędkowanie — przynęta, technika, gatunek lub miejsce. Wersja darmowa korzysta z bazy YessFish.',
    'hint': 'np. jaka przynęta na karpia?', 'send': 'Zapytaj', 'thinking': 'Myślę…',
    'free': 'Darmowe', 'left': 'darmowych pytań dziś', 'pts': 'gwiazdki AI',
    'earn': 'Zdobywaj punkty AI: publikuj publicznie i wiąż połowy z wodą.',
    'err': 'AI niedostępne, spróbuj ponownie.', 'loc': 'Włącz lokalizację',
  },
};

Map<String, String> _tr(BuildContext c) =>
    _kVisAi[Localizations.localeOf(c).languageCode] ?? _kVisAi['en']!;

/// Label voor de menu-tegel (in de huidige taal).
String visAiLabel(BuildContext c) => _tr(c)['title']!;

class VisAiScreen extends StatefulWidget {
  const VisAiScreen({super.key});
  @override
  State<VisAiScreen> createState() => _VisAiScreenState();
}

class _AiMsg {
  final bool me;
  final String text;
  _AiMsg(this.me, this.text);
}

class _VisAiScreenState extends State<VisAiScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_AiMsg>[];
  bool _busy = false, _unlimited = false, _locOn = false;
  int? _remaining, _points;
  double? _lat, _lng;

  Future<void> _getLocation() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locOn = true;
      });
    } catch (_) {}
  }

  void _jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _ctrl.text).trim();
    if (q.isEmpty || _busy) return;
    final t = _tr(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _msgs.add(_AiMsg(true, q));
      _ctrl.clear();
      _busy = true;
    });
    _jump();
    try {
      final body = <String, dynamic>{
        'question': q,
        'lang': lang,
      };
      if (_lat != null && _lng != null) {
        body['lat'] = _lat;
        body['lng'] = _lng;
      }
      final r = await Api.post('/fishing-assistant', body);
      if (r is Map) {
        setState(() {
          _msgs.add(_AiMsg(false, r['answer']?.toString() ?? ''));
          if (r['unlimited'] == true) _unlimited = true;
          if (r['free_remaining'] is int) _remaining = r['free_remaining'] as int;
          if (r['ai_points'] is int) _points = r['ai_points'] as int;
        });
      }
    } catch (e) {
      var msg = t['err']!;
      if (e is ApiException) {
        msg = e.message;
        if (e.status == 429) {
          _remaining = 0;
          if (e.data is Map && e.data['ai_points'] is int) _points = e.data['ai_points'] as int;
        }
      }
      setState(() => _msgs.add(_AiMsg(false, msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
      _jump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tr(context);
    final showStatus = !_unlimited && (_remaining != null || (_points ?? 0) > 0);
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(t['title']!, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: _unlimited ? AppColors.accent : Colors.white24,
                borderRadius: BorderRadius.circular(6)),
            child: Text(_unlimited ? 'YessFish+' : t['free']!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
            tooltip: t['loc'],
            onPressed: _getLocation,
            icon: Icon(_locOn ? Icons.my_location : Icons.location_searching,
                color: _locOn ? AppColors.mint : null),
          ),
        ],
      ),
      backgroundColor: AppColors.bg,
      body: Column(children: [
        if (showStatus)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              [
                if (_remaining != null) '$_remaining ${t['left']}',
                if ((_points ?? 0) > 0) '⭐ $_points ${t['pts']}',
              ].join('  ·  '),
              style: const TextStyle(fontSize: 12, color: AppColors.navy, fontWeight: FontWeight.w600),
            ),
          ),
        Expanded(
          child: _msgs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                      child: Text(t['intro']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, height: 1.4))),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _msgs.length + (_busy ? 1 : 0),
                  itemBuilder: (c, i) {
                    if (i >= _msgs.length) {
                      return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(t['thinking']!,
                                  style: const TextStyle(color: Colors.black45))));
                    }
                    final m = _msgs[i];
                    return Align(
                      alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints:
                            BoxConstraints(maxWidth: MediaQuery.of(c).size.width * 0.82),
                        decoration: BoxDecoration(
                          color: m.me ? AppColors.teal : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(m.text,
                            style: TextStyle(
                                color: m.me ? Colors.white : Colors.black87,
                                fontSize: 14.5,
                                height: 1.35)),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: t['hint'],
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _send(),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy, shape: const StadiumBorder()),
                child: Text(t['send']!),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
