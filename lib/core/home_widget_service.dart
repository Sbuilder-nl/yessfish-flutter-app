import 'dart:io';
import 'dart:ui' as ui;
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'api.dart';
import 'location.dart';

/// Schrijft de laatste openbare vangst (met foto) + het weer naar de Android home-screen widget.
class YfHomeWidget {
  static const _name = 'YfWidgetProvider';
  static const _qualified = 'nl.sbuilder.yessfish.YfWidgetProvider';

  static Future<void> refresh(String lang) async {
    String? photoUrl;
    // Laatste openbare vangst — met fallback (/catches/map) zodat het ook werkt vóór de nieuwe backend live is.
    try {
      Map? d;
      try {
        final r = await Api.get('/catches/latest-public');
        d = r is Map ? r['data'] as Map? : null;
      } catch (_) { d = null; }
      if (d == null) {
        final m = await Api.get('/catches/map');
        if (m is List && m.isNotEmpty) d = m.first as Map;
      }
      if (d != null) {
        await HomeWidget.saveWidgetData<String>('latest_species', '${d['species'] ?? ''}');
        await HomeWidget.saveWidgetData<String>('latest_user', '${d['username'] ?? ''}');
        if (d['id'] != null) await HomeWidget.saveWidgetData<String>('latest_catch_id', '${d['id']}');
        photoUrl = d['photo_path']?.toString();
      }
    } catch (_) {}

    // Foto → kleine thumbnail → bestand dat de widget toont.
    try {
      if (photoUrl != null && photoUrl.startsWith('http')) {
        final resp = await http.get(Uri.parse(photoUrl)).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final dir = await getApplicationSupportDirectory();
          final raw = File('${dir.path}/widget_raw.jpg');
          await raw.writeAsBytes(resp.bodyBytes);
          final out = '${dir.path}/widget_catch.jpg';
          final f = File(out); if (await f.exists()) { await f.delete(); }
          final thumb = await FlutterImageCompress.compressAndGetFile(raw.path, out, minWidth: 240, minHeight: 240, quality: 80);
          final rounded = thumb != null ? await _roundThumb(thumb.path, 26) : null;
          await HomeWidget.saveWidgetData<String>('latest_photo', rounded ?? thumb?.path ?? '');
        } else {
          await HomeWidget.saveWidgetData<String>('latest_photo', '');
        }
      } else {
        await HomeWidget.saveWidgetData<String>('latest_photo', '');
      }
    } catch (_) {
      await HomeWidget.saveWidgetData<String>('latest_photo', '');
    }

    // Weer op je locatie (kort: temp · omschrijving · wind).
    try {
      final loc = await currentLocation();
      final w = await Api.get('/weather?lat=${loc.lat}&lng=${loc.lng}');
      if (w is Map && w['temperature_c'] != null) {
        final t = (w['temperature_c'] as num).round();
        final desc = (w['description'] ?? '').toString();
        const dirs = ['N','NO','O','ZO','Z','ZW','W','NW']; // API-teksten zijn NL, dus NL-windstreken
        final dir = w['wind_deg'] != null ? ' ${dirs[(((w['wind_deg'] as num).round() % 360) ~/ 45) % 8]}' : '';
        final wind = w['wind_speed_ms'] != null ? '${(w['wind_speed_ms'] as num).round()} m/s$dir' : '';
        final parts = <String>['$t°', if (desc.isNotEmpty) desc, if (wind.isNotEmpty) wind];
        await HomeWidget.saveWidgetData<String>('weather_text', '🌤️ ${parts.join(' · ')}');
      }
    } catch (_) {}


    try {
      await HomeWidget.updateWidget(name: _name, androidName: _name, qualifiedAndroidName: _qualified);
    } catch (_) {}
  }

  // Rondt de foto af (transparante hoeken) zodat de widget-foto nette ronde hoeken heeft.
  static Future<String?> _roundThumb(String path, double radius) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final img = (await codec.getNextFrame()).image;
      final w = img.width, h = img.height;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final rrect = ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Radius.circular(radius));
      canvas.clipRRect(rrect);
      canvas.drawImage(img, ui.Offset.zero, ui.Paint());
      final out = await recorder.endRecording().toImage(w, h);
      final png = await out.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return null;
      final f = File(path.replaceAll('.jpg', '_r.png'));
      await f.writeAsBytes(png.buffer.asUint8List());
      return f.path;
    } catch (_) {
      return null;
    }
  }
}
