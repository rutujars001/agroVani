import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(flex: 2),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4)],
              ),
              child: const Center(child: Text('🌾', style: TextStyle(fontSize: 60))),
            ),
            const SizedBox(height: 32),
            const Text('AgroVani',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: _teal)),
            const SizedBox(height: 10),
            const Text('शेतकऱ्यांचा डिजिटल सहाय्यक',
                style: TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500)),
            const Spacer(flex: 2),
            _featureRow('🎤', 'मराठीत बोला, उत्तर मिळवा'),
            const SizedBox(height: 16),
            _featureRow('🌱', 'पिकानुसार सल्ला व माहिती'),
            const SizedBox(height: 16),
            _featureRow('📊', 'लाइव्ह बाजारभाव व हवामान'),
            const SizedBox(height: 16),
            _featureRow('🩺', 'कृषी डॉक्टर — रोग निदान'),
            const Spacer(flex: 2),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('सुरुवात करा', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Row(children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 14),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
    ]);
  }
}
