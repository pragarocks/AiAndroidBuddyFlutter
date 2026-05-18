import 'package:flutter/material.dart';

/// Speech bubble that fades in/out above the pet.
class SpeechBubbleWidget extends StatefulWidget {
  final String text;
  final VoidCallback? onDismiss;

  const SpeechBubbleWidget({super.key, required this.text, this.onDismiss});

  @override
  State<SpeechBubbleWidget> createState() => _SpeechBubbleWidgetState();
}

class _SpeechBubbleWidgetState extends State<SpeechBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // Auto-dismiss after reading time (roughly 4s + 50ms per char)
    final readMs = 4000 + widget.text.length * 50;
    Future.delayed(Duration(milliseconds: readMs), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss?.call());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: GestureDetector(
        onTap: () => _controller.reverse().then((_) => widget.onDismiss?.call()),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Tail
              Align(
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  size: const Size(16, 8),
                  painter: _BubbleTailPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
