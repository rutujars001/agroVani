import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';
import 'weather_screen.dart';
import 'yojana_screen.dart';
import 'mandi_price.dart';
import 'calculator_screen.dart';
import 'krushi_doctor.dart';
import 'crops_screen.dart';
import 'profile_screen.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PollyTts _tts = PollyTts();
  static const _teal = Color(0xFF00897B);

  String _userName = '';
  List<String> _userCrops = [];
  String _soilType = 'black';
  double _temp = 0;
  String _condition = '';
  int _humidity = 0;
  bool _loadingWeather = true;
  List<Map<String, dynamic>> _news = [];
  bool _loadingNews = false;
  String _suggestion = '';
  bool _loadingSuggestion = false;
  String _voiceResponse = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchWeather();
    _fetchNews();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    final data = doc.data() ?? {};
    setState(() {
      _userName  = (data['name'] ?? '').toString();
      _userCrops = List<String>.from(data['crops'] ?? []);
      _soilType  = _soilKey((data['soil_type'] ?? '').toString());
    });
    _fetchSuggestion();
  }

  String _soilKey(String s) {
    if (s.contains('काळी')) return 'black';
    if (s.contains('लाल')) return 'red';
    if (s.contains('गाळ')) return 'alluvial';
    if (s.contains('वालु')) return 'sandy';
    return 'loamy';
  }

  Future<void> _fetchWeather() async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=Solapur&appid=482a3a616b59b6ad77409e8aed90da11&units=metric'));
      final d = json.decode(res.body);
      if (!mounted) return;
      setState(() {
        _temp      = (d['main']['temp'] as num).toDouble();
        _humidity  = d['main']['humidity'] as int;
        _condition = (d['weather'] as List).first['main'].toString();
        _loadingWeather = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  Future<void> _fetchNews() async {
    setState(() => _loadingNews = true);
    try {
      final res = await http.get(Uri.parse('http://10.144.10.112:5000/agri-news'));
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final list = payload['news'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _news = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingNews = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingNews = false);
    }
  }

  Future<void> _fetchSuggestion() async {
    setState(() => _loadingSuggestion = true);
    try {
      final res = await http.post(
        Uri.parse('http://10.144.10.112:5000/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'soil_type': _soilType, 'city': 'Solapur'}),
      );
      final payload = json.decode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _suggestion = (payload['message'] ?? '').toString().replaceAll('**', '').replaceAll('🌱 स्मार्ट सूचना: ', '');
        _loadingSuggestion = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestion = false);
    }
  }

  Future<void> _handleVoice(String query) async {
    try {
      final res = await http.post(
        Uri.parse('http://10.144.10.112:5000/query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final reply = (payload['fulfillmentText'] ?? '').toString();
      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
    } catch (_) {
      setState(() => _voiceResponse = 'सर्व्हरशी कनेक्ट होता आले नाही.');
    }
  }

  String _weatherEmoji() {
    final c = _condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('cloud')) return '⛅';
    if (c.contains('snow')) return '❄️';
    if (c.contains('mist') || c.contains('fog')) return '🌫️';
    return _temp >= 34 ? '☀️' : '🌤️';
  }

  String _cropIcon(String key) {
    const map = {
      'Cotton': '🌱', 'Jowar': '🌾', 'Wheat': '🌿', 'Onion': '🧅',
      'Soybean': '🫛', 'Tur': '🫘', 'Sugarcane': '🎋', 'Tomato': '🍅',
      'Gram': '🫘', 'Maize': '🌽', 'Groundnut': '🥜', 'Pomegranate': '🍎',
      'Sunflower': '🌻', 'Bajra': '🌾', 'Grape': '🍇',
    };
    return map[key] ?? '🌿';
  }

  String _cropLabel(String key) {
    const map = {
      'Cotton': 'कापूस', 'Jowar': 'ज्वारी', 'Wheat': 'गहू', 'Onion': 'कांदा',
      'Soybean': 'सोयाबीन', 'Tur': 'तूर', 'Sugarcane': 'ऊस', 'Tomato': 'टोमॅटो',
      'Gram': 'हरभरा', 'Maize': 'मका', 'Groundnut': 'शेंगदाणा', 'Pomegranate': 'डाळिंब',
      'Sunflower': 'सूर्यफूल', 'Bajra': 'बाजरी', 'Grape': 'द्राक्षे',
    };
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _userName.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'सुप्रभात' : hour < 17 ? 'नमस्कार' : 'शुभ संध्या';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ───────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting, ${firstName.isEmpty ? 'शेतकरी' : firstName}!',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                    const Text('आजची शेती माहिती पाहा',
                        style: TextStyle(fontSize: 12, color: Colors.black45)),
                  ]),
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    await _loadUser();
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _teal.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Center(child: Icon(Icons.person_rounded, color: _teal, size: 22)),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 8),

            // ── Voice Bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VoiceMicBar(
                tts: _tts,
                hintText: 'बोला: "कापूस रोग" किंवा "हवामान सांग"',
                onResult: _handleVoice,
              ),
            ),

            if (_voiceResponse.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.smart_toy_outlined, color: _teal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_voiceResponse,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
                    GestureDetector(
                      onTap: () => _tts.speak(_voiceResponse),
                      child: const Icon(Icons.volume_up_rounded, color: _teal, size: 18),
                    ),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Weather + Suggestion ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Weather
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WeatherScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _loadingWeather
                          ? const SizedBox(height: 80,
                              child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(_weatherEmoji(), style: const TextStyle(fontSize: 24)),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 12),
                              ]),
                              const SizedBox(height: 8),
                              Text('${_temp.toStringAsFixed(0)}°C',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              Text(_condition,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text('आर्द्रता $_humidity%',
                                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Smart suggestion
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF2E7D32), size: 16),
                        ),
                        const SizedBox(width: 6),
                        const Text('सूचना', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87)),
                      ]),
                      const SizedBox(height: 8),
                      _loadingSuggestion
                          ? const LinearProgressIndicator(color: _teal)
                          : Text(
                              _suggestion.isEmpty ? 'लोड होत आहे...' : _suggestion,
                              style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
                              maxLines: 5, overflow: TextOverflow.ellipsis,
                            ),
                    ]),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── My Crops ─────────────────────────────────────────────────────
            if (_userCrops.isNotEmpty) ...[
              _sectionHeader('माझी पिके', null),
              const SizedBox(height: 10),
              SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _userCrops.length,
                  itemBuilder: (_, i) {
                    final crop = _userCrops[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CropsScreen(initialCrop: crop))),
                      child: Container(
                        width: 76,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _teal.withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.06), blurRadius: 6)],
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_cropIcon(crop), style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(_cropLabel(crop),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Services ─────────────────────────────────────────────────────
            _sectionHeader('सेवा', null),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  _serviceCard('🩺', 'कृषी डॉक्टर', const KrushiDoctor(), const Color(0xFFFCE4EC), const Color(0xFFE91E63)),
                  _serviceCard('🌾', 'पीक माहिती', const CropsScreen(), const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  _serviceCard('📊', 'बाजारभाव', const BazaarScreen(), const Color(0xFFEDE7F6), const Color(0xFF6A1B9A)),
                  _serviceCard('🌤️', 'हवामान', const WeatherScreen(), const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                  _serviceCard('🧪', 'खत गणक', const CalculatorScreen(), const Color(0xFFE0F2F1), _teal),
                  _serviceCard('📋', 'योजना', const YojanaScreen(), const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── News ─────────────────────────────────────────────────────────
            _sectionHeader('ताजे कृषी बातम्या', _fetchNews),
            const SizedBox(height: 10),
            if (_loadingNews)
              const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: _teal, strokeWidth: 2)))
            else if (_news.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('बातम्या उपलब्ध नाहीत.', style: TextStyle(color: Colors.black45)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _news.length,
                itemBuilder: (_, i) {
                  final item = _news[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: item))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(child: Icon(Icons.article_rounded, color: _teal, size: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _teal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('✅ ${item['source']}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _teal)),
                            ),
                            const SizedBox(height: 5),
                            Text((item['title'] ?? '').toString(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4, color: Colors.black87),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if ((item['date'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text((item['date'] ?? '').toString(),
                                    style: const TextStyle(fontSize: 10, color: Colors.black38)),
                              ),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
                      ]),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback? onRefresh) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
        const Spacer(),
        if (onRefresh != null)
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh_rounded, size: 18, color: _teal),
          ),
      ]),
    );
  }

  Widget _serviceCard(String emoji, String label, Widget screen, Color bg, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center, maxLines: 2),
        ]),
      ),
    );
  }
}
