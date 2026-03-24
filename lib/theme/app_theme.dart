// ─────────────────────────────────────────────────────────────────────────────
//  App Theme — Premium Gamified Design System
//  Glassmorphism · Glow Progress Bar · Mesh Gradient Background
//  Orbitron headers · Inter body · 8pt grid · Neon Cyan accent
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────
const Color kDeepNavy     = Color(0xFF0B1120);
const Color kCharcoal     = Color(0xFF1A1A2E);
const Color kNeonCyan     = Color(0xFF00FFF5);
const Color kNeonCyanDim  = Color(0xFF00B8D4);
const Color kLightGray    = Color(0xFFB8C4D0);
const Color kCardGlass    = Color(0x12FFFFFF); // 7% white
const Color kGold         = Color(0xFFFFD700);
const Color kEasyGreen    = Color(0xFF4CAF50);
const Color kMediumOrange = Color(0xFFFF9800);
const Color kHardRed      = Color(0xFFFF1744);
const Color kDimText      = Color(0xFF6B7A8D);

// ─── Typography Helpers ──────────────────────────────────────────────────────

TextStyle orbitronStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.bold,
  Color color = kNeonCyan,
  double letterSpacing = 2,
}) {
  return GoogleFonts.orbitron(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

TextStyle interStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kLightGray,
  double letterSpacing = 0,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

// ─── Glassmorphism Card ──────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? borderColor;
  final double borderOpacity;
  final double blurSigma;
  final List<BoxShadow>? extraShadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.borderColor,
    this.borderOpacity = 0.1,
    this.blurSigma = 20,
    this.extraShadows,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = borderColor ?? Colors.white;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: kCardGlass,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: bColor.withOpacity(borderOpacity),
                width: 1,
              ),
              boxShadow: extraShadows,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Animated Glow Progress Bar ──────────────────────────────────────────────

class GlowProgressBar extends ImplicitlyAnimatedWidget {
  final double value; // 0.0 – 1.0
  final Color color;
  final Color glowColor;
  final double height;
  final double borderRadius;

  const GlowProgressBar({
    super.key,
    required this.value,
    this.color = kNeonCyan,
    this.glowColor = kNeonCyan,
    this.height = 10,
    this.borderRadius = 5,
    super.duration = const Duration(milliseconds: 500),
    super.curve = Curves.easeInOut,
  });

  @override
  ImplicitlyAnimatedWidgetState<GlowProgressBar> createState() =>
      _GlowProgressBarState();
}

class _GlowProgressBarState
    extends AnimatedWidgetBaseState<GlowProgressBar> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween = visitor(
      _valueTween,
      widget.value.clamp(0.0, 1.0),
      (dynamic v) => Tween<double>(begin: v as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final animatedValue = _valueTween?.evaluate(animation) ?? widget.value;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: widget.glowColor.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _GlowBarPainter(
          value: animatedValue,
          color: widget.color,
          backgroundColor: Colors.white.withOpacity(0.08),
          borderRadius: widget.borderRadius,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GlowBarPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double borderRadius;

  _GlowBarPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(bgRect, Paint()..color = backgroundColor);

    if (value > 0) {
      final fgWidth = size.width * value;
      final fgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fgWidth, size.height),
        Radius.circular(borderRadius),
      );
      final fgPaint = Paint()
        ..shader = LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ).createShader(Rect.fromLTWH(0, 0, fgWidth, size.height));
      canvas.drawRRect(fgRect, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowBarPainter old) =>
      old.value != value || old.color != color;
}

// ─── Mesh Gradient Background ────────────────────────────────────────────────

class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kDeepNavy, kCharcoal],
          stops: [0.0, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _MeshPatternPainter(),
        child: child,
      ),
    );
  }
}

class _MeshPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    // Subtle dot-grid pattern
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.6, paint);
      }
    }

    // Subtle diagonal lines for mesh effect
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.01)
      ..strokeWidth = 0.3;
    for (double i = -size.height; i < size.width + size.height; i += 64) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Section Header Widget ───────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: kNeonCyan.withOpacity(0.6), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: orbitronStyle(
              fontSize: 12,
              color: kNeonCyan.withOpacity(0.8),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kNeonCyan.withOpacity(0.3),
                    kNeonCyan.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glass FAB ───────────────────────────────────────────────────────────────

class GlassFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String heroTag;
  final IconData icon;

  const GlassFAB({
    super.key,
    required this.onPressed,
    required this.heroTag,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      backgroundColor: kNeonCyan.withOpacity(0.2),
      elevation: 0,
      onPressed: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kNeonCyan.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kNeonCyan.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: kNeonCyan, size: 28),
      ),
    );
  }
}

// ─── Glass Dialog Theme Helper ───────────────────────────────────────────────

ShapeBorder get glassDialogShape => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
    );

Color get glassDialogBg => const Color(0xFF0F1923);

InputDecoration glassInputDecoration({
  String? hintText,
  Widget? prefixIcon,
  String? prefixText,
  TextStyle? prefixStyle,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: interStyle(color: kDimText, fontSize: 14),
    prefixIcon: prefixIcon,
    prefixText: prefixText,
    prefixStyle: prefixStyle,
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: kNeonCyan.withOpacity(0.3)),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: kNeonCyan, width: 2),
    ),
  );
}
