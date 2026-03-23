import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MandiPriceScreen extends StatefulWidget {
  @override
  State<MandiPriceScreen> createState() => _MandiPriceScreenState();
}

class _MandiPriceScreenState extends State<MandiPriceScreen> {
  final FlutterTts _tts = FlutterTts();

  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("hi-IN");
  }

  void speak() async {
    await _tts.speak("आजचा बाजार भाव ५००० रुपये आहे");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("बाजारभाव"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Card(
          elevation: 10,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("कांदा", style: TextStyle(fontSize: 24)),
                SizedBox(height: 10),
                Text("₹5000", style: TextStyle(fontSize: 32)),
                SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () => speak(), // ✅ FIXED
                  icon: Icon(Icons.volume_up),
                  label: Text("ऐका"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}