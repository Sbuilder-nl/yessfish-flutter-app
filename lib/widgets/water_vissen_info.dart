import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/gids_i18n.dart';
import '../screens/gids_screen.dart' show openWebPagina;
import 'package:url_launcher/url_launcher.dart';

/// Waterpaneel: wie het visrecht heeft (met link naar het profiel) en waar/hoe je hier mag vissen volgens de officiële bron.
/// Gegevens uit GET /waters/{id}?lang= (permits, official_rules, water_use, marina_source) — gelijk aan de website.
class WaterVissenInfo extends StatelessWidget {
  final Map data;
  const WaterVissenInfo({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final permits = (data['permits'] is List) ? data['permits'] as List : const [];
    final regels = (data['official_rules'] is List) ? data['official_rules'] as List : const [];
    final wu = data['water_use'];
    final kaders = <Widget>[];
    if (wu != null && '$wu'.isNotEmpty) {
      kaders.add(_kader(color: const Color(0xFFF1F5F9), border: const Color(0xFFCBD5E1), children: [
        Text(gt(context, 'wu_title', {'soort': gt(context, 'wu_$wu')}), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2), Text(gt(context, 'wu_sub'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ]));
      return Column(children: kaders);
    }
    if (data['marina_source'] != null) {
      kaders.add(_kader(color: const Color(0xFFECFEFF), border: const Color(0xFFA5F3FC), children: [
        Text('⛵ ${gt(context, 'wm_title')}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0E7490))),
        const SizedBox(height: 2), Text(gt(context, 'wm_sub'), style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ]));
    }
    if (permits.isNotEmpty) {
      kaders.add(_kader(color: Colors.white, border: AppColors.border, children: [
        Text(gt(context, 'wp_title').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: .5)),
        const SizedBox(height: 6),
        for (final p in permits) InkWell(
          onTap: (p['partner_slug'] ?? p['profile_href']) != null ? () => openWebPagina(p['partner_slug'] != null ? '/vereniging/${p['partner_slug']}' : '${p['profile_href']}') : null,
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            Icon(p['kind'] == 'organisation' ? Icons.account_balance_outlined : Icons.groups_outlined, size: 18, color: AppColors.teal),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${p['partner_name'] ?? p['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (p['pas'] != null || p['is_rights_holder'] == true) Text([if (p['pas'] != null) '${p['pas']}', if (p['is_rights_holder'] == true) gt(context, 'wp_rights')].join(' · '), style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ])),
            if ((p['partner_slug'] ?? p['profile_href']) != null) const Icon(Icons.chevron_right, color: Colors.black38),
          ])),
        ),
      ]));
    }
    if (regels.isNotEmpty) {
      kaders.add(_kader(color: Colors.white, border: AppColors.border, children: [
        Row(children: [const Icon(Icons.gavel, size: 15, color: AppColors.teal), const SizedBox(width: 6), Expanded(child: Text(gt(context, 'or_title').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: .5)))]),
        for (var i = 0; i < regels.length; i++) _regel(context, regels[i] as Map, i > 0),
        if (regels.any((r) => r['source'] == 'lijst')) Padding(padding: const EdgeInsets.only(top: 8), child: Text(gt(context, 'or_symbols_note'), style: const TextStyle(fontSize: 11, color: Colors.black45))),
      ]));
    }
    return Column(children: kaders);
  }

  Widget _kader({required Color color, required Color border, required List<Widget> children}) => Container(
    width: double.infinity, margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _status(String label, IconData ic, bool? ok, String ja, String nee) => Padding(padding: const EdgeInsets.only(top: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(ic, size: 15, color: Colors.black45), const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.black54)),
    Expanded(child: Text(ok == true ? ja : nee, style: TextStyle(fontSize: 13, fontWeight: ok == null ? FontWeight.w400 : FontWeight.w600, color: ok == true ? const Color(0xFF047857) : ok == false ? const Color(0xFFB91C1C) : Colors.black54))),
  ]));

  Widget _regel(BuildContext context, Map r, bool scheiding) {
    final lijst = r['source'] == 'lijst';
    final by = r['by'];
    final area = r['area'];
    final rules = (r['rules'] is List) ? r['rules'] as List : const [];
    return Container(
      margin: EdgeInsets.only(top: scheiding ? 10 : 6), padding: EdgeInsets.only(top: scheiding ? 10 : 0),
      decoration: BoxDecoration(border: scheiding ? const Border(top: BorderSide(color: Color(0xFFE2E8F0))) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (by is Map) InkWell(onTap: by['href'] != null ? () => openWebPagina('${by['href']}') : null,
          child: Text('${by['name']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal))),
        if (area is Map) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gt(context, 'or_area', {'name': '${area['name']} (${gt(context, 'or_area_${area['kind']}')})'}), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF78350F))),
            Text(gt(context, 'or_area_note', {'bron': '${area['boundary_source']}'}), style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
          ])),
        if (r['members_region_only'] == true) Padding(padding: const EdgeInsets.only(top: 4), child: Text(gt(context, 'or_region_only'), style: const TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w600))),
        if (r['where'] != null && '${r['where']}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('📍 ${gt(context, 'or_where')}: ${r['where']}', style: const TextStyle(fontSize: 13, height: 1.35))),
        if (rules.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(gt(context, 'or_rules'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54))),
          for (final x in rules) Padding(padding: const EdgeInsets.only(top: 2), child: Text('• ${'$x'.replaceFirst(RegExp(r'^[•⁃-]\s*'), '')}', style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
        const SizedBox(height: 4),
        _status(gt(context, 'or_night'), Icons.nightlight_round, r['night'] == true, lijst ? gt(context, 'or_yes_night') : gt(context, 'or_yes'), lijst ? gt(context, 'or_no_symbol') : gt(context, 'or_no')),
        _status(gt(context, 'or_third'), Icons.looks_3_outlined, r['third_rod'] == true, lijst ? gt(context, 'or_yes_third') : gt(context, 'or_yes'), lijst ? gt(context, 'or_no_symbol') : gt(context, 'or_no')),
        if (lijst) _status(gt(context, 'or_shelter'), Icons.holiday_village_outlined, r['shelter'] == true ? true : null, gt(context, 'or_yes'), gt(context, 'or_shelter_unknown')),
        if (!lijst && r['viskaart_xl'] != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(r['viskaart_xl'] == true ? gt(context, 'or_xl_yes') : gt(context, 'or_xl_no'), style: const TextStyle(fontSize: 12))),
        if (r['translated'] == true) Padding(padding: const EdgeInsets.only(top: 4), child: Text('🌐 ${gt(context, 'or_translated')}', style: const TextStyle(fontSize: 11, color: Colors.black45))),
        InkWell(onTap: () => launchUrl(Uri.parse('${r['source_url']}'), mode: LaunchMode.externalApplication),
          child: Padding(padding: const EdgeInsets.only(top: 4), child: Text('${r['source_label']} ↗', style: const TextStyle(fontSize: 11, color: Colors.black54, decoration: TextDecoration.underline)))),
      ]),
    );
  }
}
