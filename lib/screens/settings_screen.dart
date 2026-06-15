import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth.dart';
import '../core/api.dart';
import '../core/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map _s = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final r = await Api.get('/profile/settings'); setState(() { _s = r; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }
  Future<void> _set(String key, bool v) async {
    setState(() => _s[key] = v);
    try { await Api.put('/profile/settings', {key: v}); } catch (_) {}
  }

  Future<void> _deleteAccount() async {
    final pw = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Account verwijderen'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Je account en alle gegevens worden definitief verwijderd. Dit kan niet ongedaan worden gemaakt.'),
        const SizedBox(height: 12),
        TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'Wachtwoord (leeg bij Google)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuleren')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Verwijderen')),
      ],
    ));
    if (ok != true) return;
    try {
      await Api.delete('/account', {'password': pw.text, 'confirm': true});
      if (mounted) await context.read<AuthState>().logout();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Column(children: [
          SwitchListTile(activeThumbColor: AppColors.teal, title: const Text('E-mailmeldingen'),
            value: _s['email_notifications'] != false, onChanged: (v) => _set('email_notifications', v)),
          SwitchListTile(activeThumbColor: AppColors.teal, title: const Text('Vangsten delen met community-bijtkans'),
            subtitle: const Text('Anoniem, maakt de voorspelling samen beter'),
            value: _s['share_catches_community'] != false, onChanged: (v) => _set('share_catches_community', v)),
        ])),
        const SizedBox(height: 16),
        Card(child: ListTile(leading: const Icon(Icons.logout), title: const Text('Uitloggen'),
          onTap: () => context.read<AuthState>().logout())),
        const SizedBox(height: 8),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFECDD3))),
          child: ListTile(leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: const Text('Account verwijderen', style: TextStyle(color: AppColors.danger)), onTap: _deleteAccount)),
      ]),
    );
  }
}
