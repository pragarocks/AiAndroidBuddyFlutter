import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class PetInstaller {
  static const int maxZipBytes = 30 * 1024 * 1024; // 30 MB

  /// Installs a pet from a local zip file path.
  /// Returns the petId on success, or throws an exception on failure.
  static Future<String> installFromZip(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw Exception('Zip file does not exist');
    }
    if (await file.length() > maxZipBytes) {
      throw Exception('Zip file is too large (max 30MB)');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Validate archive
    bool hasPetJson = false;
    bool hasSpritesheet = false;
    
    for (final entry in archive) {
      if (entry.name.contains('..') || entry.name.startsWith('/')) {
        throw Exception('Invalid path in zip (security risk)');
      }
      final name = p.basename(entry.name).toLowerCase();
      if (name == 'pet.json') hasPetJson = true;
      if (name == 'spritesheet.webp' || name == 'spritesheet.png') hasSpritesheet = true;
    }

    if (!hasPetJson) throw Exception('Missing pet.json in zip');
    if (!hasSpritesheet) throw Exception('Missing spritesheet.webp or .png in zip');

    // Extract pet.json to read ID
    String petId = 'custom_pet';
    for (final entry in archive) {
      if (p.basename(entry.name).toLowerCase() == 'pet.json') {
        final content = utf8.decode(entry.content as List<int>);
        try {
          final json = jsonDecode(content) as Map<String, dynamic>;
          petId = json['id'] as String? ?? p.basenameWithoutExtension(zipPath).replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').toLowerCase();
        } catch (e) {
          throw Exception('Invalid pet.json format');
        }
        break;
      }
    }

    if (petId.isEmpty) petId = 'custom_pet';

    final appDocDir = await getApplicationDocumentsDirectory();
    final petDir = Directory(p.join(appDocDir.path, 'installed_pets', petId));

    if (await petDir.exists()) {
      await petDir.delete(recursive: true);
    }
    await petDir.create(recursive: true);

    // Extract files
    for (final entry in archive) {
      if (entry.isFile) {
        final name = p.basename(entry.name);
        // Only allow specific files to prevent extracting junk
        if (name == 'pet.json' || name == 'spritesheet.webp' || name == 'spritesheet.png') {
          final outFile = File(p.join(petDir.path, name));
          await outFile.writeAsBytes(entry.content as List<int>);
        }
      }
    }

    // Save to installed pets list
    final prefs = await SharedPreferences.getInstance();
    final installed = prefs.getStringList('installed_custom_pets') ?? [];
    if (!installed.contains(petId)) {
      installed.add(petId);
      await prefs.setStringList('installed_custom_pets', installed);
    }

    return petId;
  }

  static Future<List<String>> getInstalledCustomPets() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('installed_custom_pets') ?? [];
  }
}
