import 'dart:convert';
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
  final PollyTts _tts = PollyTts();
  static const _apiKey = '876cbe717c2374c47d28c0274fdd8518';
  static const _cream = Color(0xFFF3F1E7);
  static const _green = Color(0xFF1B5E20);

  String _city = 'सोलापूर';
  double _temp = 0;
  int _humidity = 0;
  double _windSpeed = 0;
  int _cloudPct = 0;
  String _condition = '';
  bool _isNight = false;
  bool _loading = true;
  List<Map<String, dynamic>> _forecast = [];

  @override
  void initState() {
    super.initState();
    _fetchWeather('Solapur');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String _toEnglish(String input) {
    const map = {
      'सोलापूर': 'Solapur', 'पुणे': 'Pune', 'मुंबई': 'Mumbai',
      'नागपूर': 'Nagpur',   'औरंगाबाद': 'Aurangabad',
    };
    for (final e in map.entries) {
      if (input.contains(e.key)) return e.value;
    }
    return input.replaceAll('हवामान', '').trim();
  }

  Future<void> _fetchWeather(String city) async {
    setState(() => _loading = true);
    final eng = _toEnglish(city);
    if (eng.isEmpty) { setState(() => _loading = false); return; }
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$eng&appid=$_apiKey&units=metric'));
      final fRes = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$eng&appid=$_apiKey&units=metric'));
      if (!mounted) return;
      final d = json.decode(res.body);
      final fd = json.decode(fRes.body);
      if (d['cod'] != 200) { setState(() => _loading = false); return; }

      final sunrise = d['sys']['sunrise'] as int;
      final sunset  = d['sys']['sunset']  as int;
      final now     = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      setState(() {
        _city      = city.replaceAll('हवामान', '').trim();
        _temp      = (d['main']['temp'] as num).toDouble();
        _humidity  = d['main']['humidity'] as int;
        _windSpeed = (d['wind']['speed'] as num).toDouble();
        _cloudPct  = d['clouds']['all'] as int;
        _condition = (d['weather'] as List).first['main'].toString();
        _isNight   = now < sunrise || now > sunset;
        _forecast  = _parseForecast(fd);
        _loading   = false;
      });
      _speakSummary();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _parseForecast(dynamic fd) {
    final list = fd['list'] as List<dynamic>? ?? [];
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (final item in list) {
      final dt = DateTime.tryParse(item['dt_txt'] ?? '');
      if (dt == null || !dt.isAfter(now)) continue;
      final days = dt.difference(now).inDays;
      if ((days == 1 || days == 2 || days == 3) && dt.hour >= 11 && dt.hour <= 14 && result.length < 3) {
        final cond = (item['weather'] as List).first['main'].toString();
        result.add({
          'day': days == 1 ? 'उद्या' : 'दिवस $days',
          'tempMax': (item['main']['temp_max'] as num).toDouble(),
          'tempMin': (item['main']['temp_min'] as num).toDouble(),
          'condition': cond,
        });
      }
      if (result.length == 3) break;
    }
    return result;
  }

  Future<void> _speakSummary() async {
    final text = '$_city मध्ये तापमान ${_temp.toStringAsFixed(1)} डिग्री, आर्द्रता $_humidity टक्के, वाऱ्याचा वेग ${_windSpeed.toStringAsFixed(1)} मीटर प्रति सेकंद.';
    await _tts.speak(text);
  }

  // ── Dynamic weather icon ──────────────────────────────────────────────
  Widget _weatherIcon({double size = 120}) {
    final c = _condition.toLowerCase();
    if (_isNight && c.contains('clear')) {
      return Text('🌙', style: TextStyle(fontSize: size));
    }
    if (_isNight && c.contains('cloud')) {
      return Text('🌛', style: TextStyle(fontSize: size));
    }
    if (c.contains('thunder')) return Text('⛈️', style: TextStyle(fontSize: size));
    if (c.contains('rain') || c.contains('drizzle')) return Text('🌧️', style: TextStyle(fontSize: size));
    if (c.contains('snow')) return Text('❄️', style: TextStyle(fontSize: size));
    if (c.contains('mist') || c.contains('fog') || c.contains('haze')) return Text('🌫️', style: TextStyle(fontSize: size));
    if (c.contains('cloud')) return Text('⛅', style: TextStyle(fontSize: size));
    if (_temp >= 34) return Text('☀️', style: TextStyle(fontSize: size));
    return Text('🌤️', style: TextStyle(fontSize: size));
  }

  Widget _forecastIcon(String condition, {double size = 28}) {
    final c = condition.toLowerCase();
    if (c.contains('thunder')) return Text('⛈️', style: TextStyle(fontSize: size));
    if (c.contains('rain') || c.contains('drizzle')) return Text('🌧️', style: TextStyle(fontSize: size));
    if (c.contains('snow')) return Text('❄️', style: TextStyle(fontSize: size));
    if (c.contains('cloud')) return Text('⛅', style: TextStyle(fontSize: size));
    return Text('☀️', style: TextStyle(fontSize: size));
  }

  Map<String, dynamic> _advice() {
    if (_temp > 35) return {'text': 'आज खूप उष्ण आहे. पिकांना पुरेसे पाणी द्या.', 'color': Colors.orange};
    if (_temp < 20) return {'text': 'थंडीचे वातावरण. पिकांचे संरक्षण करा.', 'color': Colors.blue};
    if (_humidity > 80) return {'text': 'आर्द्रता जास्त. बुरशीजन्य रोगांसाठी फवारणी करा.', 'color': Colors.cyan.shade700};
    if (_cloudPct > 70) return {'text': 'पावसाची शक्यता. फवारणी टाळा.', 'color': Colors.indigo};
    if (_windSpeed > 10) return {'text': 'वाऱ्याचा वेग जास्त. फवारणी टाळा.', 'color': Colors.teal};
    return {'text': 'हवामान चांगले आहे. सर्व कामे करू शकता.', 'color': _green};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(children: [
                      // ── Dynamic weather display ──────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isNight
                                ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                                : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 5))],
                        ),
                        child: Column(children: [
                          Text(_city, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          _weatherIcon(size: 90),
                          const SizedBox(height: 8),
                          Text('${_temp.toStringAsFixed(1)}°C',
                              style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800)),
                          Text(_condition, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      // ── Stats row ────────────────────────────────────
                      Row(children: [
                        Expanded(child: _statCard('💧', 'आर्द्रता', '$_humidity%', Colors.blue.shade700)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('🌧️', 'ढग', '$_cloudPct%', Colors.indigo.shade700)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('💨', 'वारा', '${_windSpeed.toStringAsFixed(1)} m/s', Colors.teal.shade700)),
                      ]),
                      const SizedBox(height: 16),
                      // ── Advice ───────────────────────────────────────
                      Builder(builder: (_) {
                        final adv = _advice();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: (adv['color'] as Color).withValues(alpha: 0.3)),
                            boxShadow: [BoxShadow(color: (adv['color'] as Color).withValues(alpha: 0.15), blurRadius: 8)],
                          ),
                          child: Row(children: [
                            const Text('🌱', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(adv['text'] as String,
                                style: TextStyle(color: adv['color'] as Color, fontWeight: FontWeight.w600))),
                          ]),
                        );
                      }),
                      const SizedBox(height: 16),
                      // ── 3-day forecast ───────────────────────────────
                      if (_forecast.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('३ दिवसांचा अंदाज',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 10),
                        Row(children: _forecast.map((f) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade100),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                            ),
                            child: Column(children: [
                              Text(f['day'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 8),
                              _forecastIcon(f['condition'] as String),
                              const SizedBox(height: 8),
                              Text('${(f['tempMax'] as num).toStringAsFixed(0)}°/${(f['tempMin'] as num).toStringAsFixed(0)}°',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(f['condition'] as String,
                                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
                            ]),
                          ),
                        )).toList()),
                      ],
                      const SizedBox(height: 16),
                      // ── Voice mic ────────────────────────────────────
                      VoiceMicBar(
                        tts: _tts,
                        hintText: 'बोला: "पुणे हवामान" किंवा "मुंबई"',
                        onResult: (spoken) => _fetchWeather(spoken),
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8)],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
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
            Text('हवामान', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('सोलापूर व इतर शहरे', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const Text('🌤️', style: TextStyle(fontSize: 32)),
      ]),
    );
  }
}
