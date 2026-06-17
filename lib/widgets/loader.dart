import 'dart:async';
import 'package:flutter/material.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<String> _messages = [
    "Connecting to Vyara ERP...",
    "Loading structural block inventory...",
    "Syncing dispatch schedules...",
    "Verifying batch specifications..."
  ];

  int _currentMessageIndex = 0;
  double _textOpacity = 1.0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _messageTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (!mounted) return;

        setState(() => _textOpacity = 0);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          setState(() {
            _currentMessageIndex =
                (_currentMessageIndex + 1) % _messages.length;
            _textOpacity = 1;
          });
        });
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final isMobile = size.width < 600;
    final cardWidth = size.width * 0.85;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: cardWidth.clamp(280.0, 420.0),
            maxHeight: size.height * 0.85,
          ),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black26,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ================= LOGO =================
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final pulseValue = _animationController.value;

                      final colorCurve = Curves.easeInOut.transform(
                        pulseValue <= 0.5
                            ? pulseValue * 2
                            : (1.0 - pulseValue) * 2,
                      );

                      final color = Color.lerp(
                        const Color(0xFF1A365D),
                        const Color(0xFF2B6CB0),
                        colorCurve,
                      );

                      return Text(
                        "VYARA",
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          color: color,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "CELEBRATING 68 YEARS",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF718096),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= LOADER =================
                  Container(
                    width: (cardWidth * 0.65).clamp(180.0, 240.0),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          _buildPaverUnit(
                              width: 40,
                              color: const Color(0xFFB2BCC7),
                              delay: 0.0),
                          const SizedBox(width: 2),
                          _buildPaverUnit(
                              width: 40,
                              color: const Color(0xFFC97A7A),
                              delay: 0.0),
                          const SizedBox(width: 2),
                          _buildPaverUnit(
                              width: 40,
                              color: const Color(0xFFE3C28F),
                              delay: 0.0),
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          _buildPaverUnit(
                              width: 30,
                              color: const Color(0xFFC97A7A),
                              delay: 0.25),
                          _buildPaverUnit(
                              width: 30,
                              color: const Color(0xFFE3C28F),
                              delay: 0.25),
                          _buildPaverUnit(
                              width: 30,
                              color: const Color(0xFFB2BCC7),
                              delay: 0.25),
                          _buildPaverUnit(
                              width: 30,
                              color: const Color(0xFFE3C28F),
                              delay: 0.25),
                          _buildPaverUnit(
                              width: 30,
                              color: const Color(0xFFC97A7A),
                              delay: 0.25),   

                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          _buildPaverUnit(
                              width: 40,
                              color: const Color(0xFFE3C28F),
                              delay: 0.5),
                          const SizedBox(width: 2),
                          _buildPaverUnit(
                              width: 40,
                              color: const Color(0xFFC97A7A),
                              delay: 0.5),
                          const SizedBox(width: 2),
                          _buildPaverUnit(
                              width: 40,
                              color: const Color(0xFFB2BCC7),
                              delay: 0.5),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ================= MESSAGE =================
                  AnimatedOpacity(
                    opacity: _textOpacity,
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _messages[_currentMessageIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1A365D),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= TITLE =================
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ================= SUBTITLE =================
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaverUnit({
    required double width,
    required Color color,
    required double delay,
  }) {
    return Expanded(
      flex: width.toInt(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          double progress =
              _animationController.value - (delay * 0.2);

          if (progress < 0) progress += 1;
          if (progress > 1) progress -= 1;

          double scale = 1;
          double translateY = 0;
          double opacity = 1;

          if (progress < 0.35) {
            double t = progress / 0.35;
            scale = 0.94 + (t * 0.06);
            translateY = -3 * (1 - t);
            opacity = 0.3 + (t * 0.7);
          } else if (progress > 0.75) {
            double t = (progress - 0.75) / 0.25;
            scale = 1 - (t * 0.06);
            translateY = -3 * t;
            opacity = 1 - (t * 0.7);
          }

          return Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: CustomPaint(
              painter: const ConcreteTexturePainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class ConcreteTexturePainter extends CustomPainter {
  const ConcreteTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.12);

    for (double x = 1.5; x < size.width; x += 4) {
      for (double y = 1.5; y < size.height; y += 4) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}