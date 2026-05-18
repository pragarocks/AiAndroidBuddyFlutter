import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'pet_state.dart';

/// Drives frame-by-frame sprite animation from a horizontal spritesheet.
///
/// Spritesheet layout: one row per [PetState], each cell is [frameSize] wide.
/// e.g. idle is row 0 (4 frames @ 4fps), excited is row 1, etc.
class SpriteAnimator {
  final PetConfig config;
  final VoidCallback onFrame;

  int _currentFrame = 0;
  PetState _state = PetState.idle;
  Timer? _timer;

  SpriteAnimator({required this.config, required this.onFrame});

  int get currentFrame => _currentFrame;
  PetState get currentState => _state;

  void setState(PetState state) {
    if (_state == state) return;
    _state = state;
    _currentFrame = 0;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    final anim = config.animations[_state];
    if (anim == null) return;

    final interval = Duration(milliseconds: (1000 / anim.fps).round());
    _timer = Timer.periodic(interval, (_) {
      _currentFrame = (_currentFrame + 1) % anim.frames;
      onFrame();
    });
  }

  /// Returns the source rect to slice from the spritesheet for the current frame.
  Rect get sourceRect {
    final anim = config.animations[_state] ?? config.animations[PetState.idle]!;
    final x = _currentFrame * config.frameWidth.toDouble();
    final y = anim.row * config.frameHeight.toDouble();
    return Rect.fromLTWH(x, y, config.frameWidth.toDouble(), config.frameHeight.toDouble());
  }

  void dispose() => _timer?.cancel();
}

/// Describes how to animate one state on the spritesheet.
class AnimationConfig {
  final int row;
  final int frames;
  final double fps;
  const AnimationConfig({required this.row, required this.frames, required this.fps});
}

/// Full pet configuration parsed from pet.json.
class PetConfig {
  final String name;
  final String species;
  final int frameWidth;
  final int frameHeight;
  final Map<PetState, AnimationConfig> animations;

  const PetConfig({
    required this.name,
    required this.species,
    required this.frameWidth,
    required this.frameHeight,
    required this.animations,
  });
}

/// Loaded pet data: config + decoded spritesheet image.
class LoadedPet {
  final PetConfig config;
  final ui.Image spritesheet;
  const LoadedPet({required this.config, required this.spritesheet});
}
