import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/polly_tts.dart';

class VoiceMicBar extends StatefulWidget {
  final String hintText;
  final FutureOr<void> Function(String) onResult;
  final PollyTts tts;

  const VoiceMicBar({
    super.key,
    required this.onResult,
    required this.tts,
    this.hintText = 'बोलण्यासाठी मायक्रोफोन दाबा...',
  });

  @override
  State<VoiceMicBar> createState() => _VoiceMicBarState();
}

class _VoiceMicBarState extends State<VoiceMicBar>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  bool _listening = false;
  bool _confirming = false; // waiting for user confirmation
  String _text = '';

  late AnimationController _pulse;
  late Animation<double> _scale;

  static const _green = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _ready = await _speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_confirming) return; // ignore mic tap during confirmation
    if (_listening) {
      _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_ready) return;
    await widget.tts.stop();
    setState(() {
      _listening = true;
      _text = '';
    });
    await _speech.listen(
      localeId: 'mr_IN',
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      onResult: (r) {
        if (!mounted) return;
        setState(() => _text = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          setState(() => _listening = false);
          _startConfirmation(r.recognizedWords);
        }
      },
    );
  }

  Future<void> _startConfirmation(String spokenText) async {
    setState(() => _confirming = true);
    // Speak back what was heard
    await widget.tts.speak('तुम्ही म्हणालात: $spokenText. हे बरोबर आहे का?');
  }

  void _confirm() {
    setState(() => _confirming = false);
    widget.onResult(_text.trim());
  }

  void _retry() {
    setState(() {
      _confirming = false;
      _text = '';
    });
    _toggle();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _listening
                ? Colors.red.shade300
                : _confirming
                    ? Colors.orange.shade300
                    : _green.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: (_listening
                      ? Colors.red
                      : _confirming
                          ? Colors.orange
                          : _green)
                  .withValues(alpha: 0.12),
              blurRadius: 10)
        ],
      ),
      child: _confirming ? _buildConfirmation() : _buildMicRow(),
    );
  }

  Widget _buildMicRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        // Mic button
        GestureDetector(
          onTap: _toggle,
          child: ScaleTransition(
            scale: _listening ? _scale : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening ? Colors.red.shade600 : _green,
                boxShadow: [
                  BoxShadow(
                      color: (_listening ? Colors.red : _green)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2)
                ],
              ),
              child: Icon(
                _listening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _text.isEmpty
                ? (_listening ? 'ऐकत आहे...' : widget.hintText)
                : _text,
            style: TextStyle(
              fontSize: 14,
              color: _text.isEmpty ? Colors.black38 : Colors.black87,
              fontStyle: _text.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        if (_text.isNotEmpty && !_listening)
          GestureDetector(
            onTap: () => _startConfirmation(_text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D47A1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3), blurRadius: 8)
                ],
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
      ]),
    );
  }

  Widget _buildConfirmation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heard text
          Row(children: [
            const Icon(Icons.record_voice_over, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"$_text"',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Confirmation buttons
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _confirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('होय, बरोबर आहे',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _retry,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay_rounded,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text('पुन्हा बोला',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
