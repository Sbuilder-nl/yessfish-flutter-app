import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api.dart';
import '../core/streak_i18n.dart';
import '../core/config.dart';
import 'dobber_text.dart';

/// Gedeelde lader: één GET /streak, hergebruikt door banner en kaart.
class StreakData {
  static Map<String, dynamic>? cache;
  /// Verandert bij elke geslaagde lading → luisteraars (banner) bouwen opnieuw.
  static final ValueNotifier<int> versie = ValueNotifier<int>(0);
  static Future<Map<String, dynamic>?> load({bool force = false}) async {
    if (!force && cache != null) return cache;
    try {
      final r = await Api.get('/streak');
      if (r is Map) { cache = Map<String, dynamic>.from(r); versie.value++; return cache; }
    } catch (_) {}
    return cache;   // server zonder /streak (oude API) → niets tonen
  }
  /// Na een handeling die een dag kan laten meetellen: even later opnieuw ophalen.
  static void verversStraks([Duration wacht = const Duration(seconds: 2)]) => Future.delayed(wacht, () => load(force: true));
}

/// Compacte balk onder de app-balk: 🔥 reeks + 7 dagstippen. Tik = dobbers-scherm.
class StreakBanner extends StatefulWidget {
  final VoidCallback? onTap;
  const StreakBanner({super.key, this.onTap});
  @override
  State<StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<StreakBanner> with WidgetsBindingObserver {
  Map<String, dynamic>? _d;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); StreakData.versie.addListener(_onVersie); _load(true); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); StreakData.versie.removeListener(_onVersie); super.dispose(); }
  void _onVersie() { if (mounted) setState(() => _d = StreakData.cache); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.resumed) _load(true); }
  Future<void> _load(bool force) async { final d = await StreakData.load(force: force); if (mounted) setState(() => _d = d); }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (d == null) return const SizedBox.shrink();
    final cur = (d['current'] as num?)?.toInt() ?? 0;
    final done = d['today_done'] == true;
    final risk = d['at_risk'] == true;
    final txt = done ? sti(context, 'today_done') : (cur == 0 ? sti(context, 'start') : (risk ? sti(context, 'at_risk') : sti(context, 'today_todo')));
    return Material(
      color: risk ? const Color(0xFFFFF1E6) : const Color(0xFFE8F6F1),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 6), child: Row(children: [
          Text('🔥', style: TextStyle(fontSize: 16, color: cur > 0 ? null : Colors.grey)),
          const SizedBox(width: 6),
          Text('$cur', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
          const SizedBox(width: 8),
          Expanded(child: DobberText(txt, style: TextStyle(fontSize: 12, color: risk ? const Color(0xFF9A4B00) : const Color(0xFF1f5f4f)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          WeekDots(week: (d['week'] as List?) ?? const [], size: 9),
        ])),
      ),
    );
  }
}

/// Zeven stippen: gedaan = teal, vrije misser = amber, niets = grijs (vandaag met rand).
class WeekDots extends StatelessWidget {
  final List week; final double size; final bool labels;
  const WeekDots({super.key, required this.week, this.size = 12, this.labels = false});
  @override
  Widget build(BuildContext context) {
    final wd = sti(context, 'wd').split(',');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < week.length; i++) ...[
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: size, height: size, decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: week[i]['done'] == true ? (week[i]['action'] == 'freeze' ? const Color(0xFFF2B233) : AppColors.teal) : const Color(0xFFD9DEE3),
            border: i == week.length - 1 ? Border.all(color: AppColors.navy, width: 1.5) : null,
          )),
          if (labels) Padding(padding: const EdgeInsets.only(top: 3), child: Text(_wd(wd, week[i]['day']?.toString()), style: const TextStyle(fontSize: 10, color: Colors.black45))),
        ]),
        if (i < week.length - 1) SizedBox(width: labels ? 10 : 3),
      ],
    ]);
  }
  static String _wd(List<String> wd, String? day) {
    final d = DateTime.tryParse(day ?? ''); if (d == null || wd.length < 7) return '';
    return wd[d.weekday - 1];
  }
}

/// Volledige reeks-kaart (dobbers-scherm).
class StreakCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const StreakCard({super.key, required this.d});
  @override
  Widget build(BuildContext context) {
    final cur = (d['current'] as num?)?.toInt() ?? 0;
    final longest = (d['longest'] as num?)?.toInt() ?? 0;
    final done = d['today_done'] == true;
    final bonusIn = (d['next_bonus_in'] as num?)?.toInt() ?? 7;
    final freezeUsed = d['freeze_available'] == false;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('🔥 ${sti(context, 'streak_title')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
        const Spacer(),
        Text('$cur ${cur == 1 ? sti(context, 'day') : sti(context, 'days')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1f8a70))),
      ]),
      const SizedBox(height: 12),
      Center(child: WeekDots(week: (d['week'] as List?) ?? const [], size: 22, labels: true)),
      const SizedBox(height: 12),
      DobberText(done ? sti(context, 'today_done') : (cur == 0 ? sti(context, 'start') : sti(context, 'today_todo')),
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: done ? const Color(0xFF1f8a70) : AppColors.navy)),
      const SizedBox(height: 4),
      DobberText(bonusIn == 7 && done ? sti(context, 'bonus_today') : sti(context, 'bonus_in').replaceFirst('%d', '${done ? bonusIn : bonusIn}'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
      if (freezeUsed) Padding(padding: const EdgeInsets.only(top: 2), child: Text('🟡 ${sti(context, 'freeze_used')}', style: const TextStyle(fontSize: 12, color: Colors.black45))),
      const SizedBox(height: 8),
      DobberText(sti(context, 'rules'), style: const TextStyle(fontSize: 12, color: Colors.black45)),
      if (longest > 1) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${sti(context, 'longest')}: $longest', style: const TextStyle(fontSize: 12, color: Colors.black45))),
    ])));
  }
}

/// Vismaat uitnodigen: code, delen, statistiek en zelf een code invullen.
class InviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final VoidCallback onChanged;
  const InviteCard({super.key, required this.invite, required this.onChanged});

  Future<void> _claim(BuildContext context) async {
    final c = TextEditingController();
    final code = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(sti(ctx, 'enter_code')),
      content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.characters, maxLength: 10,
        decoration: InputDecoration(hintText: sti(ctx, 'code_hint'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(sti(ctx, 'cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(sti(ctx, 'ok'))),
      ],
    ));
    if (code == null || code.isEmpty || !context.mounted) return;
    final m = ScaffoldMessenger.of(context);
    try {
      final r = await Api.post('/invites/claim', {'code': code});
      m.showSnackBar(SnackBar(content: DobberText((r is Map ? r['message'] : null)?.toString() ?? '')));
      onChanged();
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = invite['code']?.toString() ?? '';
    final url = invite['url']?.toString() ?? 'https://yessfish.com';
    final reward = (invite['reward'] as num?)?.toInt() ?? 5;
    final n = (invite['invited'] as num?)?.toInt() ?? 0, r = (invite['rewarded'] as num?)?.toInt() ?? 0;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🎣 ${sti(context, 'invite_title')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
      const SizedBox(height: 6),
      DobberText(sti(context, 'invite_text').replaceFirst('%d', '$reward'), style: const TextStyle(fontSize: 13, color: Colors.black87)),
      const SizedBox(height: 12),
      Row(children: [
        Text('${sti(context, 'your_code')}: ', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        InkWell(
          onTap: () { Clipboard.setData(ClipboardData(text: code)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sti(context, 'copied')))); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE8F6F1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.teal)),
            child: Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 2, color: AppColors.navy))),
        ),
        const Spacer(),
        Text(sti(context, 'stats').replaceFirst('%d', '$n').replaceFirst('%d', '$r'), style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
      ]),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
        onPressed: () => Share.share(sti(context, 'share_msg').replaceFirst('%s', code).replaceFirst('%d', '$reward').replaceFirst('%s', url)),
        icon: const Icon(Icons.share), label: Text(sti(context, 'share')),
      )),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _claim(context), child: Text('${sti(context, 'have_code')} ${sti(context, 'enter_code')}', style: const TextStyle(fontSize: 12)))),
    ])));
  }
}
