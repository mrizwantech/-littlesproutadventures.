import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/shapes_curriculum.dart';

class ShapePicture extends StatelessWidget {
  const ShapePicture({
    super.key,
    required this.shape,
    required this.color,
    this.size = 100,
    this.rotation = 0,
    this.outline = 0,
  });

  final ShapeKind shape;
  final Color color;
  final double size;
  final double rotation;
  final double outline;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Transform.rotate(
          angle: rotation,
          child: CustomPaint(
            painter: _ShapePainter(shape, color, outline),
          ),
        ),
      );
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.shape, this.color, this.outline);
  final ShapeKind shape;
  final Color color;
  final double outline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    final path = switch (shape) {
      ShapeKind.circle => Path()..addOval(rect),
      ShapeKind.square => Path()..addRect(rect),
      ShapeKind.triangle => Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
    };
    canvas.drawPath(path, Paint()..color = color);
    if (outline > 0) {
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * math.min(1, outline)),
        Paint()
          ..color = const Color(0xFF102354)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) =>
      shape != oldDelegate.shape ||
      color != oldDelegate.color ||
      outline != oldDelegate.outline;
}
