import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';

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

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      await context.read<AuthState>().register({
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'first_name': _first.text.trim(),
        'password': _pw.text,
        'password_confirmation': _pw2.text,
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
          const SizedBox(height: 12),
          TextField(controller: _pw, obscureText: true, decoration: InputDecoration(labelText: context.tr('register.password'))),
          const SizedBox(height: 12),
          TextField(controller: _pw2, obscureText: true, decoration: InputDecoration(labelText: context.tr('register.password_confirm'))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr('register.submit')))),
        ]),
      ),
    );
  }
}
