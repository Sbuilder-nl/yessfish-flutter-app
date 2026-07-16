import "package:flutter/material.dart";
import "../core/api.dart";
import "../core/i18n.dart";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false, _done = false;
  String? _err;

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      await Api.post("/auth/forgot-password", {"email": _email.text.trim()});
      setState(() => _done = true);
    } catch (_) {
      setState(() => _err = context.tr("forgot.error"));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr("forgot.title"))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _done
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: Text(context.tr("forgot.done")),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.tr("forgot.back")))),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr("forgot.intro"), style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  if (_err != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_err!, style: const TextStyle(color: Colors.red))),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.tr("login.email"), border: const OutlineInputBorder())),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit,
                      child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(context.tr("forgot.submit")))),
                ]),
        ),
      ),
    );
  }
}
