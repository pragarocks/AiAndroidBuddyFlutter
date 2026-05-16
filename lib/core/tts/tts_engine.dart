import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts with pet-appropriate defaults.
/// Uses Android's built-in TTS engine — no model download needed.
class TtsEngine {
  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;

  Future<void> _ensureInit() async {
    if (_initialised) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);    // slightly fast = energetic pet voice
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.25);         // slightly high = cute/energetic
    _initialised = true;
  }

  /// Speak [text]. Truncates to 140 chars to keep bubbles short.
  Future<void> speak(String text) async {
    await _ensureInit();
    final safe = text.length > 140 ? '${text.substring(0, 137)}...' : text;
    await _tts.speak(safe);
  }

  Future<void> stop() => _tts.stop();

  Future<void> setPitch(double pitch) async {
    await _ensureInit();
    await _tts.setPitch(pitch);
  }

  Future<void> setRate(double rate) async {
    await _ensureInit();
    await _tts.setSpeechRate(rate);
  }

  void dispose() => _tts.stop();
}

final ttsEngineProvider = Provider((_) => TtsEngine());
