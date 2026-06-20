import 'package:flutter/material.dart';

/// Replacement loading screen for Vyara ERP.
/// Premium/minimal style: copper gradient card, a traced square + brick
/// rectangle mark, alternating "TILES" / "FREE FORM" caption, and a thin
/// sliding progress line. `title` and `subtitle` are kept for backward
/// compatibility with existing call sites (LoaderService.show(...)).
class VyaraLoaderScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const VyaraLoaderScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<VyaraLoaderScreen> createState() => _VyaraLoaderScreenState();
}

class _VyaraLoaderScreenState extends State<VyaraLoaderScreen>
    with TickerProviderStateMixin {
  // Two controllers run independently (trace + text-swap/progress loop),
  // so this State needs TickerProviderStateMixin, not the Single- variant.
  late final AnimationController _traceController;
  late final AnimationController _loopController;

  static const Duration _traceDuration = Duration(milliseconds: 2400);
  static const Duration _loopDuration = Duration(milliseconds: 4000);

  @override
  void initState() {
    super.initState();

    _traceController = AnimationController(
      vsync: this,
      duration: _traceDuration,
    )..repeat();

    _loopController = AnimationController(
      vsync: this,
      duration: _loopDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _traceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  // Mirrors the CSS keyframes: 0% -> dashoffset start, 55% -> fully drawn
  // (offset 0), 100% -> dashoffset reversed (erasing in the same direction).
  // We express this as a 0..1 "draw amount" for the square and rectangle.
  double _drawAmount(double t) {
    if (t <= 0.55) {
      // 0 -> 1 over [0, 0.55]
      return (t / 0.55).clamp(0.0, 1.0);
    } else {
      // 1 -> 0 over [0.55, 1.0]
      final localT = (t - 0.55) / 0.45;
      return (1.0 - localT).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final cardWidth = (size.width * 0.85).clamp(260.0, 320.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: cardWidth,
            maxHeight: size.height * 0.85,
          ),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                    Color(0xFF1F4E8C),
                    Color(0xFF0A3A80),
                    Color(0xFF082C61),
                    Color(0xFF061A3A),
                  ],
                stops: [0.0, 0.45, 0.75, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ================= BRAND =================
                Text(
                  "VYARA",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: const Color(0xFFFBF1E6),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= TRACED MARK =================
                AnimatedBuilder(
                  animation: _traceController,
                  builder: (context, child) {
                    final t = _traceController.value;
                    return SizedBox(
                      width: 60,
                      height: 44,
                      child: CustomPaint(
                        painter: _TracedMarkPainter(
                          squareDraw: _drawAmount(t),
                          // Rectangle starts 0.15s into the loop, like the
                          // CSS animation-delay, so compute its own phase.
                          rectDraw: _drawAmount(
                            ((t * _traceDuration.inMilliseconds + 150) %
                                    _traceDuration.inMilliseconds) /
                                _traceDuration.inMilliseconds,
                          ),
                          color: const Color(0xFFFBF1E6),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                // ================= TILES / FREE FORM TEXT SWAP =================
                AnimatedBuilder(
                  animation: _loopController,
                  builder: (context, child) {
                    final t = _loopController.value; // 0..1 over 4s

                    double tilesOpacity;
                    if (t <= 0.20) {
                      tilesOpacity = 1.0;
                    } else if (t <= 0.32) {
                      tilesOpacity = 1.0 - ((t - 0.20) / 0.12);
                    } else if (t <= 0.68) {
                      tilesOpacity = 0.0;
                    } else if (t <= 0.80) {
                      tilesOpacity = (t - 0.68) / 0.12;
                    } else {
                      tilesOpacity = 1.0;
                    }

                    double freeFormOpacity;
                    if (t <= 0.32) {
                      freeFormOpacity = 0.0;
                    } else if (t <= 0.44) {
                      freeFormOpacity = (t - 0.32) / 0.12;
                    } else if (t <= 0.56) {
                      freeFormOpacity = 1.0;
                    } else if (t <= 0.68) {
                      freeFormOpacity = 1.0 - ((t - 0.56) / 0.12);
                    } else {
                      freeFormOpacity = 0.0;
                    }

                    return SizedBox(
                      height: 18,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: tilesOpacity.clamp(0.0, 1.0),
                            child: const _SwapText("TILES"),
                          ),
                          Opacity(
                            opacity: freeFormOpacity.clamp(0.0, 1.0),
                            child: const _SwapText("FREE FORM"),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ================= PROGRESS LINE =================
                AnimatedBuilder(
                  animation: _traceController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 64,
                      height: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(
                              color: const Color(0xFFFBF1E6).withOpacity(0.25),
                            ),
                            Align(
                              alignment: Alignment(
                                // translateX(-100%) -> translateX(250%)
                                // mapped to Alignment's -1..1 x range across
                                // the track width (64), matching the CSS feel.
                                -1.0 + (_traceController.value * 4.5),
                                0,
                              ),
                              child: FractionallySizedBox(
                                widthFactor: 0.4,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBF1E6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ================= TITLE / SUBTITLE (kept for compatibility) =================
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFBF1E6).withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: const Color(0xFFFBF1E6).withOpacity(0.7),
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

/// Small helper widget for the swap text labels, kept centered and styled
/// consistently with the CSS .swap-text rule.
class _SwapText extends StatelessWidget {
  final String text;

  const _SwapText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
        color: const Color(0xFFFBF1E6).withOpacity(0.85),
      ),
    );
  }
}

/// Paints a square and a brick-proportioned rectangle, each progressively
/// "traced" around their own perimeter, replicating the CSS
/// stroke-dasharray / stroke-dashoffset draw-then-erase effect via
/// PathMetrics.extractPath.
class _TracedMarkPainter extends CustomPainter {
  final double squareDraw; // 0..1, how much of the square's outline is drawn
  final double rectDraw; // 0..1, how much of the rectangle's outline is drawn
  final Color color;

  _TracedMarkPainter({
    required this.squareDraw,
    required this.rectDraw,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Square: x=4 y=5 w=28 h=34 rx=3 in a 60x44 viewBox -> scale to widget size
    final scaleX = size.width / 60.0;
    final scaleY = size.height / 44.0;

    final squareRect = Rect.fromLTWH(4 * scaleX, 5 * scaleY, 28 * scaleX, 34 * scaleY);
    final squarePath = Path()
      ..addRRect(RRect.fromRectAndRadius(squareRect, Radius.circular(3 * scaleX)));

    final rectRect = Rect.fromLTWH(38 * scaleX, 17 * scaleY, 18 * scaleX, 10 * scaleY);
    final rectPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rectRect, Radius.circular(2 * scaleX)));

    _drawPartialPath(canvas, squarePath, squareDraw, paint);
    _drawPartialPath(canvas, rectPath, rectDraw, paint);
  }

  void _drawPartialPath(Canvas canvas, Path path, double drawAmount, Paint paint) {
    if (drawAmount <= 0) return;

    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      final length = metric.length;
      final extractLength = length * drawAmount.clamp(0.0, 1.0);
      final extracted = metric.extractPath(0, extractLength);
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracedMarkPainter oldDelegate) {
    return oldDelegate.squareDraw != squareDraw ||
        oldDelegate.rectDraw != rectDraw ||
        oldDelegate.color != color;
  }
}