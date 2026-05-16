import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/pet/sprite_animator.dart';

/// CustomPainter that draws a single sprite frame from a spritesheet.
class PetPainter extends CustomPainter {
  final ui.Image spritesheet;
  final Rect sourceRect;
  final double scale;

  const PetPainter({
    required this.spritesheet,
    required this.sourceRect,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(spritesheet, sourceRect, dst, Paint());
  }

  @override
  bool shouldRepaint(PetPainter old) =>
      old.sourceRect != sourceRect || old.spritesheet != spritesheet;
}

/// Animated pet widget — drives its own repaint via SpriteAnimator.
class AnimatedPetWidget extends StatefulWidget {
  final ui.Image spritesheet;
  final PetConfig config;
  final double size;
  final String currentState; // PetState.name

  const AnimatedPetWidget({
    super.key,
    required this.spritesheet,
    required this.config,
    required this.currentState,
    this.size = 96,
  });

  @override
  State<AnimatedPetWidget> createState() => _AnimatedPetWidgetState();
}

class _AnimatedPetWidgetState extends State<AnimatedPetWidget> {
  late SpriteAnimator _animator;

  @override
  void initState() {
    super.initState();
    _animator = SpriteAnimator(
      config: widget.config,
      onFrame: () { if (mounted) setState(() {}); },
    );
  }

  @override
  void didUpdateWidget(AnimatedPetWidget old) {
    super.didUpdateWidget(old);
    // Parse PetState from name string safely
    final states = widget.config.animations.keys.toList();
    for (final s in states) {
      if (s.name == widget.currentState) { _animator.setState(s); break; }
    }
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: PetPainter(
        spritesheet: widget.spritesheet,
        sourceRect: _animator.sourceRect,
      ),
    );
  }
}
