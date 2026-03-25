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
  final stt.SpeechToText _speech = stt.SpeechToText();
  final PollyTts _flutterTts = PollyTts();

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
