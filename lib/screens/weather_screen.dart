import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String city = "सोलापूर"; // Marathi default
  double temp = 0;
  int humidity = 0;
  double windSpeed = 0;
  int rain = 0;

  bool isLoading = true;

  final String apiKey = "876cbe717c2374c47d28c0274fdd8518";

  @override
  void initState() {
    super.initState();
    fetchWeather(city);
  }

  // Marathi → English mapping for API
  String convertToEnglish(String input) {
    input = input.toLowerCase();
    if (input.contains("सोलापूर")) return "Solapur";
    if (input.contains("पुणे")) return "Pune";
    if (input.contains("मुंबई")) return "Mumbai";
    if (input.contains("नाशिक")) return "Nashik";
    if (input.contains("नागपूर")) return "Nagpur";
    return input;
  }

  Future<void> fetchWeather(String cityName) async {
    setState(() => isLoading = true);
    try {
      String finalCity = convertToEnglish(cityName);
      final url =
          "https://api.openweathermap.org/data/2.5/weather?q=$finalCity&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          city = cityName; // Keep in Marathi
          temp = data['main']['temp'];
          humidity = data['main']['humidity'];
          windSpeed = data['wind']['speed'];
          rain = data['clouds']['all'];
          isLoading = false;
        });
      } else {
        throw Exception("Error");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("डेटा मिळाला नाही")),
      );
    }
  }

  Map<String, dynamic> getFarmerAdvice() {
    if (temp > 35) {
      return {"text": "आज खूप गरम आहे फवारणी करा आणि सावलीत काम करा", "icon": "🌞"};
    } else if (temp < 20) {
      return {"text": "थंडी आहे ❄️ पिकांना झाकण द्या आणि रात्री काळजी घ्या", "icon": "❄️"};
    } else if (humidity > 80) {
      return {"text": "आर्द्रता जास्त आहे 💧 हवा खेळती ठेवा, बुरशी टाळा", "icon": "💧"};
    } else if (rain > 70) {
      return {"text": "आज पाऊस आहे ☔ फवारणी करू नका, कापणी टाळा", "icon": "☔"};
    } else if (windSpeed > 15) {
      return {"text": "जोरदार वारा आहे 💨 झाडे बांधा, हलके पिकांची काळजी घ्या", "icon": "💨"};
    } else {
      return {"text": "आज हवामान चांगले आहे 🌱 फवारणी करा आणि काम सुरू ठेवा", "icon": "🌱"};
    }
  }

  @override
  Widget build(BuildContext context) {
    final advice = getFarmerAdvice();
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/farm_bg3.png",
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Top Bar
              Container(
                height: 70,
                padding: const EdgeInsets.only(top: 25),
                color: const Color(0xFF2F80ED),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "हवामान",
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Microphone removed
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    const SizedBox(height: 30),
                    // City Name (Top Left)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          city,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Temperature (Smaller, Top Left)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal:10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${temp.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Farmer Advice Card (Centered)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 4),
                                    blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  advice["icon"],
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    advice["text"],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Weather Cards at Bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 130),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          weatherBox(Icons.opacity, "आर्द्रता", "$humidity%"),
                          weatherBox(Icons.water_drop, "पाऊस", "$rain%"),
                          weatherBox(Icons.air, "वारा", "${windSpeed.toStringAsFixed(1)} मी/से"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Nav
              Container(
                height: 75,
                color: const Color(0xFF0B3D02),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NavItem(Icons.home, "मुख्यपृष्ठ"),
                    NavItem(Icons.chat, "सल्ला"),
                    NavItem(Icons.mic, "व्हॉइस"),
                    NavItem(Icons.favorite, "पसंती"),
                    NavItem(Icons.person, "प्रोफाइल"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget weatherBox(IconData icon, String title, String value) {
    return Container(
      width: 115,
      height: 130,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}