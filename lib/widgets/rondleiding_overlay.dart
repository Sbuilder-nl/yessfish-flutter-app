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

  /// Schermen die iets kunnen klaarzetten (een waterblad, het lagenmenu, de reacties).
  ///
  /// Eerst was dit één enkele functie, die de kaart voor zichzelf opeiste. Daardoor kon alleen
  /// de kaart iets openzetten en bleef de rest van de rondleiding praten over panelen die dicht
  /// waren (Richard 20-09-2026: "alles openen wat geopend moet worden ... en indien nodig het
  /// ook weer sluiten"). Nu mag elk scherm meeluisteren zolang het open staat.
  static final Map<String, void Function(String vraag)> _luisteraars = {};

  static void luister(String sleutel, void Function(String vraag) bij) =>
      _luisteraars[sleutel] = bij;

  static void stopLuisteren(String sleutel, void Function(String vraag) bij) {
    if (identical(_luisteraars[sleutel], bij)) _luisteraars.remove(sleutel);
  }

  /// Stuur een verzoek naar alle schermen die nu luisteren; wie het niet kent doet niets.
  static void vraagAan(String vraag) {
    for (final f in List.of(_luisteraars.values)) {
      f(vraag);
    }
  }

  /// Zet door HomeScreen: opent (of sluit) een los scherm, zodat de rondleiding ook kan vertellen
  /// over alles wat achter een menutegel zit. null = terug naar de tabbladen.
  static Future<void> Function(String? scherm)? naarScherm;

  static OverlayEntry? _entry;
  static bool get loopt => _entry != null;

  /// Start bij het begin, of hervat bij [vanafStap].
  ///
  /// Met [totHoofdstuk] stopt hij aan het eind van dat hoofdstuk. Zo kun je een lid door de
  /// basis meenemen zonder hem daarna door 89 stappen te slepen: de rest staat met plaatjes in
  /// de handleiding (Richard 21-09-2026).
  static Future<void> start(BuildContext context,
      {String? vanafStap, String? totHoofdstuk}) async {
    if (_entry != null) return;
    final stappen = alleStappen();
    var index = 0;
    if (vanafStap != null) {
      final i = stappen.indexWhere((s) => s.id == vanafStap);
      if (i >= 0) index = i;
    }
    int? eind;
    // In de fotostand lopen we bewust álle stappen door: die build is er om van elk
    // scherm een afdruk te maken, niet om een lid rond te leiden.
    if (totHoofdstuk != null && !const bool.fromEnvironment('TOUR_SHOTS')) {
      final h = hoofdstukken.where((x) => x.id == totHoofdstuk).toList();
      if (h.isNotEmpty && h.first.stappen.isNotEmpty) {
        final laatste = h.first.stappen.last.id;
        final i = stappen.indexWhere((s) => s.id == laatste);
        if (i >= 0) eind = i;
      }
    }
    // Let op: vanaf de navigatiesleutel van de app heeft de context zélf geen Overlay boven
    // zich — de Overlay zit eronder, in de Navigator. Dan geeft Overlay.of een lege
    // verwijzing en klapt de null-check (gemeten 21-09-2026). Daarom eerst de navigator.
    final overlay = Navigator.maybeOf(context, rootNavigator: true)?.overlay
        ?? Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: (_) => _RondleidingLaag(startIndex: index, eindIndex: eind));
    overlay.insert(_entry!);
    unawaited(_meld('start', stap: stappen[index].id));
  }

  /// Eén stap in de échte app laten zien, en het lid het zélf laten doen.
  ///
  /// Vanuit de handleiding-met-plaatjes: "Laat het me zien in de app". Startte dat gewoon de
  /// rondleiding, dan liep die daarna vrolijk verder en drukte het lid nooit zelf op de knop
  /// (Richard 21-09-2026: "maar dan moeten ze het wel doen he"). Daarom: dit ene stapje, de
  /// knop licht op, jíj drukt hem in, en daarna is het klaar.
  static Future<void> losseStap(BuildContext context, String stapId) async {
    if (_entry != null) return;
    final stappen = alleStappen();
    final i = stappen.indexWhere((s) => s.id == stapId);
    if (i < 0) return;
    // Let op: vanaf de navigatiesleutel van de app heeft de context zélf geen Overlay boven
    // zich — de Overlay zit eronder, in de Navigator. Dan geeft Overlay.of een lege
    // verwijzing en klapt de null-check (gemeten 21-09-2026). Daarom eerst de navigator.
    final overlay = Navigator.maybeOf(context, rootNavigator: true)?.overlay
        ?? Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: (_) => _RondleidingLaag(startIndex: i, alleenDezeStap: true));
    overlay.insert(_entry!);
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
  const _RondleidingLaag({required this.startIndex, this.alleenDezeStap = false, this.eindIndex});
  final int startIndex;
  /// Laatste stap die we tonen; daarna is het klaar. null = tot het einde.
  final int? eindIndex;

  /// Eén stap laten doen en dan stoppen (vanuit de handleiding), in plaats van doorlopen.
  final bool alleenDezeStap;

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

  /// Zoeken we nog stilletjes naar de knop van een optionele stap?
  ///
  /// Zo'n stap gaat over iets dat er niet altijd is. Vinden we de knop niet, dan slaan we hem
  /// over — maar dan mag het lid hem ook nooit gezien hebben. Toonden we hem eerst wél, dan las
  /// je een stap en sprong hij na een seconde uit zichzelf door (Richard 20-09-2026: "gaat soms
  /// extra stappen zelf vooruit"). Daarom: eerst zoeken, dan pas tonen.
  bool _stilZoeken = false;

  /// Hoe vaak we al naar de knop hebben gescrold, en hoeveel tikken we nog op de
  /// scrol? Zonder dat wachten meten we het vlak midden in de beweging en wijst de cirkel mis.
  int _naScroll = 0;
  int _scrolPogingen = 0;
  bool _zoekAfgerond = false;

  /// Welk paneel de rondleiding heeft laten openzetten (null = niets).
  String? _openVraag;

  /// Welk los scherm nu open staat voor de rondleiding (null = de tabbladen).
  String? _openScherm;

  Stap get _stap => _stappen[_i];

  /// Zelftest: loopt de rondleiding vanzelf door en schrijft per stap in het logboek of het
  /// anker gevonden is en waar het staat. Alleen aan met `--dart-define=TOUR_AUTOTEST=true`;
  /// in een gewone build bestaat deze lus niet.
  ///
  /// Nodig omdat de schermboom van Flutter op de emulator leeg blijft: van buitenaf is niet te
  /// zien wélke stap in beeld staat, en juist dat wilden we controleren (Richard 20-09-2026:
  /// "mis nog veel stappen die web wel heeft in app").
  static const bool _zelfTest = bool.fromEnvironment('TOUR_AUTOTEST');
  /// Hoe lang een stap blijft staan tijdens de zelftest. Langer als je van elke stap
  /// een schermafdruk wilt maken: `--dart-define=TOUR_AUTOTEST_MS=2500`.
  static const int _testPauze = int.fromEnvironment('TOUR_AUTOTEST_MS', defaultValue: 500);

  /// Fotostand: de rondleiding doet alles (scherm openen, blad opentrekken, scrollen) maar
  /// tekent zichzelf niet. Zo kunnen we van elke stap een schóne schermafdruk maken voor de
  /// handleiding-met-plaatjes, mét het vlak dat we later zelf oplichten.
  /// Aanzetten met `--dart-define=TOUR_SHOTS=true`.
  static const bool _fotoStand = bool.fromEnvironment('TOUR_SHOTS');
  Timer? _testLus;
  int _gemeld = -1;
  int _wachtTellen = 0;

  void _startZelfTest() {
    _testLus = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final s = _stap;
      final klaar = !_stilZoeken && (s.zoek == null || _zoekAfgerond);
      if (!klaar) {
        // Diagnose: blijft de rondleiding hangen, dan zie je hier waaróp hij wacht.
        if (++_wachtTellen % 8 == 0) {
          debugPrint('YFWAIT ${_i + 1}/89 id=${s.id} zoek=${s.zoek} stil=$_stilZoeken '
              'vlak=${_vlak != null} pogingen=$_pogingen scrol=$_scrolPogingen naScroll=$_naScroll');
        }
        return;
      }
      _wachtTellen = 0;
      if (_gemeld == _i) return;
      _gemeld = _i;
      final v = _vlak;
      final waar = v == null
          ? 'GEEN'
          : '${v.left.round()},${v.top.round()},${v.right.round()},${v.bottom.round()}';
      debugPrint('YFTOUR ${_i + 1}/${_stappen.length} id=${s.id} zoek=${s.zoek ?? '-'} '
          'scherm=${s.scherm ?? '-'} tab=${s.tab ?? '-'} vlak=$waar');
      Future.delayed(const Duration(milliseconds: _testPauze), () {
        if (mounted && _gemeld == _i) _volgende();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _naarStap(_i, eerste: true);
    if (_zelfTest) _startZelfTest();
  }

  @override
  void dispose() {
    _zoeker?.cancel();
    _testLus?.cancel();
    super.dispose();
  }

  void _naarStap(int i, {bool eerste = false}) {
    _zoeker?.cancel();
    _pogingen = 0;
    _i = i;
    _vlak = null;
    final s = _stap;
    _stilZoeken = s.optioneel && s.zoek != null;
    if (!eerste) Rondleiding._meld('step', stap: s.id);
    setState(() {});
    // Van tabblad wisselen doet setState op het hoofdscherm. Gebeurt dat terwijl deze laag nog
    // wordt opgebouwd, dan klapt Flutter eruit met "setState() called during build" — op de
    // emulator gezien bij de allereerste stap. Daarom pas ná dit beeldje (19-09-2026).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Een ander scherm dan bij de vorige stap? Dan eerst dáárheen; de rest van deze stap wacht.
      if (s.scherm != _openScherm) {
        _openScherm = s.scherm;
        _openVraag = null;   // een ander scherm sluit de bladen sowieso
        await Rondleiding.naarScherm?.call(s.scherm);
        if (!mounted) return;
      }
      if (s.tab != null) Rondleiding.gaNaarTab?.call(s.tab!);
      // Gaat deze stap over een ander paneel dan de vorige? Dan eerst het oude dicht. Zo blijft
      // er nooit een blad over de knop liggen die we juist willen aanwijzen.
      if (s.vraag != _openVraag) {
        if (_openVraag != null) Rondleiding.vraagAan('sluit');
        _openVraag = s.vraag;
        if (s.vraag != null) Rondleiding.vraagAan(s.vraag!);
      }
    });
    _zoekAnker();
  }

  /// Blijf even zoeken: na een tabwissel moet het scherm eerst opbouwen.
  void _zoekAnker() {
    _zoeker?.cancel();
    if (_stap.zoek == null) { _zoekAfgerond = true; return; }
    _naScroll = 0;
    _scrolPogingen = 0;
    _zoekAfgerond = false;
    _zoeker = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final r = TourAnkers.vlak(_stap.zoek!);
      if (r != null) {
        if (!mounted) { t.cancel(); return; }
        final scherm = MediaQuery.of(context).size;
        // Niet alleen "staat hij in beeld", maar "staat hij er fatsoenlijk". Een tegel die pal
        // onder de titelbalk of half achter de tabbalk hangt is technisch zichtbaar, maar je ziet
        // niet wat er wordt aangewezen (Richard 20-09-2026, stap 16 en 26). Daarom scrollen we
        // hem naar een rustige band in het bovenste derde deel van het scherm.
        final bovenGrens = scherm.height * 0.20;
        final onderGrens = scherm.height * 0.52;
        final midden = r.top + r.height / 2;
        if (_naScroll > 0) { _naScroll--; return; }
        // Eén scrolpoging was te weinig. In het waterblad (een sleepbaar blad met een eigen
        // lijst) moet de lijst eerst uitklappen voordat hij écht schuift; het gevolg was dat
        // 'Beoordelingen' en 'Foto's en video's' onder de schermrand bleven staan en de
        // rondleiding een cirkel tekende die niemand zag (gemeten 20-09-2026).
        if (midden < bovenGrens || midden > onderGrens) {
          if (_scrolPogingen < 4) {
            _scrolPogingen++;
            _naScroll = 10;
            TourAnkers.inBeeld(_stap.zoek!, uitlijning: _scrolPogingen > 2 ? 0.5 : 0.32);
            return;
          }
        }
        t.cancel();
        _zoekAfgerond = true;
        // Hoeveel van de knop staat er nog in beeld? Een blok dat net met zijn onderrand
        // buiten het scherm valt is prima aan te wijzen; pas als er bijna niets van te zien is
        // tonen we de uitleg in het midden (21-09-2026).
        final zichtbaar = Rect.fromLTRB(
            r.left.clamp(0.0, scherm.width), r.top.clamp(0.0, scherm.height),
            r.right.clamp(0.0, scherm.width), r.bottom.clamp(0.0, scherm.height));
        final vlakOpp = r.width * r.height;
        final deel = vlakOpp <= 0 ? 0.0 : (zichtbaar.width * zichtbaar.height) / vlakOpp;
        setState(() { _vlak = deel < 0.35 ? null : r; _stilZoeken = false; });
        return;
      }
      // Ruim de tijd: de kaart is zwaar en heeft na een tabwissel een paar seconden nodig voor
      // zijn knoppenbalk er staat. Met 1,2 seconde sloeg de rondleiding 'zoeken' en 'lagen'
      // over terwijl die knoppen er even later gewoon waren (gemeten 20-09-2026).
      // In de fotostand mag het zoeken veel langer duren. Zes seconden was te kort voor de
      // stappen die eerst iets moeten openen — het waterblad, het herkenresultaat, het
      // AI-knopje bij een vangst — en juist die acht stappen kregen dan geen afdruk
      // (gemeten 21-09-2026). Voor een lid blijft het zes seconden: die wil niet wachten.
      if (++_pogingen >= (_fotoStand ? 250 : 60)) {
        t.cancel();
        _zoekAfgerond = true;
        // Optionele stap zonder knop slaan we over — die gaat over iets dat er nu niet is
        // (nog geen vangsten, geen reeks). Overslaan gebeurt in de richting waarin het lid
        // loopt, anders kun je met Vorige nooit langs zo'n stap terug: hij duwt je meteen
        // weer vooruit.
        if (!mounted) return;
        if (_stap.optioneel) {
          // Nooit getoond, dus ook niets zichtbaars om over te slaan.
          if (_richting < 0) {
            _vorige();
          } else {
            _volgende();
          }
        } else {
          // Verplichte stap zonder knop: uitleg gewoon in het midden tonen.
          setState(() => _stilZoeken = false);
        }
      }
    });
  }

  void _volgende() {
    _richting = 1;
    if (_i + 1 >= _stappen.length || (widget.eindIndex != null && _i >= widget.eindIndex!)) {
      Rondleiding._meld('done');
      if (_openScherm != null) Rondleiding.naarScherm?.call(null);
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
    if (_openScherm != null) Rondleiding.naarScherm?.call(null);
    Rondleiding.stop();
  }

  /// Het uit te lichten vlak, teruggebracht tot wat er écht op het scherm past.
  ///
  /// Twee dingen gingen hier mis (Richard 19-09-2026: "na een tijdje liep die vast, donkerder
  /// scherm en kon ik niks meer"):
  ///  - Een anker dat hoger is dan het scherm — het hele factorenblok, de winactielijst — heeft een
  ///    bovenkant boven en een onderkant onder de rand. De vier verduisteringspanelen gingen elkaar
  ///    dan overlappen (vandaar dónkerder) en de ballon werd buiten beeld geduwd: alles zwart, niets
  ///    meer aan te tikken.
  ///  - Een anker dat bijna het hele scherm vult licht niets ùit. Dan liever de uitleg in het
  ///    midden, zoals bij een stap zonder anker.
  Rect? _bruikbaarVlak(Rect? v, Size scherm) {
    if (v == null) return null;
    final bij = Rect.fromLTRB(
      v.left.clamp(0.0, scherm.width),
      v.top.clamp(0.0, scherm.height),
      v.right.clamp(0.0, scherm.width),
      v.bottom.clamp(0.0, scherm.height),
    );
    if (bij.width < 8 || bij.height < 8) return null;              // buiten beeld gescrold
    if (bij.height > scherm.height * 0.72) return null;            // vult het scherm: wijst niets aan
    // Ligt de knop grotendeels buiten beeld, dan is wat overblijft niet die knop maar een streepje
    // tegen de rand. Dat tekenden we wél, en zo kwam de groene cirkel over de tabbalk te staan bij
    // een menu-tegel die verderop in de lijst stond (screenshots Richard 20-09-2026). Liever geen
    // cirkel dan een cirkel om het verkeerde.
    if (bij.width * bij.height < v.width * v.height * 0.6) return null;
    return bij;
  }

  @override
  Widget build(BuildContext context) {
    if (_fotoStand) return const SizedBox.shrink();
    // Nog aan het zoeken naar een optionele knop: niets tonen. Zo flitst er geen stap voorbij.
    if (_stilZoeken) return const SizedBox.shrink();
    final taal = _taal(context);
    final scherm = MediaQuery.of(context).size;
    final v = _bruikbaarVlak(_vlak, scherm);
    final klikbaar = (_stap.klik || widget.alleenDezeStap) && v != null;

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
                  if (!mounted) return;
                  // Kwam het lid hier vanuit de handleiding voor één ding, dan is het nu klaar.
                  widget.alleenDezeStap ? _stoppen() : _volgende();
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
    // De ballon staat onder de knop, of erboven als daar geen plek is — maar hij moet ALTIJD
    // binnen het scherm blijven. Stond hij erbuiten, dan zag een lid alleen nog een donker scherm
    // zonder knoppen en kon hij geen kant meer op (Richard 19-09-2026).
    const hoogte = 230.0;   // ruime schatting; de ballon zelf groeit mee met de tekst
    const marge = 12.0;
    final maxTop = (scherm.height - hoogte - marge).clamp(marge, scherm.height);

    double top;
    if (v == null) {
      top = ((scherm.height - hoogte) / 2).clamp(marge, maxTop);
    } else if (v.bottom + hoogte + 40 < scherm.height) {
      top = v.bottom + 20;                       // past eronder
    } else if (v.top - hoogte - 20 > marge) {
      top = v.top - hoogte - 20;                 // dan erboven
    } else {
      // Past nergens netjes: zet hem op de helft met de meeste ruimte, en altijd in beeld.
      top = v.top > scherm.height / 2 ? marge : (scherm.height - hoogte - marge);
    }

    return Positioned(
      left: marge, right: marge,
      top: top.clamp(marge, maxTop),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          // Lange uitleg of een groot lettertype mag de knoppen nooit uit beeld duwen: de tekst
          // scrolt, de knoppen blijven staan.
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(tl(_stap.titel, taal),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0a3d62)))),
              Text('${_i + 1}/${_stappen.length}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
            const SizedBox(height: 8),
            Text(tl(_stap.tekst, taal), style: const TextStyle(fontSize: 14.5, height: 1.4, color: Colors.black87)),
            if (_stap.klik || widget.alleenDezeStap) Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(tl(_tikErop, taal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1f8a70)))),
            const SizedBox(height: 10),
            Row(children: [
              TextButton(onPressed: _stoppen, child: Text(tl(_stoppenTekst, taal), style: const TextStyle(color: Colors.black54))),
              const Spacer(),
              // In doe-stand geen Volgende: het lid moet de knop zelf indrukken, anders klikt
              // hij zich er langs en heeft hij het nog steeds niet gedaan (Richard 21-09-2026).
              if (!widget.alleenDezeStap) ...[
                if (_i > 0) TextButton(onPressed: _vorige, child: Text(tl(_vorigeTekst, taal))),
                const SizedBox(width: 4),
                FilledButton(onPressed: _volgende, child: Text(tl(_i + 1 >= _stappen.length ? _klaarTekst : _volgendeTekst, taal))),
              ],
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
