import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/location.dart';
import '../core/rondleiding.dart';

/// "Houd je visplek schoon": je meldt je aan bij je plek met een foto vóóraf en sluit af
/// met een foto ná afloop. Laat je de plek netjes achter, dan levert dat punten/dobbers
/// en de badge Schone Stek op.
///
/// De foto's MOETEN ter plekke met de camera gemaakt worden (nooit uit de galerij):
/// anders kan iemand een oude of andermans foto insturen en is de hele controle waardeloos.
class SchoneStekScreen extends StatefulWidget {
  const SchoneStekScreen({super.key});
  @override
  State<SchoneStekScreen> createState() => _SchoneStekScreenState();
}

/// Taalhelper: alle teksten staan als Map-literal in dit bestand, dus we raken de
/// gedeelde vertaalbestanden niet aan.
String _t(BuildContext c, Map<String, String> m) {
  final l = c.read<I18n>().locale;
  return m[l] ?? m['en'] ?? m['nl'] ?? '';
}

class _SchoneStekScreenState extends State<SchoneStekScreen> {
  bool _laden = true;
  bool _bezig = false; // foto maken / uploaden / versturen
  String? _laadfout;

  Map<String, dynamic>? _open; // lopende sessie, of null
  int _schoonTotaal = 0;
  int _puntenTotaal = 0;
  int _puntenMax = 0;
  int _wachtOpControle = 0;
  List<dynamic> _badges = const [];
  Map<String, dynamic> _regels = const {};

  @override
  void initState() {
    super.initState();
    _haalStand();
  }

  Future<void> _haalStand() async {
    if (mounted) setState(() { _laden = true; _laadfout = null; });
    try {
      final r = await Api.get('/plek');
      if (!mounted) return;
      setState(() {
        if (r is Map) {
          _open = r['open'] is Map ? Map<String, dynamic>.from(r['open'] as Map) : null;
          _schoonTotaal = (r['schoon_totaal'] as num?)?.toInt() ?? 0;
          _puntenTotaal = (r['punten_totaal'] as num?)?.toInt() ?? 0;
          _puntenMax = (r['punten_max'] as num?)?.toInt() ?? 0;
          _wachtOpControle = (r['wacht_op_controle'] as num?)?.toInt() ?? 0;
          _badges = r['badges'] is List ? (r['badges'] as List) : const [];
          _regels = r['regels'] is Map ? Map<String, dynamic>.from(r['regels'] as Map) : const {};
        }
        _laden = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _laden = false; _laadfout = e.message; });
    } catch (_) {
      if (mounted) setState(() { _laden = false; _laadfout = _t(context, _lGeenVerbinding); });
    }
  }

  void _melding(String tekst) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tekst)));
  }

  /// Zelfde melding, maar met een eigen tekst-map: het vertalen gebeurt hier, ná de
  /// mounted-controle, zodat we nooit een weggehaald scherm aanspreken.
  void _meldT(Map<String, String> m) {
    if (!mounted) return;
    _melding(_t(context, m));
  }

  /// Foto MAKEN — uitsluitend met de camera. Geen galerij-optie, ook niet als terugval:
  /// de controle staat of valt met een foto die hier en nu gemaakt is.
  /// Geeft het geüploade pad terug, of null (geannuleerd of geen toestemming; dat laatste
  /// leggen we uit in plaats van stil te falen).
  Future<String?> _maakEnUploadFoto() async {
    XFile? opname;
    try {
      opname = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 92);
    } on PlatformException catch (e) {
      _meldT(e.code == 'camera_access_denied' ? _lGeenCamToestemming : _lCameraMislukt);
      return null;
    } catch (_) {
      _meldT(_lCameraMislukt);
      return null;
    }
    if (opname == null) return null; // lid heeft geannuleerd — geen melding nodig

    try {
      final bestand = await _verklein(opname.path);
      final up = await Api.uploadImage(bestand);
      return up['path']?.toString();
    } on ApiException catch (e) {
      _melding(e.message);
    } catch (_) {
      _meldT(_lUploadMislukt);
    }
    return null;
  }

  Future<String> _verklein(String pad) async {
    try {
      final map = await getTemporaryDirectory();
      final doel = '${map.path}/yf_stek_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final uit = await FlutterImageCompress.compressAndGetFile(pad, doel, minWidth: 1600, minHeight: 1600, quality: 85);
      return uit?.path ?? pad;
    } catch (_) {
      return pad;
    }
  }

  /// Locatie ophalen. Zonder echte fix kan de server niet controleren of de vertrekfoto op
  /// dezelfde plek is gemaakt, dus dan stoppen we met uitleg in plaats van stil door te gaan.
  Future<LatLng?> _haalLocatie() async {
    try {
      final l = await currentLocation();
      if (l.isReal) return l;
    } catch (_) {}
    _meldT(_lGeenLocatie);
    return null;
  }

  Future<void> _startSessie() async {
    if (_bezig) return;
    final plek = await _haalLocatie();
    if (plek == null) return;
    final foto = await _maakEnUploadFoto();
    if (foto == null) return;

    setState(() => _bezig = true);
    try {
      final r = await Api.post('/plek/start', {
        'photo_path': foto,
        'latitude': plek.lat,
        'longitude': plek.lng,
      });
      final vuil = r is Map ? r['vuil_bij_start'] == true : false;
      _meldT(vuil ? _lGestartVuil : _lGestart);
      await _haalStand();
    } on ApiException catch (e) {
      _melding(e.message);
    } catch (_) {
      _meldT(_lGeenVerbinding);
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  Future<void> _sluitAf() async {
    if (_bezig || _open == null) return;
    final id = _open!['id'];
    // Vooraf vertalen: ná het maken/versturen van de foto mogen we de context niet meer aanspreken.
    final sjabloonWacht = _t(context, _lNogMinuten);
    final plek = await _haalLocatie();
    if (plek == null) return;
    final foto = await _maakEnUploadFoto();
    if (foto == null) return;

    setState(() => _bezig = true);
    try {
      final r = await Api.post('/plek/$id/eind', {
        'photo_path': foto,
        'latitude': plek.lat,
        'longitude': plek.lng,
      });
      if (r is Map) {
        final melding = r['message']?.toString();
        final punten = (r['punten'] as num?)?.toInt() ?? 0;
        if (melding == null || melding.isEmpty) {
          _meldT(_lAfgerond);
        } else {
          _melding(punten > 0 ? '$melding (+$punten)' : melding);
        }
      }
      await _haalStand();
    } on ApiException catch (e) {
      // plek_te_snel geeft mee hoeveel minuten er nog te gaan zijn — dat helpt meer dan alleen "te snel".
      final nog = (e.data is Map ? e.data['wacht_nog'] : null) as num?;
      _melding(nog == null ? e.message : '${e.message} (${sjabloonWacht.replaceFirst('{n}', '${nog.toInt()}')})');
    } catch (_) {
      _meldT(_lGeenVerbinding);
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(_t(context, _lTitel))),
      body: RefreshIndicator(
        onRefresh: _haalStand,
        child: _laden
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
                children: [
                  if (_laadfout != null) _foutBlok(),
                  TourAnker(id: 'schoon-uitleg', child: _uitlegBlok()),
                  const SizedBox(height: 12),
                  _open != null ? _lopendeSessieBlok() : _startBlok(),
                  const SizedBox(height: 12),
                  _standBlok(),
                  const SizedBox(height: 12),
                  TourAnker(id: 'stek-schoon-badges', child: _badgeBlok()),
                  const SizedBox(height: 12),
                  _regelBlok(),
                ],
              ),
      ),
    );
  }

  Widget _kaart({required Widget child, Color? kleur}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kleur ?? Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _foutBlok() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _kaart(
          kleur: AppColors.danger.withValues(alpha: 0.08),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(_laadfout!, style: const TextStyle(fontSize: 13))),
            TextButton(onPressed: _haalStand, child: Text(_t(context, _lOpnieuw))),
          ]),
        ),
      );

  Widget _uitlegBlok() => _kaart(
        kleur: AppColors.teal.withValues(alpha: 0.09),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🧹', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(_t(context, _lKop),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy, fontSize: 15))),
          ]),
          const SizedBox(height: 8),
          Text(_t(context, _lUitleg), style: const TextStyle(fontSize: 13, height: 1.35)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.photo_camera, size: 16, color: AppColors.teal2),
            const SizedBox(width: 6),
            // Waarom alleen camera: dit is precies de vraag die leden stellen.
            Expanded(child: Text(_t(context, _lWaaromCamera),
                style: const TextStyle(fontSize: 12.5, color: AppColors.teal2, height: 1.3))),
          ]),
        ]),
      );

  Widget _startBlok() => _kaart(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, _lStapEen), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 6),
          Text(_t(context, _lStapEenUitleg), style: const TextStyle(fontSize: 13, height: 1.35)),
          const SizedBox(height: 12),
          TourAnker(
            id: 'stek-schoon-start',
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _bezig ? null : _startSessie,
                icon: _bezig
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.photo_camera),
                label: Text(_t(context, _lStartKnop)),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
        ]),
      );

  Widget _lopendeSessieBlok() {
    final wachtNog = (_open?['mag_afsluiten_over'] as num?)?.toInt() ?? 0;
    final vuil = _open?['vuil_bij_start'];
    final gestart = DateTime.tryParse('${_open?['start_at'] ?? ''}')?.toLocal();
    final klaar = wachtNog <= 0;

    return _kaart(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.hourglass_bottom, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(_t(context, _lLoopt),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy))),
        ]),
        const SizedBox(height: 8),
        if (gestart != null)
          Text('${_t(context, _lAangekomen)} ${_tweeCijfers(gestart.hour)}:${_tweeCijfers(gestart.minute)}',
              style: const TextStyle(fontSize: 13)),
        if (vuil == true) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_t(context, _lVuilGezien), style: const TextStyle(fontSize: 12.5, color: AppColors.accent, height: 1.3)),
        ),
        const SizedBox(height: 10),
        Text(klaar ? _t(context, _lStapTweeUitleg) : _t(context, _lNogWachten).replaceFirst('{n}', '$wachtNog'),
            style: const TextStyle(fontSize: 13, height: 1.35)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (_bezig || !klaar) ? null : _sluitAf,
            icon: _bezig
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.photo_camera),
            label: Text(_t(context, _lEindKnop)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy2, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }

  String _tweeCijfers(int n) => n < 10 ? '0$n' : '$n';

  Widget _standBlok() => _kaart(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, _lJouwStand), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 10),
          Row(children: [
            _getal('$_schoonTotaal', _t(context, _lSchoneStekken)),
            _getal(_puntenMax > 0 ? '$_puntenTotaal/$_puntenMax' : '$_puntenTotaal', _t(context, _lPunten)),
            _getal('$_wachtOpControle', _t(context, _lInControle)),
          ]),
        ]),
      );

  Widget _getal(String waarde, String label) => Expanded(
        child: Column(children: [
          Text(waarde, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        ]),
      );

  Widget _badgeBlok() => _kaart(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, _lBadges), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 10),
          if (_badges.isEmpty)
            Text(_t(context, _lNogGeenBadge), style: const TextStyle(fontSize: 13, height: 1.35))
          else
            ..._badges.map((b) => _badgeRegel(Map<String, dynamic>.from(b as Map))),
        ]),
      );

  Widget _badgeRegel(Map<String, dynamic> b) {
    final niveau = (b['niveau'] as num?)?.toInt() ?? 1;
    final volgende = (b['volgende'] as num?)?.toInt();
    final aantal = (b['aantal'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _niveauKleur(niveau).withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Text('${b['icoon'] ?? '🏅'}', style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text('${b['naam'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _niveauKleur(niveau), borderRadius: BorderRadius.circular(20)),
              child: Text('${b['niveaunaam'] ?? ''}',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 2),
          Text('${b['uitleg'] ?? ''}', style: const TextStyle(fontSize: 12.5, height: 1.3, color: Colors.black87)),
          const SizedBox(height: 3),
          Text(
            volgende == null
                ? '${_t(context, _lAantalKeer).replaceFirst('{n}', '$aantal')} · ${_t(context, _lHoogste)}'
                : '${_t(context, _lAantalKeer).replaceFirst('{n}', '$aantal')} · ${_t(context, _lNogNodig).replaceFirst('{n}', '$volgende')}',
            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
        ])),
      ]),
    );
  }

  /// Brons / zilver / goud.
  Color _niveauKleur(int niveau) {
    switch (niveau) {
      case 3: return const Color(0xFFD4A017);
      case 2: return const Color(0xFF9AA5AD);
      default: return const Color(0xFFB07A3C);
    }
  }

  Widget _regelBlok() {
    final minMinuten = (_regels['min_minuten'] as num?)?.toInt();
    final maxMeter = (_regels['max_meter'] as num?)?.toInt();
    final perDag = (_regels['per_dag'] as num?)?.toInt();
    final pSchoon = (_regels['punten_schoon'] as num?)?.toInt();
    final pOpgeruimd = (_regels['punten_opgeruimd'] as num?)?.toInt();
    if (minMinuten == null && maxMeter == null && perDag == null) return const SizedBox.shrink();

    return _kaart(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t(context, _lSpelregels), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 8),
        if (minMinuten != null) _regel(_t(context, _lRegelTijd).replaceFirst('{n}', '$minMinuten')),
        if (maxMeter != null) _regel(_t(context, _lRegelAfstand).replaceFirst('{n}', '$maxMeter')),
        if (perDag != null) _regel(_t(context, _lRegelPerDag).replaceFirst('{n}', '$perDag')),
        if (pSchoon != null && pOpgeruimd != null)
          _regel(_t(context, _lRegelPunten).replaceFirst('{a}', '$pSchoon').replaceFirst('{b}', '$pOpgeruimd')),
      ]),
    );
  }

  Widget _regel(String tekst) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(color: AppColors.teal)),
          Expanded(child: Text(tekst, style: const TextStyle(fontSize: 12.5, height: 1.3))),
        ]),
      );
}

// ── Teksten (nl/en/de/fr/es/pl) ────────────────────────────────────────────────

const _lTitel = {'nl': 'Schone stek', 'en': 'Clean spot', 'de': 'Saubere Stelle', 'fr': 'Poste propre', 'es': 'Puesto limpio', 'pl': 'Czyste stanowisko'};
const _lKop = {'nl': 'Houd je visplek schoon', 'en': 'Keep your spot clean', 'de': 'Halte deinen Angelplatz sauber', 'fr': 'Garde ton poste propre', 'es': 'Mantén limpio tu puesto', 'pl': 'Utrzymaj stanowisko w czystości'};
const _lUitleg = {
  'nl': 'Meld je bij aankomst aan met een foto van je plek en maak bij vertrek nog een foto. Laat je de plek netjes achter, dan verdien je punten, dobbers en de badge Schone Stek. Zwerfvuil dat je aantreft en meeneemt telt dubbel.',
  'en': 'Check in on arrival with a photo of your spot and take a second photo when you leave. Leave it tidy and you earn points, bobbers and the Clean Spot badge. Litter you find and take with you counts double.',
  'de': 'Melde dich bei Ankunft mit einem Foto deiner Stelle an und mach beim Gehen ein zweites Foto. Hinterlässt du sie sauber, gibt es Punkte, Posen und die Badge Saubere Stelle. Gefundener Müll, den du mitnimmst, zählt doppelt.',
  'fr': "Enregistre-toi à l'arrivée avec une photo de ton poste et prends-en une autre au départ. Si tu laisses propre, tu gagnes des points, des flotteurs et le badge Poste propre. Les déchets que tu ramasses comptent double.",
  'es': 'Regístrate al llegar con una foto de tu puesto y haz otra al irte. Si lo dejas limpio ganas puntos, boyas y la insignia Puesto limpio. La basura que recoges cuenta doble.',
  'pl': 'Po przyjściu zamelduj się ze zdjęciem stanowiska, a przy wyjściu zrób drugie. Zostaw czysto, a zdobędziesz punkty, spławiki i odznakę Czyste stanowisko. Zebrane śmieci liczą się podwójnie.',
};
const _lWaaromCamera = {
  'nl': 'De foto maak je ter plekke met de camera — kiezen uit je galerij kan niet, anders zou een oude of andermans foto meetellen. Je locatie gaat mee, zodat beide foto’s van dezelfde plek zijn.',
  'en': 'You take the photo on the spot with the camera — picking from your gallery isn’t possible, otherwise an old or someone else’s photo could count. Your location is sent along so both photos are from the same place.',
  'de': 'Das Foto machst du vor Ort mit der Kamera — aus der Galerie wählen geht nicht, sonst würde ein altes oder fremdes Foto zählen. Dein Standort wird mitgeschickt, damit beide Fotos vom selben Platz sind.',
  'fr': "Tu prends la photo sur place avec l'appareil — impossible de choisir dans la galerie, sinon une vieille photo ou celle d'un autre compterait. Ta position est envoyée pour que les deux photos viennent du même endroit.",
  'es': 'La foto se hace en el sitio con la cámara — no se puede elegir de la galería, o contaría una foto antigua o de otra persona. Se envía tu ubicación para que ambas fotos sean del mismo lugar.',
  'pl': 'Zdjęcie robisz na miejscu aparatem — wyboru z galerii nie ma, inaczej liczyłoby się stare lub cudze zdjęcie. Wysyłamy Twoją lokalizację, by oba zdjęcia były z tego samego miejsca.',
};
const _lStapEen = {'nl': 'Stap 1 — aankomst', 'en': 'Step 1 — arrival', 'de': 'Schritt 1 — Ankunft', 'fr': 'Étape 1 — arrivée', 'es': 'Paso 1 — llegada', 'pl': 'Krok 1 — przyjście'};
const _lStapEenUitleg = {
  'nl': 'Maak nu een foto van je visplek, met het water erop.',
  'en': 'Take a photo of your spot now, with the water in view.',
  'de': 'Mach jetzt ein Foto von deiner Stelle, mit dem Wasser im Bild.',
  'fr': "Prends maintenant une photo de ton poste, avec l'eau dessus.",
  'es': 'Haz ahora una foto de tu puesto, con el agua a la vista.',
  'pl': 'Zrób teraz zdjęcie stanowiska, tak by widać było wodę.',
};
const _lStartKnop = {'nl': 'Aankomstfoto maken', 'en': 'Take arrival photo', 'de': 'Ankunftsfoto machen', 'fr': "Photo d'arrivée", 'es': 'Foto de llegada', 'pl': 'Zdjęcie na start'};
const _lEindKnop = {'nl': 'Vertrekfoto maken', 'en': 'Take departure photo', 'de': 'Abschiedsfoto machen', 'fr': 'Photo de départ', 'es': 'Foto de salida', 'pl': 'Zdjęcie na koniec'};
const _lLoopt = {'nl': 'Je plek staat open', 'en': 'Your spot is checked in', 'de': 'Deine Stelle ist angemeldet', 'fr': 'Ton poste est enregistré', 'es': 'Tu puesto está registrado', 'pl': 'Twoje stanowisko jest zgłoszone'};
const _lAangekomen = {'nl': 'Aangekomen om', 'en': 'Arrived at', 'de': 'Angekommen um', 'fr': 'Arrivée à', 'es': 'Llegada a las', 'pl': 'Przyjście o'};
const _lVuilGezien = {
  'nl': 'Bij aankomst lag er zwerfvuil. Neem je het mee, dan tellen je punten dubbel.',
  'en': 'There was litter on arrival. Take it with you and your points count double.',
  'de': 'Bei Ankunft lag Müll. Nimmst du ihn mit, zählen deine Punkte doppelt.',
  'fr': "Il y avait des déchets à l'arrivée. Ramasse-les et tes points comptent double.",
  'es': 'Había basura al llegar. Si te la llevas, tus puntos cuentan doble.',
  'pl': 'Na starcie leżały śmieci. Zabierz je, a punkty liczą się podwójnie.',
};
const _lStapTweeUitleg = {
  'nl': 'Stap 2 — ga je weg? Maak dan de vertrekfoto van dezelfde plek.',
  'en': 'Step 2 — leaving? Take the departure photo of the same spot.',
  'de': 'Schritt 2 — gehst du? Mach das Abschiedsfoto von derselben Stelle.',
  'fr': 'Étape 2 — tu pars ? Prends la photo de départ du même endroit.',
  'es': 'Paso 2 — ¿te vas? Haz la foto de salida del mismo sitio.',
  'pl': 'Krok 2 — wychodzisz? Zrób zdjęcie końcowe z tego samego miejsca.',
};
const _lNogWachten = {
  'nl': 'Je kunt over {n} minuten afsluiten — je moet er echt gevist hebben.',
  'en': 'You can finish in {n} minutes — you need to have actually fished here.',
  'de': 'Du kannst in {n} Minuten abschließen — du musst hier wirklich geangelt haben.',
  'fr': 'Tu peux terminer dans {n} minutes — il faut avoir vraiment pêché ici.',
  'es': 'Puedes finalizar en {n} minutos — debes haber pescado de verdad aquí.',
  'pl': 'Zakończysz za {n} minut — trzeba tu naprawdę łowić.',
};
const _lNogMinuten = {'nl': 'nog {n} min.', 'en': '{n} min. to go', 'de': 'noch {n} Min.', 'fr': 'encore {n} min', 'es': 'faltan {n} min', 'pl': 'jeszcze {n} min'};
const _lJouwStand = {'nl': 'Jouw stand', 'en': 'Your score', 'de': 'Dein Stand', 'fr': 'Ton bilan', 'es': 'Tu marcador', 'pl': 'Twój wynik'};
const _lSchoneStekken = {'nl': 'schone stekken', 'en': 'clean spots', 'de': 'saubere Stellen', 'fr': 'postes propres', 'es': 'puestos limpios', 'pl': 'czyste stanowiska'};
const _lPunten = {'nl': 'punten', 'en': 'points', 'de': 'Punkte', 'fr': 'points', 'es': 'puntos', 'pl': 'punkty'};
const _lInControle = {'nl': 'in controle', 'en': 'being checked', 'de': 'in Prüfung', 'fr': 'en contrôle', 'es': 'en revisión', 'pl': 'w sprawdzaniu'};
const _lBadges = {'nl': 'Badges', 'en': 'Badges', 'de': 'Abzeichen', 'fr': 'Badges', 'es': 'Insignias', 'pl': 'Odznaki'};
const _lNogGeenBadge = {
  'nl': 'Nog geen badge. Eén schone stek levert brons op, vijf zilver en tien goud.',
  'en': 'No badge yet. One clean spot earns bronze, five silver and ten gold.',
  'de': 'Noch kein Abzeichen. Eine saubere Stelle gibt Bronze, fünf Silber und zehn Gold.',
  'fr': "Pas encore de badge. Un poste propre donne le bronze, cinq l'argent et dix l'or.",
  'es': 'Aún sin insignia. Un puesto limpio da bronce, cinco plata y diez oro.',
  'pl': 'Brak odznaki. Jedno czyste stanowisko to brąz, pięć srebro, dziesięć złoto.',
};
const _lAantalKeer = {'nl': '{n}×', 'en': '{n}×', 'de': '{n}×', 'fr': '{n}×', 'es': '{n}×', 'pl': '{n}×'};
const _lNogNodig = {'nl': 'nog {n} voor het volgende niveau', 'en': '{n} more for the next level', 'de': 'noch {n} bis zur nächsten Stufe', 'fr': 'encore {n} pour le niveau suivant', 'es': '{n} más para el siguiente nivel', 'pl': 'jeszcze {n} do następnego poziomu'};
const _lHoogste = {'nl': 'hoogste niveau behaald', 'en': 'highest level reached', 'de': 'höchste Stufe erreicht', 'fr': 'niveau maximum atteint', 'es': 'nivel máximo alcanzado', 'pl': 'najwyższy poziom osiągnięty'};
const _lSpelregels = {'nl': 'Spelregels', 'en': 'How it works', 'de': 'Spielregeln', 'fr': 'Les règles', 'es': 'Las reglas', 'pl': 'Zasady'};
const _lRegelTijd = {'nl': 'Minimaal {n} minuten tussen beide foto’s.', 'en': 'At least {n} minutes between the two photos.', 'de': 'Mindestens {n} Minuten zwischen beiden Fotos.', 'fr': 'Au moins {n} minutes entre les deux photos.', 'es': 'Al menos {n} minutos entre las dos fotos.', 'pl': 'Co najmniej {n} minut między zdjęciami.'};
const _lRegelAfstand = {'nl': 'Beide foto’s binnen {n} meter van elkaar.', 'en': 'Both photos within {n} metres of each other.', 'de': 'Beide Fotos innerhalb von {n} Metern.', 'fr': 'Les deux photos à moins de {n} mètres.', 'es': 'Ambas fotos a menos de {n} metros.', 'pl': 'Oba zdjęcia w promieniu {n} metrów.'};
const _lRegelPerDag = {'nl': 'Maximaal {n} plek per dag.', 'en': 'At most {n} spot per day.', 'de': 'Höchstens {n} Stelle pro Tag.', 'fr': 'Au plus {n} poste par jour.', 'es': 'Como máximo {n} puesto al día.', 'pl': 'Maksymalnie {n} stanowisko dziennie.'};
const _lRegelPunten = {'nl': 'Schoon achtergelaten: {a} punt. Zwerfvuil meegenomen: {b} punten.', 'en': 'Left clean: {a} point. Litter taken along: {b} points.', 'de': 'Sauber hinterlassen: {a} Punkt. Müll mitgenommen: {b} Punkte.', 'fr': 'Laissé propre : {a} point. Déchets emportés : {b} points.', 'es': 'Dejado limpio: {a} punto. Basura recogida: {b} puntos.', 'pl': 'Zostawione czysto: {a} punkt. Zabrane śmieci: {b} punkty.'};
const _lGestart = {'nl': 'Aankomstfoto ontvangen — fijne visdag!', 'en': 'Arrival photo received — enjoy your session!', 'de': 'Ankunftsfoto erhalten — viel Spaß beim Angeln!', 'fr': "Photo d'arrivée reçue — bonne pêche !", 'es': 'Foto de llegada recibida — ¡buena pesca!', 'pl': 'Zdjęcie startowe odebrane — udanego łowienia!'};
const _lGestartVuil = {'nl': 'Aankomstfoto ontvangen. Er ligt zwerfvuil: neem je het mee, dan telt het dubbel.', 'en': 'Arrival photo received. There’s litter: take it with you and it counts double.', 'de': 'Ankunftsfoto erhalten. Es liegt Müll: nimmst du ihn mit, zählt es doppelt.', 'fr': "Photo d'arrivée reçue. Il y a des déchets : ramasse-les, ça compte double.", 'es': 'Foto de llegada recibida. Hay basura: si te la llevas, cuenta doble.', 'pl': 'Zdjęcie startowe odebrane. Są śmieci: zabierz je, liczy się podwójnie.'};
const _lAfgerond = {'nl': 'Vertrekfoto ontvangen.', 'en': 'Departure photo received.', 'de': 'Abschiedsfoto erhalten.', 'fr': 'Photo de départ reçue.', 'es': 'Foto de salida recibida.', 'pl': 'Zdjęcie końcowe odebrane.'};
const _lGeenCamToestemming = {
  'nl': 'De app mag je camera niet gebruiken. Zet camera-toegang aan bij de app-instellingen van je telefoon; de foto moet ter plekke gemaakt worden.',
  'en': 'The app isn’t allowed to use your camera. Enable camera access in your phone’s app settings; the photo has to be taken on the spot.',
  'de': 'Die App darf die Kamera nicht nutzen. Erlaube den Kamerazugriff in den App-Einstellungen; das Foto muss vor Ort entstehen.',
  'fr': "L'app n'a pas accès à la caméra. Active l'accès dans les réglages de l'app ; la photo doit être prise sur place.",
  'es': 'La app no puede usar la cámara. Activa el acceso en los ajustes de la app; la foto debe hacerse en el sitio.',
  'pl': 'Aplikacja nie ma dostępu do aparatu. Włącz go w ustawieniach aplikacji; zdjęcie musi powstać na miejscu.',
};
const _lCameraMislukt = {'nl': 'De camera kon niet worden geopend.', 'en': 'The camera could not be opened.', 'de': 'Die Kamera konnte nicht geöffnet werden.', 'fr': "Impossible d'ouvrir la caméra.", 'es': 'No se pudo abrir la cámara.', 'pl': 'Nie udało się otworzyć aparatu.'};
const _lUploadMislukt = {'nl': 'De foto kon niet worden verstuurd. Probeer het nog eens.', 'en': 'The photo could not be sent. Please try again.', 'de': 'Das Foto konnte nicht gesendet werden. Versuch es nochmal.', 'fr': "La photo n'a pas pu être envoyée. Réessaie.", 'es': 'No se pudo enviar la foto. Inténtalo de nuevo.', 'pl': 'Nie udało się wysłać zdjęcia. Spróbuj ponownie.'};
const _lGeenLocatie = {
  'nl': 'Geen GPS-locatie. Zet locatie aan en geef de app toestemming — we moeten kunnen zien dat beide foto’s van dezelfde plek zijn.',
  'en': 'No GPS location. Turn on location and allow the app — we need to see that both photos are from the same place.',
  'de': 'Kein GPS-Standort. Aktiviere den Standort und erlaube es der App — beide Fotos müssen von derselben Stelle sein.',
  'fr': "Pas de position GPS. Active la localisation et autorise l'app — les deux photos doivent venir du même endroit.",
  'es': 'Sin ubicación GPS. Activa la ubicación y da permiso a la app — ambas fotos deben ser del mismo lugar.',
  'pl': 'Brak lokalizacji GPS. Włącz lokalizację i zezwól aplikacji — oba zdjęcia muszą być z tego samego miejsca.',
};
const _lGeenVerbinding = {'nl': 'Geen verbinding. Probeer het later nog eens.', 'en': 'No connection. Please try again later.', 'de': 'Keine Verbindung. Versuch es später nochmal.', 'fr': 'Pas de connexion. Réessaie plus tard.', 'es': 'Sin conexión. Inténtalo más tarde.', 'pl': 'Brak połączenia. Spróbuj później.'};
const _lOpnieuw = {'nl': 'Opnieuw', 'en': 'Retry', 'de': 'Erneut', 'fr': 'Réessayer', 'es': 'Reintentar', 'pl': 'Ponów'};
