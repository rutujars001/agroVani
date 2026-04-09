import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';
import 'splash_screen.dart';
import 'weather_screen.dart';
import 'yojana_screen.dart';
import 'mandi_price.dart';
import 'calculator_screen.dart';
import 'krushi_doctor.dart';
import 'crops_screen.dart';

final String apiKey =
    "AIzaSyAThZFmxDZhqfEYRAto_FwB9XHyzrdWgWU"; // Paste your API Key here
final String projectId = "agrovani-assistant-gmeh";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color creamColor = const Color(0xFFF3F1E7);

  bool _isListening = false;
  bool _speechReady = false;
  String _recognizedText = "शेतकऱ्याचा आवाज येथे दिसेल...";
  String _dialogflowResponse = "डायलॉगफ्लो उत्तर येथे दिसेल...";
  String _suggestion = '';
  String _suggestedCrop = '';
  bool _loadingSuggestion = false;
  String _selectedSoil = 'black';
  List<Map<String, dynamic>> _news = [];
  bool _loadingNews = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final PollyTts _flutterTts = PollyTts();

  static const _soilOptions = [
    {'key': 'black',    'label': 'काळी माती'},
    {'key': 'red',      'label': 'लाल माती'},
    {'key': 'alluvial', 'label': 'गाळाची माती'},
    {'key': 'sandy',    'label': 'वालुकामय'},
    {'key': 'loamy',    'label': 'चिकणमाती'},
  ];

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initSpeech();
    _fetchSuggestion();
    _fetchNews();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    setState(() => _loadingNews = true);
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:5000/agri-news'));
      final payload = json.decode(res.body) as Map<String, dynamic>;
      final list = payload['news'] as List<dynamic>? ?? [];
      setState(() {
        _news = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingNews = false;
      });
    } catch (_) {
      setState(() => _loadingNews = false);
    }
  }

  Future<void> _fetchSuggestion() async {
    setState(() => _loadingSuggestion = true);
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'soil_type': _selectedSoil, 'city': 'Solapur'}),
      );
      final payload = json.decode(res.body) as Map<String, dynamic>;
      setState(() {
        _suggestion     = payload['message'] ?? '';
        _suggestedCrop  = payload['crop']    ?? '';
        _loadingSuggestion = false;
      });
    } catch (_) {
      setState(() => _loadingSuggestion = false);
    }
  }

  Future<void> _speakDialogflowResponse(String responseText) async {
    if (responseText.trim().isEmpty) return;
    await _flutterTts.speak(responseText);
  }

  Future<void> _fetchDialogflowReply(String userQuery) async {
    final cleanQuery = userQuery.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _dialogflowResponse = "उत्तर मिळवत आहे...";
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': cleanQuery}),
      );

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}");
      }

      final Map<String, dynamic> payload = json.decode(response.body);
      final reply = (payload['fulfillmentText'] ?? '').toString();
      if (!mounted) return;
      setState(() {
        _dialogflowResponse = reply.isEmpty
            ? "उत्तर मिळाले नाही. कृपया पुन्हा प्रयत्न करा."
            : reply;
      });

      await _speakDialogflowResponse(_dialogflowResponse);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dialogflowResponse =
            "सर्व्हरला कनेक्ट होता आले नाही. Flask server चालू आहे का तपासा.";
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady) {
      setState(() => _recognizedText = "स्पीच ओळख उपलब्ध नाही.");
      return;
    }

    // Stop TTS so it doesn't listen to its own voice
    await _flutterTts.stop();

    setState(() {
      _isListening = true;
      _recognizedText = "ऐकत आहे...";
    });

    await _speech.listen(
      localeId: 'mr_IN',
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognizedText = result.recognizedWords.isEmpty
              ? "ऐकत आहे..."
              : result.recognizedWords;
        });
        // Auto-send when speech recognition is finalized
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _fetchDialogflowReply(result.recognizedWords);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      _stopListening();
    } else {
      await _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamColor,

      /// 🔝 APP BAR
      appBar: AppBar(
        backgroundColor: darkGreen,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          },
        ),
        title: const Text(
          "नमस्कार शेतकरी मित्रा!",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),

      /// 📱 BODY
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// 🎤 MIC BUTTON
            GestureDetector(
              onTap: _toggleMic,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green
                            .withValues(alpha: _isListening ? 0.6 : 0.3),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 70,
                    color: _isListening ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _isListening ? "ऐकत आहे..." : "बोलण्यासाठी टॅप करा",
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.green : Colors.black87,
              ),
            ),

            const SizedBox(height: 14),

            VoiceMicBar(
              tts: _flutterTts,
              hintText: 'बोला: "ज्वारी भाव" किंवा "हवामान सांग"',
              onResult: _fetchDialogflowReply,
            ),

            const SizedBox(height: 10),

            if (_dialogflowResponse != "डायलॉगफ्लो उत्तर येथे दिसेल...")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dialogflowResponse,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "उत्तर ऐका",
                        onPressed: () =>
                            _speakDialogflowResponse(_dialogflowResponse),
                        icon: const Icon(Icons.volume_up, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // ── Smart Suggestion Card ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  const Row(children: [
                    Text('🌱', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text('स्मार्ट सूचना',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                  const SizedBox(height: 10),
                  // Soil selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _soilOptions.map((s) {
                        final sel = _selectedSoil == s['key'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedSoil = s['key']!);
                            _fetchSuggestion();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? Colors.white : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(s['label']!,
                                style: TextStyle(
                                    color: sel ? const Color(0xFF1B5E20) : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Suggestion content
                  _loadingSuggestion
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _suggestion.isEmpty
                          ? const Text('सूचना मिळवत आहे...',
                              style: TextStyle(color: Colors.white70))
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                _suggestion.replaceAll('**', ''),
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.6),
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                GestureDetector(
                                  onTap: () => _flutterTts.speak(_suggestion.replaceAll('**', '')),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.volume_up_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text('ऐका', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _fetchSuggestion,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text('अपडेट', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ),
                              ]),
                            ]),
                ]),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔲 FEATURES GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CropsScreen()),
                          ),
                          child:
                              featureBox(Icons.eco, "पीक माहिती", Colors.green),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WeatherScreen()),
                          ),
                          child: featureBox(Icons.cloud, "हवामान", Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const YojanaScreen()),
                          ),
                          child:
                              featureBox(Icons.policy, "योजना", Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BazaarScreen()),
                          ),
                          child: featureBox(
                              Icons.trending_up, "बाजारभाव", Colors.purple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CalculatorScreen()),
                          ),
                          child: featureBox(
                              Icons.calculate, "खत गणक", Colors.teal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const KrushiDoctor()),
                          ),
                          child: featureBox(Icons.medical_services,
                              "कृषी डॉक्टर", Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Latest Agri News ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Text('📰 ताजे कृषी बातम्या',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchNews,
                  child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF1B5E20)),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            _loadingNews
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _news.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('बातम्या मिळवत आहे...',
                            style: TextStyle(color: Colors.black45)),
                      )
                    : SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _news.length,
                          itemBuilder: (_, i) {
                            final item = _news[i];
                            return Container(
                              width: 260,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade100),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Source tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '✅ Source: ${item['source']}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B5E20)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Headline
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if ((item['date'] as String).isNotEmpty)
                                    Text(item['date'] as String,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.black38)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 📦 FEATURE BOX (UPDATED UI)
  Widget featureBox(IconData icon, String text, Color color) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: creamColor.withValues(alpha: 0.6), // 👈 subtle card color
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: color),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
