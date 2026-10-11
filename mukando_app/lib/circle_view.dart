import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

List<Offset> nodePositions(Size size, int n) {
  final c = size.center(Offset.zero);
  final r = math.min(size.width, size.height) * 0.36;
  return List.generate(n, (i) {
    final a = -math.pi / 2 + i * 2 * math.pi / n;
    return c + Offset(math.cos(a) * r, math.sin(a) * r);
  });
}

double nodeRadius(Size size) =>
    math.min(24.0, math.max(17.0, math.min(size.width, size.height) * 0.36 * 0.17));

class CircleView extends StatefulWidget {
  final SavingsCircle data;
  final String? selectedId;
  final ValueChanged<Member> onTap;

  const CircleView({
    super.key,
    required this.data,
    required this.selectedId,
    required this.onTap,
  });

  @override
  State<CircleView> createState() => _CircleViewState();
}

class _CircleViewState extends State<CircleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap(Offset p, Size size) {
    final pos = nodePositions(size, widget.data.members.length);
    final reach = nodeRadius(size) + 14;
    int? best;
    double bestD = reach;
    for (int i = 0; i < pos.length; i++) {
      final d = (pos[i] - p).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best != null) widget.onTap(widget.data.members[best]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.data.pot.toDouble()),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, potShown, _) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tap(d.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _CirclePainter(
                  widget.data, potShown, widget.selectedId, _c),
            ),
          );
        },
      );
    });
  }
}

class _CirclePainter extends CustomPainter {
  final SavingsCircle d;
  final double potShown;
  final String? selectedId;
  final Animation<double> anim;

  _CirclePainter(this.d, this.potShown, this.selectedId, this.anim)
      : super(repaint: anim);

  void _text(Canvas canvas, String s, Offset center, double size, Color color,
      {FontWeight weight = FontWeight.w600}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * 0.36;
    final nr = nodeRadius(size);
    final t = anim.value;
    final pos = nodePositions(size, d.members.length);
    final recipientIndex = d.members.indexWhere((m) => m.id == d.recipientId);

    // Orbit ring with two spinning accents
    final orbitRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0x14FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawArc(
      orbitRect,
      t * 2 * math.pi,
      0.9,
      false,
      Paint()
        ..color = Palette.cyan.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      orbitRect,
      t * 2 * math.pi + math.pi,
      0.5,
      false,
      Paint()
        ..color = Palette.emerald.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Money flowing from paid members into the pot
    for (int i = 0; i < d.members.length; i++) {
      if (!d.members[i].paid) continue;
      canvas.drawLine(
        pos[i],
        c,
        Paint()
          ..color = Palette.emerald.withOpacity(0.12)
          ..strokeWidth = 1.5,
      );
      final u = (t + i * 0.125) % 1.0;
      final pt = Offset.lerp(pos[i], c, u)!;
      canvas.drawCircle(
        pt,
        6,
        Paint()
          ..color = Palette.emerald.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(pt, 2.5, Paint()..color = Palette.emerald);
    }

    // Pot full: gold coins flow to the recipient
    if (d.canPayout && recipientIndex >= 0) {
      for (int k = 0; k < 3; k++) {
        final u = (t * 1.5 + k / 3) % 1.0;
        final pt = Offset.lerp(c, pos[recipientIndex], u)!;
        canvas.drawCircle(
          pt,
          7,
          Paint()
            ..color = Palette.gold.withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(pt, 3.5, Paint()..color = Palette.gold);
      }
    }

    // Pot in the centre
    final pr = r * 0.42;
    final progress = (potShown / d.target).clamp(0.0, 1.0).toDouble();
    final ringColor = d.canPayout ? Palette.gold : Palette.emerald;
    final potRect = Rect.fromCircle(center: c, radius: pr);
    canvas.drawCircle(
      c,
      pr,
      Paint()
        ..color = const Color(0x1AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    canvas.drawArc(
      potRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = ringColor.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      potRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    _text(canvas, money(potShown.round()), c + const Offset(0, -9), 24,
        Palette.text,
        weight: FontWeight.w800);
    _text(canvas, 'of ${money(d.target)}', c + const Offset(0, 12), 11,
        Palette.dim);
    _text(canvas, '${d.paidCount} of ${d.members.length} paid',
        c + const Offset(0, 27), 10, ringColor);

    // Member nodes
    for (int i = 0; i < d.members.length; i++) {
      final m = d.members[i];
      final p = pos[i];
      final isRecipient = i == recipientIndex;
      final color = isRecipient
          ? Palette.gold
          : (m.paid ? Palette.emerald : Palette.pending);
      final selected = m.id == selectedId;

      if (isRecipient) {
        canvas.drawCircle(
          p,
          nr + 4 + 10 * t,
          Paint()
            ..color = Palette.gold.withOpacity(1 - t)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (m.paid || isRecipient) {
        canvas.drawCircle(
          p,
          nr + 4,
          Paint()
            ..color = color.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas.drawCircle(p, nr, Paint()..color = Palette.node);
      canvas.drawCircle(
        p,
        nr,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = isRecipient ? 3 : 2,
      );
      if (selected) {
        canvas.drawCircle(
          p,
          nr + 6,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      _text(canvas, m.initial, p, 15,
          m.paid || isRecipient ? color : Palette.dim,
          weight: FontWeight.w700);

      if (m.paid) {
        final b = p + Offset(nr * 0.72, -nr * 0.72);
        canvas.drawCircle(b, 7, Paint()..color = Palette.emerald);
        _text(canvas, '✓', b, 9, Palette.bg, weight: FontWeight.w800);
      }
      if (m.receivedCycle != null) {
        final b = p + Offset(-nr * 0.72, -nr * 0.72);
        canvas.drawCircle(b, 7, Paint()..color = Palette.gold);
        _text(canvas, '${m.receivedCycle}', b, 9, Palette.bg,
            weight: FontWeight.w800);
      }
      _text(canvas, m.name, p + Offset(0, nr + 13), 10.5,
          selected ? Palette.text : Palette.dim,
          weight: selected ? FontWeight.w700 : FontWeight.w500);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter old) =>
      old.d != d || old.potShown != potShown || old.selectedId != selectedId;
}
