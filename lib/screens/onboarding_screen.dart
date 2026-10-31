import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/auth.dart';
import '../core/disciplines_i18n.dart';
import '../core/onboarding_i18n.dart';
import 'leeftijd_screens.dart';

/// Verplichte eenmalige welkomststap na de eerste login/registratie (ook Google/Apple,
/// en bestaande leden die de gegevens nog missen). Verzamelt geboortedatum + land +
/// minstens één vistijl (onder de 16 → automatisch jeugdmodus). Blokkerend: geen terug.
/// Wordt getoond door RootGate zolang user.needsOnboarding == true.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<Map<String, dynamic>> _discs = [];
  final Set<int> _picked = {};
  DateTime? _birthday;
  String? _country;
  String? _experience;
  String? _gender;
  final _city = TextEditingController();
  final _invite = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _agreed = false;
  String? _err;
  bool _bdBevestigd = false; // 31-10: alleen nodig bij 1-1-2001
  final _ouderMail = TextEditingController(); // 31-10: 13-15 jaar


  bool _datumVast = false; // 31-10: geboortedatum al bekend (bv. bij registratie ingevuld) → niet opnieuw vragen

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthState>().user;
    if (u != null && !u.needsBirthday && u.birthday != null) {
      _birthday = DateTime.tryParse(u.birthday!);
      _datumVast = _birthday != null;
    }
    _load();
  }

  @override
  void dispose() {
    _city.dispose();
    _invite.dispose();
    _ouderMail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await Api.get('/disciplines') as List<dynamic>;
      _discs = all.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // 31-10-2026: de kiezer opende op DateTime(now.year - 25) = 2001-01-01; wie meteen OK tikte kreeg die
  // datum (18 leden). Nu via kiesGeboortedatum (leeftijd_screens.dart): opent op vandaag, jaarweergave.

  Future<void> _submit() async {
    setState(() => _err = null);
    if (_birthday == null || _country == null || _picked.isEmpty) {
      setState(() => _err = oui(context, 'err_required'));
      return;
    }
    // Al een aanvraag bij registratie gedaan (pending/granted)? Dan geen ouder-e-mail meer nodig.
    final ag = ouderAlGevraagd(context.read<AuthState>().user?.parentConsent);
    final lftFout = controleerLeeftijdVelden(context, _birthday, _bdBevestigd || _datumVast, _ouderMail.text,
        alGevraagd: ag || _datumVast, teJongNaarServer: true);
    if (lftFout != null) {
      setState(() => _err = lftFout);
      return;
    }
    if (!_datumVast && !await bevestigTeJong(context, _birthday!)) return;
    if (!mounted) return;
    if (!_agreed) {
      setState(() => _err = oui(context, 'hr_required'));
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.post('/profile/onboarding', {
        ...leeftijdPayload(_birthday!, _bdBevestigd, _ouderMail.text, alGevraagd: ag),
        'country': _country,
        'disciplines': _picked.toList(),
        if (_experience != null) 'fishing_experience': _experience,
        if (_gender != null) 'gender': _gender,
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_invite.text.trim().isNotEmpty) 'invite_code': _invite.text.trim().toUpperCase(),
      });
      if (!mounted) return;
      // needsOnboarding wordt false → RootGate toont automatisch het HomeScreen.
      await context.read<AuthState>().refresh();
    } catch (e) {
      // Onder de 13: de server legt de datum vast en geeft age_too_young → het te-jong-scherm.
      if (e is ApiException && e.data is Map && e.data['code'] == 'age_too_young' && mounted) {
        await context.read<AuthState>().refresh();
        return;
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _err = e is ApiException ? e.message : oui(context, 'err_generic');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // verplichte stap — niet weg te navigeren
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.navy, AppColors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(oui(context, 'title'),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(oui(context, 'intro'),
                              style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Geboortedatum
                          _label('${oui(context, 'birthday')} *'),
                          if (_datumVast)
                            Padding(padding: const EdgeInsets.only(bottom: 4),
                              child: Text(fmtDatum(_birthday!), style: const TextStyle(fontSize: 15, color: AppColors.navy)))
                          else LeeftijdVelden(
                            datum: _birthday,
                            onDatum: (d) => setState(() { _birthday = d; _bdBevestigd = false; }),
                            bevestigd: _bdBevestigd,
                            onBevestigd: (v) => setState(() => _bdBevestigd = v),
                            ouderMail: _ouderMail,
                            alGevraagd: ouderAlGevraagd(context.watch<AuthState>().user?.parentConsent),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(oui(context, 'birthday_hint'),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ),
                          const SizedBox(height: 16),

                          // Land
                          _label('${oui(context, 'country')} *'),
                          DropdownButtonFormField<String>(
                            value: _country,
                            isExpanded: true,
                            decoration: _dec(),
                            hint: Text(oui(context, 'select')),
                            items: kOnbCountries
                                .map((c) => DropdownMenuItem<String>(
                                      value: c['v'] as String,
                                      child: Text('${c['flag']}  ${onbCountryName(context, c)}',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _country = v),
                          ),
                          const SizedBox(height: 16),

                          // Vistijlen
                          _label('${oui(context, 'disciplines')} *'),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(oui(context, 'disc_hint'),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _discs.map((d) {
                              final id = d['id'] as int;
                              final key = (d['key'] ?? '') as String;
                              final on = _picked.contains(id);
                              return FilterChip(
                                selected: on,
                                showCheckmark: false,
                                label: Text('${kDiscEmoji[key] ?? '\u{1F41F}'} ${discName(context, key)}'),
                                selectedColor: AppColors.teal,
                                labelStyle: TextStyle(color: on ? Colors.white : AppColors.navy),
                                onSelected: (_) => setState(() {
                                  on ? _picked.remove(id) : _picked.add(id);
                                }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          // Optioneel
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(oui(context, 'optional'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            children: [
                              _label(oui(context, 'experience')),
                              DropdownButtonFormField<String>(
                                value: _experience,
                                isExpanded: true,
                                decoration: _dec(),
                                hint: Text(oui(context, 'select')),
                                items: [
                                  DropdownMenuItem(value: 'beginner', child: Text(oui(context, 'exp_beginner'))),
                                  DropdownMenuItem(value: 'intermediate', child: Text(oui(context, 'exp_intermediate'))),
                                  DropdownMenuItem(value: 'advanced', child: Text(oui(context, 'exp_advanced'))),
                                  DropdownMenuItem(value: 'expert', child: Text(oui(context, 'exp_expert'))),
                                ],
                                onChanged: (v) => setState(() => _experience = v),
                              ),
                              const SizedBox(height: 12),
                              _label(oui(context, 'gender')),
                              DropdownButtonFormField<String>(
                                value: _gender,
                                isExpanded: true,
                                decoration: _dec(),
                                hint: Text(oui(context, 'select')),
                                items: [
                                  DropdownMenuItem(value: 'male', child: Text(oui(context, 'g_male'))),
                                  DropdownMenuItem(value: 'female', child: Text(oui(context, 'g_female'))),
                                  DropdownMenuItem(value: 'other', child: Text(oui(context, 'g_other'))),
                                  DropdownMenuItem(value: 'prefer_not_to_say', child: Text(oui(context, 'g_prefer'))),
                                ],
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                              const SizedBox(height: 12),
                              _label(oui(context, 'city')),
                              TextField(controller: _city, decoration: _dec(), maxLength: 120),
                              _label(oui(context, 'invite')),
                              TextField(controller: _invite, decoration: _dec().copyWith(hintText: oui(context, 'invite_hint')), maxLength: 10, textCapitalization: TextCapitalization.characters),
                            ],
                          ),

                          if (_err != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_err!,
                                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(height: 4),
                          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Checkbox(value: _agreed, activeColor: AppColors.teal,
                              onChanged: (v) => setState(() => _agreed = v ?? false)),
                            Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                              Text(oui(context, 'hr_accept'), style: const TextStyle(fontSize: 13.5)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://yessfish.com/huisregels'), mode: LaunchMode.externalApplication),
                                child: Text('(${oui(context, 'hr_link')})', style: const TextStyle(fontSize: 13.5, color: AppColors.teal, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                              ),
                            ])),
                          ]),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              onPressed: (_saving || !_agreed) ? null : _submit,
                              child: Text(_saving ? oui(context, 'saving') : oui(context, 'save'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
      );

  InputDecoration _dec() => const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        counterText: '',
      );
}
