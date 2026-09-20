import 'package:flutter/material.dart';
import '../core/api.dart';
import '../widgets/streak_card.dart';
import '../core/config.dart';
import '../core/location.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/rondleiding.dart';

class BiteScreen extends StatefulWidget {
  /// Zonder plek gebruikt dit scherm je GPS. Kom je vanaf een water op de kaart, dan geef je die
  /// plek mee — dan zie je de bijtkans van dát water, net als /vistijden?lat=..&lng=.. op het web.
  const BiteScreen({super.key, this.lat, this.lng, this.plaats});
  final double? lat;
  final double? lng;
  final String? plaats;

  @override
  State<BiteScreen> createState() => _BiteScreenState();
}

class _BiteScreenState extends State<BiteScreen> {
  /// Welke factor staat opengeklapt; null = geen. Eén tegelijk, net als op het web.
  String? _openFactor;

  Map? _data;
  Map? _sol;
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      double lat, lng;
      if (widget.lat != null && widget.lng != null) {
        lat = widget.lat!;
        lng = widget.lng!;
      } else {
        final loc = await currentLocation();
        lat = loc.lat;
        lng = loc.lng;
      }
      final r = await Api.get('/bite-forecast?lat=$lat&lng=$lng');
      Map? sol;
      try { sol = await Api.get('/solunar?lat=$lat&lng=$lng') as Map?; } catch (_) {}
      setState(() { _data = r; _sol = sol; _loading = false; });
      StreakData.load(force: true);   // bijtkans bekeken = reeks-dag → balk direct bijwerken
    } catch (e) {
      setState(() { _err = 'error'; _loading = false; });
    }
  }

  static const _moonKeys = {
    'new': 'bite.moon_new', 'waxing_crescent': 'bite.moon_waxing_crescent', 'first_quarter': 'bite.moon_first_quarter',
    'waxing_gibbous': 'bite.moon_waxing_gibbous', 'full': 'bite.moon_full', 'waning_gibbous': 'bite.moon_waning_gibbous',
    'last_quarter': 'bite.moon_last_quarter', 'waning_crescent': 'bite.moon_waning_crescent',
  };
  String _moonName(String? phase) { final k = _moonKeys[phase]; return k != null ? context.tr(k) : context.tr('bite.moon'); }

  Color _labelColor(String? l) {
    switch (l) {
      case 'top': return const Color(0xFF16A34A);
      case 'good': return const Color(0xFF65A30D);
      case 'ok': return const Color(0xFFCA8A04);
      default: return const Color(0xFF9CA3AF);
    }
  }

  Widget _solItem(IconData ic, String label, String value) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(ic, color: AppColors.teal, size: 22), const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black45), textAlign: TextAlign.center),
  ]);

  String _labelNl(String? l) { final k = {'top': 'bite.label_top', 'good': 'bite.label_good', 'ok': 'bite.label_ok', 'poor': 'bite.label_poor'}[l]; return k != null ? context.tr(k) : ''; }
  String _factorNl(String k) { final key = {'solunar': 'bite.factor_solunar', 'pressure': 'bite.factor_pressure', 'wind': 'bite.factor_wind', 'clouds': 'bite.factor_clouds', 'history': 'bite.factor_history', 'community': 'bite.factor_community'}[k]; return key != null ? context.tr(key) : k; }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(context.tr('bite.load_error')), TextButton(onPressed: _load, child: Text(context.tr('bite.retry')))]));
    final d = _data!;
    final score = d['score'] ?? 0;
    final color = _labelColor(d['label']);
    final factors = (d['factors'] ?? []) as List;
    final windows = (d['best_windows'] ?? []) as List;
    final species = (d['species'] ?? []) as List;
    final weather = d['weather'] as Map?;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text(context.tr('bite.today'), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12), border: Border.all(color: color, width: 4)),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$score', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: color)),
              const Text('/100', style: TextStyle(color: Colors.black45)),
            ])),
          const SizedBox(height: 10),
          Text(_labelNl(d['label']), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          if (weather != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('${weather['pressure_hpa']} hPa · ${(weather['wind_speed_ms'] as num?)?.round()} m/s · ${weather['clouds_pct']}% ${context.tr('bite.clouds')}', style: const TextStyle(color: Colors.black45, fontSize: 12))),
        ]))),
        if (_sol != null && (_sol!['sun'] != null || _sol!['moon'] != null)) ...[
          const SizedBox(height: 14),
          Text(context.tr('bite.sun_moon'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _solItem(Icons.wb_sunny_outlined, context.tr('bite.sunrise'), _sol!['sun']?['rise']?.toString() ?? '—'),
            _solItem(Icons.nightlight_outlined, context.tr('bite.sunset'), _sol!['sun']?['set']?.toString() ?? '—'),
            _solItem(Icons.brightness_3, _moonName(_sol!['moon']?['phase']), _sol!['moon']?['illumination'] != null ? '${((_sol!['moon']['illumination'] as num) * (((_sol!['moon']['illumination'] as num) <= 1) ? 100 : 1)).round()}%' : '—'),
          ]))),
        ],
        const SizedBox(height: 14),
        Text(context.tr('bite.factors'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        TourAnker(id: 'bijt-factoren', child: Column(children: [...factors.map((f) {
          final s = (f['score'] ?? 0) as int;
          final sleutel = '${f['key']}';
          final uitleg = kFactorUitleg[sleutel]?[Provider.of<I18n>(context, listen: false).locale]
              ?? kFactorUitleg[sleutel]?['en'];
          final open = _openFactor == sleutel;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Tikken opent de uitleg, net als op het web. Het cijfer alleen zegt te weinig.
            InkWell(
              onTap: uitleg == null ? null : () => setState(() => _openFactor = open ? null : sleutel),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
                SizedBox(width: 96, child: Row(children: [
                  Flexible(child: Text(_factorNl(f['key']), style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  if (uitleg != null) Icon(open ? Icons.expand_less : Icons.expand_more, size: 15, color: Colors.black38),
                ])),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: s / 100, minHeight: 10, backgroundColor: const Color(0xFFE5E7EB), color: AppColors.teal))),
                SizedBox(width: 64, child: Text(' ${f['detail'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.black45), overflow: TextOverflow.ellipsis)),
              ])),
            ),
            if (open && uitleg != null) Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Text(uitleg, style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF475569))),
              ),
            ),
          ]);
        })])),
        const SizedBox(height: 16),
        if (windows.isNotEmpty)
          TourAnker(id: 'bijt-periodes', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('bite.windows'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          ...windows.map((w) => Card(child: ListTile(
            dense: true,
            leading: Icon(w['type'] == 'major' ? Icons.star : Icons.star_border, color: AppColors.teal),
            title: Text('${w['start']} – ${w['end']}'),
            subtitle: Text(w['type'] == 'major' ? context.tr('bite.window_major') : context.tr('bite.window_minor')),
          ))),
        ])),
        if (species.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(context.tr('bite.likely_species'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: species.map<Widget>((s) => Chip(label: Text('$s'), backgroundColor: Colors.white)).toList()),
        ],
        const SizedBox(height: 16),
        Text(context.tr('bite.disclaimer'),
          style: const TextStyle(color: Colors.black38, fontSize: 12)),
      ]),
    );
  }
}

/// Uitleg per bijtkans-factor, letterlijk gelijk aan het web.
///
/// Het cijfer alleen zegt een lid weinig: "In de buurt 40%" roept vooral de vraag op wat dat
/// betekent. Deze teksten komen één op één uit de webversie, zodat app en site hetzelfde
/// uitleggen (Richard 17/19-09-2026).
const Map<String, Map<String, String>> kFactorUitleg = {
  'solunar': {'nl': 'Zon en maan bepalen de bijtmomenten: rond op- en ondergang en bij nieuwe of volle maan wordt er meer gevangen.', 'en': 'Sun and moon drive the bite: around rise and set and at new or full moon more fish are caught.', 'de': 'Sonne und Mond bestimmen die Beißzeiten: um Auf- und Untergang und bei Neu- oder Vollmond wird mehr gefangen.', 'fr': 'Le soleil et la lune rythment les touches : autour du lever et du coucher et à la nouvelle ou pleine lune, ça mord davantage.', 'es': 'El sol y la luna marcan las picadas: cerca del orto y el ocaso y en luna nueva o llena se pesca más.', 'pl': 'Słońce i księżyc wyznaczają brania: przy wschodzie i zachodzie oraz przy nowiu i pełni łowi się więcej.'},
  'pressure': {'nl': 'Vis reageert op luchtdruk. Een stabiele of licht dalende druk is meestal beter dan een snel stijgende.', 'en': 'Fish react to air pressure. Steady or slightly falling is usually better than fast rising.', 'de': 'Fische reagieren auf Luftdruck. Stabil oder leicht fallend ist meist besser als schnell steigend.', 'fr': 'Le poisson réagit à la pression. Stable ou en légère baisse vaut mieux qu’une hausse rapide.', 'es': 'El pez reacciona a la presión. Estable o bajando un poco suele ser mejor que subiendo rápido.', 'pl': 'Ryby reagują na ciśnienie. Stabilne lub lekko spadające jest zwykle lepsze niż szybko rosnące.'},
  'wind': {'nl': 'Wat wind zet het water in beweging en brengt voedsel naar de oever; windstil en keihard zijn allebei minder.', 'en': 'Some wind stirs the water and pushes food to the bank; dead calm and a gale are both worse.', 'de': 'Etwas Wind bewegt das Wasser und treibt Futter ans Ufer; Flaute und Sturm sind beide schlechter.', 'fr': 'Un peu de vent brasse l’eau et pousse la nourriture vers la berge ; le calme plat et la tempête sont moins bons.', 'es': 'Algo de viento mueve el agua y lleva comida a la orilla; la calma total y el vendaval son peores.', 'pl': 'Lekki wiatr porusza wodę i spycha pokarm do brzegu; cisza i wichura są gorsze.'},
  'clouds': {'nl': 'Bewolking geeft dekking. Veel vis staat bij bewolkt weer actiever en ondieper dan bij felle zon.', 'en': 'Cloud gives cover. Many fish are more active and shallower under cloud than in bright sun.', 'de': 'Wolken geben Deckung. Viele Fische sind bei bewölktem Wetter aktiver und flacher unterwegs.', 'fr': 'Les nuages donnent du couvert. Beaucoup de poissons sont plus actifs et moins profonds par temps couvert.', 'es': 'Las nubes dan cobertura. Muchos peces están más activos y menos profundos con cielo cubierto.', 'pl': 'Chmury dają osłonę. Przy zachmurzeniu ryby są aktywniejsze i płycej.'},
  'history': {'nl': 'Jouw eigen vangsten: hoe vaak jij in deze maand ving, vergeleken met je gemiddelde over het jaar. Pas zichtbaar vanaf 3 vangsten.', 'en': 'Your own catches: how often you caught in this month compared with your yearly average. Shown from 3 catches.', 'de': 'Deine eigenen Fänge: wie oft du in diesem Monat gefangen hast im Vergleich zu deinem Jahresschnitt. Ab 3 Fängen sichtbar.', 'fr': 'Tes propres prises : combien tu as pris ce mois-ci par rapport à ta moyenne annuelle. Visible à partir de 3 prises.', 'es': 'Tus propias capturas: cuántas hiciste este mes frente a tu media anual. Visible a partir de 3 capturas.', 'pl': 'Twoje połowy: ile złowiłeś w tym miesiącu w porównaniu ze średnią roczną. Widoczne od 3 połowów.'},
  'community': {'nl': 'Openbare vangsten van andere leden binnen 25 kilometer, deze maand. Vangsten bij vergelijkbaar weer wegen extra mee. Namen zie je niet.', 'en': 'Public catches by other members within 25 kilometres this month. Catches in similar weather count extra. You never see names.', 'de': 'Öffentliche Fänge anderer Mitglieder im Umkreis von 25 Kilometern in diesem Monat. Fänge bei ähnlichem Wetter zählen extra. Namen siehst du nie.', 'fr': 'Prises publiques d’autres membres dans un rayon de 25 kilomètres ce mois-ci. Les prises par météo comparable comptent davantage. Aucun nom affiché.', 'es': 'Capturas públicas de otros miembros en 25 kilómetros a la redonda este mes. Las capturas con tiempo parecido cuentan más. Nunca ves nombres.', 'pl': 'Publiczne połowy innych członków w promieniu 25 kilometrów w tym miesiącu. Połowy przy podobnej pogodzie liczą się bardziej. Nie widzisz nazwisk.'},
};
