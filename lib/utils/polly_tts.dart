import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Drop-in TTS helper.
/// Tries Amazon Polly (/speak) first; falls back to FlutterTts on any error.
class PollyTts {
  static const _speakUrl = 'http://127.0.0.1:5000/speak';

  final AudioPlayer _player   = AudioPlayer();
  final FlutterTts  _fallback = FlutterTts();

  // ── Public API ────────────────────────────────────────────────────────
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await stop();
    try {
      final res = await http
          .post(
            Uri.parse(_speakUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final payload = json.decode(res.body) as Map<String, dynamic>;
        final b64 = payload['audio_base64'] as String? ?? '';
        if (b64.isNotEmpty) {
          final bytes = base64Decode(b64);
          await _player.play(BytesSource(bytes));
          return;
        }
      }
      throw Exception('Polly: bad response ${res.statusCode}');
    } catch (e) {
      debugPrint('PollyTts fallback → FlutterTts: $e');
      await _speakFallback(text);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _fallback.stop();
  }

  void dispose() {
    _player.dispose();
    _fallback.stop();
  }

  // ── Fallback ──────────────────────────────────────────────────────────
  Future<void> _speakFallback(String text) async {
    await _fallback.setLanguage('mr-IN');
    await _fallback.setSpeechRate(0.45);
    await _fallback.setPitch(1.0);
    await _fallback.speak(text);
  }
}
