import 'package:flutter/material.dart';
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final PollyTts _tts = PollyTts();
  final TextEditingController _areaCtrl = TextEditingController();

  String _crop = 'कापूस';
  String _fertilizer = 'युरिया';
  String _unit = 'एकर';
  String _result = '';
  bool _calculated = false;

  static const _green = Color(0xFF1B5E20);
  static const _cream = Color(0xFFF3F1E7);

  // kg per acre for each crop × fertilizer
  static const _doses = <String, Map<String, double>>{
    'ज्वारी':    {'युरिया': 40, 'DAP': 20, 'MOP': 20, 'SSP': 50},
    'गहू':       {'युरिया': 60, 'DAP': 30, 'MOP': 15, 'SSP': 75},
    'तूर':       {'युरिया': 25, 'DAP': 50, 'MOP': 20, 'SSP': 60},
    'कांदा':     {'युरिया': 50, 'DAP': 50, 'MOP': 50, 'SSP': 100},
    'सोयाबीन':  {'युरिया': 25, 'DAP': 50, 'MOP': 20, 'SSP': 60},
    'सूर्यफूल': {'युरिया': 60, 'DAP': 30, 'MOP': 30, 'SSP': 75},
    'शेंगदाणा': {'युरिया': 25, 'DAP': 50, 'MOP': 50, 'SSP': 60},
    'कापूस':     {'युरिया': 50, 'DAP': 40, 'MOP': 20, 'SSP': 100},
    'हरभरा':     {'युरिया': 25, 'DAP': 50, 'MOP': 20, 'SSP': 60},
    'मका':       {'युरिया': 60, 'DAP': 30, 'MOP': 30, 'SSP': 75},
    'बाजरी':     {'युरिया': 40, 'DAP': 20, 'MOP': 15, 'SSP': 50},
    'ऊस':        {'युरिया': 80, 'DAP': 60, 'MOP': 40, 'SSP': 150},
    'टोमॅटो':   {'युरिया': 60, 'DAP': 60, 'MOP': 60, 'SSP': 120},
    'डाळिंब':   {'युरिया': 30, 'DAP': 25, 'MOP': 25, 'SSP': 60},
    'द्राक्षे': {'युरिया': 40, 'DAP': 40, 'MOP': 40, 'SSP': 80},
  };

  // Voice keyword → crop Marathi name
  static const _voiceCropMap = <String, String>{
    'ज्वारी': 'ज्वारी',   'jwari': 'ज्वारी',   'jowar': 'ज्वारी',
    'गहू': 'गहू',          'gahu': 'गहू',        'wheat': 'गहू',
    'तूर': 'तूर',          'tur': 'तूर',
    'कांदा': 'कांदा',      'kanda': 'कांदा',     'onion': 'कांदा',
    'सोयाबीन': 'सोयाबीन', 'soya': 'सोयाबीन',   'soybean': 'सोयाबीन',
    'सूर्यफूल': 'सूर्यफूल','sunflower': 'सूर्यफूल',
    'शेंगदाणा': 'शेंगदाणा','shengdana': 'शेंगदाणा','groundnut': 'शेंगदाणा',
    'कापूस': 'कापूस',      'kapus': 'कापूस',     'cotton': 'कापूस',
    'हरभरा': 'हरभरा',      'harbhara': 'हरभरा',  'gram': 'हरभरा',
    'मका': 'मका',           'makka': 'मका',       'maize': 'मका',
    'बाजरी': 'बाजरी',      'bajra': 'बाजरी',
    'ऊस': 'ऊस',             'oos': 'ऊस',          'sugarcane': 'ऊस',
    'टोमॅटो': 'टोमॅटो',   'tamatar': 'टोमॅटो',  'tomato': 'टोमॅटो',
    'डाळिंब': 'डाळिंब',   'dalimb': 'डाळिंब',   'pomegranate': 'डाळिंब',
    'द्राक्षे': 'द्राक्षे','draksha': 'द्राक्षे','grape': 'द्राक्षे',
  };

  static const _voiceFertMap = <String, String>{
    'युरिया': 'युरिया', 'urea': 'युरिया', 'uriya': 'युरिया',
    'dap': 'DAP', 'डीएपी': 'DAP',
    'mop': 'MOP', 'पोटाश': 'MOP',
    'ssp': 'SSP', 'एसएसपी': 'SSP',
  };

  @override
  void dispose() {
    _areaCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaCtrl.text.trim());
    if (area == null || area <= 0) {
      setState(() { _result = 'कृपया योग्य क्षेत्रफळ टाका.'; _calculated = true; });
      return;
    }
    final acres = _unit == 'हेक्टर' ? area * 2.471 : area;
    final dose  = _doses[_crop]?[_fertilizer] ?? 0;
    final total = acres * dose;
    final bags  = total / 50;
    final text  = '$_crop साठी $_fertilizer:\n'
        '${total.toStringAsFixed(1)} कि.ग्रा. (${bags.toStringAsFixed(1)} पिशव्या)\n'
        '${area.toStringAsFixed(1)} $_unit क्षेत्रासाठी';
    setState(() { _result = text; _calculated = true; });
    _speak(text);
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  // Marathi word → number
  static const _marathiNumbers = <String, String>{
    'एक': '1', 'दोन': '2', 'तीन': '3', 'चार': '4', 'पाच': '5',
    'सहा': '6', 'सात': '7', 'आठ': '8', 'नऊ': '9', 'दहा': '10',
    'अकरा': '11', 'बारा': '12', 'तेरा': '13', 'चौदा': '14', 'पंधरा': '15',
    'वीस': '20', 'पंचवीस': '25', 'तीस': '30', 'पन्नास': '50',
  };

  void _handleVoice(String spoken) {
    String lower = spoken.toLowerCase();

    // Replace Marathi number words with digits
    _marathiNumbers.forEach((word, digit) {
      lower = lower.replaceAll(word, digit);
    });

    // Extract crop anywhere in sentence
    _voiceCropMap.forEach((k, v) { if (lower.contains(k)) _crop = v; });

    // Extract fertilizer anywhere in sentence
    _voiceFertMap.forEach((k, v) { if (lower.contains(k)) _fertilizer = v; });

    // Extract area — digits (including decimals)
    final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(lower);
    if (numMatch != null) _areaCtrl.text = numMatch.group(1)!;

    // Extract unit anywhere in sentence
    if (lower.contains('हेक्टर') || lower.contains('hectare')) _unit = 'हेक्टर';
    if (lower.contains('एकर') || lower.contains('acre')) _unit = 'एकर';

    // Fallback fertilizer if not valid for crop
    if (!(_doses[_crop]?.containsKey(_fertilizer) ?? false)) {
      _fertilizer = _doses[_crop]?.keys.first ?? 'युरिया';
    }
    setState(() {});
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final fertilizers = _doses[_crop]?.keys.toList() ?? ['युरिया'];
    if (!fertilizers.contains(_fertilizer)) _fertilizer = fertilizers.first;

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
                  hintText: 'बोला: "५ एकर उसासाठी युरिया किती लागेल"',
                  onResult: _handleVoice,
                ),
                const SizedBox(height: 16),
                // Crop selector
                _label('पीक निवडा'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _doses.keys.map((c) {
                    final sel = _crop == c;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _crop = c;
                          if (!(_doses[c]?.containsKey(_fertilizer) ?? false)) {
                            _fertilizer = _doses[c]!.keys.first;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? _green : Colors.grey.shade300),
                          boxShadow: sel ? [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 6)] : [],
                        ),
                        child: Text(c,
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Fertilizer selector
                _label('खत प्रकार'),
                const SizedBox(height: 8),
                Row(children: fertilizers.map((f) {
                  final sel = _fertilizer == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _fertilizer = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? _green : Colors.grey.shade300),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                // Area input + unit
                _label('क्षेत्रफळ'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _areaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'उदा. 2.5',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Unit toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(children: ['एकर', 'हेक्टर'].map((u) {
                      final sel = _unit == u;
                      return GestureDetector(
                        onTap: () => setState(() => _unit = u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? _green : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(u,
                              style: TextStyle(
                                  color: sel ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      );
                    }).toList()),
                  ),
                ]),
                const SizedBox(height: 16),
                // Calculate button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text('गणना करा', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                // Result
                if (_calculated && _result.isNotEmpty) ...[
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
                        const Icon(Icons.science_rounded, color: _green),
                        const SizedBox(width: 8),
                        const Text('गणना निकाल', style: TextStyle(fontWeight: FontWeight.w700, color: _green)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: _green),
                          onPressed: () => _speak(_result),
                        ),
                      ]),
                      const Divider(),
                      Text(_result, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.6)),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),
                const Text('टीप: हा अंदाज साधारण आहे. माती परीक्षण व कृषी तज्ज्ञांचा सल्ला घ्या.',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15));

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
            Text('खत गणक', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('पीक व क्षेत्रफळानुसार खत प्रमाण', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const Text('🧪', style: TextStyle(fontSize: 32)),
      ]),
    );
  }
}
