import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:google_sign_in/google_sign_in.dart";
import "../core/auth.dart";
import "../core/api.dart";
import "../core/config.dart";
import "../core/i18n.dart";
import "register_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  bool _gbusy = false;
  String? _err;

  final _gsi = GoogleSignIn(
    serverClientId: Config.googleServerClientId,
    scopes: const ["email", "profile"],
  );

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      await context.read<AuthState>().login(_email.text.trim(), _pw.text);
    } on ApiException catch (e) {
      setState(() => _err = e.message);
    } catch (_) {
      setState(() => _err = context.tr("login.login_failed"));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Native Google Sign-In: schone Android-accountkiezer, geen browser/Custom-Tab.
  // De app haalt het idToken op en wisselt dat bij onze server in voor een Sanctum-token.
  Future<void> _google() async {
    setState(() { _gbusy = true; _err = null; });
    try {
      await _gsi.signOut();
      final acc = await _gsi.signIn();
      if (acc == null) return; // gebruiker brak af
      final auth = await acc.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) setState(() => _err = context.tr("login.google_failed"));
        return;
      }
      final r = await Api.post("/auth/google/token", {"id_token": idToken});
      if (mounted) await context.read<AuthState>().loginWithToken(r["token"]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = e.message);
    } catch (_) {
      if (mounted) setState(() => _err = context.tr("login.google_failed"));
    } finally {
      if (mounted) setState(() => _gbusy = false);
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
                Image.asset("assets/logo.png", height: 84),
                const SizedBox(height: 10),
                const Text("YessFish", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.navy)),
                Text(context.tr("login.subtitle"), style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 28),
                if (_err != null)
                  Container(width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
                    child: Text(_err!, style: const TextStyle(color: AppColors.danger))),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.tr("login.email"))),
                const SizedBox(height: 12),
                TextField(controller: _pw, obscureText: true, decoration: InputDecoration(labelText: context.tr("login.password"))),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr("login.login")))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _gbusy ? null : _google,
                  icon: _gbusy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(context.tr("login.login_google")))),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text(context.tr("login.no_account")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
