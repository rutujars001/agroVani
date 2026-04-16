import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';

import '../utils/app_config.dart';
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';
import 'calculator_screen.dart';
import 'crops_screen.dart';
import 'krushi_doctor.dart';
import 'mandi_price.dart';
import 'news_detail_screen.dart';
import 'profile_screen.dart';
import 'weather_screen.dart';
import 'yojana_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _bg = Color(0xFFF5F7F6);
  static const String _weatherApiKey = '482a3a616b59b6ad77409e8aed90da11';

  final PollyTts _tts = PollyTts();

  String _userName = '';
  String _userVillage = 'Solapur';
  String _profileImageUrl = '';
  String _gender = '';

  List<String> _userCrops = [];
  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> _recentActions = [];

  String _soilType = 'black';
  String _suggestion = '';
  String _voiceResponse = '';

  double _temp = 0;
  String _condition = '';
  int _humidity = 0;

  bool _loadingWeather = true;
  bool _loadingNews = false;
  bool _loadingSuggestion = false;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initializeHome() async {
    await _loadUser();
    await Future.wait([
      _fetchWeather(),
      _fetchNews(),
      _fetchSuggestion(),
    ]);
  }

  Future<void> _loadUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() => _loadingUser = false);
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data() ?? <String, dynamic>{};

      if (!mounted) return;

      final village = (data['village'] ?? 'Solapur').toString().trim();
      final name = (data['name'] ?? '').toString().trim();
      final crops = List<String>.from(data['crops'] ?? []);
      final soil = _soilKey((data['soil_type'] ?? '').toString());
      final gender = (data['gender'] ?? '').toString().trim();
      final profileImage = (data['profile_photo'] ?? '').toString().trim();

      setState(() {
        _userName = name;
        _userVillage = village.isEmpty ? 'Solapur' : village;
        _userCrops = crops;
        _soilType = soil;
        _gender = gender;
        _profileImageUrl = profileImage;
        _loadingUser = false;
      });

      _prepareRecentActions();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
    }
  }

  void _prepareRecentActions() {
    final actions = <Map<String, dynamic>>[];

    if (_userCrops.isNotEmpty) {
      actions.add({
        'icon': '🌾',
        'title': 'तुमची पिके अपडेट झाली',
        'subtitle': '${_userCrops.length} पिके निवडलेली आहेत',
      });
    }

    if (_condition.isNotEmpty) {
      actions.add({
        'icon': '🌤️',
        'title': 'हवामान अपडेट झाले',
        'subtitle': '$_userVillage मध्ये $_condition, $_humidity% आर्द्रता',
      });
    }

    if (_suggestion.trim().isNotEmpty) {
      actions.add({
        'icon': '💡',
        'title': 'स्मार्ट सूचना तयार',
        'subtitle': _suggestion,
      });
    }

    if (_news.isNotEmpty) {
      actions.add({
        'icon': '📰',
        'title': 'नवीन कृषी बातम्या उपलब्ध',
        'subtitle': '${_news.length} बातम्या पाहण्यासाठी टॅप करा',
      });
    }

    setState(() {
      _recentActions = actions.take(4).toList();
    });
  }

  String _soilKey(String soil) {
    if (soil.contains('काळी')) return 'black';
    if (soil.contains('लाल')) return 'red';
    if (soil.contains('गाळ')) return 'alluvial';
    if (soil.contains('वालु')) return 'sandy';
    return 'loamy';
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$_userVillage&appid=$_weatherApiKey&units=metric',
        ),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _temp = ((data['main']?['temp'] ?? 0) as num).toDouble();
        _humidity = (data['main']?['humidity'] ?? 0) as int;
        _condition = ((data['weather'] as List?)?.isNotEmpty ?? false)
            ? data['weather'][0]['main'].toString()
            : '';
        _loadingWeather = false;
      });

      _prepareRecentActions();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWeather = false);
    }
  }

  Future<void> _fetchNews() async {
    setState(() => _loadingNews = true);

    try {
      final response =
          await apiGet('$kBaseUrl/agri-news');

      final payload = json.decode(response.body) as Map<String, dynamic>;
      final list = (payload['news'] as List? ?? []);

      if (!mounted) return;

      setState(() {
        _news = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingNews = false;
      });

      _prepareRecentActions();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingNews = false);
    }
  }

  Future<void> _fetchSuggestion() async {
    setState(() => _loadingSuggestion = true);

    try {
      final response = await apiPost(
        '$kBaseUrl/recommend',
        body: json.encode({
          'soil_type': _soilType,
          'city': _userVillage,
        }),
      );

      final payload = json.decode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _suggestion = (payload['message'] ?? '')
            .toString()
            .replaceAll('**', '')
            .replaceAll('🌱 स्मार्ट सूचना: ', '')
            .trim();
        _loadingSuggestion = false;
      });

      _prepareRecentActions();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSuggestion = false);
    }
  }

  Future<void> _handleVoice(String query) async {
    final q = query.toLowerCase().trim();
    String reply = '';

    if (q.contains('हवामान') || q.contains('weather')) {
      reply =
          'तुम्हाला हवामान पेजवर घेऊन जात आहे. आज $_userVillage मध्ये $_condition आणि ${_temp.toStringAsFixed(0)} अंश तापमान आहे.';
      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherScreen()),
      );
      return;
    }

    if (q.contains('बाजारभाव') || q.contains('mandi')) {
      reply = 'तुम्हाला बाजारभाव पेजवर घेऊन जात आहे.';
      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BazaarScreen()),
      );
      return;
    }

    if (q.contains('योजना')) {
      reply = 'तुम्हाला योजना पेजवर घेऊन जात आहे.';
      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const YojanaScreen()),
      );
      return;
    }

    if (q.contains('खत') || q.contains('गणक') || q.contains('calculator')) {
      reply = 'तुम्हाला खत गणक पेजवर घेऊन जात आहे.';
      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalculatorScreen()),
      );
      return;
    }

    if (q.contains('डॉक्टर') || q.contains('रोग')) {
      reply = 'तुम्हाला कृषी डॉक्टर पेजवर घेऊन जात आहे.';
      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KrushiDoctor()),
      );
      return;
    }

    try {
      final response = await apiPost(
        '$kBaseUrl/query',
        body: json.encode({'query': query}),
      );

      final payload = json.decode(response.body) as Map<String, dynamic>;
      reply = (payload['fulfillmentText'] ?? 'उत्तर उपलब्ध नाही.')
          .toString()
          .trim();

      if (!mounted) return;
      setState(() => _voiceResponse = reply);
      await _tts.speak(reply);
    } catch (_) {
      if (!mounted) return;
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
      'Cotton': '🌱',
      'Jowar': '🌾',
      'Wheat': '🌿',
      'Onion': '🧅',
      'Soybean': '🫛',
      'Tur': '🫘',
      'Sugarcane': '🎋',
      'Tomato': '🍅',
      'Gram': '🫘',
      'Maize': '🌽',
      'Groundnut': '🥜',
      'Pomegranate': '🍎',
      'Sunflower': '🌻',
      'Bajra': '🌾',
      'Grape': '🍇',
    };
    return map[key] ?? '🌿';
  }

  String _cropLabel(String key) {
    const map = {
      'Cotton': 'कापूस',
      'Jowar': 'ज्वारी',
      'Wheat': 'गहू',
      'Onion': 'कांदा',
      'Soybean': 'सोयाबीन',
      'Tur': 'तूर',
      'Sugarcane': 'ऊस',
      'Tomato': 'टोमॅटो',
      'Gram': 'हरभरा',
      'Maize': 'मका',
      'Groundnut': 'शेंगदाणा',
      'Pomegranate': 'डाळिंब',
      'Sunflower': 'सूर्यफूल',
      'Bajra': 'बाजरी',
      'Grape': 'द्राक्षे',
    };
    return map[key] ?? key;
  }

  bool _isFemale() {
    final g = _gender.toLowerCase();
    return g.contains('female') ||
        g.contains('woman') ||
        g.contains('girl') ||
        g.contains('महिला') ||
        g.contains('स्त्री');
  }

  Widget _buildAvatar() {
    if (_profileImageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(_profileImageUrl),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        shape: BoxShape.circle,
        border: Border.all(color: _teal.withValues(alpha: 0.35), width: 1.4),
      ),
      child: Center(
        child: Icon(
          _isFemale() ? Icons.face_3_rounded : Icons.face_rounded,
          color: _teal,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _userName.trim().isEmpty
        ? 'शेतकरी'
        : _userName.trim().split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'सुप्रभात'
        : hour < 17
            ? 'नमस्कार'
            : 'शुभ संध्या';

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _teal,
        onRefresh: _initializeHome,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _loadingUser
                            ? const SizedBox(
                                height: 42,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: CircularProgressIndicator(
                                    color: _teal,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting, $firstName!',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '$_userVillage मधील आजची शेती माहिती',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                          await _loadUser();
                          await _fetchSuggestion();
                        },
                        child: _buildAvatar(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VoiceMicBar(
                    tts: _tts,
                    hintText: 'बोला: "आजचे हवामान", "बाजारभाव", "कृषी डॉक्टर"',
                    onResult: _handleVoice,
                  ),
                ),
                if (_voiceResponse.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _teal.withValues(alpha: 0.20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.smart_toy_outlined,
                            color: _teal,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _voiceResponse,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _tts.speak(_voiceResponse),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              color: _teal,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WeatherScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _teal,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: _loadingWeather
                                ? const SizedBox(
                                    height: 86,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _weatherEmoji(),
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.white70,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${_temp.toStringAsFixed(0)}°C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        _condition,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'आर्द्रता $_humidity%',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.tips_and_updates_rounded,
                                      color: Color(0xFF2E7D32),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'सूचना',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _loadingSuggestion
                                  ? const LinearProgressIndicator(color: _teal)
                                  : Text(
                                      _suggestion.isEmpty
                                          ? 'सध्या सूचना उपलब्ध नाही.'
                                          : _suggestion,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_userCrops.isNotEmpty) ...[
                  _sectionHeader('माझी पिके', 'सर्व पहा'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _userCrops.length,
                      itemBuilder: (_, i) {
                        final crop = _userCrops[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CropsScreen(initialCrop: crop),
                            ),
                          ),
                          child: Container(
                            width: 82,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: _teal.withValues(alpha: 0.20)),
                              boxShadow: [
                                BoxShadow(
                                  color: _teal.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _cropIcon(crop),
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _cropLabel(crop),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
                      _serviceCard(
                        '🩺',
                        'कृषी डॉक्टर',
                        const KrushiDoctor(),
                        const Color(0xFFFCE4EC),
                        const Color(0xFFE91E63),
                      ),
                      _serviceCard(
                        '🌾',
                        'पीक माहिती',
                        const CropsScreen(),
                        const Color(0xFFE8F5E9),
                        const Color(0xFF2E7D32),
                      ),
                      _serviceCard(
                        '📊',
                        'बाजारभाव',
                        const BazaarScreen(),
                        const Color(0xFFEDE7F6),
                        const Color(0xFF6A1B9A),
                      ),
                      _serviceCard(
                        '🌤️',
                        'हवामान',
                        const WeatherScreen(),
                        const Color(0xFFE3F2FD),
                        const Color(0xFF1565C0),
                      ),
                      _serviceCard(
                        '🧪',
                        'खत गणक',
                        const CalculatorScreen(),
                        const Color(0xFFE0F2F1),
                        _teal,
                      ),
                      _serviceCard(
                        '📋',
                        'योजना',
                        const YojanaScreen(),
                        const Color(0xFFFFF8E1),
                        const Color(0xFFF57F17),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_recentActions.isNotEmpty) ...[
                  _sectionHeader('अलीकडील हालचाली', 'See more'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 124,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recentActions.length,
                      itemBuilder: (_, i) {
                        final item = _recentActions[i];
                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['icon'] ?? '✅',
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  item['subtitle'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.45,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _sectionHeader('कृषी बातम्या', _loadingNews ? null : 'सर्व पहा'),
                const SizedBox(height: 10),
                if (_loadingNews)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: _teal),
                    ),
                  )
                else if (_news.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'सध्या बातम्या उपलब्ध नाहीत.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    itemCount: _news.take(4).length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, index) {
                      final item = _news[index];
                      final title = (item['title'] ?? '').toString();
                      final source = (item['source'] ?? 'Agri News').toString();
                      final date = (item['date'] ?? '').toString();

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailScreen(news: item),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text(
                                    '📰',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          source,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _teal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? actionText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          if (actionText != null)
            Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                color: _teal,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _serviceCard(
    String emoji,
    String title,
    Widget screen,
    Color bgColor,
    Color accent,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}