import 'dart:typed_data';
import '../core/rondleiding.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/documenten_i18n.dart';

/// Je visdocumenten: VISpas, vergunning of permit — met geldigheid en een foto van je pas.
///
/// Dit is de app-kant van /visdocumenten op de site en doet bewust hetzelfde: negen soorten
/// documenten, op wiens naam, uitgevende instantie, geldig van/tot, notities, en per document een
/// foto van de voor- en achterkant. Juist op de telefoon heb je de camera én je pas bij je, dus
/// hier hoort de app niet minder te kunnen dan het web (Richard 20-09-2026).
///
/// De foto's staan in een afgeschermde map op de server: ze komen nooit in de feed, andere leden
/// zien ze niet, en ze zijn alleen met je eigen inlog op te halen. Daarom halen we ze hier met de
/// ingelogde verbinding op en tonen we ze uit het geheugen.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});
  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

enum _Stand { geldig, binnenkort, verlopen, geen }

_Stand _standVan(String? tot) {
  if (tot == null || tot.isEmpty) return _Stand.geen;
  final d = DateTime.tryParse(tot);
  if (d == null) return _Stand.geen;
  final nu = DateTime.now();
  if (d.isBefore(nu)) return _Stand.verlopen;
  if (d.isBefore(nu.add(const Duration(days: 30)))) return _Stand.binnenkort;
  return _Stand.geldig;
}

class _LicensesScreenState extends State<LicensesScreen> {
  List _lijst = [];
  bool _laden = true;
  bool _fout = false;

  @override
  void initState() {
    super.initState();
    _laad();
  }

  Future<void> _laad() async {
    if (mounted) setState(() => _fout = false);
    try {
      final r = await Api.get('/licenses');
      if (!mounted) return;
      setState(() {
        _lijst = r is List ? r : (r is Map ? (r['data'] ?? []) : []);
        _laden = false;
      });
    } catch (_) {
      if (mounted) setState(() { _laden = false; _fout = true; });
    }
  }

  void _melding(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e is ApiException ? e.message : dt(context, 'lic.none'))),
    );
  }

  Future<void> _bewerk([Map? bestaand]) async {
    final opgeslagen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DocumentBlad(document: bestaand),
    );
    if (opgeslagen == true) _laad();
  }

  Future<void> _verwijder(Map l) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      scrollable: true,
      content: Text(dt(c, 'lic.confirm_delete')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(dt(c, 'lic.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(dt(c, 'lic.save'))),
      ],
    ));
    if (ok != true) return;
    try {
      await Api.delete('/licenses/${l['id']}');
      _laad();
    } catch (e) {
      _melding(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dt(context, 'lic.title'))),
      floatingActionButton: TourAnker(id: 'documenten-add', child: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        onPressed: () => _bewerk(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(dt(context, 'lic.add'), style: const TextStyle(color: Colors.white)),
      )),
      body: _laden
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _laad, child: ListView(
              padding: const EdgeInsets.all(12) + EdgeInsets.only(bottom: 88 + MediaQuery.of(context).padding.bottom),
              children: [
                Text(dt(context, 'lic.subtitle'), style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black54)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.shield_outlined, size: 17, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(dt(context, 'lic.disclaimer'),
                        style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF78350F)))),
                  ]),
                ),
                if (_fout) Padding(padding: const EdgeInsets.only(top: 16),
                    child: Center(child: TextButton(onPressed: _laad, child: Text(dt(context, 'lic.add'))))),
                if (_lijst.isNotEmpty) _overzicht(context),
                if (_lijst.isEmpty && !_fout)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [
                    const Icon(Icons.badge_outlined, size: 34, color: Colors.black26),
                    const SizedBox(height: 8),
                    Text(dt(context, 'lic.none'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)),
                  ])),
                for (final l in _lijst) _kaart(context, l as Map),
              ],
            )),
    );
  }

  /// Wat heb je, in welke landen, en wat moet je binnenkort verlengen?
  Widget _overzicht(BuildContext c) {
    final landen = <String>{for (final l in _lijst) '${(l as Map)['country']}'};
    final binnenkort = _lijst.where((l) => _standVan((l as Map)['valid_until'] as String?) == _Stand.binnenkort).length;
    final verlopen = _lijst.where((l) => _standVan((l as Map)['valid_until'] as String?) == _Stand.verlopen).length;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dt(c, 'lic.overzicht').toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4, color: Colors.black38)),
          const SizedBox(height: 4),
          Text(dt(c, 'lic.overzicht_sub').replaceFirst('%d', '${_lijst.length}').replaceFirst('%d', '${landen.length}'),
              style: const TextStyle(fontSize: 14, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final code in landen)
              _speld('${docLand(code).vlag} ${docLand(code).naam} · ${_lijst.where((l) => (l as Map)['country'] == code).length}'),
            if (binnenkort > 0) _speld(dt(c, 'lic.verloopt').replaceFirst('%d', '$binnenkort'), kleur: const Color(0xFFFEF3C7), tekstKleur: const Color(0xFFB45309)),
            if (verlopen > 0) _speld(dt(c, 'lic.verlopen').replaceFirst('%d', '$verlopen'), kleur: const Color(0xFFFEE2E2), tekstKleur: const Color(0xFFB91C1C)),
          ]),
        ]),
      ),
    );
  }

  Widget _kaart(BuildContext c, Map l) {
    final land = docLand('${l['country']}');
    final stand = _standVan(l['valid_until'] as String?);
    final soort = '${l['type'] ?? ''}';
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(land.vlag, style: const TextStyle(fontSize: 17)),
                Text('${l['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy)),
                if (soort.isNotEmpty) _speld(dt(c, 'lic.type_$soort')),
                if (stand != _Stand.geen) _speld(
                  dt(c, stand == _Stand.geldig ? 'lic.status_valid' : stand == _Stand.binnenkort ? 'lic.status_soon' : 'lic.status_expired'),
                  kleur: stand == _Stand.geldig ? const Color(0xFFD1FAE5) : stand == _Stand.binnenkort ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                  tekstKleur: stand == _Stand.geldig ? const Color(0xFF047857) : stand == _Stand.binnenkort ? const Color(0xFFB45309) : const Color(0xFFB91C1C),
                ),
              ]),
              const SizedBox(height: 4),
              for (final r in [
                if ('${l['issuer'] ?? ''}'.isNotEmpty) '${l['issuer']}',
                if ('${l['number'] ?? ''}'.isNotEmpty) '${dt(c, 'lic.number')}: ${l['number']}',
                if ('${l['holder_name'] ?? ''}'.isNotEmpty) '${dt(c, 'lic.holder')}: ${l['holder_name']}',
                if (l['valid_from'] != null || l['valid_until'] != null)
                  '${_datum(l['valid_from'])} → ${_datum(l['valid_until'])}',
                if ('${l['notes'] ?? ''}'.isNotEmpty) '${l['notes']}',
              ])
                Text(r, style: const TextStyle(fontSize: 12.5, height: 1.35, color: Colors.black54)),
            ])),
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.edit_outlined, size: 19, color: Colors.black38), onPressed: () => _bewerk(l)),
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.delete_outline, size: 19, color: Colors.black38), onPressed: () => _verwijder(l)),
          ]),
          TourAnker(id: 'documenten-foto', child: _PasFotos(
            id: (l['id'] as num).toInt(),
            heeftVoor: l['heeft_foto_voor'] == true,
            heeftAchter: l['heeft_foto_achter'] == true,
            opWijziging: _laad,
          )),
        ]),
      ),
    );
  }

  String _datum(dynamic v) {
    final s = '${v ?? ''}';
    return s.length >= 10 ? s.substring(0, 10) : '…';
  }

  Widget _speld(String tekst, {Color kleur = const Color(0xFFF1F5F9), Color tekstKleur = const Color(0xFF475569)}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: kleur, borderRadius: BorderRadius.circular(20)),
        child: Text(tekst, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: tekstKleur)),
      );
}

/// Invulblad voor één document (nieuw of bestaand).
class _DocumentBlad extends StatefulWidget {
  const _DocumentBlad({this.document});
  final Map? document;
  @override
  State<_DocumentBlad> createState() => _DocumentBladState();
}

class _DocumentBladState extends State<_DocumentBlad> {
  late String _land = '${widget.document?['country'] ?? 'NL'}';
  late String _soort = '${widget.document?['type'] ?? 'vispas'}';
  late final _naam = TextEditingController(text: '${widget.document?['name'] ?? ''}');
  late final _nummer = TextEditingController(text: '${widget.document?['number'] ?? ''}');
  late final _houder = TextEditingController(text: '${widget.document?['holder_name'] ?? ''}');
  late final _instantie = TextEditingController(text: '${widget.document?['issuer'] ?? ''}');
  late final _notities = TextEditingController(text: '${widget.document?['notes'] ?? ''}');
  DateTime? _vanaf;
  DateTime? _tot;
  bool _bezig = false;

  @override
  void initState() {
    super.initState();
    _vanaf = DateTime.tryParse('${widget.document?['valid_from'] ?? ''}');
    _tot = DateTime.tryParse('${widget.document?['valid_until'] ?? ''}');
    if (!kDocTypes.contains(_soort)) _soort = 'overig';
  }

  @override
  void dispose() {
    for (final c in [_naam, _nummer, _houder, _instantie, _notities]) { c.dispose(); }
    super.dispose();
  }

  String? _alsDatum(DateTime? d) =>
      d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _kiesDatum(bool vanaf) async {
    final nu = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (vanaf ? _vanaf : _tot) ?? nu,
      firstDate: DateTime(nu.year - 10),
      lastDate: DateTime(nu.year + 10),
    );
    if (d != null) setState(() => vanaf ? _vanaf = d : _tot = d);
  }

  Future<void> _bewaar() async {
    if (_naam.text.trim().isEmpty) return;
    setState(() => _bezig = true);
    final body = {
      'country': _land,
      'name': _naam.text.trim(),
      'type': _soort,
      'number': _nummer.text.trim().isEmpty ? null : _nummer.text.trim(),
      'holder_name': _houder.text.trim().isEmpty ? null : _houder.text.trim(),
      'issuer': _instantie.text.trim().isEmpty ? null : _instantie.text.trim(),
      'valid_from': _alsDatum(_vanaf),
      'valid_until': _alsDatum(_tot),
      'notes': _notities.text.trim().isEmpty ? null : _notities.text.trim(),
    };
    try {
      final id = widget.document?['id'];
      if (id != null) {
        await Api.put('/licenses/$id', body);
      } else {
        await Api.post('/licenses', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _bezig = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : dt(context, 'lic.cancel'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final land = docLand(_land);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(children: [
              Expanded(child: Text(dt(context, widget.document == null ? 'lic.add' : 'lic.edit'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _land,
              decoration: InputDecoration(labelText: dt(context, 'lic.country'), border: const OutlineInputBorder()),
              items: [for (final l in kDocLanden) DropdownMenuItem(value: l.code, child: Text('${l.vlag} ${l.naam}'))],
              onChanged: (v) => setState(() => _land = v ?? 'NL'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _soort,
              decoration: InputDecoration(labelText: dt(context, 'lic.type'), border: const OutlineInputBorder()),
              items: [for (final t in kDocTypes) DropdownMenuItem(value: t, child: Text(dt(context, 'lic.type_$t')))],
              onChanged: (v) => setState(() => _soort = v ?? 'overig'),
            ),
            // De officiële instantie van het gekozen land, zodat je het zelf kunt nakijken.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(land.instantie, style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.black54)),
                  if (land.url.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text('${dt(context, 'lic.official_source')}: ${land.url}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.teal))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _naam, decoration: InputDecoration(
                labelText: dt(context, 'lic.name'), hintText: dt(context, 'lic.name_ph'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _nummer, decoration: InputDecoration(labelText: dt(context, 'lic.number'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _houder, decoration: InputDecoration(labelText: dt(context, 'lic.holder'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _instantie, decoration: InputDecoration(labelText: dt(context, 'lic.issuer'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _datumKnop(context, dt(context, 'lic.valid_from'), _vanaf, () => _kiesDatum(true))),
              const SizedBox(width: 10),
              Expanded(child: _datumKnop(context, dt(context, 'lic.valid_until'), _tot, () => _kiesDatum(false))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _notities, maxLines: 2, decoration: InputDecoration(labelText: dt(context, 'lic.notes'), border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _bezig ? null : _bewaar,
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size.fromHeight(46)),
              child: Text(dt(context, 'lic.save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datumKnop(BuildContext c, String label, DateTime? waarde, VoidCallback opTik) => InkWell(
        onTap: opTik,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          child: Text(waarde == null ? '—' : _alsDatum(waarde)!, style: const TextStyle(fontSize: 14)),
        ),
      );
}

/// Foto van de voor- en achterkant van je pas.
class _PasFotos extends StatelessWidget {
  const _PasFotos({required this.id, required this.heeftVoor, required this.heeftAchter, required this.opWijziging});
  final int id;
  final bool heeftVoor, heeftAchter;
  final VoidCallback opWijziging;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Divider(height: 22),
        // Boven uitlijnen: heeft één kant al een foto (en dus Vervangen/Verwijderen eronder),
        // dan moet de andere kant niet naar beneden zakken.
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _Zijde(id: id, kant: 'voor', aanwezig: heeftVoor, opWijziging: opWijziging)),
          const SizedBox(width: 10),
          Expanded(child: _Zijde(id: id, kant: 'achter', aanwezig: heeftAchter, opWijziging: opWijziging)),
        ]),
        const SizedBox(height: 6),
        Text(dt(context, 'lic.foto_let_op'), style: const TextStyle(fontSize: 11, height: 1.3, color: Colors.black38)),
      ]);
}

class _Zijde extends StatefulWidget {
  const _Zijde({required this.id, required this.kant, required this.aanwezig, required this.opWijziging});
  final int id;
  final String kant;
  final bool aanwezig;
  final VoidCallback opWijziging;
  @override
  State<_Zijde> createState() => _ZijdeState();
}

class _ZijdeState extends State<_Zijde> {
  Uint8List? _beeld;
  bool _bezig = false;

  @override
  void initState() {
    super.initState();
    if (widget.aanwezig) _haalFoto();
  }

  @override
  void didUpdateWidget(_Zijde oud) {
    super.didUpdateWidget(oud);
    if (oud.aanwezig != widget.aanwezig) {
      if (widget.aanwezig) { _haalFoto(); } else { setState(() => _beeld = null); }
    }
  }

  Future<void> _haalFoto() async {
    try {
      final b = await Api.bytes('/licenses/${widget.id}/foto/${widget.kant}');
      if (mounted) setState(() => _beeld = Uint8List.fromList(b));
    } catch (_) {
      if (mounted) setState(() => _beeld = null);
    }
  }

  Future<void> _kies() async {
    final bron = await showModalBottomSheet<ImageSource>(context: context, builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text(dt(c, 'lic.foto_camera')),
            onTap: () => Navigator.pop(c, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(dt(c, 'lic.foto_galerij')),
            onTap: () => Navigator.pop(c, ImageSource.gallery)),
      ]),
    ));
    if (bron == null) return;
    try {
      final f = await ImagePicker().pickImage(source: bron, maxWidth: 1600, imageQuality: 85);
      if (f == null) return;
      setState(() => _bezig = true);
      await Api.uploadNaar('/licenses/${widget.id}/foto/${widget.kant}', f.path, veld: 'foto');
      await _haalFoto();
      widget.opWijziging();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : dt(context, 'lic.foto_fout'))));
      }
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  Future<void> _weg() async {
    setState(() => _bezig = true);
    try {
      await Api.delete('/licenses/${widget.id}/foto/${widget.kant}');
      if (mounted) setState(() => _beeld = null);
      widget.opWijziging();
    } catch (_) {
      // Lukt het niet, dan blijft de foto gewoon staan; de melding komt van de server.
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  void _groot() {
    if (_beeld == null) return;
    showDialog(context: context, builder: (c) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: InteractiveViewer(child: Image.memory(_beeld!)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final label = dt(context, widget.kant == 'voor' ? 'lic.foto_voor' : 'lic.foto_achter');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black54)),
      const SizedBox(height: 4),
      InkWell(
        onTap: _bezig ? null : (_beeld == null ? _kies : _groot),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            image: _beeld == null ? null : DecorationImage(image: MemoryImage(_beeld!), fit: BoxFit.cover),
          ),
          child: _bezig
              ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
              : _beeld == null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_camera_outlined, size: 20, color: Colors.black26),
                      const SizedBox(height: 3),
                      Text(dt(context, 'lic.foto_toevoegen'), style: const TextStyle(fontSize: 11, color: Colors.black38)),
                    ]))
                  : null,
        ),
      ),
      if (_beeld != null)
        Row(children: [
          TextButton(onPressed: _bezig ? null : _kies,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), visualDensity: VisualDensity.compact),
              child: Text(dt(context, 'lic.foto_vervangen'), style: const TextStyle(fontSize: 11.5))),
          TextButton(onPressed: _bezig ? null : _weg,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), visualDensity: VisualDensity.compact, foregroundColor: Colors.red.shade400),
              child: Text(dt(context, 'lic.foto_weg'), style: const TextStyle(fontSize: 11.5))),
        ]),
    ]);
  }
}
