import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum SwordStage {
  raw,      // 0–6 dias
  heating,  // 7–29
  forged,   // 30–59
  sharp,    // 60–89
  complete; // 90+

  static SwordStage fromDays(int days) {
    if (days >= 90) return complete;
    if (days >= 60) return sharp;
    if (days >= 30) return forged;
    if (days >= 7)  return heating;
    return raw;
  }

  String get label => switch (this) {
        raw      => 'FERRO BRUTO',
        heating  => 'AQUECENDO',
        forged   => 'MOLDADA',
        sharp    => 'AFIADA',
        complete => 'COMPLETA',
      };
}

class SwordWidget extends StatefulWidget {
  const SwordWidget({super.key, required this.days});

  final int days;

  @override
  State<SwordWidget> createState() => _SwordWidgetState();
}

class _SwordWidgetState extends State<SwordWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _pulse;

  SwordStage get _stage => SwordStage.fromDays(widget.days);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _pulseMsFor(_stage)),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  int _pulseMsFor(SwordStage s) => switch (s) {
        SwordStage.raw      => 3200,
        SwordStage.heating  => 2600,
        SwordStage.forged   => 2000,
        SwordStage.sharp    => 1500,
        SwordStage.complete => 1100,
      };

  @override
  void didUpdateWidget(SwordWidget old) {
    super.didUpdateWidget(old);
    final newStage = _stage;
    if (newStage != SwordStage.fromDays(old.days)) {
      _pulseController.duration = Duration(milliseconds: _pulseMsFor(newStage));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulse, _particleController]),
          builder: (_, child) => CustomPaint(
            size: const Size(120, 300),
            painter: SwordPainter(
              stage: stage,
              pulse: _pulse.value,
              particle: _particleController.value,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stage.label,
          style: const TextStyle(
            color: ForjaColors.textSecondary,
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SwordPainter extends CustomPainter {
  const SwordPainter({
    required this.stage,
    required this.pulse,
    required this.particle,
  });

  final SwordStage stage;
  final double pulse;    // 0..1 eased, repeating reverse
  final double particle; // 0..1 linear, repeating

  // ── Geometry ─────────────────────────────────────────────────────

  Path _blade(Size s) {
    final cx = s.width / 2;
    return Path()
      ..moveTo(cx, s.height * 0.040)
      ..lineTo(cx + s.width * 0.085, s.height * 0.540)
      ..lineTo(cx - s.width * 0.085, s.height * 0.540)
      ..close();
  }

  Path _guard(Size s) {
    final cx = s.width / 2;
    final cy = s.height * 0.566;
    final hw = s.width * 0.300;
    final hh = s.height * 0.022;
    final taper = hw * 0.12;
    return Path()
      ..moveTo(cx - hw, cy)
      ..lineTo(cx - hw + taper, cy - hh)
      ..lineTo(cx + hw - taper, cy - hh)
      ..lineTo(cx + hw, cy)
      ..lineTo(cx + hw - taper, cy + hh)
      ..lineTo(cx - hw + taper, cy + hh)
      ..close();
  }

  Path _grip(Size s) {
    final cx = s.width / 2;
    final hw = s.width * 0.065;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - hw, s.height * 0.588, cx + hw, s.height * 0.800),
        const Radius.circular(4),
      ));
  }

  Path _pommel(Size s) {
    final cx = s.width / 2;
    final r = s.width * 0.110;
    return Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, s.height * 0.874),
        width: r * 2,
        height: r * 2.4,
      ));
  }

  // Rough iron blob — no sword form yet
  Path _rawBlob(Size s) {
    final cx = s.width / 2;
    return Path()
      ..moveTo(cx + 5,  s.height * 0.12)
      ..lineTo(cx + 20, s.height * 0.22)
      ..lineTo(cx + 24, s.height * 0.37)
      ..lineTo(cx + 17, s.height * 0.50)
      ..lineTo(cx + 22, s.height * 0.62)
      ..lineTo(cx + 13, s.height * 0.78)
      ..lineTo(cx +  2, s.height * 0.84)
      ..lineTo(cx -  9, s.height * 0.81)
      ..lineTo(cx - 18, s.height * 0.70)
      ..lineTo(cx - 13, s.height * 0.55)
      ..lineTo(cx - 21, s.height * 0.40)
      ..lineTo(cx - 14, s.height * 0.23)
      ..lineTo(cx -  3, s.height * 0.11)
      ..close();
  }

  // ── Stage painters ────────────────────────────────────────────────

  void _paintRaw(Canvas canvas, Size s) {
    final blob = _rawBlob(s);

    canvas.drawPath(blob, Paint()..color = const Color(0xFF252525));
    canvas.drawPath(blob, Paint()
      ..color = const Color(0xFF3E3E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    // Faint forge-heat glow
    canvas.drawPath(blob, Paint()
      ..color = ForjaColors.ember.withValues(alpha: pulse * 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }

  void _paintHeating(Canvas canvas, Size s) {
    _glow(canvas, s, blur: 14, alpha: 0.22 + pulse * 0.22);

    const body = Color(0xFF261000);
    _fillAll(canvas, s, color: body);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ForjaColors.ember.withValues(alpha: 0.55 + pulse * 0.35);
    _strokeAll(canvas, s, paint: edge);
  }

  void _paintForged(Canvas canvas, Size s) {
    _glow(canvas, s, blur: 18, alpha: 0.30 + pulse * 0.28);

    _fillAll(canvas, s,
        color: Color.lerp(const Color(0xFF3A1600), const Color(0xFF5A2800), pulse)!);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = ForjaColors.ember.withValues(alpha: 0.75 + pulse * 0.25);
    _strokeAll(canvas, s, paint: edge);

    _edgeShimmer(canvas, s, opacity: 0.28 + pulse * 0.22);
  }

  void _paintSharp(Canvas canvas, Size s) {
    _glow(canvas, s, blur: 28, alpha: 0.20 + pulse * 0.18);
    _glow(canvas, s, blur: 10, alpha: 0.48 + pulse * 0.30);

    canvas.drawPath(
        _blade(s),
        Paint()
          ..color =
              Color.lerp(ForjaColors.emberDim, ForjaColors.ember, pulse)!);
    final metalColor =
        Color.lerp(const Color(0xFF4A2000), ForjaColors.emberDim, pulse)!;
    canvas.drawPath(_guard(s), Paint()..color = metalColor);
    canvas.drawPath(_grip(s), Paint()..color = metalColor);
    canvas.drawPath(_pommel(s), Paint()..color = metalColor);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ForjaColors.emberGlow.withValues(alpha: 0.80 + pulse * 0.20);
    canvas.drawPath(_blade(s), edge);
    canvas.drawPath(_guard(s), edge);

    _edgeShimmer(canvas, s, opacity: 0.60 + pulse * 0.30);
    _tipFlare(canvas, s, opacity: 0.60 + pulse * 0.40);
  }

  void _paintComplete(Canvas canvas, Size s) {
    _glow(canvas, s, blur: 44, alpha: 0.16 + pulse * 0.12);
    _glow(canvas, s, blur: 14, alpha: 0.55 + pulse * 0.30);

    canvas.drawPath(
        _blade(s),
        Paint()
          ..color =
              Color.lerp(ForjaColors.ember, ForjaColors.emberGlow, pulse)!);
    canvas.drawPath(_guard(s), Paint()..color = ForjaColors.ember);
    canvas.drawPath(_grip(s), Paint()..color = ForjaColors.emberDim);
    canvas.drawPath(_pommel(s), Paint()..color = ForjaColors.ember);

    // White sheen over blade
    canvas.drawPath(_blade(s), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.50 + pulse * 0.40));

    _edgeShimmer(canvas, s, opacity: 0.85 + pulse * 0.15);
    _tipFlare(canvas, s, opacity: 0.90);
    _particles(canvas, s);
  }

  // ── Shared effects ────────────────────────────────────────────────

  void _glow(Canvas canvas, Size s,
      {required double blur, required double alpha}) {
    final p = Paint()
      ..color = ForjaColors.ember.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawPath(_blade(s), p);
    canvas.drawPath(_guard(s), p);
    canvas.drawPath(_grip(s), p);
    canvas.drawPath(_pommel(s), p);
  }

  void _fillAll(Canvas canvas, Size s, {required Color color}) {
    final p = Paint()..color = color;
    canvas.drawPath(_blade(s), p);
    canvas.drawPath(_guard(s), p);
    canvas.drawPath(_grip(s), p);
    canvas.drawPath(_pommel(s), p);
  }

  void _strokeAll(Canvas canvas, Size s, {required Paint paint}) {
    canvas.drawPath(_blade(s), paint);
    canvas.drawPath(_guard(s), paint);
    canvas.drawPath(_grip(s), paint);
    canvas.drawPath(_pommel(s), paint);
  }

  void _edgeShimmer(Canvas canvas, Size s, {required double opacity}) {
    final cx = s.width / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx, s.height * 0.040)
        ..lineTo(cx + s.width * 0.085, s.height * 0.540),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _tipFlare(Canvas canvas, Size s, {required double opacity}) {
    canvas.drawCircle(
      Offset(s.width / 2, s.height * 0.040),
      3.0 + pulse * 2.5,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, 5.0 + pulse * 4.0),
    );
  }

  // Deterministic particle x-offsets (relative to center, fraction of canvas width)
  static const _px = [
    0.06, -0.19, 0.31, -0.44, 0.13, 0.27,
    -0.23, 0.40, -0.09, 0.34, -0.29, 0.16, -0.39, 0.22,
  ];

  void _particles(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final bottom = s.height * 0.540;
    final top = s.height * 0.040;
    final count = _px.length;

    for (var i = 0; i < count; i++) {
      final t = (particle + i / count) % 1.0;
      final y = bottom + (top - bottom) * t - 14 * t;
      final x = cx + _px[i] * s.width + math.sin(t * math.pi * 2.5 + i) * 7;
      final alpha = (1.0 - t) * 0.88;
      final r = (1 - t) * 2.8 + 0.4;

      if (alpha < 0.06) continue;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = ForjaColors.ember.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ── CustomPainter ─────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) => switch (stage) {
        SwordStage.raw      => _paintRaw(canvas, size),
        SwordStage.heating  => _paintHeating(canvas, size),
        SwordStage.forged   => _paintForged(canvas, size),
        SwordStage.sharp    => _paintSharp(canvas, size),
        SwordStage.complete => _paintComplete(canvas, size),
      };

  @override
  bool shouldRepaint(SwordPainter old) =>
      old.stage != stage || old.pulse != pulse || old.particle != particle;
}
