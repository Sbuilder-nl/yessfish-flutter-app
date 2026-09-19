import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/rondleiding.dart';
import '../core/rondleiding_inhoud.dart';

/// De rondleiding zoals het lid hem ziet: scherm dimmen, de échte knop uitlichten, uitleggen.
///
/// Wat hier gebeurt is met opzet hetzelfde als op het web: dezelfde hoofdstukken, dezelfde
/// volgorde, dezelfde teksten. Een lid dat de rondleiding op zijn telefoon doet en later op de
/// site kijkt, moet hetzelfde verhaal herkennen (Richard 19-09-2026).
class Rondleiding {
  Rondleiding._();

  /// Zet door HomeScreen, zodat de rondleiding naar het juiste tabblad kan springen.
  static void Function(int tab)? gaNaarTab;

  /// Zet door schermen die iets kunnen klaarzetten (bijvoorbeeld een waterblad openen).
  static void Function(String vraag)? opVraag;

  static OverlayEntry? _entry;
  static bool get loopt => _entry != null;

  /// Start bij het begin, of hervat bij [vanafStap].
  static Future<void> start(BuildContext context, {String? vanafStap}) async {
    if (_entry != null) return;
    final stappen = alleStappen();
    var index = 0;
    if (vanafStap != null) {
      final i = stappen.indexWhere((s) => s.id == vanafStap);
      if (i >= 0) index = i;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: (_) => _RondleidingLaag(startIndex: index));
    overlay.insert(_entry!);
    unawaited(_meld('start', stap: stappen[index].id));
  }

  static void stop() {
    _entry?.remove();
    _entry = null;
  }

  /// Voortgang naar de server, zodat hervatten op een ander toestel klopt.
  static Future<void> _meld(String actie, {String? stap, String? hoofdstuk}) async {
    try {
      await Api.post('/tour', {
        'action': actie,
        if (stap != null) 'step': stap,
        if (hoofdstuk != null) 'chapter': hoofdstuk,
      });
    } catch (_) {
      // Geen verbinding? De rondleiding moet gewoon doorlopen; voortgang is bijzaak.
    }
  }

  /// "Liever later": we onthouden dat, zodat het lid het niet elke keer opnieuw krijgt.
  static Future<void> overslaan() => _meld('skip');

  /// Opnieuw beginnen vanaf stap 1.
  static Future<void> opnieuw(BuildContext context) async {
    await _meld('reset');
    if (context.mounted) await start(context);
  }

  static Future<Map?> stand() async {
    try {
      final r = await Api.get('/tour');
      return r is Map ? r : null;
    } catch (_) {
      return null;
    }
  }
}

class _RondleidingLaag extends StatefulWidget {
  const _RondleidingLaag({required this.startIndex});
  final int startIndex;

  @override
  State<_RondleidingLaag> createState() => _RondleidingLaagState();
}

class _RondleidingLaagState extends State<_RondleidingLaag> {
  late int _i = widget.startIndex;
  late final List<Stap> _stappen = alleStappen();
  Rect? _vlak;
  Timer? _zoeker;
  int _pogingen = 0;

  /// Richting waarin het lid door de rondleiding loopt: bepaalt welke kant een
  /// overgeslagen stap uit springt. Zonder dit kom je nooit terug langs zo'n stap.
  int _richting = 1;

  Stap get _stap => _stappen[_i];

  @override
  void initState() {
    super.initState();
    _naarStap(_i, eerste: true);
  }

  @override
  void dispose() {
    _zoeker?.cancel();
    super.dispose();
  }

  void _naarStap(int i, {bool eerste = false}) {
    _zoeker?.cancel();
    _pogingen = 0;
    _i = i;
    _vlak = null;
    final s = _stap;
    if (!eerste) Rondleiding._meld('step', stap: s.id);
    setState(() {});
    // Van tabblad wisselen doet setState op het hoofdscherm. Gebeurt dat terwijl deze laag nog
    // wordt opgebouwd, dan klapt Flutter eruit met "setState() called during build" — op de
    // emulator gezien bij de allereerste stap. Daarom pas ná dit beeldje (19-09-2026).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (s.tab != null) Rondleiding.gaNaarTab?.call(s.tab!);
      if (s.vraag != null) Rondleiding.opVraag?.call(s.vraag!);
    });
    _zoekAnker();
  }

  /// Blijf even zoeken: na een tabwissel moet het scherm eerst opbouwen.
  void _zoekAnker() {
    _zoeker?.cancel();
    if (_stap.zoek == null) return;
    _zoeker = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final r = TourAnkers.vlak(_stap.zoek!);
      if (r != null) {
        t.cancel();
        if (mounted) setState(() => _vlak = r);
        return;
      }
      if (++_pogingen >= 12) {
        t.cancel();
        // Optionele stap zonder knop slaan we over — die gaat over iets dat er nu niet is
        // (nog geen vangsten, geen reeks). Overslaan gebeurt in de richting waarin het lid
        // loopt, anders kun je met Vorige nooit langs zo'n stap terug: hij duwt je meteen
        // weer vooruit.
        if (_stap.optioneel && mounted) {
          if (_richting < 0) {
            _vorige();
          } else {
            _volgende();
          }
        }
      }
    });
  }

  void _volgende() {
    _richting = 1;
    if (_i + 1 >= _stappen.length) {
      Rondleiding._meld('done');
      Rondleiding.stop();
      return;
    }
    _naarStap(_i + 1);
  }

  void _vorige() {
    _richting = -1;
    if (_i == 0) return;
    _naarStap(_i - 1);
  }

  void _stoppen() {
    Rondleiding._meld('skip', stap: _stap.id);
    Rondleiding.stop();
  }

  @override
  Widget build(BuildContext context) {
    final taal = _taal(context);
    final scherm = MediaQuery.of(context).size;
    final v = _vlak;
    final klikbaar = _stap.klik && v != null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        // Vier panelen rond de uitgelichte knop. Zo kan het lid die knop écht indrukken:
        // met één groot scherm eroverheen zou de rondleiding elke tik opslokken.
        if (v == null)
          Positioned.fill(child: GestureDetector(onTap: () {}, child: Container(color: Colors.black54)))
        else ...[
          _paneel(const Rect.fromLTWH(0, 0, 0, 0).expandToInclude(Rect.fromLTWH(0, 0, scherm.width, v.top - 8))),
          _paneel(Rect.fromLTWH(0, v.bottom + 8, scherm.width, scherm.height - v.bottom - 8)),
          _paneel(Rect.fromLTWH(0, v.top - 8, v.left - 8, v.height + 16)),
          _paneel(Rect.fromLTWH(v.right + 8, v.top - 8, scherm.width - v.right - 8, v.height + 16)),
          // Rand om de knop
          Positioned(
            left: v.left - 8, top: v.top - 8, width: v.width + 16, height: v.height + 16,
            child: IgnorePointer(child: Container(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1f8a70), width: 3),
              boxShadow: [BoxShadow(color: const Color(0xFF1f8a70).withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 2)],
            ))),
          ),
          // Tikt het lid op de knop, dan gaat de uitleg vanzelf verder — maar pas nadat de knop
          // zelf zijn werk heeft gedaan, anders staat de volgende stap er eerder dan het scherm.
          if (klikbaar)
            Positioned(
              left: v.left - 8, top: v.top - 8, width: v.width + 16, height: v.height + 16,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => Future.delayed(const Duration(milliseconds: 650), () {
                  if (mounted) _volgende();
                }),
              ),
            )
          else
            // Hoeft het lid hier níét te klikken, dan vangen we de tik ook boven de uitgelichte
            // knop af. Anders navigeer je met één misklik weg en loopt de rondleiding door over
            // een scherm waar hij niet over gaat (19-09-2026).
            Positioned(
              left: v.left - 8, top: v.top - 8, width: v.width + 16, height: v.height + 16,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
            ),
        ],
        _ballon(taal, v, scherm),
      ]),
    );
  }

  Widget _paneel(Rect r) => Positioned(
        left: r.left, top: r.top, width: r.width.clamp(0, double.infinity), height: r.height.clamp(0, double.infinity),
        child: GestureDetector(onTap: () {}, child: Container(color: Colors.black54)),
      );

  Widget _ballon(String taal, Rect? v, Size scherm) {
    // Ballon onder de knop, of erboven als daar geen plek is.
    final onder = v == null || v.bottom + 260 < scherm.height;
    final top = v == null ? null : (onder ? v.bottom + 20 : null);
    final bodem = v == null ? null : (onder ? null : scherm.height - v.top + 20);

    return Positioned(
      left: 12, right: 12,
      top: v == null ? scherm.height / 2 - 130 : top,
      bottom: bodem,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(tl(_stap.titel, taal),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0a3d62)))),
              Text('${_i + 1}/${_stappen.length}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
            const SizedBox(height: 8),
            Text(tl(_stap.tekst, taal), style: const TextStyle(fontSize: 14.5, height: 1.4, color: Colors.black87)),
            if (_stap.klik) Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(tl(_tikErop, taal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1f8a70)))),
            const SizedBox(height: 10),
            Row(children: [
              TextButton(onPressed: _stoppen, child: Text(tl(_stoppenTekst, taal), style: const TextStyle(color: Colors.black54))),
              const Spacer(),
              if (_i > 0) TextButton(onPressed: _vorige, child: Text(tl(_vorigeTekst, taal))),
              const SizedBox(width: 4),
              FilledButton(onPressed: _volgende, child: Text(tl(_i + 1 >= _stappen.length ? _klaarTekst : _volgendeTekst, taal))),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// De taal van het lid. Een Overlay hangt buiten de schermboom, dus we lezen hem zonder te
/// luisteren; wisselt het lid van taal, dan geldt dat bij de volgende rondleiding.
String _taal(BuildContext c) {
  try {
    return Provider.of<I18n>(c, listen: false).locale;
  } catch (_) {
    return 'nl';
  }
}

final _volgendeTekst = tx('Volgende', 'Next', 'Weiter', 'Suivant', 'Siguiente', 'Dalej');
final _vorigeTekst = tx('Vorige', 'Back', 'Zurück', 'Précédent', 'Anterior', 'Wstecz');
final _stoppenTekst = tx('Stoppen', 'Stop', 'Beenden', 'Arrêter', 'Parar', 'Zakończ');
final _klaarTekst = tx('Klaar', 'Done', 'Fertig', 'Terminé', 'Listo', 'Gotowe');
final _tikErop = tx('Tik er zelf op om verder te gaan.', 'Tap it yourself to continue.',
    'Tippe selbst darauf, um weiterzugehen.', 'Touche-le toi-même pour continuer.',
    'Tócalo tú mismo para continuar.', 'Dotknij sam, aby przejść dalej.');
