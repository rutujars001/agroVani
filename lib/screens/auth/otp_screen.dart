import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_navigation.dart';
import 'register_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String name;
  final String email;
  final String password;
  final String village;
  final String district;
  final String state;
  final String area;
  final String soilType;
  final List<String> crops;
  final String gender;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.email,
    required this.password,
    required this.village,
    required this.district,
    required this.state,
    required this.area,
    required this.soilType,
    required this.crops,
    this.gender = 'पुरुष',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading  = false;
  bool _otpSent  = false;
  String _verificationId = '';
  String _error  = '';

  static const _teal  = Color(0xFF00897B);
  static const _light = Color(0xFFE0F2F1);

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _error = ''; _otpSent = false; });
    final phone = '+91${widget.phone}';
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
        } catch (_) {}
        _goHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _loading = false;
          _error = 'OTP पाठवणे अयशस्वी: ${e.message ?? e.code}\nमोबाइल नंबर तपासा आणि पुन्हा प्रयत्न करा.';
        });
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
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpCtrl.text.trim(),
      );
      try {
        await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'provider-already-linked') rethrow;
      }
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = 'OTP चुकीचा आहे. पुन्हा प्रयत्न करा. (${e.code})';
      });
    }
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    try {
      // Create Firebase Auth account after OTP verified
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      // Save profile to Firestore
      await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
        'name': widget.name, 'email': widget.email,
        'phone': widget.phone, 'village': widget.village,
        'district': widget.district, 'state': widget.state,
        'area_acres': widget.area, 'soil_type': widget.soilType,
        'crops': widget.crops, 'gender': widget.gender,
        'created_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      // If account already exists just sign in
      if (e.code == 'email-already-in-use') {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: widget.email, password: widget.password);
      }
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MainNavigation()), (_) => false);
  }

  void _goBackToRegister() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => RegisterScreen(
        prefillPhone: widget.phone,
        prefillName: widget.name,
        prefillEmail: widget.email,
        prefillVillage: widget.village,
        prefillDistrict: widget.district,
        prefillState: widget.state,
        prefillArea: widget.area,
        prefillSoil: widget.soilType,
        prefillCrops: widget.crops,
        focusPhone: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('मोबाइल तपासा',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: _light, shape: BoxShape.circle),
              child: const Center(child: Text('📱', style: TextStyle(fontSize: 34))),
            ),
            const SizedBox(height: 24),
            const Text('OTP तपासा',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('+91 ${widget.phone} वर OTP पाठवला आहे.',
                style: const TextStyle(fontSize: 14, color: Colors.black45)),
            const SizedBox(height: 36),

            if (_loading && !_otpSent)
              const Center(child: CircularProgressIndicator(color: _teal))
            else ...[
              const Text('6 अंकी OTP',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 10),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 14),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _light,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _teal, width: 2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                TextButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: const Text('OTP पुन्हा पाठवा', style: TextStyle(color: _teal)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _goBackToRegister,
                  child: const Text('नंबर बदला', style: TextStyle(color: Colors.black45)),
                ),
              ]),
            ],

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error,
                        style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _goBackToRegister,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('मोबाइल नंबर बदला',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ]),
              ),
            ],

            const Spacer(),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: (_loading || !_otpSent) ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('OTP तपासा',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}


