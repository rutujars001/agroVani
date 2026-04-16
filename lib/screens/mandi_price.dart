import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';
import '../utils/app_config.dart';
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

// Expanded icon map covering all possible crops from data.gov.in
const _cropIcons = <String, String>{
  'Jowar': '🌾', 'Wheat': '🌿', 'Tur': '🫘', 'Onion': '🧅',
  'Soybean': '🫛', 'Sunflower': '🌻', 'Groundnut': '🥜', 'Cotton': '🌱',
  'Gram': '🫘', 'Maize': '🌽', 'Bajra': '🌾', 'Sugarcane': '🎋',
  'Tomato': '🍅', 'Pomegranate': '🍎', 'Grape': '🍇',
  'Carrot': '🥕', 'Potato': '🥔', 'Brinjal': '🍆', 'Cabbage': '🥬',
  'Cauliflower': '🥦', 'Banana': '🍌', 'Mango': '🥭', 'Orange': '🍊',
  'Lemon': '🍋', 'Garlic': '🧄', 'Ginger': '🫚', 'Turmeric': '🟡',
  'Chilli': '🌶️', 'Coriander': '🌿', 'Spinach': '🥬', 'Peas': '🫛',
  'Beans': '🫘', 'Cucumber': '🥒', 'Pumpkin': '🎃', 'Watermelon': '🍉',
};

const _cropMarathi = <String, String>{
  'Jowar': 'ज्वारी', 'Wheat': 'गहू', 'Tur': 'तूर', 'Onion': 'कांदा',
  'Soybean': 'सोयाबीन', 'Sunflower': 'सूर्यफूल', 'Groundnut': 'शेंगदाणा',
  'Cotton': 'कापूस', 'Gram': 'हरभरा', 'Maize': 'मका', 'Bajra': 'बाजरी',
  'Sugarcane': 'ऊस', 'Tomato': 'टोमॅटो', 'Pomegranate': 'डाळिंब',
  'Grape': 'द्राक्षे', 'Carrot': 'गाजर', 'Potato': 'बटाटा',
  'Brinjal': 'वांगी', 'Cabbage': 'कोबी', 'Cauliflower': 'फुलकोबी',
  'Banana': 'केळी', 'Mango': 'आंबा', 'Orange': 'संत्री',
  'Lemon': 'लिंबू', 'Garlic': 'लसूण', 'Ginger': 'आले',
  'Chilli': 'मिरची', 'Coriander': 'कोथिंबीर', 'Peas': 'वाटाणा',
  'Cucumber': 'काकडी', 'Pumpkin': 'भोपळा', 'Watermelon': 'टरबूज',
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
  'बटाटा': 'Potato',   'batata': 'Potato', 'potato': 'Potato',
  'गाजर': 'Carrot',    'gajar': 'Carrot',  'carrot': 'Carrot',
  'कोबी': 'Cabbage',   'kobi': 'Cabbage',  'cabbage': 'Cabbage',
  'मिरची': 'Chilli',   'mirchi': 'Chilli', 'chilli': 'Chilli',
  'लसूण': 'Garlic',    'lasun': 'Garlic',  'garlic': 'Garlic',
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
  String? _pinnedCrop;

  static const _green = Color(0xFF00897B);
  static const _cream = Color(0xFFF5F7F6);

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await apiGet('$kBaseUrl/mandi-prices?state=Maharashtra');
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}: ${res.body}');
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final data = payload['data'] as List<dynamic>? ?? [];
      setState(() {
        _rows = data.map((item) => <String, dynamic>{
          'variety':           item['variety'] ?? '-',
          'market_name':       item['market_name'] ?? 'Maharashtra',
          'price_per_quintal': item['price_per_quintal'] ?? 0,
          'min':               item['min'] ?? 0,
          'max':               item['max'] ?? 0,
          'date':              item['date'] ?? '-',
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Error: $e'; });
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
      _speakCropPrice(found);
    }
  }

  Future<void> _speakCropPrice(String cropKey) async {
    final row = _rows.firstWhere((r) => r['variety'] == cropKey, orElse: () => {});
    if (row.isEmpty) return;
    final name = _cropMarathi[cropKey] ?? cropKey;
    final market = row['market_name'];
    final text = '$market मंडईत आज $name चा सरासरी भाव ₹${row['price_per_quintal']} प्रति क्विंटल आहे. किमान ₹${row['min']}, कमाल ₹${row['max']}.';
    await _tts.speak(text);
  }

  List<Map<String, dynamic>> get _sortedRows {
    if (_pinnedCrop == null) return _rows;
    final pinned = _rows.where((r) => r['variety'] == _pinnedCrop).toList();
    final rest   = _rows.where((r) => r['variety'] != _pinnedCrop).toList();
    return [...pinned, ...rest];
  }

  String _icon(String variety) {
    if (_cropIcons.containsKey(variety)) return _cropIcons[variety]!;
    // fuzzy fallback
    final lower = variety.toLowerCase();
    for (final e in _cropIcons.entries) {
      if (lower.contains(e.key.toLowerCase()) || e.key.toLowerCase().contains(lower)) {
        return e.value;
      }
    }
    return '🌿';
  }

  String _marathi(String variety) => _cropMarathi[variety] ?? variety;

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
              Expanded(child: _chip('सरासरी', '₹${avg.toStringAsFixed(0)}', Colors.green.shade700)),
              const SizedBox(width: 8),
              Expanded(child: _chip('किमान', '₹${minP.toStringAsFixed(0)}', Colors.blue.shade700)),
              const SizedBox(width: 8),
              Expanded(child: _chip('कमाल', '₹${maxP.toStringAsFixed(0)}', Colors.deepOrange.shade700)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: VoiceMicBar(
              tts: _tts,
              hintText: 'बोला: "ज्वारी भाव" किंवा "कापूस"',
              onResult: _handleVoice,
            ),
          ),
          const SizedBox(height: 6),
          // Pinned crop popup card
          if (_pinnedCrop != null) _buildPinnedCard(),
          Expanded(child: _buildBody()),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _green,
            child: const Text('स्रोत: data.gov.in | महाराष्ट्र कृषी बाजार',
                style: TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center),
          ),
        ]),
      ),
    );
  }

  Widget _buildPinnedCard() {
    final row = _rows.firstWhere((r) => r['variety'] == _pinnedCrop, orElse: () => {});
    if (row.isEmpty) return const SizedBox.shrink();
    final variety = _pinnedCrop!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(children: [
          Text(_icon(variety), style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.mic, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(_marathi(variety),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
              Text(row['market_name'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                _priceChip('किमान', '₹${row['min']}', Colors.blue.shade200),
                const SizedBox(width: 8),
                _priceChip('सरासरी', '₹${row['price_per_quintal']}', Colors.white),
                const SizedBox(width: 8),
                _priceChip('कमाल', '₹${row['max']}', Colors.orange.shade200),
              ]),
            ]),
          ),
          Column(children: [
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
              onPressed: () => _speakCropPrice(variety),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
              onPressed: () => setState(() => _pinnedCrop = null),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _priceChip(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
    ]);
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _sortedRows.length,
      itemBuilder: (_, index) {
        final item    = _sortedRows[index];
        final variety = item['variety'] as String;
        final isPinned = variety == _pinnedCrop;

        return GestureDetector(
          onTap: () {
            setState(() => _pinnedCrop = variety);
            _speakCropPrice(variety);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPinned ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPinned ? _green : Colors.grey.shade200,
                width: isPinned ? 1.5 : 1,
              ),
              boxShadow: [BoxShadow(
                color: isPinned ? _green.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 3),
              )],
            ),
            child: Row(children: [
              // Icon + name
              Text(_icon(variety), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_marathi(variety),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isPinned ? _green : Colors.black87)),
                  Text(item['market_name'] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  Text(item['date'] as String,
                      style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ]),
              ),
              // Prices
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: isPinned ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('₹${item['price_per_quintal']}',
                      style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(height: 4),
                Text('↓₹${item['min']}  ↑₹${item['max']}',
                    style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ]),
            ]),
          ),
        );
      },
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
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
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
            Text('महाराष्ट्र बाजारभाव', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('data.gov.in — अधिकृत लाइव्ह किंमती', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetch,
        ),
        const Text('📊', style: TextStyle(fontSize: 28)),
      ]),
    );
  }
}
