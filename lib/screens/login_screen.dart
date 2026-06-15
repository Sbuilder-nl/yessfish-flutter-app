import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../core/auth.dart';
import '../core/api.dart';
import '../core/config.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      await context.read<AuthState>().login(_email.text.trim(), _pw.text);
    } on ApiException catch (e) {
      setState(() => _err = e.message);
    } catch (_) {
      setState(() => _err = 'Inloggen mislukt');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _err = null);
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: '${Config.apiBase}/auth/google/redirect?platform=app',
        callbackUrlScheme: 'nl.sbuilder.yessfish',
      );
      final params = Uri.parse(result).queryParameters;
      if (params['token'] != null && mounted) {
        await context.read<AuthState>().loginWithToken(params['token']!);
      } else if (mounted) {
        setState(() => _err = 'Google-login mislukt');
      }
    } catch (_) {
      // gebruiker brak af — geen melding nodig
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.set_meal, size: 56, color: AppColors.teal),
                const SizedBox(height: 8),
                const Text('YessFish', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const Text('Het sociale netwerk voor sportvissers', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 28),
                if (_err != null)
                  Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
                    child: Text(_err!, style: const TextStyle(color: AppColors.danger))),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 12),
                TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(labelText: 'Wachtwoord')),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Inloggen'))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _google,
                  icon: const Icon(Icons.g_mobiledata, size: 28), label: const Text('Inloggen met Google'))),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Nog geen account? Aanmelden'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
