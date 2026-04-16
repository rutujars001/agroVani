import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

import '../utils/app_config.dart';

const _serverBaseUrl = kBaseUrl;

const _crops = [
  {'key': 'Jowar', 'label': 'ज्वारी', 'icon': '🌾'},
  {'key': 'Wheat', 'label': 'गहू', 'icon': '🌿'},
  {'key': 'Tur', 'label': 'तूर', 'icon': '🫘'},
  {'key': 'Onion', 'label': 'कांदा', 'icon': '🧅'},
  {'key': 'Soybean', 'label': 'सोयाबीन', 'icon': '🫛'},
  {'key': 'Sunflower', 'label': 'सूर्यफूल', 'icon': '🌻'},
  {'key': 'Groundnut', 'label': 'शेंगदाणा', 'icon': '🥜'},
  {'key': 'Cotton', 'label': 'कापूस', 'icon': '🌱'},
  {'key': 'Gram', 'label': 'हरभरा', 'icon': '🫘'},
  {'key': 'Maize', 'label': 'मका', 'icon': '🌽'},
  {'key': 'Bajra', 'label': 'बाजरी', 'icon': '🌾'},
  {'key': 'Sugarcane', 'label': 'ऊस', 'icon': '🎋'},
  {'key': 'Tomato', 'label': 'टोमॅटो', 'icon': '🍅'},
  {'key': 'Pomegranate', 'label': 'डाळिंब', 'icon': '🍎'},
  {'key': 'Grape', 'label': 'द्राक्षे', 'icon': '🍇'},
];

const _topics = [
  {
    'key': 'रोग',
    'label': 'रोग व कीड',
    'icon': Icons.bug_report,
    'color': Color(0xFFD32F2F),
  },
  {
    'key': 'खत',
    'label': 'खत व पोषण',
    'icon': Icons.science,
    'color': Color(0xFF1565C0),
  },
  {
    'key': 'पाणी',
    'label': 'पाणी व सिंचन',
    'icon': Icons.water_drop,
    'color': Color(0xFF00838F),
  },
];

const _symptomOptions = [
  'पानावर काळे डाग आहेत',
  'पानांवर पिवळेपणा आहे',
  'पाने गुंडाळत आहेत',
  'पाने वाळत आहेत',
  'खोड कुजत आहे',
  'झाडाची वाढ कमी आहे',
  'फळावर डाग आहेत',
  'मुळे सडत आहेत',
];

const _voiceCropMap = {
  'ज्वारी': 'Jowar',
  'jwari': 'Jowar',
  'jowar': 'Jowar',
  'गहू': 'Wheat',
  'gahu': 'Wheat',
  'wheat': 'Wheat',
  'तूर': 'Tur',
  'tur': 'Tur',
  'toor': 'Tur',
  'कांदा': 'Onion',
  'kanda': 'Onion',
  'onion': 'Onion',
  'सोयाबीन': 'Soybean',
  'soya': 'Soybean',
  'soybean': 'Soybean',
  'सूर्यफूल': 'Sunflower',
  'sunflower': 'Sunflower',
  'शेंगदाणा': 'Groundnut',
  'shengdana': 'Groundnut',
  'groundnut': 'Groundnut',
  'कापूस': 'Cotton',
  'kapus': 'Cotton',
  'cotton': 'Cotton',
  'हरभरा': 'Gram',
  'harbhara': 'Gram',
  'gram': 'Gram',
  'मका': 'Maize',
  'makka': 'Maize',
  'maize': 'Maize',
  'बाजरी': 'Bajra',
  'bajra': 'Bajra',
  'bajri': 'Bajra',
  'ऊस': 'Sugarcane',
  'oos': 'Sugarcane',
  'sugarcane': 'Sugarcane',
  'टोमॅटो': 'Tomato',
  'tamatar': 'Tomato',
  'tomato': 'Tomato',
  'डाळिंब': 'Pomegranate',
  'dalimb': 'Pomegranate',
  'pomegranate': 'Pomegranate',
  'द्राक्षे': 'Grape',
  'draksha': 'Grape',
  'grape': 'Grape',
};

const _voiceTopicMap = {
  'रोग': 'रोग',
  'rog': 'रोग',
  'kida': 'रोग',
  'कीड': 'रोग',
  'disease': 'रोग',
  'खत': 'खत',
  'khat': 'खत',
  'khad': 'खत',
  'fertilizer': 'खत',
  'पाणी': 'पाणी',
  'pani': 'पाणी',
  'water': 'पाणी',
  'sinchan': 'पाणी',
  'सिंचन': 'पाणी',
};

enum _Step { crop, mode, symptom, confirm, result }

class KrushiDoctor extends StatefulWidget {
  const KrushiDoctor({super.key});

  @override
  State<KrushiDoctor> createState() => _KrushiDoctorState();
}

class _KrushiDoctorState extends State<KrushiDoctor> {
  final PollyTts _tts = PollyTts();

  String? _selectedCrop;
  String? _selectedTopic;
  String? _selectedSymptom;
  String _advice = '';
  String _finalQuery = '';
  bool _loading = false;
  _Step _step = _Step.crop;

  static const _green = Color(0xFF00897B);
  static const _greenDark = Color(0xFF00695C);
  static const _lightBg = Color(0xFFF5F7F6);
  static const _cardBg = Colors.white;
  static const _softBorder = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _tts.speak(
        'नमस्कार! कृषी डॉक्टर मध्ये आपले स्वागत आहे. प्रथम पीक निवडा.',
      );
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String _cropLabel(String cropKey) {
    final crop = _crops.firstWhere((c) => c['key'] == cropKey);
    return crop['label'] as String;
  }

  void _onCropTap(String cropKey) {
    setState(() {
      _selectedCrop = cropKey;
      _selectedTopic = null;
      _selectedSymptom = null;
      _finalQuery = '';
      _advice = '';
      _step = _Step.mode;
    });
    _tts.speak('${_cropLabel(cropKey)} निवडले. आता विषय किंवा लक्षणे निवडा.');
  }

  void _selectTopicMode(String topicKey) {
    setState(() {
      _selectedTopic = topicKey;
      _selectedSymptom = null;
      _step = _Step.confirm;
    });
    final cropLabel = _cropLabel(_selectedCrop!);
    _tts.speak('$cropLabel साठी $topicKey निवडले. माहिती मिळवायची का?');
  }

  void _selectSymptomMode(String symptom) {
    setState(() {
      _selectedTopic = 'रोग';
      _selectedSymptom = symptom;
      _step = _Step.confirm;
    });
    final cropLabel = _cropLabel(_selectedCrop!);
    _tts.speak('$cropLabel साठी "$symptom" हे लक्षण निवडले. निदान करायचे का?');
  }

  String _buildQuery() {
    final cropLabel = _cropLabel(_selectedCrop!);
    if (_selectedSymptom != null && _selectedSymptom!.trim().isNotEmpty) {
      return '$cropLabelच्या $_selectedSymptom';
    }
    return '$cropLabel ${_selectedTopic ?? ''}'.trim();
  }

  Future<void> _fetchAndShow() async {
    final query = _buildQuery();
    setState(() {
      _loading = true;
      _step = _Step.result;
      _advice = '';
      _finalQuery = query;
    });

    try {
      final res = await apiPost(
        '$_serverBaseUrl/query',
        body: json.encode({'query': query}),
      );

      final payload = json.decode(res.body) as Map;
      final text = payload['fulfillmentText']?.toString() ?? '';

      setState(() {
        _advice = text.isEmpty ? 'माहिती उपलब्ध नाही.' : text;
        _loading = false;
      });

      await _tts.speak(_advice);
    } catch (_) {
      setState(() {
        _advice = 'सर्व्हरशी कनेक्ट होता आले नाही.';
        _loading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedCrop = null;
      _selectedTopic = null;
      _selectedSymptom = null;
      _advice = '';
      _finalQuery = '';
      _step = _Step.crop;
    });
    _tts.speak('खालील पिकांमधून एक पीक निवडा.');
  }

  void _goBackOneStep() {
    setState(() {
      if (_step == _Step.mode) {
        _step = _Step.crop;
        _selectedCrop = null;
      } else if (_step == _Step.symptom) {
        _step = _Step.mode;
        _selectedSymptom = null;
      } else if (_step == _Step.confirm) {
        if (_selectedSymptom != null) {
          _step = _Step.symptom;
          _selectedSymptom = null;
        } else {
          _step = _Step.mode;
          _selectedTopic = null;
        }
      } else if (_step == _Step.result) {
        _step = _Step.confirm;
      }
    });
  }

  void _handleVoice(String spoken) {
    final lower = spoken.toLowerCase();

    String? crop;
    String? topic;

    for (final e in _voiceCropMap.entries) {
      if (lower.contains(e.key)) {
        crop = e.value;
        break;
      }
    }

    for (final e in _voiceTopicMap.entries) {
      if (lower.contains(e.key)) {
        topic = e.value;
        break;
      }
    }

    final symptomLikeWords = [
      'डाग',
      'पिवळ',
      'गुंडाळ',
      'वाळ',
      'कुज',
      'सड',
      'ठिपके',
      'करपा',
      'spot',
      'yellow',
      'curl',
      'wilt',
      'rot',
      'blight',
      'lesion',
    ];

    final hasSymptom = symptomLikeWords.any((w) => lower.contains(w));

    if (crop != null && hasSymptom) {
      setState(() {
        _selectedCrop = crop;
        _selectedTopic = 'रोग';
        _selectedSymptom = spoken.trim();
        _step = _Step.confirm;
      });
      _tts.speak(
        '${_cropLabel(crop)} साठी लक्षण समजले. आता पुष्टी करून निदान मिळवा.',
      );
      return;
    }

    if (crop != null && topic != null) {
      setState(() {
        _selectedCrop = crop;
        _selectedTopic = topic;
        _selectedSymptom = null;
        _step = _Step.confirm;
      });
      _tts.speak(
        '${_cropLabel(crop)} साठी $topic निवडले. माहिती मिळवायची का?',
      );
      return;
    }

    if (crop != null) {
      _onCropTap(crop);
      return;
    }

    if (topic != null && _selectedCrop != null) {
      _selectTopicMode(topic);
      return;
    }

    if (_selectedCrop != null && hasSymptom) {
      _selectSymptomMode(spoken.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VoiceMicBar(
                      tts: _tts,
                      hintText:
                          'बोला: "कापसाच्या पानावर काळे डाग आहेत" किंवा "गहू खत"',
                      onResult: _handleVoice,
                    ),
                    const SizedBox(height: 14),
                    _buildStepIndicator(),
                    const SizedBox(height: 18),
                    _buildIntroCard(),
                    const SizedBox(height: 18),
                    if (_step == _Step.crop) ...[
                      _buildSectionTitle('🌱 पीक निवडा', 'तुमच्या पिकासाठी योग्य सल्ला मिळवा'),
                      const SizedBox(height: 12),
                      _buildCropGrid(),
                    ],
                    if (_step == _Step.mode) ...[
                      _selectedCropChip(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('🔎 काय हवे आहे?', 'रोग निदान किंवा सामान्य सल्ला निवडा'),
                      const SizedBox(height: 12),
                      _buildModeCards(),
                    ],
                    if (_step == _Step.symptom) ...[
                      _selectedCropChip(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('🩺 लक्षणे निवडा', 'दिलेल्या लक्षणांमधून निवडा किंवा आवाज वापरा'),
                      const SizedBox(height: 12),
                      _buildSymptomCards(),
                    ],
                    if (_step == _Step.confirm) ...[
                      _buildConfirmCard(),
                    ],
                    if (_step == _Step.result) ...[
                      _buildResultCard(),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'टीप: गंभीर स्थितीत जवळच्या कृषी तज्ज्ञांचा सल्ला घ्या.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'कृषी डॉक्टर',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'पीक रोग निदान, खत आणि पाणी सल्ला',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'तुमच्या पिकासाठी जलद सल्ला',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _greenDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '१) पीक निवडा  २) रोग/खत/पाणी किंवा लक्षणे निवडा  ३) पुष्टी करा  ४) सल्ला ऐका',
            style: TextStyle(fontSize: 13.2, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['पीक', 'निवड', 'पुष्टी', 'सल्ला'];
    int current;
    switch (_step) {
      case _Step.crop:
        current = 0;
        break;
      case _Step.mode:
      case _Step.symptom:
        current = 1;
        break;
      case _Step.confirm:
        current = 2;
        break;
      case _Step.result:
        current = 3;
        break;
    }

    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < current;
        final active = i == current;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done || active ? _green : Colors.white,
                        border: Border.all(
                          color: done || active ? _green : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active ? Colors.white : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? _green : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < current ? _green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCropGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _crops.map((c) {
        return GestureDetector(
          onTap: () => _onCropTap(c['key'] as String),
          child: Container(
            width: MediaQuery.of(context).size.width / 2 - 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _softBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Text(c['icon'] as String, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectedCropChip() {
    final crop = _crops.firstWhere((c) => c['key'] == _selectedCrop);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(crop['icon'] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            'निवडलेले पीक: ${crop['label']}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _greenDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCards() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _step = _Step.symptom);
            _tts.speak('लक्षणे निवडा किंवा आवाजात सांगा.');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD6D6)),
              boxShadow: const [
                BoxShadow(color: Color(0x10D32F2F), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.health_and_safety, color: Color(0xFFD32F2F), size: 26),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'रोग निदान करा',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'लक्षणांवर आधारित रोग ओळखा',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFD32F2F)),
              ],
            ),
          ),
        ),
        ..._topics.where((t) => t['key'] != 'रोग').map((t) {
          final color = t['color'] as Color;
          return GestureDetector(
            onTap: () => _selectTopicMode(t['key'] as String),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.10),
                    child: Icon(t['icon'] as IconData, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _goBackOneStep,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('पीक बदला'),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomCards() {
    return Column(
      children: [
        ..._symptomOptions.map((symptom) {
          final selected = _selectedSymptom == symptom;
          return GestureDetector(
            onTap: () => _selectSymptomMode(symptom),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF4F4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFFD32F2F) : _softBorder,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0E000000), blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.coronavirus_outlined, color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      symptom,
                      style: const TextStyle(
                        fontSize: 13.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: Color(0xFFD32F2F)),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _goBackOneStep,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('मागे जा'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmCard() {
    final crop = _crops.firstWhere((c) => c['key'] == _selectedCrop);
    final isSymptomMode = _selectedSymptom != null;
    final titleColor = isSymptomMode ? const Color(0xFFD32F2F) : _greenDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _softBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '✅ पुष्टी करा',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(crop['icon'] as String, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        crop['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isSymptomMode ? 'निदानासाठी लक्षण:' : 'निवडलेला विषय:',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSymptomMode ? _selectedSymptom! : _selectedTopic!,
                  style: TextStyle(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Query: ${_buildQuery()}',
              style: const TextStyle(
                fontSize: 12.8,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _fetchAndShow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'होय, सल्ला मिळवा',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _goBackOneStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade400),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay_rounded, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'पुन्हा निवडा',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final crop = _selectedCrop != null
        ? _crops.firstWhere((c) => c['key'] == _selectedCrop)
        : null;

    final Color color = _selectedSymptom != null
        ? const Color(0xFFD32F2F)
        : (_selectedTopic == 'खत'
            ? const Color(0xFF1565C0)
            : _selectedTopic == 'पाणी'
                ? const Color(0xFF00838F)
                : _green);

    final String modeLabel = _selectedSymptom != null
        ? 'रोग निदान'
        : (_selectedTopic ?? 'सल्ला');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (crop != null)
                Text(crop['icon'] as String, style: const TextStyle(fontSize: 28)),
              if (crop != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  crop != null
                      ? '${crop['label']} — $modeLabel'
                      : modeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 15.5,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up_rounded, color: color),
                onPressed: _advice.isEmpty ? null : () => _tts.speak(_advice),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                onPressed: _reset,
                tooltip: 'पुन्हा सुरू करा',
              ),
            ],
          ),
          if (_finalQuery.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'तुमची query: $_finalQuery',
                style: const TextStyle(fontSize: 12.4, color: Colors.black87),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: color.withValues(alpha: 0.20)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Text(
              _advice,
              style: const TextStyle(fontSize: 14.6, height: 1.72),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goBackOneStep,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('मागे जा'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _reset,
                  icon: const Icon(Icons.home_repair_service),
                  label: const Text('नवीन सल्ला'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}