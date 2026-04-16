import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../utils/polly_tts.dart';

class VoiceMicBar extends StatefulWidget {
  final PollyTts tts;
  final String? hintText;
  final Function(String query) onResult;

  const VoiceMicBar({
    super.key,
    required this.tts,
    required this.onResult,
    this.hintText,
  });

  @override
  State<VoiceMicBar> createState() => _VoiceMicBarState();
}

enum _MicState { idle, listening, confirming, processing }

class _VoiceMicBarState extends State<VoiceMicBar> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _lightTeal = Color(0xFFE0F2F1);

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  _MicState _state = _MicState.idle;
  String _spokenText = '';
  int _hintIndex = 0;
  Timer? _hintTimer;

  final List<String> _defaultHints = const [
    'बोला: "आजचे हवामान सांग"',
    'बोला: "कापूस रोग माहिती"',
    'बोला: "कांदा बाजारभाव दाखवा"',
    'बोला: "खत गणक उघडा"',
    'बोला: "योजना दाखवा"',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _startHintRotation();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (_) {
          if (!mounted) return;
          setState(() => _state = _MicState.idle);
        },
      );
      if (!mounted) return;
      setState(() => _isAvailable = available);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAvailable = false);
    }
  }

  void _startHintRotation() {
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _state != _MicState.idle) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _defaultHints.length);
    });
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' && _state == _MicState.listening) {
      setState(() => _state = _MicState.idle);
      if (_spokenText.trim().isNotEmpty) {
        _showConfirmation(_spokenText.trim());
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_state == _MicState.processing) return;

    if (_state == _MicState.confirming) {
      // Cancel confirmation, go back to idle
      setState(() {
        _state = _MicState.idle;
        _spokenText = '';
      });
      return;
    }

    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('व्हॉइस सेवा उपलब्ध नाही.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_state == _MicState.listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _state = _MicState.idle);
      if (_spokenText.trim().isNotEmpty) {
        _showConfirmation(_spokenText.trim());
      }
      return;
    }

    setState(() {
      _spokenText = '';
      _state = _MicState.listening;
    });

    await _speech.listen(
      localeId: 'mr_IN',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() => _spokenText = result.recognizedWords);
      },
    );
  }

  Future<void> _showConfirmation(String query) async {
    setState(() => _state = _MicState.confirming);
    await widget.tts.stop();
    await widget.tts.speak('तुम्ही म्हटले: $query. बरोबर आहे का?');
  }

  Future<void> _onConfirm() async {
    final query = _spokenText.trim();
    if (query.isEmpty) return;

    setState(() => _state = _MicState.processing);
    try {
      final result = widget.onResult(query);
      if (result is Future) await result;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('व्हॉइस प्रोसेसिंगमध्ये त्रुटी आली.'), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _state = _MicState.idle;
        _spokenText = '';
      });
    }
  }

  Future<void> _onRetry() async {
    await widget.tts.stop();
    setState(() {
      _state = _MicState.idle;
      _spokenText = '';
    });
    await Future.delayed(const Duration(milliseconds: 300));
    _toggleListening();
  }

  String get _activeHint {
    if (widget.hintText != null && widget.hintText!.trim().isNotEmpty) {
      return widget.hintText!.trim();
    }
    return _defaultHints[_hintIndex];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _state == _MicState.confirming
            ? _buildConfirmRow()
            : _buildMicRow(),
      ),
    );
  }

  Widget _buildMicRow() {
    final isListening = _state == _MicState.listening;
    final isProcessing = _state == _MicState.processing;

    return Row(
      children: [
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isListening ? Colors.red.shade400 : _teal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isListening ? Colors.red : _teal).withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isListening ? 'ऐकत आहे...' : isProcessing ? 'प्रोसेस होत आहे...' : 'व्हॉइस सहाय्यक',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                _spokenText.isNotEmpty ? _spokenText : _activeHint,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: _spokenText.isNotEmpty ? Colors.black87 : Colors.black54,
                  fontWeight: _spokenText.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: _lightTeal, borderRadius: BorderRadius.circular(14)),
          child: Text(
            isListening ? 'LIVE' : isProcessing ? 'WAIT' : 'TAP',
            style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.record_voice_over_rounded, color: _teal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _spokenText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '✓ होय, बरोबर आहे',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '🔄 पुन्हा बोला',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
