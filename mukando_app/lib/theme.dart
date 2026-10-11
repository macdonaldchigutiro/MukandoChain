import 'dart:ui';

import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFF040C10);
  static const bgTop = Color(0xFF0A1E26);
  static const emerald = Color(0xFF00F5A0);
  static const gold = Color(0xFFFFC857);
  static const cyan = Color(0xFF00D9FF);
  static const red = Color(0xFFFF4D6D);
  static const text = Color(0xFFE8F4FF);
  static const dim = Color(0xFF7F98B2);
  static const node = Color(0xFF0B1A22);
  static const pending = Color(0xFF3B5160);
  static const glass = Color(0x12FFFFFF);
  static const glassBorder = Color(0x22FFFFFF);
}

const emeraldGradient = LinearGradient(colors: [Palette.emerald, Palette.cyan]);
const goldGradient =
    LinearGradient(colors: [Color(0xFFFFC857), Color(0xFFFF9F43)]);

/// Dark background with two slowly drifting glow orbs.
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _orb(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withOpacity(0.18), c.withOpacity(0.0)],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bgTop, Palette.bg],
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(
              children: [
                Positioned(
                  top: -140 + 60 * _c.value,
                  right: -110 + 40 * _c.value,
                  child: _orb(Palette.cyan, 320),
                ),
                Positioned(
                  bottom: -150 + 50 * (1 - _c.value),
                  left: -130 + 40 * _c.value,
                  child: _orb(Palette.emerald, 340),
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Frosted-glass card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? tint;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? Palette.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor ?? Palette.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Big glowing button, easy to tap.
class GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final Color glow;

  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.gradient = emeraldGradient,
    this.glow = Palette.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: glow.withOpacity(0.4), blurRadius: 22),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Palette.bg),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Palette.bg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
