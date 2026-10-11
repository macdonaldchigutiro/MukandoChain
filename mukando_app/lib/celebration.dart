import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

Future<void> showCelebration(
    BuildContext context, String title, String subtitle) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => _Celebration(title: title, subtitle: subtitle),
  );
}

class _Particle {
  final double angle, speed, size, spin;
  final Color color;
  _Particle(this.angle, this.speed, this.size, this.spin, this.color);
}

class _Celebration extends StatefulWidget {
  final String title, subtitle;
  const _Celebration({required this.title, required this.subtitle});

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final List<_Particle> _ps;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [Palette.gold, Palette.emerald, Palette.cyan, Colors.white];
    _ps = List.generate(
      80,
      (_) => _Particle(
        -math.pi * (0.1 + 0.8 * rnd.nextDouble()),
        250 + 450 * rnd.nextDouble(),
        4 + 5 * rnd.nextDouble(),
        rnd.nextDouble() * 10,
        colors[rnd.nextInt(colors.length)],
      ),
    );
    _timer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) Navigator.maybePop(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(_ps, _c.value),
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xEE0A1820),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Palette.gold.withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                        color: Palette.gold.withOpacity(0.3), blurRadius: 40),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration_rounded,
                        color: Palette.gold, size: 48),
                    const SizedBox(height: 12),
                    Text(widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Palette.gold,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Palette.text)),
                    const SizedBox(height: 14),
                    const Text('Recorded on the ledger',
                        style: TextStyle(color: Palette.emerald, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> ps;
  final double progress;
  _ConfettiPainter(this.ps, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final t = progress * 2.4;
    final opacity = (1 - progress).clamp(0.0, 1.0).toDouble();
    for (final p in ps) {
      final pos = origin +
          Offset(math.cos(p.angle) * p.speed * t,
              math.sin(p.angle) * p.speed * t + 0.5 * 900 * t * t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6),
        Paint()..color = p.color.withOpacity(opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
