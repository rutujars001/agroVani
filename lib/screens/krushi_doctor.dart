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
  {'key': 'रोग',  'label': 'रोग व कीड',    'icon': Icons.bug_report,  'color': Color(0xFFD32F2F)},
  {'key': 'खत',   'label': 'खत व पोषण',   'icon': Icons.science,     'color': Color(0xFF1565C0)},
  {'key': 'पाणी', 'label': 'पाणी व सिंचन', 'icon': Icons.water_drop,  'color': Color(0xFF00838F)},
];

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

// step 0 = select crop, step 1 = select topic, step 2 = confirm, step 3 = result
enum _Step { crop, topic, confirm, result }

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
  _Step _step = _Step.crop;

  static const _green = Color(0xFF1B5E20);
  static const _cream = Color(0xFFF3F1E7);

  @override
  void initState() {
    super.initState();
    // Greet and prompt on open
    Future.delayed(const Duration(milliseconds: 600), () {
      _tts.speak('खालील पिकांमधून एक पीक निवडा.');
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _onCropTap(String cropKey) {
    setState(() {
      _selectedCrop = cropKey;
      _step = _Step.topic;
    });
    final label = _crops.firstWhere((c) => c['key'] == cropKey)['label'];
    _tts.speak('$label निवडले. आता लक्षणे किंवा विषय निवडा.');
  }

  void _onTopicTap(String topicKey) {
    setState(() {
      _selectedTopic = topicKey;
      _step = _Step.confirm;
    });
    final cropLabel = _crops.firstWhere((c) => c['key'] == _selectedCrop)['label'];
    _tts.speak('$cropLabel साठी $topicKey निवडले. माहिती मिळवायची का?');
  }

  Future<void> _fetchAndShow() async {
    setState(() { _loading = true; _step = _Step.result; _advice = ''; });
    try {
      final res = await http.post(
        Uri.parse('http://10.210.216.112:5000/query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': '$_selectedCrop $_selectedTopic'}),
      );
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final text = payload['fulfillmentText']?.toString() ?? '';
      setState(() { _advice = text.isEmpty ? 'माहिती उपलब्ध नाही.' : text; _loading = false; });
      // Auto-speak the advice
      await _tts.speak(_advice);
    } catch (_) {
      setState(() { _advice = 'सर्व्हरशी कनेक्ट होता आले नाही.'; _loading = false; });
    }
  }

  void _reset() {
    setState(() {
      _selectedCrop = null;
      _selectedTopic = null;
      _advice = '';
      _step = _Step.crop;
    });
    _tts.speak('खालील पिकांमधून एक पीक निवडा.');
  }

  void _handleVoice(String spoken) {
    final lower = spoken.toLowerCase();
    String? crop, topic;
    for (final e in _voiceCropMap.entries) {
      if (lower.contains(e.key)) { crop = e.value; break; }
    }
    for (final e in _voiceTopicMap.entries) {
      if (lower.contains(e.key)) { topic = e.value; break; }
    }
    if (crop != null) {
      _onCropTap(crop);
      if (topic != null) {
        Future.delayed(const Duration(milliseconds: 800), () => _onTopicTap(topic!));
      }
    } else if (topic != null && _selectedCrop != null) {
      _onTopicTap(topic);
    }
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
                // Voice mic always visible
                VoiceMicBar(
                  tts: _tts,
                  hintText: 'बोला: "कापूस रोग" किंवा "गहू खत"',
                  onResult: _handleVoice,
                ),
                const SizedBox(height: 16),

                // ── Step indicator ──────────────────────────────────
                _buildStepIndicator(),
                const SizedBox(height: 20),

                // ── Step 0: Crop selection ──────────────────────────
                if (_step == _Step.crop) ...[
                  const Text('🌱 पीक निवडा', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _crops.map((c) => GestureDetector(
                      onTap: () => _onCropTap(c['key'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(c['icon'] as String, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(c['label'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      ),
                    )).toList(),
                  ),
                ],

                // ── Step 1: Topic selection ─────────────────────────
                if (_step == _Step.topic) ...[
                  _selectedCropChip(),
                  const SizedBox(height: 16),
                  const Text('🔍 लक्षणे / विषय निवडा', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  Column(
                    children: _topics.map((t) {
                      final color = t['color'] as Color;
                      return GestureDetector(
                        onTap: () => _onTopicTap(t['key'] as String),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8)],
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(t['icon'] as IconData, color: color, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(t['label'] as String,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color))),
                            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('पीक बदला'),
                  ),
                ],

                // ── Step 2: Confirmation ────────────────────────────
                if (_step == _Step.confirm) ...[
                  _buildConfirmCard(),
                ],

                // ── Step 3: Result ──────────────────────────────────
                if (_step == _Step.result) ...[
                  _buildResultCard(),
                ],

                const SizedBox(height: 10),
                const Text('टीप: गंभीर स्थितीत कृषी तज्ज्ञांचा सल्ला घ्या.',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['पीक', 'विषय', 'पुष्टी', 'सल्ला'];
    final current = _step.index;
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? _green : active ? _green : Colors.grey.shade200,
                    border: Border.all(color: active ? _green : Colors.transparent, width: 2),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: TextStyle(
                                color: active ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(steps[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                        color: active ? _green : Colors.black45)),
              ]),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < current ? _green : Colors.grey.shade200,
                  margin: const EdgeInsets.only(bottom: 20),
                ),
              ),
          ]),
        );
      }),
    );
  }

  Widget _selectedCropChip() {
    final crop = _crops.firstWhere((c) => c['key'] == _selectedCrop);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(crop['icon'] as String, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('निवडलेले पीक: ${crop['label']}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _green)),
      ]),
    );
  }

  Widget _buildConfirmCard() {
    final crop  = _crops.firstWhere((c) => c['key'] == _selectedCrop);
    final topic = _topics.firstWhere((t) => t['key'] == _selectedTopic);
    final color = topic['color'] as Color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(children: [
        const Text('✅ पुष्टी करा', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Crop
          Column(children: [
            Text(crop['icon'] as String, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(crop['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.add_circle_outline, color: _green, size: 28),
          ),
          // Topic
          Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(topic['icon'] as IconData, color: color, size: 32),
            ),
            const SizedBox(height: 6),
            Text(topic['label'] as String,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          ]),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _fetchAndShow,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('होय, सल्ला मिळवा',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade400),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.replay_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text('पुन्हा निवडा',
                      style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildResultCard() {
    final crop  = _crops.firstWhere((c) => c['key'] == _selectedCrop);
    final topic = _topics.firstWhere((t) => t['key'] == _selectedTopic);
    final color = topic['color'] as Color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(crop['icon'] as String, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${crop['label']} — ${topic['label']}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
          ),
          IconButton(
            icon: Icon(Icons.volume_up_rounded, color: color),
            onPressed: () => _tts.speak(_advice),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            onPressed: _reset,
            tooltip: 'पुन्हा सुरू करा',
          ),
        ]),
        Divider(color: color.withValues(alpha: 0.2)),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Text(_advice, style: const TextStyle(fontSize: 14.5, height: 1.7)),
      ]),
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
