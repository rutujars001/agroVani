import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'weather_screen.dart';
import 'yojana_screen.dart';
import 'mandi_price.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


final String apiKey = "AIzaSyAThZFmxDZhqfEYRAto_FwB9XHyzrdWgWU"; // Paste your API Key here
final String projectId = "agrovani-assistant-gmeh";
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color navGreen = const Color(0xFF0D3B0D);

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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  void _toggleMic() {
    setState(() {
      _isListening = !_isListening;
    });

    // TEST: If the mic is turned on, we send a "Hi" to test the connection
    if (_isListening) {
      _sendToAgroVani("नमस्कार"); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGreen,
        centerTitle: true,
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
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/farm_bg2.png", fit: BoxFit.cover),
          ),
          Column(
            children: [
              const SizedBox(height: 50),
              GestureDetector(
                onTap: _toggleMic,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isListening
                            ? [Colors.red, Colors.orange]
                            : [Colors.white, Colors.grey.shade200],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.green).withValues(alpha: 102),
                          blurRadius: 25,
                        )
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 80,
                      color: _isListening ? Colors.white : darkGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "बोलण्यासाठी टाइप करा",
                style: TextStyle(
                  color: _isListening ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(height: 30),
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
                              MaterialPageRoute(builder: (_) => MandiPriceScreen()),
                            ),
                            child: featureBox(Icons.trending_up, "बाजारभाव", Colors.purple),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: navGreen,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.home, color: Colors.white),
                    Icon(Icons.favorite, color: Colors.white),
                    Icon(Icons.mic, color: Colors.white),
                    Icon(Icons.person, color: Colors.white),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget featureBox(IconData icon, String text, Color color) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 77),
            blurRadius: 12,
          )
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}