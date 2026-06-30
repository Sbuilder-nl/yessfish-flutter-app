import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/auth.dart';
import '../core/api.dart';
import '../core/config.dart';
import '../core/i18n.dart';
import '../core/disciplines_i18n.dart';
import 'disciplines_screen.dart';

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
    try { await Api.put('/profile/settings', {key: v}); }
    catch (e) { if (mounted) setState(() => _s[key] = !v); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Er ging iets mis'))); }
  }

  Future<void> _deleteAccount() async {
    final pw = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('settings.delete_title')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.tr('settings.delete_body')),
        const SizedBox(height: 12),
        TextField(controller: pw, obscureText: true, decoration: InputDecoration(labelText: context.tr('settings.delete_password'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('settings.cancel'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('settings.delete'))),
      ],
    ));
    if (ok != true) return;
    try {
      await Api.delete('/account', {'password': pw.text, 'confirm': true});
      if (!mounted) return;
      final nav = Navigator.of(context);
      await context.read<AuthState>().logout();
      nav.popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings.title'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: ListTile(
          leading: const Icon(Icons.language, color: AppColors.teal),
          title: Text(context.tr('settings.language')),
          trailing: DropdownButton<String>(
            value: context.watch<I18n>().locale,
            underline: const SizedBox.shrink(),
            items: I18n.languages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) { if (v != null) context.read<I18n>().setLocale(v); },
          ),
        )),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.style_outlined, color: AppColors.teal),
          title: Text(dui(context, 'title')),
          subtitle: Text(dui(context, 'hint')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplinesScreen())),
        )),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          SwitchListTile(activeThumbColor: AppColors.teal, title: Text(context.tr('settings.email_notifications')),
            value: _s['email_notifications'] != false, onChanged: (v) => _set('email_notifications', v)),
          SwitchListTile(activeThumbColor: AppColors.teal, title: Text(context.tr('settings.share_catches')),
            subtitle: Text(context.tr('settings.share_catches_sub')),
            value: _s['share_catches_community'] != false, onChanged: (v) => _set('share_catches_community', v)),
        ])),
        const SizedBox(height: 16),
        Card(child: ListTile(
          leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.teal),
          title: Text(context.tr('priv.title')),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => launchUrl(Uri.parse('https://yessfish.com/privacy'), mode: LaunchMode.externalApplication),
        )),
        const SizedBox(height: 8),
        Card(child: ListTile(leading: const Icon(Icons.logout), title: Text(context.tr('settings.logout')),
          onTap: () async { final nav = Navigator.of(context); await context.read<AuthState>().logout(); nav.popUntil((r) => r.isFirst); })),
        const SizedBox(height: 8),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFECDD3))),
          child: ListTile(leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: Text(context.tr('settings.delete_account'), style: const TextStyle(color: AppColors.danger)), onTap: _deleteAccount)),
        const SizedBox(height: 20),
        Center(child: Text('YessFish · ${context.tr('settings.version')} ${Config.appVersion}', style: const TextStyle(color: Colors.black38, fontSize: 12))),
      ]),
    );
  }
}
