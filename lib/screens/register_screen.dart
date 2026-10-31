import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../widgets/email_typo_hint.dart';
import '../core/leeftijd_i18n.dart';
import 'leeftijd_screens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _first = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;
  String? _err;
  // 31-10-2026: geboortedatum verplicht; < 13 geen account; 13-15 e-mailadres van een ouder of voogd.
  DateTime? _bd;
  bool _bdBevestigd = false;
  final _ouderMail = TextEditingController();

  @override
  void dispose() {
    for (final c in [_username, _email, _first, _pw, _pw2, _ouderMail]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    final lftFout = controleerLeeftijdVelden(context, _bd, _bdBevestigd, _ouderMail.text);
    if (lftFout != null) { setState(() => _err = lftFout); return; }
    setState(() { _busy = true; _err = null; });
    try {
      await context.read<AuthState>().register({
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'first_name': _first.text.trim(),
        'password': _pw.text,
        'password_confirmation': _pw2.text,
        ...leeftijdPayload(_bd!, _bdBevestigd, _ouderMail.text),
      });
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _err = e.message);
    } catch (_) {
      setState(() => _err = context.tr('register.register_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('register.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          if (_err != null)
            Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
              child: Text(_err!, style: const TextStyle(color: AppColors.danger))),
          TextField(controller: _first, decoration: InputDecoration(labelText: context.tr('register.first_name'))),
          const SizedBox(height: 12),
          TextField(controller: _username, decoration: InputDecoration(labelText: context.tr('register.username'))),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.tr('register.email'))),
          EmailTypoHint(controller: _email),
          const SizedBox(height: 12),
          TextField(controller: _pw, obscureText: true, decoration: InputDecoration(labelText: context.tr('register.password'))),
          const SizedBox(height: 12),
          TextField(controller: _pw2, obscureText: true, decoration: InputDecoration(labelText: context.tr('register.password_confirm'))),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 6),
            child: Text('${lft(context, 'birthday')} *', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)))),
          LeeftijdVelden(datum: _bd, onDatum: (d) => setState(() { _bd = d; _bdBevestigd = false; _err = null; }),
            bevestigd: _bdBevestigd, onBevestigd: (v) => setState(() => _bdBevestigd = v), ouderMail: _ouderMail),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr('register.submit')))),
        ]),
      ),
    );
  }
}
