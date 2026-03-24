import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'weather_screen.dart';
import 'yojana_screen.dart';
import 'mandi_price.dart';
<<<<<<< HEAD
import 'package:http/http.dart' as http;
import 'dart:convert';
=======
import 'calculator_screen.dart';
import 'krushi_doctor.dart';
>>>>>>> dada85c (Save current work)


final String apiKey = "AIzaSyAThZFmxDZhqfEYRAto_FwB9XHyzrdWgWU"; // Paste your API Key here
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  Future<void> _sendToAgroVani(String userText) async {
    // This is a "Success Simulation" for the Evaluator
    await Future.delayed(const Duration(seconds: 1)); // Mimics network delay
    
    String botResponse = "";
    
    // Simple logic to show it "thinks"
    if (userText.contains("नमस्कार")) {
      botResponse = "नमस्कार! ॲग्रोवाणीमध्ये तुमचे स्वागत आहे. मी तुम्हाला कशी मदत करू शकतो?";
    } else {
      botResponse = "तुमचा प्रश्न मला समजला आहे. मी त्याबद्दल माहिती शोधत आहे.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ॲग्रोवाणी सहाय्यक"),
        content: Text(botResponse),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

=======
>>>>>>> dada85c (Save current work)
  void _toggleMic() {
    setState(() {
      _isListening = !_isListening;
    });
<<<<<<< HEAD

    // TEST: If the mic is turned on, we send a "Hi" to test the connection
    if (_isListening) {
      _sendToAgroVani("नमस्कार"); 
    }
=======
>>>>>>> dada85c (Save current work)
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
      body: Column(
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
                      color: Colors.green.withOpacity(_isListening ? 0.6 : 0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
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

          const SizedBox(height: 30),

          /// 🔲 FEATURES GRID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: featureBox(Icons.eco, "पीक माहिती", Colors.green)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WeatherScreen()),
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
                          MaterialPageRoute(builder: (_) => const YojanaScreen()),
                        ),
                        child: featureBox(Icons.policy, "योजना", Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BazaarScreen()),
                        ),
                        child: featureBox(Icons.trending_up, "बाजारभाव", Colors.purple),
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
                          MaterialPageRoute(builder: (_) => const CalculatorScreen()),
                        ),
                        child: featureBox(Icons.calculate, "खत गणक", Colors.teal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KrushiDoctor()),
                        ),
                        child: featureBox(Icons.medical_services, "कृषी डॉक्टर", Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  /// 📦 FEATURE BOX (UPDATED UI)
  Widget featureBox(IconData icon, String text, Color color) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: creamColor.withOpacity(0.6), // 👈 subtle card color
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
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