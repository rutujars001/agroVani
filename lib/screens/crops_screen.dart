import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

const _allCrops = [
  {'key': 'Jowar',       'label': 'ज्वारी',    'icon': '🌾', 'season': 'खरीप'},
  {'key': 'Wheat',       'label': 'गहू',        'icon': '🌿', 'season': 'रब्बी'},
  {'key': 'Tur',         'label': 'तूर',        'icon': '🫘', 'season': 'खरीप'},
  {'key': 'Onion',       'label': 'कांदा',      'icon': '🧅', 'season': 'खरीप/रब्बी'},
  {'key': 'Soybean',     'label': 'सोयाबीन',   'icon': '🫛', 'season': 'खरीप'},
  {'key': 'Sunflower',   'label': 'सूर्यफूल',  'icon': '🌻', 'season': 'रब्बी'},
  {'key': 'Groundnut',   'label': 'शेंगदाणा',  'icon': '🥜', 'season': 'खरीप'},
  {'key': 'Cotton',      'label': 'कापूस',      'icon': '🌱', 'season': 'खरीप'},
  {'key': 'Gram',        'label': 'हरभरा',      'icon': '🫘', 'season': 'रब्बी'},
  {'key': 'Maize',       'label': 'मका',        'icon': '🌽', 'season': 'खरीप'},
  {'key': 'Bajra',       'label': 'बाजरी',      'icon': '🌾', 'season': 'खरीप'},
  {'key': 'Sugarcane',   'label': 'ऊस',         'icon': '🎋', 'season': 'वार्षिक'},
  {'key': 'Tomato',      'label': 'टोमॅटो',    'icon': '🍅', 'season': 'रब्बी'},
  {'key': 'Pomegranate', 'label': 'डाळिंब',    'icon': '🍎', 'season': 'वार्षिक'},
  {'key': 'Grape',       'label': 'द्राक्षे',  'icon': '🍇', 'season': 'वार्षिक'},
];

const _voiceCropMap = {
  'ज्वारी': 'Jowar',   'jwari': 'Jowar',   'jowar': 'Jowar',
  'गहू': 'Wheat',      'gahu': 'Wheat',    'wheat': 'Wheat',
  'तूर': 'Tur',        'tur': 'Tur',
  'कांदा': 'Onion',    'kanda': 'Onion',   'onion': 'Onion',
  'सोयाबीन': 'Soybean','soya': 'Soybean',  'soybean': 'Soybean',
  'सूर्यफूल': 'Sunflower','sunflower': 'Sunflower',
  'शेंगदाणा': 'Groundnut','shengdana': 'Groundnut','groundnut': 'Groundnut',
  'कापूस': 'Cotton',   'kapus': 'Cotton',  'cotton': 'Cotton',
  'हरभरा': 'Gram',     'harbhara': 'Gram', 'gram': 'Gram',
  'मका': 'Maize',      'makka': 'Maize',   'maize': 'Maize',
  'बाजरी': 'Bajra',    'bajra': 'Bajra',
  'ऊस': 'Sugarcane',   'oos': 'Sugarcane', 'sugarcane': 'Sugarcane',
  'टोमॅटो': 'Tomato',  'tamatar': 'Tomato','tomato': 'Tomato',
  'डाळिंब': 'Pomegranate','dalimb': 'Pomegranate','pomegranate': 'Pomegranate',
  'द्राक्षे': 'Grape', 'draksha': 'Grape', 'grape': 'Grape',
};

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});
  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final PollyTts _tts = PollyTts();
  String? _selectedKey;
  String? _speakingKey;
  final Map<String, String> _adviceCache = {};
  bool _loading = false;
  String _activeTopic = 'रोग';

  static const _green = Color(0xFF1B5E20);
  static const _cream = Color(0xFFF3F1E7);

  static const _topics = [
    {'key': 'रोग',  'icon': Icons.bug_report,  'label': 'रोग'},
    {'key': 'खत',   'icon': Icons.science,     'label': 'खत'},
    {'key': 'पाणी', 'icon': Icons.water_drop,  'label': 'पाणी'},
  ];

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _fetchAdvice(String cropKey, String topic) async {
    final cacheKey = '$cropKey|$topic';
    if (_adviceCache.containsKey(cacheKey)) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': '$cropKey $topic'}),
      );
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final text = payload['fulfillmentText']?.toString() ?? '';
      _adviceCache[cacheKey] = text.isEmpty ? 'माहिती उपलब्ध नाही.' : text;
    } catch (_) {
      _adviceCache[cacheKey] = 'सर्व्हरशी कनेक्ट होता आले नाही.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectCrop(String key) {
    setState(() => _selectedKey = key);
    _fetchAdvice(key, _activeTopic);
  }

  void _handleVoice(String spoken) {
    final lower = spoken.toLowerCase();
    String? crop;
    _voiceCropMap.forEach((k, v) { if (lower.contains(k)) crop = v; });
    if (crop != null) _selectCrop(crop!);
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  /// Fetches all 3 topics for a crop and speaks them sequentially
  Future<void> _speakCropSummary(String cropKey) async {
    setState(() => _speakingKey = cropKey);
    await _tts.stop();
    final crop = _allCrops.firstWhere((c) => c['key'] == cropKey);
    final label = crop['label'] as String;
    final topics = ['रोग', 'खत', 'पाणी'];
    final parts = <String>[];
    for (final topic in topics) {
      await _fetchAdvice(cropKey, topic);
      final text = _adviceCache['$cropKey|$topic'] ?? '';
      if (text.isNotEmpty) parts.add(text);
    }
    final full = '$label बद्दल माहिती. ${parts.join(' ')} ';
    await _speak(full);
    if (mounted) setState(() => _speakingKey = null);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedKey != null
        ? _allCrops.firstWhere((c) => c['key'] == _selectedKey)
        : null;
    final cacheKey = _selectedKey != null ? '$_selectedKey|$_activeTopic' : null;
    final advice = cacheKey != null ? _adviceCache[cacheKey] : null;

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
                  hintText: 'बोला: "कापूस माहिती" किंवा "गहू बद्दल सांगा"',
                  onResult: _handleVoice,
                ),
                const SizedBox(height: 16),
                const Text('पीक निवडा', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                // Crop grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _allCrops.length,
                  itemBuilder: (_, i) {
                    final c = _allCrops[i];
                    final sel = _selectedKey == c['key'];
                    final isSpeaking = _speakingKey == c['key'];
                    return GestureDetector(
                      onTap: () => _selectCrop(c['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: sel ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: sel ? _green : Colors.grey.shade200,
                              width: 1.5),
                          boxShadow: sel
                              ? [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 8)]
                              : [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Emoji — dominant
                            Text(c['icon'] as String,
                                style: const TextStyle(fontSize: 30)),
                            const SizedBox(height: 4),
                            // Crop name — subheading
                            Text(c['label'] as String,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : Colors.black87),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            // Sound button
                            GestureDetector(
                              onTap: () => _speakCropSummary(c['key'] as String),
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : _green.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  isSpeaking
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_up_outlined,
                                  size: 16,
                                  color: sel ? Colors.white : _green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Detail panel
                if (selected != null) ...[
                  const SizedBox(height: 20),
                  // Topic tabs
                  Row(children: _topics.map((t) {
                    final active = _activeTopic == t['key'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _activeTopic = t['key'] as String);
                          _fetchAdvice(_selectedKey!, t['key'] as String);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? _green : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: active ? _green : Colors.grey.shade300),
                          ),
                          child: Column(children: [
                            Icon(t['icon'] as IconData,
                                color: active ? Colors.white : _green, size: 22),
                            const SizedBox(height: 4),
                            Text(t['label'] as String,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: active ? Colors.white : Colors.black87)),
                          ]),
                        ),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 12),
                  // Advice card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: _green))
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(selected['icon'] as String, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Text('${selected['label']} — $_activeTopic',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: _green, fontSize: 15)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: _green),
                                onPressed: () => _speak(advice ?? ''),
                              ),
                            ]),
                            const Divider(),
                            Text(advice ?? 'माहिती लोड होत आहे...',
                                style: const TextStyle(fontSize: 14, height: 1.6)),
                          ]),
                  ),
                ],
                const SizedBox(height: 20),
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
            Text('पीक माहिती', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('पिकाची संपूर्ण माहिती मिळवा', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const Text('🌾', style: TextStyle(fontSize: 32)),
      ]),
    );
  }
}
