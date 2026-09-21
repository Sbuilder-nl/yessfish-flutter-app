import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/rondleiding.dart';
import '../core/rondleiding_inhoud.dart';
import '../widgets/rondleiding_overlay.dart';

/// De handleiding: alle hoofdstukken met schermafbeeldingen erbij.
///
/// Eerst liep de uitleg volledig dóór de echte app. Dat ging op de kaart mis: die moet eerst
/// tegels en wateren laden, het lagenblad moet open, en het waterblad pakte een willekeurig
/// water dat toevallig in beeld was. Elke kaartstap kostte daardoor seconden en vijf stappen
/// wezen helemaal niets aan. Erger nog: een gloednieuw lid — precies wie de uitleg nodig heeft —
/// kreeg het minst te zien, want stappen over een foto bij je vangst, je meldingen of je
/// vistijlen werden overgeslagen omdat hij die nog niet had (Richard 21-09-2026).
///
/// Nu staat de uitleg op eigen schermen: een afbeelding van het echte scherm met het stuk waar
/// het over gaat opgelicht. Dat is meteen, overal hetzelfde, en laat óók zien hoe iets eruitziet
/// als het wél gevuld is. Wie het in zijn eigen app wil zien drukt op "Laat het me zien".
class HandleidingScreen extends StatefulWidget {
  const HandleidingScreen({super.key});

  @override
  State<HandleidingScreen> createState() => _HandleidingScreenState();
}

/// De teksten van dit scherm zelf, in de zes talen.
const _t = {
  'titel': {'nl': 'Handleiding', 'en': 'Guide', 'de': 'Anleitung', 'fr': 'Guide', 'es': 'Guía', 'pl': 'Przewodnik'},
  'intro': {
    'nl': 'Alles wat je met YessFish kunt, hoofdstuk voor hoofdstuk. Je kunt hem ook in je eigen app volgen.',
    'en': 'Everything you can do with YessFish, chapter by chapter. You can also follow it in your own app.',
    'de': 'Alles, was du mit YessFish kannst, Kapitel für Kapitel. Du kannst es auch in deiner App mitgehen.',
    'fr': 'Tout ce que tu peux faire avec YessFish, chapitre par chapitre. Tu peux aussi le suivre dans ton appli.',
    'es': 'Todo lo que puedes hacer con YessFish, capítulo a capítulo. También puedes seguirlo en tu propia app.',
    'pl': 'Wszystko, co możesz w YessFish, rozdział po rozdziale. Możesz też przejść to w swojej aplikacji.',
  },
  'stappen': {'nl': 'stappen', 'en': 'steps', 'de': 'Schritte', 'fr': 'étapes', 'es': 'pasos', 'pl': 'kroków'},
  'gedaan': {'nl': 'Gelezen', 'en': 'Read', 'de': 'Gelesen', 'fr': 'Lu', 'es': 'Leído', 'pl': 'Przeczytane'},
  'toon': {
    'nl': 'Laat het me zien in de app', 'en': 'Show me in the app', 'de': 'Zeig es mir in der App',
    'fr': 'Montre-moi dans l’appli', 'es': 'Muéstramelo en la app', 'pl': 'Pokaż mi w aplikacji',
  },
  'volgende': {'nl': 'Volgende', 'en': 'Next', 'de': 'Weiter', 'fr': 'Suivant', 'es': 'Siguiente', 'pl': 'Dalej'},
  'vorige': {'nl': 'Vorige', 'en': 'Back', 'de': 'Zurück', 'fr': 'Retour', 'es': 'Atrás', 'pl': 'Wstecz'},
  'klaar': {'nl': 'Klaar', 'en': 'Done', 'de': 'Fertig', 'fr': 'Terminé', 'es': 'Listo', 'pl': 'Gotowe'},
  'alles': {
    'nl': 'Alle hoofdstukken achter elkaar', 'en': 'All chapters in a row', 'de': 'Alle Kapitel nacheinander',
    'fr': 'Tous les chapitres à la suite', 'es': 'Todos los capítulos seguidos', 'pl': 'Wszystkie rozdziały po kolei',
  },
};

String _tt(BuildContext c, String sleutel) {
  final taal = Provider.of<I18n>(c, listen: false).locale;
  final m = _t[sleutel]!;
  return m[taal] ?? m['en']!;
}

/// Waar de schermafbeelding van een stap staat. Op de server, zodat we hem kunnen bijwerken
/// zonder een nieuwe app-versie; de app bewaart hem daarna in zijn eigen buffer.
/// Versie van de afbeeldingen. Bijwerken we de plaatjes, dan moet dit mee omhoog: anders blijft
/// de app zijn eigen buffer tonen en ziet een lid maanden later nog het oude scherm
/// (gemeten 21-09-2026: nieuwe afdruk stond er, app toonde de oude).
const handleidingVersie = '20260921';

String beeldVan(String stapId) =>
    '${Config.origin}/uploads/handleiding/app/$stapId.webp?v=$handleidingVersie';

class _HandleidingScreenState extends State<HandleidingScreen> {
  Set<String> _gelezen = {};

  @override
  void initState() {
    super.initState();
    Api.get('/tour').then((r) {
      if (!mounted) return;
      final c = r is Map ? r['chapters'] : null;
      if (c is List) setState(() => _gelezen = c.map((e) => '$e').toSet());
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final taal = Provider.of<I18n>(context).locale;
    return Scaffold(
      appBar: AppBar(title: Text(_tt(context, 'titel'))),
      body: ListView(
        padding: const EdgeInsets.all(14) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom),
        children: [
          Text(_tt(context, 'intro'), style: const TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.35)),
          const SizedBox(height: 12),
          // Wie liever door zijn eigen app loopt kan dat nog steeds.
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(context); Rondleiding.start(context); },
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: Text(_tt(context, 'alles')),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < hoofdstukken.length; i++) _hoofdstukTegel(context, taal, i),
        ],
      ),
    );
  }

  Widget _hoofdstukTegel(BuildContext context, String taal, int i) {
    final h = hoofdstukken[i];
    final klaar = _gelezen.contains(h.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(h.icoon, style: const TextStyle(fontSize: 26)),
        title: Text(tl(h.naam, taal), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tl(h.samenvatting, taal), style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 3),
          Text('${i + 1} · ${h.stappen.length} ${_tt(context, 'stappen')}'
              '${klaar ? ' · ${_tt(context, 'gedaan')} ✓' : ''}',
              style: TextStyle(fontSize: 11, color: klaar ? AppColors.teal : Colors.black38)),
        ]),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => _HoofdstukScherm(hoofdstuk: h))),
      ),
    );
  }
}

/// Eén hoofdstuk: blader door de stappen met de afbeelding erbij.
class _HoofdstukScherm extends StatefulWidget {
  const _HoofdstukScherm({required this.hoofdstuk});
  final Hoofdstuk hoofdstuk;

  @override
  State<_HoofdstukScherm> createState() => _HoofdstukSchermState();
}

class _HoofdstukSchermState extends State<_HoofdstukScherm> {
  final _pager = PageController();
  int _i = 0;

  @override
  void dispose() { _pager.dispose(); super.dispose(); }

  /// Deze ene stap in de échte app laten doen.
  ///
  /// Niet de hele rondleiding starten: dan loopt die vrolijk verder en heeft het lid nog steeds
  /// niets zelf ingedrukt. Nu komt hij op het echte scherm, licht de knop op, en moet hij hem
  /// zelf aantikken (Richard 21-09-2026: "maar dan moeten ze het wel doen he").
  void _toonInApp() {
    final stap = widget.hoofdstuk.stappen[_i];
    Navigator.popUntil(context, (r) => r.isFirst);
    Rondleiding.losseStap(context, stap.id);
  }

  @override
  Widget build(BuildContext context) {
    final taal = Provider.of<I18n>(context).locale;
    final stappen = widget.hoofdstuk.stappen;
    final laatste = _i >= stappen.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.hoofdstuk.icoon} ${tl(widget.hoofdstuk.naam, taal)}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_i + 1) / stappen.length, minHeight: 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(AppColors.mint),
          ),
        ),
      ),
      body: Column(children: [
        Expanded(child: PageView.builder(
          controller: _pager,
          itemCount: stappen.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => _stapBlad(stappen[i], taal, i, stappen.length),
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: Row(children: [
            TextButton.icon(
              onPressed: _toonInApp,
              icon: const Icon(Icons.open_in_new, size: 17),
              label: Text(_tt(context, 'toon'), style: const TextStyle(fontSize: 12.5)),
            ),
            const Spacer(),
            if (_i > 0) TextButton(
              onPressed: () => _pager.previousPage(
                  duration: const Duration(milliseconds: 220), curve: Curves.easeOut),
              child: Text(_tt(context, 'vorige')),
            ),
            const SizedBox(width: 4),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () {
                if (laatste) {
                  Navigator.pop(context);
                } else {
                  _pager.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
                }
              },
              child: Text(_tt(context, laatste ? 'klaar' : 'volgende')),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _stapBlad(Stap s, String taal, int i, int totaal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // De schermafbeelding. Ontbreekt er eentje, dan tonen we gewoon de tekst — nooit een
        // kapot plaatje of een lege plek.
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: beeldVan(s.id),
            fit: BoxFit.contain,
            placeholder: (_, __) => const AspectRatio(
                aspectRatio: 0.62,
                child: ColoredBox(color: Color(0xFFECF1F4),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)))),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(tl(s.titel, taal),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy))),
          Text('${i + 1}/$totaal', style: const TextStyle(fontSize: 12, color: Colors.black38)),
        ]),
        const SizedBox(height: 6),
        Text(tl(s.tekst, taal), style: const TextStyle(fontSize: 14.5, height: 1.45)),
      ]),
    );
  }
}
