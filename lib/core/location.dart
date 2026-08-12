import 'package:geolocator/geolocator.dart';

class LatLng {
  final double lat, lng;
  final double? accuracy; // nauwkeurigheid in meters; null/<0 = geen echte fix
  const LatLng(this.lat, this.lng, {this.accuracy});
  bool get isReal => accuracy != null && accuracy! >= 0;
}

// Steenwijk als veilige fallback (NL). accuracy < 0 = GEEN echte fix.
const LatLng kFallback = LatLng(52.78, 6.12, accuracy: -1);

/// Verse, nauwkeurige locatie. BELANGRIJK: we pakken NIET meer blind
/// getLastKnownPosition() als eerste — die kan uren oud en kilometers
/// verderop zijn (oorzaak van "iemand staat heel ergens anders").
/// We vragen een echte high-accuracy GPS-fix; lukt dat niet, dan alleen
/// een laatst-bekende positie als die nog redelijk nauwkeurig is.
Future<LatLng> currentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return kFallback;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return kFallback;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
    return LatLng(pos.latitude, pos.longitude, accuracy: pos.accuracy);
  } catch (_) {
    // Eén nette terugval: laatst bekende positie, maar alleen als ze écht
    // nauwkeurig is (<= 100 m). Anders géén nep-locatie teruggeven.
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && last.accuracy > 0 && last.accuracy <= 100) {
        return LatLng(last.latitude, last.longitude, accuracy: last.accuracy);
      }
    } catch (_) {}
    return kFallback;
  }
}

/// Scherpe GPS-fix voor plekken die ECHT moeten kloppen (stek plaatsen).
/// Luistert enkele seconden naar de GPS-stream en houdt de beste meting bij:
/// klaar zodra de fix <= [goodEnough] m is, anders na [timeout] de beste die
/// er was. GEEN terugval op een laatst-bekende positie — liever geen fix dan
/// een stek die meters verkeerd staat.
Future<LatLng> preciseLocation({double goodEnough = 8, Duration timeout = const Duration(seconds: 15)}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return kFallback;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return kFallback;
    Position? best;
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0),
    ).timeout(timeout, onTimeout: (sink) => sink.close());
    await for (final p in stream) {
      if (p.accuracy <= 0) continue;
      if (best == null || p.accuracy < best.accuracy) best = p;
      if (p.accuracy <= goodEnough) break;
    }
    if (best != null) return LatLng(best.latitude, best.longitude, accuracy: best.accuracy);
    // Stream gaf niets → één losse verse poging (nog steeds geen oude cache).
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).timeout(const Duration(seconds: 10));
    return LatLng(pos.latitude, pos.longitude, accuracy: pos.accuracy);
  } catch (_) {
    return kFallback;
  }
}
