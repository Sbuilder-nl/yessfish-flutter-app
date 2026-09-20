import 'package:flutter/material.dart';

/// Rondleiding door de app: wijst de échte knop aan en legt uit wat hij doet.
///
/// Dit is de app-kant van dezelfde rondleiding als op het web. Daar zoekt hij een knop met
/// `data-tour="<id>"`; hier registreert een knop zich met `TourAnker(id: '<id>')`. De stap-id's
/// zijn gelijk waar de functie gelijk is, zodat we één verhaal hebben en niet twee.
///
/// Vindt de rondleiding een knop niet (ander scherm, knop verplaatst, functie niet beschikbaar),
/// dan toont hij de uitleg gewoon in het midden en gaat Volgende gewoon verder. Er gaat dus nooit
/// iets stuk — precies zoals op het web (Richard 16/19-09-2026).

/// Waar de rondleiding een knop kan vinden. Gevuld door [TourAnker].
class TourAnkers {
  TourAnkers._();
  static final Map<String, GlobalKey> _ankers = {};

  static void zet(String id, GlobalKey key) => _ankers[id] = key;
  static void weg(String id, GlobalKey key) {
    if (identical(_ankers[id], key)) _ankers.remove(id);
  }

  /// Het vlak van de knop op het scherm, of null als hij er niet (meer) is.
  static Rect? vlak(String id) {
    final key = _ankers[id];
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final pos = box.localToGlobal(Offset.zero);
    final r = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    // Een knop die (deels) buiten beeld staat is voor een rondleiding waardeloos: dan liever
    // de uitleg in het midden dan een cirkel op een rand die het lid niet ziet.
    return r.width <= 0 || r.height <= 0 ? null : r;
  }

  /// Scrol de knop naar het midden van zijn lijst.
  ///
  /// Zonder dit sloeg de rondleiding menu-tegels over die gewoon bestaan, maar verderop in de
  /// lijst staan: het vlak viel buiten beeld en dan valt er niets aan te wijzen (20-09-2026).
  static void inBeeld(String id, {double uitlijning = 0.32}) {
    final ctx = _ankers[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: uitlijning, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }
}

/// Zet dit om een knop heen zodat de rondleiding hem kan aanwijzen.
class TourAnker extends StatefulWidget {
  const TourAnker({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  @override
  State<TourAnker> createState() => _TourAnkerState();
}

class _TourAnkerState extends State<TourAnker> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TourAnkers.zet(widget.id, _key);
  }

  @override
  void didUpdateWidget(TourAnker oud) {
    super.didUpdateWidget(oud);
    if (oud.id != widget.id) {
      TourAnkers.weg(oud.id, _key);
      TourAnkers.zet(widget.id, _key);
    }
  }

  @override
  void dispose() {
    TourAnkers.weg(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

/// Eén stap van de rondleiding.
class Stap {
  const Stap({
    required this.id,
    required this.titel,
    required this.tekst,
    this.zoek,
    this.tab,
    this.klik = false,
    this.optioneel = false,
    this.vraag,
  });

  final String id;

  /// Anker-id van de knop waar deze stap over gaat. Leeg = uitleg in het midden.
  final String? zoek;

  /// Naar welk tabblad de rondleiding gaat (0 feed, 1 vangsten, 2 bijtkans, 3 kaart, 4 menu).
  final int? tab;

  /// Het lid moet zélf op de knop drukken; de rest van het scherm doet even niets mee.
  final bool klik;

  /// Knop bestaat alleen in bepaalde situaties (nog geen vangsten, geen vismaten …).
  /// Niet gevonden = stap overslaan in plaats van een lege cirkel tonen.
  final bool optioneel;

  /// Signaal aan het scherm om iets klaar te zetten (bijvoorbeeld een waterblad openen).
  final String? vraag;

  final Map<String, String> titel;
  final Map<String, String> tekst;
}

/// Een hoofdstuk: alles wat je op één plek in de app kunt.
class Hoofdstuk {
  const Hoofdstuk({
    required this.id,
    required this.icoon,
    required this.naam,
    required this.samenvatting,
    required this.stappen,
  });

  final String id;
  final String icoon;
  final Map<String, String> naam;
  final Map<String, String> samenvatting;
  final List<Stap> stappen;
}

/// Korte schrijfwijze voor de zes talen, gelijk aan `tx()` op het web.
Map<String, String> tx(String nl, String en, String de, String fr, String es, String pl) =>
    {'nl': nl, 'en': en, 'de': de, 'fr': fr, 'es': es, 'pl': pl};

/// Tekst in de taal van het lid, met Engels als terugval.
String tl(Map<String, String> m, String taal) => m[taal] ?? m['en'] ?? m['nl'] ?? '';
