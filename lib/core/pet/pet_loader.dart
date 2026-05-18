import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pet_state.dart';
import 'sprite_animator.dart';

/// Loads pet.json + spritesheet.webp from assets for a given pet id.
class PetLoader {
  static Future<LoadedPet> load(String petId) async {
    final jsonStr = await rootBundle.loadString('assets/pets/$petId/pet.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    final frameSize = json['frameSize'] as Map<String, dynamic>;
    final rawStates = json['states'] as Map<String, dynamic>;

    final animations = <PetState, AnimationConfig>{};
    rawStates.forEach((key, value) {
      final petState = _parseState(key);
      if (petState != null) {
        animations[petState] = AnimationConfig(
          row: value['row'] as int,
          frames: value['frames'] as int,
          fps: (value['fps'] as num).toDouble(),
        );
      }
    });

    // Fallback: if run_left/run_right missing but 'running' exists, alias them
    if (!animations.containsKey(PetState.runLeft) &&
        animations.containsKey(PetState.running)) {
      animations[PetState.runLeft]  = animations[PetState.running]!;
      animations[PetState.runRight] = animations[PetState.running]!;
    }
    // Fallback: if 'jump' missing, use 'excited'
    if (!animations.containsKey(PetState.jump) &&
        animations.containsKey(PetState.excited)) {
      animations[PetState.jump] = animations[PetState.excited]!;
    }
    // Fallback: if 'sad' missing, use 'waiting' or 'idle'
    if (!animations.containsKey(PetState.sad)) {
      animations[PetState.sad] =
          animations[PetState.waiting] ?? animations[PetState.idle]!;
    }

    final byteData =
        await rootBundle.load('assets/pets/$petId/spritesheet.webp');
    final codec =
        await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    return LoadedPet(
      config: PetConfig(
        name: json['name'] as String,
        species: json['species'] as String,
        frameWidth: frameSize['width'] as int,
        frameHeight: frameSize['height'] as int,
        animations: animations,
      ),
      spritesheet: frame.image,
    );
  }

  static PetState? _parseState(String key) => switch (key) {
    'idle'      => PetState.idle,
    'excited'   => PetState.excited,
    'thinking'  => PetState.thinking,
    'working'   => PetState.working,
    'sleeping'  => PetState.sleeping,
    'success'   => PetState.success,
    'error'     => PetState.error,
    'waiting'   => PetState.waiting,
    'running'   => PetState.running,
    'run_left'  => PetState.runLeft,
    'run_right' => PetState.runRight,
    'jump'      => PetState.jump,
    'sad'       => PetState.sad,
    _           => null,
  };
}

/// Provider that asynchronously loads the active pet.
final loadedPetProvider = FutureProvider.family<LoadedPet, String>((_, petId) {
  return PetLoader.load(petId);
});
