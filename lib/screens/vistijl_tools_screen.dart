import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/vistijl_tools_i18n.dart';

/// Vistijl-tools — 1-op-1 port van de web-pagina (vistijl-tools/page.tsx).
/// Toont per geselecteerde visstijl de bijbehorende reken-/adviestool(s),
/// plus rig-kiezer (karper), tippet-calculator (vlieg), een "Populair bij
/// leden"-blok en een uitklapbaar "Kennis & tips"-blok. Zelfde rekenlogica
/// en teksten als de website (6 talen).
class VistijlToolsScreen extends StatefulWidget {
  const VistijlToolsScreen({super.key});
  @override
  State<VistijlToolsScreen> createState() => _VistijlToolsScreenState();
}

// Welke discipline-keys een tool hebben (parallel aan TOOL_KEYS in de web).
const List<String> _kToolKeys = ['carp', 'feeder', 'predator', 'coarse', 'street', 'catfish', 'fly', 'trout', 'sea'];

// Zachte tint-kleuren voor de uitkomst-blokjes (benadering van de web-tints).
const Color _tintBlue = Color(0x1A0EA5E9); // #0ea5e9 @ ~10%
const Color _tintAmber = Color(0x0DC08A2D); // #c08a2d @ ~5%
const Color _tintTeal = Color(0x0D1F8A70); // #1f8a70 @ ~5%

class _VistijlToolsScreenState extends State<VistijlToolsScreen> {
  List<Map<String, dynamic>> _all = [];
  List<int> _selected = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await Api.get('/disciplines');
      _all = (d is List) ? d.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];
    } catch (_) {
      _all = [];
    }
    try {
      final r = await Api.get('/profile/disciplines');
      final list = (r is Map) ? r['disciplines'] : null;
      _selected = (list is List) ? list.map((e) => (e as num).toInt()).toList() : <int>[];
    } catch (_) {
      _selected = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // De gekozen discipline-keys (alleen die met een tool).
    final selKeys = _all.where((d) => _selected.contains((d['id'] as num?)?.toInt())).map((d) => '${d['key']}').toList();
    final active = selKeys.where(_kToolKeys.contains).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('🧰 ${vtt(context, 'title')}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selected.isEmpty
              ? _emptyState()
              : ListView(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + MediaQuery.of(context).padding.bottom),
                  children: _buildTools(active),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧰', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(vtt(context, 'pickFirst'),
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 15)),
            ],
          ),
        ),
      );

  List<Widget> _buildTools(List<String> active) {
    final w = <Widget>[];
    void gap() => w.add(const SizedBox(height: 14));

    if (active.contains('carp')) {
      w.add(const _CarpTool());
      gap();
      w.add(const _RigPicker());
      gap();
      w.add(const _Popular(disc: 'carp'));
      gap();
      w.add(const _Knowledge(disc: 'carp'));
      gap();
    }
    if (active.contains('feeder')) {
      w.add(const _FeederTool());
      gap();
      w.add(const _Popular(disc: 'feeder'));
      gap();
      w.add(const _Knowledge(disc: 'feeder'));
      gap();
    }
    if (active.contains('predator')) {
      w.add(const _PredatorTool());
      gap();
      w.add(const _Popular(disc: 'predator'));
      gap();
      w.add(const _Knowledge(disc: 'predator'));
      gap();
    }
    if (active.contains('coarse')) {
      w.add(const _CoarseTool());
      gap();
      w.add(const _Popular(disc: 'coarse'));
      gap();
      w.add(const _Knowledge(disc: 'coarse'));
      gap();
    }
    if (active.contains('street')) {
      w.add(const _StreetTool());
      gap();
      w.add(const _Popular(disc: 'street'));
      gap();
      w.add(const _Knowledge(disc: 'street'));
      gap();
    }
    if (active.contains('catfish')) {
      w.add(const _CatfishTool());
      gap();
      w.add(const _Popular(disc: 'catfish'));
      gap();
      w.add(const _Knowledge(disc: 'catfish'));
      gap();
    }
    if (active.contains('fly')) {
      w.add(const _FlyTool());
      gap();
      w.add(const _TippetCalc());
      gap();
      w.add(const _Popular(disc: 'fly'));
      gap();
      w.add(const _Knowledge(disc: 'fly'));
      gap();
    }
    if (active.contains('trout')) {
      w.add(const _TroutTool());
      gap();
      w.add(const _Popular(disc: 'trout'));
      gap();
      w.add(const _Knowledge(disc: 'trout'));
      gap();
    }
    if (active.contains('sea')) {
      w.add(const _SeaTool());
      gap();
      w.add(const _Popular(disc: 'sea'));
      gap();
      w.add(const _Knowledge(disc: 'sea'));
      gap();
    }
    w.add(Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(vtt(context, 'more'),
          textAlign: TextAlign.center, style: const TextStyle(color: Colors.black38, fontSize: 12)),
    ));
    return w;
  }
}

// ── Gedeelde bouwstenen ──────────────────────────────────────────────────────

String _fmtNum(num v) {
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

Widget _card({required String icon, required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: const [BoxShadow(color: Color(0x0F0A3D62), blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$icon $title', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 16)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

Widget _fieldLabel(String label, Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
      const SizedBox(height: 4),
      child,
    ],
  );
}

Widget _outBox(String label, String value, {bool big = false, Color tint = _tintBlue}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, letterSpacing: 0.4, color: Colors.black45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontWeight: big ? FontWeight.w800 : FontWeight.w600,
                color: big ? AppColors.navy : const Color(0xFF1E293B),
                fontSize: big ? 22 : 15)),
      ],
    ),
  );
}

Widget _tipLine(String emoji, String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text('$emoji $text', style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
  );
}

// Herbruikbare dropdown: waarden = keys, labels via vtt.
class _Dd<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const _Dd({required this.value, required this.options, required this.label, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isDense: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: options.map((o) => DropdownMenuItem<T>(value: o, child: Text(label(o), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// Numeriek invoerveld met vaste breedte.
class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final double width;
  final bool decimal;
  final ValueChanged<String> onChanged;
  const _NumField({required this.controller, required this.onChanged, this.width = 80, this.decimal = false});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

Widget _chips(List<String> items) {
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: items
        .map((it) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
              child: Text(it, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ))
        .toList(),
  );
}

Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 11, letterSpacing: 0.4, color: Colors.black45)),
    );

// ── Karper · Sessie- & voerplanner ──────────────────────────────────────────
class _CarpTool extends StatefulWidget {
  const _CarpTool();
  @override
  State<_CarpTool> createState() => _CarpToolState();
}

class _CarpToolState extends State<_CarpTool> {
  final _nights = TextEditingController(text: '2');
  final _rods = TextEditingController(text: '3');
  String _act = 'normal';

  @override
  void dispose() { _nights.dispose(); _rods.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final nights = int.tryParse(_nights.text) ?? 1;
    final rods = int.tryParse(_rods.text) ?? 1;
    final m = _act == 'low' ? 0.6 : _act == 'high' ? 1.4 : 1.0;
    final feed = (nights * rods * 0.5 * m * 10).round() / 10;
    final pva = nights * rods * 4;
    final list = vttChecklist(context, 'carp');

    return _card(icon: '🐟', title: vtt(context, 'carp'), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _fieldLabel(vtt(context, 'nights'), _NumField(controller: _nights, width: 76, onChanged: (_) => setState(() {}))),
        _fieldLabel(vtt(context, 'rods'), _NumField(controller: _rods, width: 76, onChanged: (_) => setState(() {}))),
        _fieldLabel(vtt(context, 'activity'), SizedBox(width: 150, child: _Dd<String>(
          value: _act, options: const ['low', 'normal', 'high'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _act = v)))),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _outBox(vtt(context, 'feed'), '${_fmtNum(feed)} kg')),
        const SizedBox(width: 12),
        Expanded(child: _outBox(vtt(context, 'pva'), '$pva×')),
      ]),
      _sectionLabel(vtt(context, 'checklist')),
      _chips(list),
    ]);
  }
}

// ── Feeder · Korfgewicht-adviseur ───────────────────────────────────────────
class _FeederTool extends StatefulWidget {
  const _FeederTool();
  @override
  State<_FeederTool> createState() => _FeederToolState();
}

class _FeederToolState extends State<_FeederTool> {
  String _flow = 'light';
  final _depth = TextEditingController(text: '3');
  String _dist = 'mid';

  @override
  void dispose() { _depth.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final depth = int.tryParse(_depth.text) ?? 1;
    const base = {'none': 20, 'light': 30, 'mod': 45, 'strong': 65};
    var g = base[_flow]!;
    final add = ((depth - 3) / 2).round() * 5;
    g += add > 0 ? add : 0;
    g += _dist == 'far' ? 15 : _dist == 'mid' ? 5 : 0;

    return _card(icon: '🎯', title: vtt(context, 'feeder'), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _fieldLabel(vtt(context, 'flow'), SizedBox(width: 150, child: _Dd<String>(
          value: _flow, options: const ['none', 'light', 'mod', 'strong'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _flow = v)))),
        _fieldLabel(vtt(context, 'depth'), _NumField(controller: _depth, width: 76, onChanged: (_) => setState(() {}))),
        _fieldLabel(vtt(context, 'dist'), SizedBox(width: 150, child: _Dd<String>(
          value: _dist, options: const ['short', 'mid', 'far'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _dist = v)))),
      ]),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'weight'), '$g–${g + 15} g', big: true),
      _tipLine('💡', vtt(context, 'feederTip')),
    ]);
  }
}

// ── Roofvis · Kunstaas-adviseur ─────────────────────────────────────────────
class _PredatorTool extends StatefulWidget {
  const _PredatorTool();
  @override
  State<_PredatorTool> createState() => _PredatorToolState();
}

class _PredatorToolState extends State<_PredatorTool> {
  String _temp = 'cool';
  String _clar = 'clear';
  String _dep = 'shallow';

  @override
  Widget build(BuildContext context) {
    final lure = _temp == 'cold'
        ? (_dep == 'deep' ? vtt(context, 'pl_coldDeep') : vtt(context, 'pl_coldShallow'))
        : _temp == 'warm'
            ? (_dep == 'shallow' ? vtt(context, 'pl_warmShallow') : vtt(context, 'pl_warmDeep'))
            : vtt(context, 'pl_mid');
    final color = _clar == 'clear' ? vtt(context, 'pc_clear') : vtt(context, 'pc_murky');
    final retrieve = _temp == 'cold' ? vtt(context, 'pr_cold') : _temp == 'warm' ? vtt(context, 'pr_warm') : vtt(context, 'pr_mid');

    return _card(icon: '🦈', title: vtt(context, 'pred'), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _fieldLabel(vtt(context, 'temp'), SizedBox(width: 150, child: _Dd<String>(
          value: _temp, options: const ['cold', 'cool', 'warm'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _temp = v)))),
        _fieldLabel(vtt(context, 'clarity'), SizedBox(width: 150, child: _Dd<String>(
          value: _clar, options: const ['clear', 'murky'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _clar = v)))),
        _fieldLabel(vtt(context, 'depthL'), SizedBox(width: 150, child: _Dd<String>(
          value: _dep, options: const ['shallow', 'deep'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _dep = v)))),
      ]),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'lure'), lure, tint: _tintAmber),
      const SizedBox(height: 10),
      _outBox(vtt(context, 'color'), color, tint: _tintAmber),
      const SizedBox(height: 10),
      _outBox(vtt(context, 'retrieve'), retrieve, tint: _tintAmber),
    ]);
  }
}

// ── Witvis · Wedstrijd-rekenaar ─────────────────────────────────────────────
class _CoarseTool extends StatefulWidget {
  const _CoarseTool();
  @override
  State<_CoarseTool> createState() => _CoarseToolState();
}

class _CoarseToolState extends State<_CoarseTool> {
  final _w = TextEditingController(text: '10');
  final _h = TextEditingController(text: '5');

  @override
  void dispose() { _w.dispose(); _h.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final w = double.tryParse(_w.text.replaceAll(',', '.')) ?? 0;
    final h = int.tryParse(_h.text) ?? 1;
    final per = h > 0 ? (w / h * 100).round() / 100 : 0;

    return _card(icon: '🎣', title: vtt(context, 'coarse'), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _fieldLabel(vtt(context, 'totalW'), _NumField(controller: _w, width: 96, decimal: true, onChanged: (_) => setState(() {}))),
        _fieldLabel(vtt(context, 'hours'), _NumField(controller: _h, width: 76, onChanged: (_) => setState(() {}))),
      ]),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'perHour'), '${_fmtNum(per)} kg/u', big: true),
      _tipLine('💡', vtt(context, 'coarseTip')),
    ]);
  }
}

// ── Streetfishing · Jigkop-adviseur ─────────────────────────────────────────
class _StreetTool extends StatefulWidget {
  const _StreetTool();
  @override
  State<_StreetTool> createState() => _StreetToolState();
}

class _StreetToolState extends State<_StreetTool> {
  String _flow = 'none';
  final _depth = TextEditingController(text: '2');

  @override
  void dispose() { _depth.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final depth = int.tryParse(_depth.text) ?? 1;
    const base = {'none': 3, 'light': 5, 'mod': 8, 'strong': 12};
    var x = base[_flow]!;
    final add = ((depth - 2) / 1).round() * 1;
    x += add > 0 ? add : 0;

    return _card(icon: '🏙️', title: vtt(context, 'street'), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _fieldLabel(vtt(context, 'flow'), SizedBox(width: 150, child: _Dd<String>(
          value: _flow, options: const ['none', 'light', 'mod', 'strong'],
          label: (o) => vtt(context, o), onChanged: (v) => setState(() => _flow = v)))),
        _fieldLabel(vtt(context, 'depth'), _NumField(controller: _depth, width: 76, onChanged: (_) => setState(() {}))),
      ]),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'streetOut'), '$x–${x + 3} g', big: true),
      _tipLine('💡', vtt(context, 'streetTip')),
    ]);
  }
}

// ── Meerval · Methode & materiaal ───────────────────────────────────────────
class _CatfishTool extends StatefulWidget {
  const _CatfishTool();
  @override
  State<_CatfishTool> createState() => _CatfishToolState();
}

class _CatfishToolState extends State<_CatfishTool> {
  String _m = 'sensor';

  @override
  Widget build(BuildContext context) {
    final tipKey = {'drift': 'cf_tip_drift', 'sensor': 'cf_tip_sensor', 'clonk': 'cf_tip_clonk', 'bank': 'cf_tip_bank'}[_m]!;
    final list = vttChecklist(context, 'catfish');

    return _card(icon: '🐋', title: vtt(context, 'catfish'), children: [
      _fieldLabel(vtt(context, 'method'), SizedBox(width: 200, child: _Dd<String>(
        value: _m, options: const ['drift', 'sensor', 'clonk', 'bank'],
        label: (o) => vtt(context, 'cf_${o}_l'), onChanged: (v) => setState(() => _m = v)))),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _tintAmber, borderRadius: BorderRadius.circular(12)),
        child: Text('💡 ${vtt(context, tipKey)}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
      ),
      _sectionLabel(vtt(context, 'checklist')),
      _chips(list),
    ]);
  }
}

// ── Vliegvissen · Match-the-hatch ───────────────────────────────────────────
class _FlyTool extends StatefulWidget {
  const _FlyTool();
  @override
  State<_FlyTool> createState() => _FlyToolState();
}

class _FlyToolState extends State<_FlyTool> {
  String _s = 'summer';

  @override
  Widget build(BuildContext context) {
    final flyKey = {'spring': 'fly_spring', 'summer': 'fly_summer', 'autumn': 'fly_autumn', 'winter': 'fly_winter'}[_s]!;
    return _card(icon: '🪰', title: vtt(context, 'fly'), children: [
      _fieldLabel(vtt(context, 'season'), SizedBox(width: 180, child: _Dd<String>(
        value: _s, options: const ['spring', 'summer', 'autumn', 'winter'],
        label: (o) => vtt(context, o), onChanged: (v) => setState(() => _s = v)))),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'flyOut'), vtt(context, flyKey), tint: _tintTeal),
    ]);
  }
}

// ── Forel · Spinner/aas-adviseur ────────────────────────────────────────────
class _TroutTool extends StatefulWidget {
  const _TroutTool();
  @override
  State<_TroutTool> createState() => _TroutToolState();
}

class _TroutToolState extends State<_TroutTool> {
  String _temp = 'cool';

  @override
  Widget build(BuildContext context) {
    final out = _temp == 'cold' ? vtt(context, 'tr_cold') : _temp == 'warm' ? vtt(context, 'tr_warm') : vtt(context, 'tr_mid');
    return _card(icon: '🏞️', title: vtt(context, 'trout'), children: [
      _fieldLabel(vtt(context, 'temp'), SizedBox(width: 180, child: _Dd<String>(
        value: _temp, options: const ['cold', 'cool', 'warm'],
        label: (o) => vtt(context, o), onChanged: (v) => setState(() => _temp = v)))),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'trOut'), out, tint: _tintTeal),
    ]);
  }
}

// ── Zeevissen · Aas & montage ───────────────────────────────────────────────
class _SeaTool extends StatefulWidget {
  const _SeaTool();
  @override
  State<_SeaTool> createState() => _SeaToolState();
}

class _SeaToolState extends State<_SeaTool> {
  String _t = 'bass';

  @override
  Widget build(BuildContext context) {
    final outKey = {'flatfish': 'sea_flat', 'cod': 'sea_cod', 'bass': 'sea_bass', 'mackerel': 'sea_mack'}[_t]!;
    return _card(icon: '🌊', title: vtt(context, 'sea'), children: [
      _fieldLabel(vtt(context, 'target'), SizedBox(width: 180, child: _Dd<String>(
        value: _t, options: const ['flatfish', 'cod', 'bass', 'mackerel'],
        label: (o) => vtt(context, o), onChanged: (v) => setState(() => _t = v)))),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'seaOut'), vtt(context, outKey)),
      _tipLine('🌙', vtt(context, 'tideTip')),
    ]);
  }
}

// ── Karper · Rig-kiezer (bodem + aas → juiste rig) ──────────────────────────
class _RigPicker extends StatefulWidget {
  const _RigPicker();
  @override
  State<_RigPicker> createState() => _RigPickerState();
}

class _RigPickerState extends State<_RigPicker> {
  String _b = 'hard';
  String _a = 'bottom';

  @override
  Widget build(BuildContext context) {
    final rig = (_b == 'weed' || _b == 'silt')
        ? (_a == 'popup' ? vtt(context, 'rig_r_ronnie') : vtt(context, 'rig_r_chod'))
        : (_a == 'popup' ? vtt(context, 'rig_r_ronnie') : _a == 'wafter' ? vtt(context, 'rig_r_blow') : vtt(context, 'rig_r_hair'));

    return _card(icon: '🎯', title: vtt(context, 'rig_title'), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _fieldLabel(vtt(context, 'rig_bottom'), SizedBox(width: 170, child: _Dd<String>(
          value: _b, options: const ['hard', 'soft', 'weed', 'silt'],
          label: (o) => vtt(context, 'rig_$o'), onChanged: (v) => setState(() => _b = v)))),
        _fieldLabel(vtt(context, 'rig_bait'), SizedBox(width: 170, child: _Dd<String>(
          value: _a, options: const ['bottom', 'popup', 'wafter'],
          label: (o) => vtt(context, o == 'bottom' ? 'rig_bBottom' : o == 'popup' ? 'rig_bPop' : 'rig_bWaf'),
          onChanged: (v) => setState(() => _a = v)))),
      ]),
      const SizedBox(height: 14),
      _outBox(vtt(context, 'rig_out'), rig, tint: _tintAmber),
    ]);
  }
}

// ── Vliegvissen · Tippet/leader-calculator (regel van 3) ────────────────────
class _TippetCalc extends StatefulWidget {
  const _TippetCalc();
  @override
  State<_TippetCalc> createState() => _TippetCalcState();
}

class _TippetCalcState extends State<_TippetCalc> {
  final _hook = TextEditingController(text: '16');

  @override
  void dispose() { _hook.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hook = int.tryParse(_hook.text) ?? 4;
    final x = (hook / 3).round().clamp(3, 8).toInt();
    return _card(icon: '🪰', title: vtt(context, 'tip_title'), children: [
      _fieldLabel(vtt(context, 'tip_hook'), _NumField(controller: _hook, width: 96, onChanged: (_) => setState(() {}))),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _outBox(vtt(context, 'tip_tippet'), '${x}X', big: true)),
        const SizedBox(width: 10),
        Expanded(child: _outBox(vtt(context, 'tip_leader'), '9–12 ft', tint: _tintTeal)),
        const SizedBox(width: 10),
        Expanded(child: _outBox(vtt(context, 'tip_strain'), kTippetLb[x] ?? '', tint: _tintTeal)),
      ]),
      _tipLine('💡', vtt(context, 'tip_tip')),
    ]);
  }
}

// ── Populair bij leden: top-3 uit echte community-vangsten ───────────────────
class _Popular extends StatefulWidget {
  final String disc;
  const _Popular({required this.disc});
  @override
  State<_Popular> createState() => _PopularState();
}

class _PopularState extends State<_Popular> {
  Map<String, dynamic>? _d;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lang = Provider.of<I18n>(context, listen: false).locale;
      final r = await Api.get('/disciplines/popular?key=${widget.disc}&lang=$lang');
      if (mounted) setState(() { _d = (r is Map) ? Map<String, dynamic>.from(r) : null; _done = true; });
    } catch (_) {
      if (mounted) setState(() { _d = null; _done = true; });
    }
  }

  List<Map<String, dynamic>> _items(String key) {
    final l = _d?[key];
    if (l is List) return l.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (!_done || _d == null) return const SizedBox.shrink();
    final total = (_d!['total'] as num?)?.toInt() ?? 0;

    return _card(icon: '🔥', title: vtt(context, 'pop_title'), children: [
      if (total == 0)
        Text(vtt(context, 'pop_none'), style: const TextStyle(fontSize: 13, color: Colors.black45))
      else ...[
        Text('${vtt(context, 'pop_based')} $total ${vtt(context, 'pop_catches')}',
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 12),
        _col(vtt(context, 'pop_bait'), _items('top_bait')),
        const SizedBox(height: 10),
        _col(vtt(context, 'pop_tech'), _items('top_technique')),
        const SizedBox(height: 10),
        _col(vtt(context, 'pop_species'), _items('top_species')),
      ],
    ]);
  }

  Widget _col(String title, List<Map<String, dynamic>> items) {
    const medals = ['🥇', '🥈', '🥉'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _tintAmber, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 10, letterSpacing: 0.4, color: Colors.black45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text('—', style: TextStyle(fontSize: 12, color: Colors.black38))
          else
            ...items.asMap().entries.map((e) {
              final i = e.key;
              final x = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text('${i < medals.length ? medals[i] : ''} ${x['name'] ?? ''}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    Text('${(x['count'] as num?)?.toInt() ?? 0}×',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black38)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Uitklapbare "Kennis & tips" per vistijl ─────────────────────────────────
class _Knowledge extends StatefulWidget {
  final String disc;
  const _Knowledge({required this.disc});
  @override
  State<_Knowledge> createState() => _KnowledgeState();
}

class _KnowledgeState extends State<_Knowledge> {
  int? _open;

  Future<void> _openVideo(Map<String, String> m) async {
    final yt = m['yt'];
    final q = m['q'];
    final Uri uri;
    if (yt != null && yt.isNotEmpty) {
      uri = Uri.parse('https://www.youtube.com/watch?v=$yt');
    } else if (q != null && q.isNotEmpty) {
      uri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}');
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final items = vttKnow(context, widget.disc);
    final media = vttKnowMedia(widget.disc);
    if (items.isEmpty) return const SizedBox.shrink();

    return _card(icon: '📚', title: vtt(context, 'know_label'), children: [
      for (var i = 0; i < items.length; i++)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            InkWell(
              onTap: () => setState(() => _open = _open == i ? null : i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(items[i]['t'] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)))),
                    Text(_open == i ? '−' : '+', style: const TextStyle(fontSize: 18, color: Colors.black38)),
                  ],
                ),
              ),
            ),
            if (_open == i)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(items[i]['b'] ?? '',
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.5)),
                    if (i < media.length && (media[i]['yt'] != null || media[i]['q'] != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openVideo(media[i]),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text(vtt(context, 'know_video'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
    ]);
  }
}
