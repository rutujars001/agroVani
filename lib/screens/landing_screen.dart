import 'package:flutter/material.dart';
import 'auth/phone_auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 4)],
                ),
                child: const Center(child: Text('🌾', style: TextStyle(fontSize: 54))),
              ),
              const SizedBox(height: 28),
              const Text('AgroVani',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _teal)),
              const SizedBox(height: 8),
              const Text('शेतकऱ्यांचा डिजिटल सहाय्यक',
                  style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
              const SizedBox(height: 48),
              // Features
              _featureRow('🎤', 'मराठीत बोला, उत्तर मिळवा'),
              const SizedBox(height: 16),
              _featureRow('🌱', 'पिकानुसार सल्ला व माहिती'),
              const SizedBox(height: 16),
              _featureRow('📊', 'लाइव्ह बाजारभाव व हवामान'),
              const SizedBox(height: 16),
              _featureRow('🩺', 'कृषी डॉक्टर — रोग निदान'),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PhoneAuthScreen(isLogin: false))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('नोंदणी करा', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PhoneAuthScreen(isLogin: true))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _teal,
                    side: const BorderSide(color: _teal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('लॉगिन करा', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Row(children: [
      Container(
        width: 44, height: 44,
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
