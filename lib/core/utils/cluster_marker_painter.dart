import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Buat BitmapDescriptor bentuk lingkaran badge dg jumlah armada. (icon cluster)
class ClusterMarkerPainter {
  ClusterMarkerPainter._();

  // Ikon cluster lingkaran biru dengan angka [count]
  static Future<BitmapDescriptor> createClusterIcon(int count) async {
    // Ukuran lingkaran tergantung count
    final double size = 60 + (count * 2.0).clamp(0, 60);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint bgPaint = Paint()
      ..color = Colors.blueAccent.withAlpha(230)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 -4;

    // Lingkaran luar (semi-trasnparan)
    canvas.drawCircle(center, radius + 2, 
        Paint()..color = Colors.blueAccent.withAlpha(80));
        
    // Linkaran Utama
    canvas.drawCircle(center, radius, bgPaint);

    // Border putih
    canvas.drawCircle(center, radius, borderPaint);

    // Teks angka
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
          fontSize: size * 0.30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
} 