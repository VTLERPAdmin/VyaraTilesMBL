import 'package:flutter/material.dart';

/// No-internet / connection-error screen for Vyara ERP.
/// Shows a bouncing paver-block character (static right arm, waving left
/// arm), a typewriter "Please turn on internet!" caption, a one-time
/// "VYARA / Welcome to Mobile ERP Application" fade-in header, and a
/// RETRY button.
///
/// Usage:
/// ```dart
/// NoInternetScreen(onRetry: () => loadData());
/// ```
class NoInternetScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  // Drives idle bounce + shadow pulse (2.6s loop, matches CSS).
  late final AnimationController _bounceController;
  // Drives the left forearm's elbow wave (0.8s loop, matches CSS).
  late final AnimationController _waveController;
  // Drives the typewriter caption (2.4s loop, matches CSS).
  late final AnimationController _typeController;
  // One-shot fade-in for the welcome header (1.4s, plays once).
  late final AnimationController _welcomeController;

  static const String _typedMessage = "Please turn on internet!";

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Matches CSS `animation: welcomeFadeIn 1.4s ease-out 0.3s forwards;`
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _welcomeController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _waveController.dispose();
    _typeController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ================= WELCOME HEADER (one-time fade-in) =================
                AnimatedBuilder(
                  animation: _welcomeController,
                  builder: (context, child) {
                    final t = Curves.easeOut.transform(_welcomeController.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 6 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      children: [
                        Text(
                          "VYARA",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            color: const Color(0xFF0A3A80),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Welcome to Mobile ERP Application",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7A93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ================= CHARACTER STAGE =================
                SizedBox(
                  width: 160,
                  height: 160,
                  child: AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      final t = _bounceController.value;
                      // 0,1 -> 0 ; 0.5 -> -8 (matches CSS idleBounce keyframes)
                      final bounceY = -8.0 *
                          (t <= 0.5
                              ? (t / 0.5)
                              : (1 - (t - 0.5) / 0.5));
                      final shadowScale = t <= 0.5
                          ? 1.0 - 0.15 * (t / 0.5)
                          : 0.85 + 0.15 * ((t - 0.5) / 0.5);
                      final shadowOpacity = t <= 0.5
                          ? 0.12 - 0.04 * (t / 0.5)
                          : 0.08 + 0.04 * ((t - 0.5) / 0.5);

                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Shadow
                          Positioned(
                            bottom: 8,
                            child: Transform.scale(
                              scale: shadowScale,
                              child: Container(
                                width: 64,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withOpacity(shadowOpacity),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ),
                          // Character (bounces vertically)
                          Positioned(
                            bottom: 18,
                            child: Transform.translate(
                              offset: Offset(0, bounceY),
                              child: AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, child) {
                                  final wt = _waveController.value;
                                  // -22deg..22deg, matches CSS elbowWave
                                  final waveAngle = -22 +
                                      44 *
                                          (wt <= 0.5
                                              ? (wt / 0.5)
                                              : (1 - (wt - 0.5) / 0.5));
                                  return SizedBox(
                                    width: 104,
                                    height: 134,
                                    child: CustomPaint(
                                      painter: _PaverCharacterPainter(
                                        waveAngleDegrees: waveAngle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 4),

                // ================= TYPEWRITER CAPTION =================
                SizedBox(
                  height: 20,
                  child: AnimatedBuilder(
                    animation: _typeController,
                    builder: (context, child) {
                      final t = _typeController.value;
                      // Matches @keyframes typeText: 0->0, 65%->full, 85%->full, 92%->0
                      int charCount;
                      if (t <= 0.65) {
                        charCount =
                            ((t / 0.65) * _typedMessage.length).floor();
                      } else if (t <= 0.85) {
                        charCount = _typedMessage.length;
                      } else if (t <= 0.92) {
                        final shrinkT = (t - 0.85) / 0.07;
                        charCount =
                            (_typedMessage.length * (1 - shrinkT)).ceil();
                      } else {
                        charCount = 0;
                      }
                      charCount = charCount.clamp(0, _typedMessage.length);

                      // Blinking cursor: matches @keyframes blinkCursor (0.6s)
                      final cursorOn =
                          (t * 2400 / 600).floor().isEven;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _typedMessage.substring(0, charCount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A3A80),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 16,
                            margin: const EdgeInsets.only(left: 2),
                            color: cursorOn
                                ? const Color(0xFF0A3A80)
                                : Colors.transparent,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ================= TITLE / SUBTITLE =================
                const Text(
                  "No Internet Connection",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2A26),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We couldn't reach the server.\n"
                  "Please check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF8A8276),
                  ),
                ),
                const SizedBox(height: 28),

                // ================= RETRY BUTTON =================
                ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3A80),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF0A3A80).withOpacity(0.35),
                  ),
                  child: const Text(
                    "RETRY",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the paver-block character: legs+feet, square body with chamfer
/// inset, static right arm+hand, and a two-piece left arm (fixed upper
/// arm + waving forearm+hand) — all coordinates ported directly from the
/// confirmed SVG (viewBox 0 -14 104 134).
class _PaverCharacterPainter extends CustomPainter {
  final double waveAngleDegrees;

  _PaverCharacterPainter({required this.waveAngleDegrees});

  static const Color _bodyFill = Color(0xFFE8B339);
  static const Color _bodyStroke = Color(0xFF9C6E0D);
  static const Color _footFill = Color(0xFFC99320);
  static const Color _faceColor = Color(0xFF2B2F36);
  static const Color _cheekColor = Color(0xFFE8A99A);

  // viewBox is "0 -14 104 134": x in [0,104], y in [-14, 120].
  static const double _vbX = 0;
  static const double _vbY = -14;
  static const double _vbW = 104;
  static const double _vbH = 134;

  Offset _map(double x, double y, Size size) {
    final sx = (x - _vbX) / _vbW * size.width;
    final sy = (y - _vbY) / _vbH * size.height;
    return Offset(sx, sy);
  }

  double _scaleX(Size size) => size.width / _vbW;
  double _scaleY(Size size) => size.height / _vbH;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = _bodyFill
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = _bodyStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;

    void drawPath(Path path, {double strokeWidth = 2.2}) {
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(
        path,
        Paint()
          ..color = _bodyStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // ---- RIGHT LEG ----
    final rightLeg = Path()
      ..moveTo2(this, size, 58, 86)
      ..quadTo2(this, size, 62, 96, 58, 106)
      ..lineTo2(this, size, 66, 108)
      ..quadTo2(this, size, 72, 96, 68, 84)
      ..close();
    drawPath(rightLeg);

    // right foot
    canvas.save();
    canvas.translate(_map(63, 110, size).dx, _map(63, 110, size).dy);
    canvas.scale(_scaleX(size), _scaleY(size));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 10),
      Paint()..color = _footFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 10),
      Paint()
        ..color = _bodyStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    // ---- LEFT LEG ----
    final leftLeg = Path()
      ..moveTo2(this, size, 44, 86)
      ..quadTo2(this, size, 40, 96, 44, 106)
      ..lineTo2(this, size, 36, 108)
      ..quadTo2(this, size, 30, 96, 34, 84)
      ..close();
    drawPath(leftLeg);

    // left foot
    canvas.save();
    canvas.translate(_map(39, 110, size).dx, _map(39, 110, size).dy);
    canvas.scale(_scaleX(size), _scaleY(size));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 10),
      Paint()..color = _footFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 10),
      Paint()
        ..color = _bodyStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    // ---- BODY (square paver, chamfer inset) ----
    final bodyRect = Rect.fromPoints(
      _map(20, 34, size),
      _map(84, 90, size),
    );
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.elliptical(4 * _scaleX(size), 4 * _scaleY(size)),
    );
    canvas.drawRRect(bodyRRect, fillPaint);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = _bodyStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // top highlight (subtle diagonal gradient)
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.6 * 0.4),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(bodyRect),
    );
    // chamfer inset
    final chamferRect = Rect.fromPoints(
      _map(25, 39, size),
      _map(79, 85, size),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        chamferRect,
        Radius.elliptical(2 * _scaleX(size), 2 * _scaleY(size)),
      ),
      Paint()
        ..color = _bodyStroke.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ---- RIGHT ARM + HAND (static) ----
    final rightArm = Path()
      ..moveTo2(this, size, 80, 48)
      ..quadTo2(this, size, 86, 58, 82, 68)
      ..lineTo2(this, size, 88, 70)
      ..quadTo2(this, size, 94, 58, 86, 46)
      ..close();
    drawPath(rightArm);

    _drawDiamond(canvas, size, 85.5, 70, 10, 10);

    // ---- LEFT ARM (fixed upper arm, shortened) ----
    final leftUpperArm = Path()
      ..moveTo2(this, size, 24, 48)
      ..quadTo2(this, size, 20, 53, 22, 58)
      ..lineTo2(this, size, 17, 59)
      ..quadTo2(this, size, 14, 53, 18, 47)
      ..close();
    drawPath(leftUpperArm);

    // ---- LEFT FOREARM + HAND (rotates at the elbow for the wave) ----
    final elbow = _map(18.5, 56, size);
    canvas.save();
    canvas.translate(elbow.dx, elbow.dy);
    canvas.rotate(waveAngleDegrees * 3.1415926535 / 180);
    canvas.translate(-elbow.dx, -elbow.dy);

    final forearm = Path()
      ..moveTo2(this, size, 22, 56)
      ..quadTo2(this, size, 16, 48, 20, 38)
      ..lineTo2(this, size, 14, 36)
      ..quadTo2(this, size, 8, 48, 16, 58)
      ..close();
    drawPath(forearm);

    _drawDiamond(canvas, size, 18.5, 34, 10, 10);

    canvas.restore();

    // ---- FACE ----
    final facePaint = Paint()
      ..color = _faceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo2(this, size, 34, 58)
      ..quadTo2(this, size, 38, 53, 42, 58);
    canvas.drawPath(leftEye, facePaint);

    final rightEye = Path()
      ..moveTo2(this, size, 62, 58)
      ..quadTo2(this, size, 66, 53, 70, 58);
    canvas.drawPath(rightEye, facePaint);

    final smile = Path()
      ..moveTo2(this, size, 36, 66)
      ..quadTo2(this, size, 52, 80, 68, 66);
    canvas.drawPath(
      smile,
      Paint()
        ..color = _faceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // rosy cheeks
    canvas.save();
    canvas.translate(_map(30, 64, size).dx, _map(30, 64, size).dy);
    canvas.scale(_scaleX(size), _scaleY(size));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 5.2),
      Paint()..color = _cheekColor.withOpacity(0.6),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(_map(74, 64, size).dx, _map(74, 64, size).dy);
    canvas.scale(_scaleX(size), _scaleY(size));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 5.2),
      Paint()..color = _cheekColor.withOpacity(0.6),
    );
    canvas.restore();
  }

  void _drawDiamond(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    final center = _map(cx, cy, size);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(45 * 3.1415926535 / 180);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: w * _scaleX(size),
      height: h * _scaleY(size),
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(2.5 * _scaleX(size)),
    );
    canvas.drawRRect(rrect, Paint()..color = _bodyFill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _bodyStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PaverCharacterPainter oldDelegate) {
    return oldDelegate.waveAngleDegrees != waveAngleDegrees;
  }
}

/// Small helper extension so Path construction can reference the
/// painter's viewBox-to-canvas mapping inline, matching the SVG
/// coordinates 1:1 without manually converting every point.
extension _PathViewBoxHelpers on Path {
  void moveTo2(
    _PaverCharacterPainter painter,
    Size size,
    double x,
    double y,
  ) {
    final p = painter._map(x, y, size);
    moveTo(p.dx, p.dy);
  }

  void lineTo2(
    _PaverCharacterPainter painter,
    Size size,
    double x,
    double y,
  ) {
    final p = painter._map(x, y, size);
    lineTo(p.dx, p.dy);
  }

  void quadTo2(
    _PaverCharacterPainter painter,
    Size size,
    double cx,
    double cy,
    double x,
    double y,
  ) {
    final c = painter._map(cx, cy, size);
    final p = painter._map(x, y, size);
    quadraticBezierTo(c.dx, c.dy, p.dx, p.dy);
  }
}