import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

const _crops = [
  {'key': 'Jowar',       'label': 'ज्वारी',    'icon': '🌾'},
  {'key': 'Wheat',       'label': 'गहू',        'icon': '🌿'},
  {'key': 'Tur',         'label': 'तूर',        'icon': '🫘'},
  {'key': 'Onion',       'label': 'कांदा',      'icon': '🧅'},
  {'key': 'Soybean',     'label': 'सोयाबीन',   'icon': '🫛'},
  {'key': 'Sunflower',   'label': 'सूर्यफूल',  'icon': '🌻'},
  {'key': 'Groundnut',   'label': 'शेंगदाणा',  'icon': '🥜'},
  {'key': 'Cotton',      'label': 'कापूस',      'icon': '🌱'},
  {'key': 'Gram',        'label': 'हरभरा',      'icon': '🫘'},
  {'key': 'Maize',       'label': 'मका',        'icon': '🌽'},
  {'key': 'Bajra',       'label': 'बाजरी',      'icon': '🌾'},
  {'key': 'Sugarcane',   'label': 'ऊस',         'icon': '🎋'},
  {'key': 'Tomato',      'label': 'टोमॅटो',    'icon': '🍅'},
  {'key': 'Pomegranate', 'label': 'डाळिंब',    'icon': '🍎'},
  {'key': 'Grape',       'label': 'द्राक्षे',  'icon': '🍇'},
];

const _topics = [
  {'key': 'रोग',  'label': 'रोग व कीड',    'icon': Icons.bug_report},
  {'key': 'खत',   'label': 'खत व पोषण',   'icon': Icons.science},
  {'key': 'पाणी', 'label': 'पाणी व सिंचन', 'icon': Icons.water_drop},
];

// Marathi voice keyword → crop key
const _voiceCropMap = {
  'ज्वारी': 'Jowar',   'jwari': 'Jowar',   'jowar': 'Jowar',
  'गहू': 'Wheat',      'gahu': 'Wheat',    'wheat': 'Wheat',
  'तूर': 'Tur',        'tur': 'Tur',       'toor': 'Tur',
  'कांदा': 'Onion',    'kanda': 'Onion',   'onion': 'Onion',
  'सोयाबीन': 'Soybean','soya': 'Soybean',  'soybean': 'Soybean',
  'सूर्यफूल': 'Sunflower','sunflower': 'Sunflower',
  'शेंगदाणा': 'Groundnut','shengdana': 'Groundnut','groundnut': 'Groundnut',
  'कापूस': 'Cotton',   'kapus': 'Cotton',  'cotton': 'Cotton',
  'हरभरा': 'Gram',     'harbhara': 'Gram', 'gram': 'Gram',
  'मका': 'Maize',      'makka': 'Maize',   'maize': 'Maize',
  'बाजरी': 'Bajra',    'bajra': 'Bajra',   'bajri': 'Bajra',
  'ऊस': 'Sugarcane',   'oos': 'Sugarcane', 'sugarcane': 'Sugarcane',
  'टोमॅटो': 'Tomato',  'tamatar': 'Tomato','tomato': 'Tomato',
  'डाळिंब': 'Pomegranate','dalimb': 'Pomegranate','pomegranate': 'Pomegranate',
  'द्राक्षे': 'Grape', 'draksha': 'Grape', 'grape': 'Grape',
};

const _voiceTopicMap = {
  'रोग': 'रोग', 'rog': 'रोग', 'kida': 'रोग', 'कीड': 'रोग', 'disease': 'रोग',
  'खत': 'खत',  'khat': 'खत', 'khad': 'खत',  'fertilizer': 'खत',
  'पाणी': 'पाणी','pani': 'पाणी','water': 'पाणी','sinchan': 'पाणी','सिंचन': 'पाणी',
};

class KrushiDoctor extends StatefulWidget {
  const KrushiDoctor({super.key});
  @override
  State<KrushiDoctor> createState() => _KrushiDoctorState();
}

class _KrushiDoctorState extends State<KrushiDoctor> {
  final PollyTts _tts = PollyTts();
  String? _selectedCrop;
  String? _selectedTopic;
  String _advice = '';
  bool _loading = false;

  static const _green = Color(0xFF1B5E20);
  static const _cream = Color(0xFFF3F1E7);

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _fetchAdvice() async {
    if (_selectedCrop == null || _selectedTopic == null) return;
    setState(() { _loading = true; _advice = ''; });
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': '$_selectedCrop $_selectedTopic'}),
      );
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final text = payload['fulfillmentText']?.toString() ?? '';
      setState(() { _advice = text.isEmpty ? 'माहिती उपलब्ध नाही.' : text; });
      await _speak(_advice);
    } catch (_) {
      setState(() => _advice = 'सर्व्हरशी कनेक्ट होता आले नाही.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _handleVoice(String spoken) {
    final lower = spoken.toLowerCase();
    String? crop, topic;
    _voiceCropMap.forEach((k, v) { if (lower.contains(k)) crop = v; });
    _voiceTopicMap.forEach((k, v) { if (lower.contains(k)) topic = v; });
    setState(() {
      if (crop != null) _selectedCrop = crop;
      if (topic != null) _selectedTopic = topic;
    });
    if (_selectedCrop != null && _selectedTopic != null) _fetchAdvice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VoiceMicBar(
                  tts: _tts,
                  hintText: 'बोला: "कापूस रोग" किंवा "गहू खत"',
                  onResult: _handleVoice,
                ),
                const SizedBox(height: 16),
                // Crop selector
                const Text('पीक निवडा', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _crops.map((c) {
                    final selected = _selectedCrop == c['key'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCrop = c['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: selected ? _green : Colors.grey.shade300,
                              width: 1.5),
                          boxShadow: selected
                              ? [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 8)]
                              : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(c['icon'] as String, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(c['label'] as String,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Topic selector
                const Text('विषय निवडा', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                Row(children: _topics.map((t) {
                  final selected = _selectedTopic == t['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTopic = t['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected ? _green : Colors.grey.shade300),
                          boxShadow: selected
                              ? [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 8)]
                              : [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(children: [
                          Icon(t['icon'] as IconData,
                              color: selected ? Colors.white : _green, size: 28),
                          const SizedBox(height: 6),
                          Text(t['label'] as String,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 20),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: (_selectedCrop != null && _selectedTopic != null && !_loading)
                        ? _fetchAdvice
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.medical_services_rounded),
                    label: Text(_loading ? 'माहिती मिळवत आहे...' : 'सल्ला मिळवा',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                // Advice result
                if (_advice.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.eco_rounded, color: _green),
                        const SizedBox(width: 8),
                        Text(
                          '${_crops.firstWhere((c) => c['key'] == _selectedCrop, orElse: () => {'label': _selectedCrop ?? ''})['label']} — $_selectedTopic',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _green),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: _green),
                          onPressed: () => _speak(_advice),
                          tooltip: 'ऐका',
                        ),
                      ]),
                      const Divider(),
                      Text(_advice, style: const TextStyle(fontSize: 14.5, height: 1.6)),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),
                const Text('टीप: गंभीर स्थितीत कृषी तज्ज्ञांचा सल्ला घ्या.',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('कृषी डॉक्टर', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('पीक रोग, खत व पाणी सल्ला', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const Text('🩺', style: TextStyle(fontSize: 32)),
      ]),
    );
  }
}
