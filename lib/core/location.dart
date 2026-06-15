import 'package:geolocator/geolocator.dart';

class LatLng {
  final double lat, lng;
  const LatLng(this.lat, this.lng);
}

// Steenwijk als veilige fallback (NL).
const LatLng kFallback = LatLng(52.78, 6.12);

Future<LatLng> currentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return kFallback;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return kFallback;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(const Duration(seconds: 8));
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return kFallback;
  }
}
