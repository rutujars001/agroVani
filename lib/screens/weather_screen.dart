import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _bg = Color(0xFFF5F7F6);
  static const String _apiKey = '482a3a616b59b6ad77409e8aed90da11';

  final PollyTts _tts = PollyTts();

  bool _loading = true;
  String _village = 'Solapur';
  String _userName = '';

  double _temp = 0;
  double _feelsLike = 0;
  double _windSpeed = 0;
  int _humidity = 0;
  int _pressure = 0;
  String _condition = '';
  String _description = '';
  String _alertMessage = '';
  String _updatedAt = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndWeather();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadUserAndWeather() async {
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data() ?? {};

        _village = ((data['village'] ?? 'Solapur').toString().trim().isEmpty)
            ? 'Solapur'
            : (data['village'] ?? 'Solapur').toString().trim();

        _userName = (data['name'] ?? '').toString().trim();
      }

      await _fetchWeather();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=$_village&appid=$_apiKey&units=metric';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body) as Map<String, dynamic>;

      final temp = ((data['main']?['temp'] ?? 0) as num).toDouble();
      final feelsLike = ((data['main']?['feels_like'] ?? 0) as num).toDouble();
      final humidity = (data['main']?['humidity'] ?? 0) as int;
      final pressure = (data['main']?['pressure'] ?? 0) as int;
      final windSpeed = ((data['wind']?['speed'] ?? 0) as num).toDouble();
      final condition = ((data['weather'] as List?)?.isNotEmpty ?? false)
          ? data['weather'][0]['main'].toString()
          : '';
      final description = ((data['weather'] as List?)?.isNotEmpty ?? false)
          ? data['weather'][0]['description'].toString()
          : '';

      final alert = _buildAlertMessage(
        temp: temp,
        humidity: humidity,
        windSpeed: windSpeed,
        condition: condition,
      );

      if (!mounted) return;

      setState(() {
        _temp = temp;
        _feelsLike = feelsLike;
        _humidity = humidity;
        _pressure = pressure;
        _windSpeed = windSpeed;
        _condition = condition;
        _description = description;
        _alertMessage = alert;
        _updatedAt = _formatNow();
        _loading = false;
      });

      await _saveWeatherSnapshot();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveWeatherSnapshot() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'last_weather': {
          'village': _village,
          'temp': _temp,
          'feels_like': _feelsLike,
          'humidity': _humidity,
          'pressure': _pressure,
          'wind_speed': _windSpeed,
          'condition': _condition,
          'description': _description,
          'alert': _alertMessage,
          'updated_at': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  String _buildAlertMessage({
    required double temp,
    required int humidity,
    required double windSpeed,
    required String condition,
  }) {
    final c = condition.toLowerCase();

    if (c.contains('thunderstorm')) {
      return 'वादळी वातावरण आहे. शेतातील कामे काळजीपूर्वक करा.';
    }

    if (c.contains('rain') || c.contains('drizzle')) {
      return 'पावसाची शक्यता आहे. फवारणी पुढे ढकला आणि निचरा तपासा.';
    }

    if (temp >= 35) {
      return 'उच्च तापमान आहे. पिकांना पाणी व्यवस्थापनावर लक्ष द्या.';
    }

    if (humidity >= 85) {
      return 'आर्द्रता जास्त आहे. बुरशीजन्य रोगांवर लक्ष ठेवा.';
    }

    if (windSpeed >= 10) {
      return 'वारा जास्त आहे. फवारणी टाळा किंवा काळजीपूर्वक करा.';
    }

    return 'हवामान सध्या स्थिर आहे. नियमित शेती कामे सुरू ठेवू शकता.';
  }

  String _formatNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
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

  Future<void> _handleVoice(String query) async {
    final q = query.toLowerCase();

    String response = 'आज $_village मध्ये तापमान ${_temp.toStringAsFixed(0)} अंश आहे.';

    if (q.contains('तापमान') || q.contains('temperature')) {
      response = 'आज $_village मध्ये तापमान ${_temp.toStringAsFixed(0)} अंश सेल्सिअस आहे.';
    } else if (q.contains('आर्द्रता') || q.contains('humidity')) {
      response = 'सध्याची आर्द्रता $_humidity टक्के आहे.';
    } else if (q.contains('वारा') || q.contains('wind')) {
      response = 'वाऱ्याचा वेग ${_windSpeed.toStringAsFixed(1)} मीटर प्रति सेकंद आहे.';
    } else if (q.contains('अलर्ट') || q.contains('alert')) {
      response = _alertMessage;
    } else if (q.contains('हवामान') || q.contains('weather')) {
      response =
          '$_village मध्ये $_description आहे. तापमान ${_temp.toStringAsFixed(0)} अंश आणि आर्द्रता $_humidity टक्के आहे.';
    }

    await _tts.speak(response);
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _userName.trim().isEmpty
        ? 'शेतकरी'
        : _userName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'हवामान माहिती',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _teal,
        onRefresh: _loadUserAndWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _loading
              ? const SizedBox(
                  height: 500,
                  child: Center(
                    child: CircularProgressIndicator(color: _teal),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00796B), Color(0xFF26A69A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'नमस्कार, $firstName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_village चे आजचे हवामान',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                _weatherEmoji(),
                                style: const TextStyle(fontSize: 34),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_temp.toStringAsFixed(0)}°C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    _description.isEmpty ? _condition : _description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'शेवटचे अपडेट: $_updatedAt',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    VoiceMicBar(
                      tts: _tts,
                      hintText: 'बोला: "आजचे हवामान", "आर्द्रता", "अलर्ट"',
                      onResult: _handleVoice,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _alertMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            title: 'अनुभव तापमान',
                            value: '${_feelsLike.toStringAsFixed(0)}°C',
                            icon: Icons.thermostat_rounded,
                            color: const Color(0xFFE3F2FD),
                            iconColor: const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(
                            title: 'आर्द्रता',
                            value: '$_humidity%',
                            icon: Icons.water_drop_outlined,
                            color: const Color(0xFFE0F7FA),
                            iconColor: const Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            title: 'वाऱ्याचा वेग',
                            value: '${_windSpeed.toStringAsFixed(1)} m/s',
                            icon: Icons.air_rounded,
                            color: const Color(0xFFF3E5F5),
                            iconColor: const Color(0xFF7B1FA2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(
                            title: 'दाब',
                            value: '$_pressure hPa',
                            icon: Icons.speed_rounded,
                            color: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'शेतीसाठी सूचना',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '• तापमान जास्त असल्यास सकाळी किंवा संध्याकाळी सिंचन करा.\n'
                            '• आर्द्रता जास्त असल्यास बुरशीजन्य रोगांवर लक्ष ठेवा.\n'
                            '• वारा जास्त असल्यास फवारणी पुढे ढकला.\n'
                            '• पावसाची शक्यता असल्यास निचरा आणि साठवण तपासा.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.7,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}