import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Servicio para capturar widgets y compartir como imagen.
/// Usa RepaintBoundary + toImage (sin paquete screenshot).
class ShareService {
  static Future<void> captureAndShare(
    BuildContext context, {
    required Widget widget,
    required double width,
    required double height,
    double pixelRatio = 3,
  }) async {
    final key = GlobalKey();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Offstage(
        offstage: true,
        child: SizedBox(
          width: width,
          height: height,
          child: RepaintBoundary(
            key: key,
            child: widget,
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    entry.remove();
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/padelero_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    await Share.shareXFiles([XFile(file.path)]);
  }
}
