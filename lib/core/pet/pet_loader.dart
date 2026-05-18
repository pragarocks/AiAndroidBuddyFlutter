import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'pet_state.dart';
import 'sprite_animator.dart';

/// Loads pet.json + spritesheet from assets or local storage for a given pet id.
class PetLoader {
  static Future<LoadedPet> load(String petId) async {
    String jsonStr;
    Uint8List imageBytes;

    final appDocDir = await getApplicationDocumentsDirectory();
    final customPetDir = Directory(p.join(appDocDir.path, 'installed_pets', petId));

    if (await customPetDir.exists()) {
      // Load custom pet
      final jsonFile = File(p.join(customPetDir.path, 'pet.json'));
      jsonStr = await jsonFile.readAsString();

      final webpFile = File(p.join(customPetDir.path, 'spritesheet.webp'));
      final pngFile = File(p.join(customPetDir.path, 'spritesheet.png'));
      if (await webpFile.exists()) {
        imageBytes = await webpFile.readAsBytes();
      } else if (await pngFile.exists()) {
        imageBytes = await pngFile.readAsBytes();
      } else {
        throw Exception('Custom pet missing spritesheet image');
      }
    } else {
      // Load bundled pet
      jsonStr = await rootBundle.loadString('assets/pets/$petId/pet.json');
      
      try {
        final byteData = await rootBundle.load('assets/pets/$petId/spritesheet.webp');
        imageBytes = byteData.buffer.asUint8List();
      } catch (e) {
        final byteData = await rootBundle.load('assets/pets/$petId/spritesheet.png');
        imageBytes = byteData.buffer.asUint8List();
      }
    }

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    PetConfig config;

    if (json.containsKey('frameSize')) {
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
      // Fallbacks
      if (!animations.containsKey(PetState.runLeft) && animations.containsKey(PetState.running)) {
        animations[PetState.runLeft]  = animations[PetState.running]!;
        animations[PetState.runRight] = animations[PetState.running]!;
      }
      if (!animations.containsKey(PetState.jump) && animations.containsKey(PetState.excited)) {
        animations[PetState.jump] = animations[PetState.excited]!;
      }
      if (!animations.containsKey(PetState.sad)) {
        animations[PetState.sad] = animations[PetState.waiting] ?? animations[PetState.idle]!;
      }
      config = PetConfig(
        name: json['name'] as String? ?? petId,
        species: json['species'] as String? ?? 'custom',
        frameWidth: frameSize['width'] as int,
        frameHeight: frameSize['height'] as int,
        animations: animations,
      );
    } else {
      // OpenPets format — synthesize!
      final displayName = json['displayName'] as String? ?? json['id'] as String? ?? petId;
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception("Failed to get image byte data");
      final bytes = byteData.buffer.asUint8List();

      final bitmapW = frame.image.width;
      final bitmapH = frame.image.height;
      final cols = (bitmapW / 192).clamp(1, 16).toInt();
      final rows = (bitmapH / 208).clamp(1, 16).toInt();
      final frameW = bitmapW ~/ cols;
      final frameH = bitmapH ~/ rows;

      int detectFrames(int rowIdx) {
        final safeRow = rowIdx.clamp(0, rows - 1);
        final sampleY = (safeRow * frameH + frameH ~/ 2).clamp(0, bitmapH - 1);
        final sampleY2 = (safeRow * frameH + frameH ~/ 4).clamp(0, bitmapH - 1);

        int count = 0;
        for (int col = 0; col < cols; col++) {
          final sampleX = (col * frameW + frameW ~/ 2).clamp(0, bitmapW - 1);
          final alpha1 = bytes[(sampleY * bitmapW + sampleX) * 4 + 3];
          final alpha2 = bytes[(sampleY2 * bitmapW + sampleX) * 4 + 3];

          if (alpha1 < 20 && alpha2 < 20) {
            break;
          }
          count++;
        }
        return count.clamp(1, cols);
      }

      AnimationConfig row(int r, double fps) => AnimationConfig(
        row: r.clamp(0, rows - 1),
        frames: detectFrames(r),
        fps: fps,
      );

      final animations = <PetState, AnimationConfig>{
        PetState.idle: row(0, 6.0),
        PetState.runRight: row(1, 12.0),
        PetState.runLeft: row(2, 12.0),
        PetState.excited: row(3, 10.0),
        PetState.jump: row(4, 10.0),
        PetState.success: row(4, 10.0),
        PetState.error: row(5, 8.0),
        PetState.waiting: row(6, 6.0),
        PetState.working: row(7, 10.0),
        PetState.thinking: row(8, 6.0),
        PetState.sleeping: row(6, 2.0),
        PetState.running: row(1, 12.0),
        PetState.sad: row(5, 8.0),
      };

      config = PetConfig(
        name: displayName,
        species: 'openpets',
        frameWidth: frameW,
        frameHeight: frameH,
        animations: animations,
      );
    }

    return LoadedPet(
      config: config,
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
