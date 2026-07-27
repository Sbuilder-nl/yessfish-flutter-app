import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';

/// Draaiend YessFish-dobbertje als laad-animatie (huisstijl).
class DobberLoader extends StatefulWidget {
  final double size;
  const DobberLoader({super.key, this.size = 64});
  @override
  State<DobberLoader> createState() => _DobberLoaderState();
}

class _DobberLoaderState extends State<DobberLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: Image.asset('assets/marker_dobber.png', width: widget.size, height: widget.size),
      );
}

/// Voortgang van een upload: fase ('compress' | 'upload') + 0..1 voortgang.
class UploadState {
  final String phase;
  final double progress;
  const UploadState(this.phase, this.progress);
}

const _lbl = {
  'compress': {'nl': 'Video voorbereiden…', 'en': 'Preparing video…', 'de': 'Video wird vorbereitet…', 'fr': 'Préparation de la vidéo…', 'es': 'Preparando vídeo…', 'pl': 'Przygotowywanie wideo…'},
  'upload': {'nl': 'Uploaden…', 'en': 'Uploading…', 'de': 'Wird hochgeladen…', 'fr': 'Téléversement…', 'es': 'Subiendo…', 'pl': 'Przesyłanie…'},
};

/// Nette upload-overlay met het draaiende dobbertje + status + %.
class UploadOverlay extends StatelessWidget {
  final ValueListenable<UploadState> info;
  const UploadOverlay(this.info, {super.key});
  @override
  Widget build(BuildContext context) {
    String lang = 'nl';
    try { lang = Provider.of<I18n>(context, listen: false).flutterLocale.languageCode; } catch (_) {}
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ValueListenableBuilder<UploadState>(
          valueListenable: info,
          builder: (_, v, __) {
            final label = _lbl[v.phase]?[lang] ?? _lbl[v.phase]?['en'] ?? '…';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const DobberLoader(size: 64),
                const SizedBox(height: 18),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A3D62), fontSize: 15)),
                if (v.progress > 0) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: 170, child: ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: v.progress.clamp(0.0, 1.0), minHeight: 7, backgroundColor: const Color(0xFFE8EEF3), color: const Color(0xFF1F8A70)))),
                  const SizedBox(height: 6),
                  Text('${(v.progress.clamp(0.0, 1.0) * 100).round()}%', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ]),
            );
          },
        ),
      ),
    );
  }
}
