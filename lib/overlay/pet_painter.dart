import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/pet/pet_state.dart';
import '../core/pet/sprite_animator.dart';

/// CustomPainter that draws a single sprite frame from a spritesheet.
class PetPainter extends CustomPainter {
  final ui.Image spritesheet;
  final Rect sourceRect;

  const PetPainter({
    required this.spritesheet,
    required this.sourceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(spritesheet, sourceRect, dst, paint);
  }

  @override
  bool shouldRepaint(PetPainter old) =>
      old.sourceRect != sourceRect || old.spritesheet != spritesheet;
}

/// Animated pet widget — drives frame-by-frame animation via SpriteAnimator.
/// Accepts a [PetState] directly so the overlay widget fully controls the state.
class AnimatedPetWidget extends StatefulWidget {
  final ui.Image spritesheet;
  final PetConfig config;
  final double size;
  final PetState currentState;

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
    _animator.setState(widget.currentState);
  }

  @override
  void didUpdateWidget(AnimatedPetWidget old) {
    super.didUpdateWidget(old);
    if (old.currentState != widget.currentState) {
      _animator.setState(widget.currentState);
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
