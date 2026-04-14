import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main_navigation.dart';
import 'register_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isLogin;
  const PhoneAuthScreen({super.key, required this.isLogin});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  bool _otpSent    = false;
  bool _loading    = false;
  String _verificationId = '';
  String _error    = '';
  ConfirmationResult? _confirmationResult;

  static const _teal  = Color(0xFF00897B);
  static const _light = Color(0xFFE0F2F1);

  // Test credentials for web
  static const _testPhone = '9999999999';
  static const _testOtp   = '123456';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().length != 10) {
      setState(() => _error = 'कृपया 10 अंकी मोबाइल नंबर टाका.');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    // Web: use test credentials bypass
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() { _otpSent = true; _loading = false; });
      return;
    }

    // Android: real OTP
    final phone = '+91${_phoneCtrl.text.trim()}';
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _handleSignedIn(FirebaseAuth.instance.currentUser!);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { _loading = false; _error = 'OTP पाठवणे अयशस्वी.'; });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() { _verificationId = verificationId; _otpSent = true; _loading = false; });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'कृपया 6 अंकी OTP टाका.');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    // Web: validate test OTP and sign in anonymously
    if (kIsWeb) {
      if (_phoneCtrl.text.trim() == _testPhone && _otpCtrl.text.trim() == _testOtp) {
        try {
          // Store phone in Firestore with a fake UID based on phone
          final fakeUid = 'web_test_${_phoneCtrl.text.trim()}';
          final doc = await FirebaseFirestore.instance.collection('users').doc(fakeUid).get();
          if (!mounted) return;
          if (!doc.exists) {
            // Create a mock user object
            final result = await FirebaseAuth.instance.signInAnonymously();
            await _handleSignedIn(result.user!);
          } else {
            final result = await FirebaseAuth.instance.signInAnonymously();
            await _handleSignedIn(result.user!);
          }
        } catch (e) {
          setState(() { _loading = false; _error = 'लॉगिन अयशस्वी: $e'; });
        }
      } else {
        setState(() { _loading = false; _error = 'OTP चुकीचा आहे. वेब टेस्ट: 9999999999 / 123456'; });
      }
      return;
    }

    // Android: real OTP verify
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpCtrl.text.trim(),
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      await _handleSignedIn(result.user!);
    } on FirebaseAuthException {
      setState(() { _loading = false; _error = 'OTP चुकीचा आहे.'; });
    }
  }

  Future<void> _handleSignedIn(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (!doc.exists) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainNavigation()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Text(
              widget.isLogin ? 'लॉगिन करा' : 'नोंदणी करा',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? '+91 ${_phoneCtrl.text} वर OTP पाठवला आहे.'
                  : 'तुमचा मोबाइल नंबर टाका',
              style: const TextStyle(fontSize: 14, color: Colors.black45),
            ),

            // Web test hint
            if (kIsWeb) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  '🧪 वेब टेस्ट: नंबर 9999999999, OTP 123456',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],

            const SizedBox(height: 28),

            if (!_otpSent) ...[
              const Text('मोबाइल नंबर',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.black12)),
                    ),
                    child: const Text('+91',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: '10 अंकी नंबर',
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ]),
              ),
            ] else ...[
              const Text('OTP',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 12),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _light,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _teal),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _teal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : _sendOtp,
                child: const Text('OTP पुन्हा पाठवा', style: TextStyle(color: _teal)),
              ),
            ],

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_otpSent ? 'OTP तपासा' : 'OTP पाठवा',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            if (_otpSent)
              Center(
                child: TextButton(
                  onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); _error = ''; }),
                  child: const Text('नंबर बदला', style: TextStyle(color: _teal)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}


