import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vraag één keer om een beoordeling, op een blij moment (direct na een gelogde vangst).
/// De store zelf beperkt hoe vaak het dialoogje echt verschijnt.
Future<void> maybeAskReview() async {
  try {
    final p = await SharedPreferences.getInstance();
    final n = (p.getInt('review_catches') ?? 0) + 1;
    await p.setInt('review_catches', n);
    if (p.getBool('review_asked') == true || n < 1) return;
    await Future.delayed(const Duration(milliseconds: 1200));
    final r = InAppReview.instance;
    if (await r.isAvailable()) { await p.setBool('review_asked', true); await r.requestReview(); }
  } catch (_) {}
}
