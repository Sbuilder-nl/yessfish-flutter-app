import 'package:flutter/material.dart';
import '../core/rondleiding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api.dart';
import '../core/config.dart';
import 'species_detail_screen.dart';
import '../core/i18n.dart';
import '../core/species_l10n.dart';
import 'package:provider/provider.dart';

/// Soortengids: welke vissen zwemmen er, en waar.
///
/// Had eerst alleen een raster met álle soorten. Op het web staan er een landkeuze, een
/// zoet/zee-keuze en een zoekveld boven — de rondleiding vertelde daarover terwijl er in de app
/// niets te zien was (Richard 20-09-2026). Nu is de gids hetzelfde ingedeeld.
class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key});
  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

/// Dezelfde zes landen als op het web, met vlag en code.
const _landen = [
  ('nl', '🇳🇱'), ('be', '🇧🇪'), ('de', '🇩🇪'), ('fr', '🇫🇷'), ('es', '🇪🇸'), ('pl', '🇵🇱'),
];

class _SpeciesScreenState extends State<SpeciesScreen> {
  List _list = [];
  bool _loading = true;
  String _land = 'nl';
  String _soortWater = 'alles';     // alles | zoet | zee
  final _zoek = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    // Het lid begint in zijn eigen land; anders zie je altijd de Nederlandse lijst.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taal = Provider.of<I18n>(context, listen: false).locale;
      if (_landen.any((l) => l.$1 == taal) && taal != _land) setState(() => _land = taal);
    });
  }

  @override
  void dispose() { _zoek.dispose(); super.dispose(); }

  Future<void> _load() async {
    try { final r = await Api.get('/species'); setState(() { _list = r is List ? r : (r['data'] ?? []); _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  /// Wat er na de filters overblijft.
  ///
  /// Een soort zonder landenlijst laten we staan: hem wegfilteren zou hem stil laten verdwijnen,
  /// en dat is erger dan er eentje te veel tonen (zelfde keuze als op het web).
  List get _zichtbaar {
    final term = _zoek.text.trim().toLowerCase();
    return _list.where((x) {
      final s = x as Map;
      final landen = (s['countries'] as List?)?.map((e) => '$e').toList();
      if (landen != null && landen.isNotEmpty && !landen.contains(_land)) return false;
      final water = '${s['water_type'] ?? ''}';
      if (_soortWater == 'zoet' && !['fresh', 'both'].contains(water)) return false;
      if (_soortWater == 'zee' && !['salt', 'both'].contains(water)) return false;
      if (term.isNotEmpty) {
        final hooi = '${s['name_nl'] ?? ''} ${s['name_en'] ?? ''} ${speciesName(context, s)} '
            '${s['scientific_name'] ?? ''}'.toLowerCase();
        if (!hooi.contains(term)) return false;
      }
      return true;
    }).toList();
  }

  Widget _waterKnop(String sleutel, String label) {
    final aan = _soortWater == sleutel;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: aan,
        onSelected: (_) => setState(() => _soortWater = sleutel),
        label: Text(label),
        selectedColor: AppColors.teal,
        labelStyle: TextStyle(color: aan ? Colors.white : Colors.black87, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lijst = _zichtbaar;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('species.title'))),
      // De filters staan er meteen, ook terwijl de lijst nog laadt. Anders is er in de eerste
      // seconden niets om aan te wijzen en sloeg de rondleiding die stappen over (21-09-2026).
      body: Column(children: [
              // Landkeuze: welke soorten komen hier voor?
              TourAnker(id: 'soorten-land', child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(children: [
                  Text('${context.tr('species.in_country')}:',
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(width: 8),
                  Expanded(child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final l in _landen)
                        Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                          selected: _land == l.$1,
                          onSelected: (_) => setState(() => _land = l.$1),
                          label: Text('${l.$2} ${l.$1.toUpperCase()}'),
                          selectedColor: AppColors.teal,
                          labelStyle: TextStyle(
                              color: _land == l.$1 ? Colors.white : Colors.black87,
                              fontSize: 13, fontWeight: FontWeight.w600),
                        )),
                    ]),
                  )),
                ]),
              )),
              // Zoet of zee.
              Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Row(children: [
                _waterKnop('alles', context.tr('species.all')),
                _waterKnop('zoet', context.tr('species.freshwater')),
                _waterKnop('zee', context.tr('species.sea')),
              ])),
              // Zoeken op naam, ook op de wetenschappelijke naam en de naam in een andere taal.
              TourAnker(id: 'soorten-zoek', child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  controller: _zoek,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: context.tr('species.search'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
              Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 0), child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${lijst.length} ${context.tr('species.results')}',
                    style: const TextStyle(fontSize: 12, color: Colors.black38)),
              )),
              Expanded(child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TourAnker(id: 'soorten-lijst', child: GridView.builder(
                padding: const EdgeInsets.all(12) + EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.82, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: lijst.length,
                itemBuilder: (_, i) {
                  final s = lijst[i] as Map;
                  return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpeciesDetailScreen(id: (s['id'] as num).toInt(), name: speciesName(context, s)))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: s['image_path'] != null
                      ? CachedNetworkImage(imageUrl: s['image_path'], fit: BoxFit.cover, errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.bg, child: Icon(Icons.set_meal, color: AppColors.teal, size: 40)))
                      : const ColoredBox(color: AppColors.bg, child: Icon(Icons.set_meal, color: AppColors.teal, size: 40))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(speciesName(context, s), style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ])));
                })),
              ),
            ]),
    );
  }
}
