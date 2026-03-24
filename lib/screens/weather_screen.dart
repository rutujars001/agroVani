import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {

  String city = "सोलापूर";
  double temp = 0;
  int humidity = 0;
  double windSpeed = 0;
  int rain = 0;

  bool isLoading = true;

  final String apiKey = "876cbe717c2374c47d28c0274fdd8518";

  /// 🎤 Speech
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String spokenText = "";

  /// 🎤 Animation
  late AnimationController _micController;
  late Animation<double> _micAnimation;

  final Color creamColor = const Color(0xFFF3F1E7);

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();

    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );

    fetchWeather(city);
  }

  @override
  void dispose() {
    _micController.dispose();
    super.dispose();
  }

  /// 🔤 Marathi → English
  String convertToEnglish(String input) {
    if (input.contains("सोलापूर")) return "Solapur";
    if (input.contains("पुणे")) return "Pune";
    if (input.contains("मुंबई")) return "Mumbai";
    return input;
  }

  /// 🌐 API
  Future<void> fetchWeather(String cityName) async {
    final cleanText =
    cityName.replaceAll("हवामान", "").trim();

    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=${convertToEnglish(cleanText)}&appid=$apiKey&units=metric";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    setState(() {
      city = cleanText;
      temp = data['main']['temp'];
      humidity = data['main']['humidity'];
      windSpeed = data['wind']['speed'];
      rain = data['clouds']['all'];
      isLoading = false;
    });
  }

  /// 🎤 MIC FUNCTION
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);

        _micController.repeat(reverse: true);

        _speech.listen(
          localeId: "mr_IN",
          onResult: (result) {
            setState(() {
              spokenText = result.recognizedWords;
            });

            fetchWeather(spokenText);
          },
        );
      }
    } else {
      setState(() => _isListening = false);

      _micController.stop();
      _micController.reset();

      _speech.stop();
    }
  }

  /// 🌱 Farmer Advice (Improved Full Sentences)
  Map<String, dynamic> getAdvice() {
    if (temp > 35) {
      return {
        "text": "आज खूप उष्ण हवामान आहे. शेतात काम करताना सावलीत विश्रांती घ्या आणि पिकांना पुरेसे पाणी द्या.",
        "color": Colors.orange
      };
    } else if (temp < 20) {
      return {
        "text": "आज थंडीचे वातावरण आहे. पिकांचे संरक्षण करा आणि सकाळी लवकर पाणी देणे टाळा.",
        "color": Colors.blue
      };
    } else if (humidity > 80) {
      return {
        "text": "आर्द्रता खूप जास्त आहे. बुरशीजन्य रोग टाळण्यासाठी योग्य फवारणी करा.",
        "color": Colors.cyan
      };
    } else if (rain > 70) {
      return {
        "text": "पावसाची शक्यता जास्त आहे. आज फवारणी करणे टाळा आणि पाण्याचा निचरा योग्य ठेवा.",
        "color": Colors.indigo
      };
    } else if (windSpeed > 10) {
      return {
        "text": "वाऱ्याचा वेग जास्त आहे. फवारणी टाळा आणि पिकांचे संरक्षण करा.",
        "color": Colors.teal
      };
    } else {
      return {
        "text": "आज हवामान चांगले आहे. शेतातील सर्व कामे नियमितपणे करू शकता.",
        "color": Colors.green
      };
    }
  }

  Widget adviceCard() {
    final advice = getAdvice();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: advice["color"].withOpacity(0.4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.eco, color: advice["color"]),
          const SizedBox(width: 10),
          Expanded(child: Text(advice["text"])),
        ],
      ),
    );
  }

  Widget weatherBox(
      IconData icon, String title, String value, Color color) {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(title),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamColor,

      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("हवामान"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),

            Text(city,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Icon(Icons.wb_sunny,
                size: 90, color: Colors.orange),

            Text("${temp.toStringAsFixed(1)}°C",
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold)),

            const SizedBox(height: 25),

            /// 🎤 MIC BUTTON (FINAL)
            ScaleTransition(
              scale: _micAnimation,
              child: GestureDetector(
                onTap: _listen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Colors.green
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: _isListening
                            ? Colors.green.withOpacity(0.6)
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: _isListening ? 25 : 10,
                        spreadRadius: _isListening ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 40,
                    color: _isListening
                        ? Colors.white
                        : Colors.green,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _isListening
                  ? "ऐकत आहे..."
                  : "बोलण्यासाठी टॅप करा",
              style: TextStyle(
                fontSize: 16,
                color: _isListening
                    ? Colors.green
                    : Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            adviceCard(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: [
                weatherBox(Icons.opacity, "आर्द्रता",
                    "$humidity%", Colors.blue),
                weatherBox(Icons.water_drop, "पाऊस",
                    "$rain%", Colors.indigo),
                weatherBox(Icons.air, "वारा",
                    "${windSpeed.toStringAsFixed(1)} m/s",
                    Colors.green),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}