import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

const _cropMarathi = <String, String>{
  'Jowar': 'ज्वारी', 'Wheat': 'गहू', 'Tur': 'तूर', 'Onion': 'कांदा',
  'Soybean': 'सोयाबीन', 'Sunflower': 'सूर्यफूल', 'Groundnut': 'शेंगदाणा',
  'Cotton': 'कापूस', 'Gram': 'हरभरा', 'Maize': 'मका', 'Bajra': 'बाजरी',
  'Sugarcane': 'ऊस', 'Tomato': 'टोमॅटो', 'Pomegranate': 'डाळिंब', 'Grape': 'द्राक्षे',
};

const _cropIcons = <String, String>{
  'Jowar': '🌾', 'Wheat': '🌿', 'Tur': '🫘', 'Onion': '🧅',
  'Soybean': '🫛', 'Sunflower': '🌻', 'Groundnut': '🥜', 'Cotton': '🌱',
  'Gram': '🫘', 'Maize': '🌽', 'Bajra': '🌾', 'Sugarcane': '🎋',
  'Tomato': '🍅', 'Pomegranate': '🍎', 'Grape': '🍇',
};

const _voiceCropMap = <String, String>{
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
  'बाजरी': 'Bajra',    'bajra': 'Bajra',
  'ऊस': 'Sugarcane',   'oos': 'Sugarcane', 'sugarcane': 'Sugarcane',
  'टोमॅटो': 'Tomato',  'tamatar': 'Tomato','tomato': 'Tomato',
  'डाळिंब': 'Pomegranate','dalimb': 'Pomegranate','pomegranate': 'Pomegranate',
  'द्राक्षे': 'Grape', 'draksha': 'Grape', 'grape': 'Grape',
};

class BazaarScreen extends StatefulWidget {
  const BazaarScreen({super.key});
  @override
  State<BazaarScreen> createState() => _BazaarScreenState();
}

class _BazaarScreenState extends State<BazaarScreen> {
  final PollyTts _tts = PollyTts();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  String? _pinnedCrop; // voice-selected crop shown on top

  static const _green = Color(0xFF1B5E20);
  static const _cream = Color(0xFFF3F1E7);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('http://10.210.216.112:5000/mandi-prices?market=Solapur'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final data = payload['data'] as List<dynamic>? ?? [];
      setState(() {
        _rows = data.map((item) => <String, dynamic>{
          'variety':           item['variety']           ?? '-',
          'market_name':       item['market_name']       ?? 'Solapur',
          'price_per_quintal': item['price_per_quintal'] ?? 0,
          'min':               item['min']               ?? 0,
          'max':               item['max']               ?? 0,
          'date':              item['date']              ?? '-',
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'डेटा मिळाला नाही. Flask server चालू आहे का?'; });
    }
  }

  void _handleVoice(String spoken) {
    final lower = spoken.toLowerCase();
    String? found;
    for (final e in _voiceCropMap.entries) {
      if (lower.contains(e.key)) { found = e.value; break; }
    }
    if (found != null) {
      setState(() => _pinnedCrop = found);
      _speakCropPrice(found!);
    }
  }

  Future<void> _speakCropPrice(String cropKey) async {
    final row = _rows.firstWhere((r) => r['variety'] == cropKey, orElse: () => {});
    if (row.isEmpty) return;
    final name = _cropMarathi[cropKey] ?? cropKey;
    final text = 'सोलापूर मंडईत आज $name चा सरासरी भाव ₹${row['price_per_quintal']} प्रति क्विंटल आहे. किमान ₹${row['min']}, कमाल ₹${row['max']}.';
    await _tts.speak(text);
  }

  List<Map<String, dynamic>> get _sortedRows {
    if (_pinnedCrop == null) return _rows;
    final pinned = _rows.where((r) => r['variety'] == _pinnedCrop).toList();
    final rest   = _rows.where((r) => r['variety'] != _pinnedCrop).toList();
    return [...pinned, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final prices = _rows.map((e) => (e['price_per_quintal'] as num).toDouble()).toList();
    final avg  = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a + b) / prices.length;
    final minP = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 10),
          // Summary chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Expanded(child: _chip('सरासरी', '₹ ${avg.toStringAsFixed(0)}', Colors.green.shade700)),
              const SizedBox(width: 8),
              Expanded(child: _chip('किमान', '₹ ${minP.toStringAsFixed(0)}', Colors.blue.shade700)),
              const SizedBox(width: 8),
              Expanded(child: _chip('कमाल', '₹ ${maxP.toStringAsFixed(0)}', Colors.deepOrange.shade700)),
            ]),
          ),
          const SizedBox(height: 8),
          // Voice mic
          VoiceMicBar(
            tts: _tts,
            hintText: 'बोला: "ज्वारी भाव" किंवा "कापूस"',
            onResult: _handleVoice,
          ),
          const SizedBox(height: 6),
          // Table
          Expanded(child: _buildBody()),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: _green,
            child: const Text('टीप: हे दर फक्त माहितीसाठी आहेत.',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center),
          ),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _green));
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
            label: const Text('पुन्हा प्रयत्न करा'),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          ),
        ]),
      ));
    }
    if (_rows.isEmpty) return const Center(child: Text('आजचा डेटा उपलब्ध नाही.'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green, width: 1.4),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: [
            // Header row
            Container(
              color: _green,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              child: const Row(children: [
                SizedBox(width: 28, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(flex: 4, child: Text('पीक नाव', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 3, child: Text('किमान (₹)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('सरासरी (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('कमाल (₹)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _sortedRows.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.green.shade100),
                itemBuilder: (_, index) {
                  final item    = _sortedRows[index];
                  final variety = item['variety'] as String;
                  final isPinned = variety == _pinnedCrop;
                  final icon    = _cropIcons[variety]   ?? '🌿';
                  final marathi = _cropMarathi[variety] ?? variety;
                  final rowBg   = isPinned
                      ? const Color(0xFFE8F5E9)
                      : index.isEven ? Colors.white : const Color(0xFFEFF7F0);

                  return GestureDetector(
                    onTap: () => _speakCropPrice(variety),
                    child: Container(
                      color: rowBg,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      child: Row(children: [
                        SizedBox(
                          width: 28,
                          child: isPinned
                              ? const Icon(Icons.mic, size: 16, color: _green)
                              : Text('${index + 1}',
                                  style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Row(children: [
                            Text(icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Flexible(child: Text(marathi,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isPinned ? _green : Colors.black87),
                                overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                        Expanded(flex: 3, child: Text('₹ ${item['min']}',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                            textAlign: TextAlign.center)),
                        Expanded(
                          flex: 3,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: isPinned ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('₹ ${item['price_per_quintal']}',
                                style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13),
                                textAlign: TextAlign.center),
                          ),
                        ),
                        Expanded(flex: 3, child: Text('₹ ${item['max']}',
                            style: TextStyle(color: Colors.deepOrange.shade700, fontSize: 13),
                            textAlign: TextAlign.center)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Column(children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
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
            Text('सोलापूर बाजारभाव', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('सोलापूर कृषी उत्पन्न बाजार समिती', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const Text('📊', style: TextStyle(fontSize: 32)),
      ]),
    );
  }
}
