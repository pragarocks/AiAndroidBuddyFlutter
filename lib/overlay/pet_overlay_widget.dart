import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/pet/pet_loader.dart';
import '../core/pet/pet_state.dart';
import '../core/pet/pet_state_machine.dart';
import '../core/personality/pet_profile_repository.dart';
import '../core/tts/tts_engine.dart';
import 'pet_painter.dart';
import 'speech_bubble_widget.dart';

/// The floating overlay widget rendered above all other apps.
/// Entry point: overlayMain() in main.dart.
class PetOverlayWidget extends ConsumerStatefulWidget {
  const PetOverlayWidget({super.key});

  @override
  ConsumerState<PetOverlayWidget> createState() => _PetOverlayWidgetState();
}

class _PetOverlayWidgetState extends ConsumerState<PetOverlayWidget> {
  // Overlay position (top-left corner)
  double _x = 20;
  double _y = 200;

  String? _bubbleText;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Listen for messages from the main Flutter isolate
    FlutterOverlayWindow.overlayListener.listen(_onOverlayMessage);
  }

  void _onOverlayMessage(dynamic message) {
    if (message is Map) {
      final action = message['action'] as String?;
      if (action == 'showBubble') {
        final text = message['text'] as String?;
        if (text != null && mounted) {
          setState(() => _bubbleText = text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petState = ref.watch(petStateMachineProvider);
    final profileAsync = ref.watch(petProfileProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final petAsync = ref.watch(loadedPetProvider(profile.petId));
        return petAsync.when(
          loading: () => _buildPlaceholder(),
          error: (_, __) => _buildPlaceholder(),
          data: (loaded) => Stack(
            children: [
              Positioned(
                left: _x,
                top: _y,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_bubbleText != null)
                      SpeechBubbleWidget(
                        text: _bubbleText!,
                        onDismiss: () => setState(() => _bubbleText = null),
                      ),
                    GestureDetector(
                      onPanStart: (_) => setState(() => _isDragging = true),
                      onPanUpdate: (details) {
                        final screen = MediaQuery.of(context).size;
                        setState(() {
                          _x = (_x + details.delta.dx).clamp(0, screen.width - 96);
                          _y = (_y + details.delta.dy).clamp(0, screen.height - 96);
                        });
                      },
                      onPanEnd: (_) => setState(() => _isDragging = false),
                      onTap: () {
                        ref.read(petStateMachineProvider.notifier)
                            .send(const UserTapped());
                        ref.read(ttsEngineProvider).speak(
                          "Hey! I'm ${profile.name}. How's it going?",
                        );
                      },
                      child: AnimatedPetWidget(
                        spritesheet: loaded.spritesheet,
                        config: loaded.config,
                        currentState: petState.name,
                        size: 96,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Positioned(
      left: _x,
      top: _y,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pets, color: Colors.white, size: 48),
      ),
    );
  }
}
