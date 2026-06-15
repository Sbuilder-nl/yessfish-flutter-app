import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String versionName;
  final String url;
  final String notes;
  UpdateInfo(this.versionName, this.url, this.notes);
}

/// Test-fase update-check (sideload). Vergelijkt versionCode met /app-version.json.
/// Voor de Play Store-release verwijderen — Play levert updates dan zelf.
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final current = int.tryParse(info.buildNumber) ?? 0;
    final res = await http.get(Uri.parse('https://yessfish.com/app-version.json')).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body);
    final latest = (j['versionCode'] ?? 0) as int;
    if (latest > current) {
      return UpdateInfo(j['versionName']?.toString() ?? '', j['url']?.toString() ?? '', j['notes']?.toString() ?? '');
    }
  } catch (_) {}
  return null;
}
