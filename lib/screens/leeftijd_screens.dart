import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/config.dart';
import '../core/leeftijd_i18n.dart';

/// 31-10-2026 Minderjarigen (AVG art. 8 / UAVG art. 5), gelijk aan web en API:
///  < 13 geen account · 13–15 alleen met toestemming van een ouder of voogd · 16–17 strengere standaarden.

/// Datumkiezer zonder voorgekozen geboortedatum. De oude kiezer opende op 1 januari van (dit jaar − 25)
/// = 2001-01-01; wie meteen op OK tikte, kreeg die datum. Nu opent hij op vandaag in de jaarweergave,
/// zodat je echt een jaar moet kiezen.
Future<DateTime?> kiesGeboortedatum(BuildContext context, String help, {DateTime? huidig}) {
  final nu = DateTime.now();
  final vandaag = DateTime(nu.year, nu.month, nu.day);
  return showDatePicker(
    context: context,
    // Al gekozen? Dan heropenen op die datum (anders begin je bij elke correctie weer bij vandaag).
    initialDate: (huidig != null && !huidig.isAfter(vandaag)) ? huidig : vandaag,
    firstDate: DateTime(1900),
    lastDate: vandaag,
    initialDatePickerMode: DatePickerMode.year,
    helpText: help,
  );
}

int leeftijdOp(DateTime d) {
  final nu = DateTime.now();
  var a = nu.year - d.year;
  if (nu.month < d.month || (nu.month == d.month && nu.day < d.day)) a--;
  return a;
}

bool isStandaardDatum(DateTime d) => d.year == 2001 && d.month == 1 && d.day == 1;
bool heeftOuderNodig(DateTime? d, {bool alGevraagd = false}) => !alGevraagd && d != null && leeftijdOp(d) >= 13 && leeftijdOp(d) < 16;

/// Loopt er al een aanvraag (of is er toestemming)? Dan vraagt de API geen ouder-e-mail meer.
bool ouderAlGevraagd(Map<String, dynamic>? pc) => pc != null && (pc['status'] == 'pending' || pc['status'] == 'granted');

String fmtDatum(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Blok met de leeftijdsvelden, gedeeld door registratie, onboarding en het geboortedatum-scherm:
/// knop voor de datum, bij 1-1-2001 een bevestig-vinkje, bij 13–15 het e-mailadres van de ouder.
class LeeftijdVelden extends StatelessWidget {
  final DateTime? datum;
  final ValueChanged<DateTime> onDatum;
  final bool bevestigd;
  final ValueChanged<bool> onBevestigd;
  final TextEditingController ouderMail;
  final bool alGevraagd;
  const LeeftijdVelden({super.key, required this.datum, required this.onDatum, required this.bevestigd,
      required this.onBevestigd, required this.ouderMail, this.alGevraagd = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OutlinedButton.icon(
        key: const Key('leeftijd-datum'),
        onPressed: () async {
          final d = await kiesGeboortedatum(context, lft(context, 'birthday'), huidig: datum);
          if (d != null) onDatum(d);
        },
        icon: const Icon(Icons.cake_outlined, size: 18),
        label: Text(datum == null ? lft(context, 'pick') : fmtDatum(datum!)),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), alignment: Alignment.centerLeft, foregroundColor: AppColors.navy),
      ),
      if (datum != null && isStandaardDatum(datum!))
        CheckboxListTile(
          contentPadding: EdgeInsets.zero, dense: true, controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.teal, value: bevestigd, onChanged: (v) => onBevestigd(v ?? false),
          title: Text(lft(context, 'confirm_2001'), style: const TextStyle(fontSize: 13.5)),
        ),
      if (datum != null && leeftijdOp(datum!) < 13)
        Padding(padding: const EdgeInsets.only(top: 8),
          child: Text(lft(context, 'too_young'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
      if (heeftOuderNodig(datum, alGevraagd: alGevraagd)) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF5C26B))),
          child: Text(lft(context, 'parent_hint'), style: const TextStyle(fontSize: 13, color: Color(0xFF7A4B00))),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('leeftijd-ouder-mail'),
          controller: ouderMail, keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: '${lft(context, 'parent_email')} *', border: const OutlineInputBorder(), isDense: true),
        ),
      ],
    ]);
  }
}

/// Lokale controle vóór het versturen. Geeft een foutmelding of null.
/// [teJongNaarServer]: bij registratie weigeren we < 13 lokaal (er is nog geen account). Bij onboarding en het
/// geboortedatum-scherm bestaat het account al: dan gaat de datum (na bevestiging) naar de server, die hem
/// vastlegt en het account stilzet, zodat een kind niet gewoon een oudere datum kan proberen.
String? controleerLeeftijdVelden(BuildContext c, DateTime? d, bool bevestigd, String ouderMail, {bool alGevraagd = false, bool teJongNaarServer = false}) {
  if (d == null) return lft(c, 'err_pick');
  if (leeftijdOp(d) < 13) return teJongNaarServer ? null : lft(c, 'too_young');
  if (isStandaardDatum(d) && !bevestigd) return lft(c, 'err_confirm');
  if (heeftOuderNodig(d, alGevraagd: alGevraagd) && !ouderMail.contains('@')) return lft(c, 'err_parent');
  return null;
}

/// Vóór het opsturen van een datum onder de 13: echt zeker? Een vergissing zet het account stil.
Future<bool> bevestigTeJong(BuildContext c, DateTime d) async {
  if (leeftijdOp(d) >= 13) return true;
  final ok = await showDialog<bool>(context: c, builder: (ctx) => AlertDialog(
    scrollable: true,
    title: Text(lft(c, 'tj_confirm_title')),
    content: Text('${fmtDatum(d)}\n\n${lft(c, 'tj_confirm_body')}'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lft(c, 'tj_confirm_no'))),
      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(lft(c, 'tj_confirm_yes'))),
    ]));
  return ok == true;
}

/// Velden voor de API (birthday, birthday_confirm, parent_email).
Map<String, dynamic> leeftijdPayload(DateTime d, bool bevestigd, String ouderMail, {bool alGevraagd = false}) => {
  'birthday': fmtDatum(d),
  if (isStandaardDatum(d) && bevestigd) 'birthday_confirm': true,
  if (heeftOuderNodig(d, alGevraagd: alGevraagd) && ouderMail.trim().isNotEmpty) 'parent_email': ouderMail.trim(),
};

/// Eenmalig scherm voor bestaande leden zonder (echte) geboortedatum, o.a. de leden die op 2001-01-01 stonden.
class GeboortedatumScherm extends StatefulWidget {
  const GeboortedatumScherm({super.key});
  @override
  State<GeboortedatumScherm> createState() => _GeboortedatumSchermState();
}

class _GeboortedatumSchermState extends State<GeboortedatumScherm> {
  DateTime? _d;
  bool _bev = false;
  final _ouder = TextEditingController();
  bool _bezig = false;
  String? _err;

  @override
  void dispose() { _ouder.dispose(); super.dispose(); }

  Future<void> _opslaan() async {
    final ag = ouderAlGevraagd(context.read<AuthState>().user?.parentConsent);
    final fout = controleerLeeftijdVelden(context, _d, _bev, _ouder.text, alGevraagd: ag, teJongNaarServer: true);
    if (fout != null) { setState(() => _err = fout); return; }
    if (!await bevestigTeJong(context, _d!)) return;
    if (!mounted) return;
    setState(() { _bezig = true; _err = null; });
    try {
      await Api.post('/profile/birthday', leeftijdPayload(_d!, _bev, _ouder.text, alGevraagd: ag));
      if (mounted) await context.read<AuthState>().refresh();
    } catch (e) {
      // Onder de 13 slaat de server de datum op en geeft 422 age_too_young → refresh toont het te-jong-scherm.
      if (e is ApiException && e.data is Map && e.data['code'] == 'age_too_young') {
        if (mounted) await context.read<AuthState>().refresh();
        return;
      }
      if (mounted) setState(() { _bezig = false; _err = e is ApiException ? e.message : lft(context, 'err_generic'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.navy, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lft(context, 'bd_title'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(lft(context, 'bd_intro'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LeeftijdVelden(datum: _d, onDatum: (d) => setState(() { _d = d; _bev = false; _err = null; }),
                bevestigd: _bev, onBevestigd: (v) => setState(() => _bev = v), ouderMail: _ouder,
                alGevraagd: ouderAlGevraagd(context.watch<AuthState>().user?.parentConsent)),
            if (_err != null) Padding(padding: const EdgeInsets.only(top: 10),
                child: Text(_err!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('leeftijd-opslaan'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size(double.infinity, 50)),
              onPressed: _bezig || _d == null ? null : _opslaan,
              child: Text(_bezig ? lft(context, 'saving') : lft(context, 'save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.read<AuthState>().logout(), child: Text(lft(context, 'logout'))),
          ])),
        ])),
      ),
    );
  }
}

/// Account van iemand onder de 13: staat stil. Alleen uitleg, verwijderen (website) en uitloggen.
class TeJongScherm extends StatelessWidget {
  const TeJongScherm({super.key});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
          const Icon(Icons.lock_clock_outlined, size: 64, color: AppColors.navy),
          const SizedBox(height: 16),
          Text(lft(context, 'tj_title'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 10),
          Text(lft(context, 'tj_body'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('${Config.webOrigin}/account-verwijderen'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.delete_outline), label: Text(lft(context, 'tj_delete')),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => context.read<AuthState>().logout(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy, minimumSize: const Size(double.infinity, 48)),
            child: Text(lft(context, 'logout')),
          ),
        ])))),
      ),
    );
  }
}

/// 13–15 zonder toestemming: opvallende balk boven het gewone startscherm, met "Regelen" (ouder-e-mail,
/// opnieuw sturen, vernieuwen). De app blijft verder bruikbaar (kaart, logboek, gids); sociale acties
/// geeft de server netjes terug als 403 met uitleg.
class ToestemmingBalk extends StatelessWidget {
  final Widget child;
  const ToestemmingBalk({super.key, required this.child});

  String _tekst(BuildContext c, Map? pc) {
    final st = pc?['status'];
    if (st == 'pending') return lft(c, 'bar_pending', {'email': '${pc?['parent_email'] ?? ''}'});
    if (st == 'declined') return lft(c, 'bar_declined');
    if (st == 'revoked') return lft(c, 'bar_revoked');
    return lft(c, 'bar_none');
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthState>().user;
    return Scaffold(
      body: Column(children: [
        Material(
          color: const Color(0xFFFFF1D6),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(children: [
              const Icon(Icons.family_restroom, color: Color(0xFF7A4B00)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lft(context, 'bar_title'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7A4B00), fontSize: 13.5)),
                Text(_tekst(context, u?.parentConsent), style: const TextStyle(color: Color(0xFF7A4B00), fontSize: 12)),
              ])),
              TextButton(
                key: const Key('toestemming-regelen'),
                onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _ToestemmingBlad()),
                child: Text(lft(context, 'arrange'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          )),
        ),
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ]),
    );
  }
}

class _ToestemmingBlad extends StatefulWidget {
  const _ToestemmingBlad();
  @override
  State<_ToestemmingBlad> createState() => _ToestemmingBladState();
}

class _ToestemmingBladState extends State<_ToestemmingBlad> {
  final _mail = TextEditingController();
  bool _bezig = false;
  String? _msg;
  bool _fout = false;

  @override
  void dispose() { _mail.dispose(); super.dispose(); }

  Future<void> _stuur() async {
    if (!_mail.text.contains('@')) { setState(() { _msg = lft(context, 'err_parent'); _fout = true; }); return; }
    setState(() { _bezig = true; _msg = null; });
    try {
      final r = await Api.post('/profile/parent-consent', {'parent_email': _mail.text.trim()});
      if (!mounted) return;
      setState(() { _msg = (r is Map ? r['message'] : null)?.toString(); _fout = false; _bezig = false; });
      await context.read<AuthState>().refresh();
    } catch (e) {
      if (mounted) setState(() { _msg = e is ApiException ? e.message : lft(context, 'err_generic'); _fout = true; _bezig = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lft(context, 'bar_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 6),
        Text(lft(context, 'parent_hint'), style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 12),
        TextField(controller: _mail, keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: lft(context, 'parent_email'), border: const OutlineInputBorder(), isDense: true)),
        if (_msg != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(_msg!, style: TextStyle(color: _fout ? AppColors.danger : AppColors.teal, fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: _bezig ? null : _stuur, child: Text(_bezig ? lft(context, 'saving') : lft(context, 'send')))),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () async { await context.read<AuthState>().refresh(); if (context.mounted) Navigator.pop(context); },
              child: Text(lft(context, 'refresh'))),
        ]),
      ])),
    );
  }
}
