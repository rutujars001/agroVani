import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main_navigation.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String prefillPhone;
  final String prefillName;
  final String prefillEmail;
  final String prefillVillage;
  final String prefillDistrict;
  final String prefillState;
  final String prefillArea;
  final String prefillSoil;
  final List<String> prefillCrops;
  final bool focusPhone;

  const RegisterScreen({
    super.key,
    this.prefillPhone = '',
    this.prefillName = '',
    this.prefillEmail = '',
    this.prefillVillage = '',
    this.prefillDistrict = '',
    this.prefillState = 'महाराष्ट्र',
    this.prefillArea = '',
    this.prefillSoil = 'काळी माती',
    this.prefillCrops = const [],
    this.focusPhone = false,
  });
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _villageCtrl  = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _areaCtrl     = TextEditingController();

  final _phoneFocus = FocusNode();

  String _selectedSoil   = 'काळी माती';
  String _selectedState  = 'महाराष्ट्र';
  String _selectedGender = 'पुरुष';
  bool _obscure          = true;
  bool _loading          = false;
  String _error          = '';

  static const _teal  = Color(0xFF00897B);
  static const _light = Color(0xFFE0F2F1);

  final _soils  = ['काळी माती', 'लाल माती', 'गाळाची माती', 'वालुकामय', 'चिकणमाती'];
  final _states = ['महाराष्ट्र', 'कर्नाटक', 'मध्य प्रदेश', 'गुजरात', 'राजस्थान'];

  final _crops = [
    {'key': 'Cotton',      'label': 'कापूस',     'icon': '🌱'},
    {'key': 'Jowar',       'label': 'ज्वारी',    'icon': '🌾'},
    {'key': 'Wheat',       'label': 'गहू',        'icon': '🌿'},
    {'key': 'Onion',       'label': 'कांदा',      'icon': '🧅'},
    {'key': 'Soybean',     'label': 'सोयाबीन',   'icon': '🫛'},
    {'key': 'Tur',         'label': 'तूर',        'icon': '🫘'},
    {'key': 'Sugarcane',   'label': 'ऊस',         'icon': '🎋'},
    {'key': 'Tomato',      'label': 'टोमॅटो',    'icon': '🍅'},
    {'key': 'Gram',        'label': 'हरभरा',      'icon': '🫘'},
    {'key': 'Maize',       'label': 'मका',        'icon': '🌽'},
    {'key': 'Groundnut',   'label': 'शेंगदाणा',  'icon': '🥜'},
    {'key': 'Pomegranate', 'label': 'डाळिंब',    'icon': '🍎'},
  ];

  final Set<String> _selectedCrops = {};

  @override
  void initState() {
    super.initState();
    // Prefill data if coming back from OTP screen
    _nameCtrl.text     = widget.prefillName;
    _emailCtrl.text    = widget.prefillEmail;
    _phoneCtrl.text    = widget.prefillPhone;
    _villageCtrl.text  = widget.prefillVillage;
    _districtCtrl.text = widget.prefillDistrict;
    _areaCtrl.text     = widget.prefillArea;
    _selectedSoil      = widget.prefillSoil.isEmpty ? 'काळी माती' : widget.prefillSoil;
    _selectedState     = widget.prefillState.isEmpty ? 'महाराष्ट्र' : widget.prefillState;
    _selectedCrops.addAll(widget.prefillCrops);
    // Focus phone field if coming back to change number
    if (widget.focusPhone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phoneFocus.requestFocus();
        _phoneCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _phoneCtrl.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passwordCtrl.dispose(); _villageCtrl.dispose();
    _districtCtrl.dispose(); _areaCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'कृपया सर्व आवश्यक माहिती भरा.');
      return;
    }
    if (_phoneCtrl.text.trim().length != 10) {
      setState(() => _error = 'कृपया 10 अंकी मोबाइल नंबर टाका.');
      return;
    }
    if (_selectedCrops.isEmpty) {
      setState(() => _error = 'कृपया किमान एक पीक निवडा.');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    // On web skip OTP, create account directly
    if (kIsWeb) {
      try {
        final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(), 'village': _villageCtrl.text.trim(),
          'district': _districtCtrl.text.trim(), 'state': _selectedState,
          'area_acres': _areaCtrl.text.trim(), 'soil_type': _selectedSoil,
          'crops': _selectedCrops.toList(), 'gender': _selectedGender,
          'created_at': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const MainNavigation()), (_) => false);
      } on FirebaseAuthException catch (e) {
        setState(() {
          _loading = false;
          _error = e.code == 'email-already-in-use'
              ? 'हा ईमेल आधीच नोंदणीकृत आहे.'
              : e.code == 'weak-password'
                  ? 'पासवर्ड किमान 6 अक्षरांचा असावा.'
                  : 'नोंदणी अयशस्वी: ${e.message}';
        });
      }
      return;
    }

    // On Android: go to OTP first, create account after OTP verified
    setState(() => _loading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => OtpScreen(
        phone:    _phoneCtrl.text.trim(),
        name:     _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        village:  _villageCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        state:    _selectedState,
        area:     _areaCtrl.text.trim(),
        soilType: _selectedSoil,
        crops:    _selectedCrops.toList(),
        gender:   _selectedGender,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('नोंदणी करा',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Personal Info
          _sectionTitle('👤 वैयक्तिक माहिती'),
          const SizedBox(height: 12),
          _label('लिंग'),
          const SizedBox(height: 8),
          Row(children: ['पुरुष', 'महिला', 'इतर'].map((g) {
            final sel = _selectedGender == g;
            return GestureDetector(
              onTap: () => setState(() => _selectedGender = g),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _teal : _light,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(g, style: TextStyle(
                    color: sel ? Colors.white : _teal,
                    fontWeight: FontWeight.w600)),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),
          _label('पूर्ण नाव *'),
          const SizedBox(height: 6),
          _field(_nameCtrl, 'उदा. रामराव पाटील'),
          const SizedBox(height: 12),
          _label('ईमेल *'),
          const SizedBox(height: 6),
          _field(_emailCtrl, 'example@gmail.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _label('मोबाइल नंबर * (OTP साठी)'),
          const SizedBox(height: 6),
          _field(_phoneCtrl, '10 अंकी नंबर', keyboardType: TextInputType.phone, maxLength: 10, focusNode: _phoneFocus),
          const SizedBox(height: 12),
          _label('पासवर्ड *'),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'किमान 6 अक्षरे',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.black38),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Location Info
          _sectionTitle('📍 स्थान माहिती'),
          const SizedBox(height: 12),
          _label('गाव'),
          const SizedBox(height: 6),
          _field(_villageCtrl, 'उदा. पंढरपूर'),
          const SizedBox(height: 12),
          _label('जिल्हा'),
          const SizedBox(height: 6),
          _field(_districtCtrl, 'उदा. सोलापूर'),
          const SizedBox(height: 12),
          _label('राज्य'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _selectedState = v!),
          ),
          const SizedBox(height: 20),

          // Farm Info
          _sectionTitle('🌾 शेती माहिती'),
          const SizedBox(height: 12),
          _label('एकूण जमीन (एकर)'),
          const SizedBox(height: 6),
          _field(_areaCtrl, 'उदा. 5', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _label('माती प्रकार'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _soils.map((s) {
              final sel = _selectedSoil == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSoil = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _teal : _light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s, style: TextStyle(
                      color: sel ? Colors.white : _teal,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _label('तुमची पिके निवडा *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _crops.map((c) {
              final sel = _selectedCrops.contains(c['key']);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel) _selectedCrops.remove(c['key']);
                  else _selectedCrops.add(c['key']!);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _teal : _light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(c['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(c['label']!, style: TextStyle(
                        color: sel ? Colors.white : _teal,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              );
            }).toList(),
          ),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
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
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('पुढे जा — OTP तपासा',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87));

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54));

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text, int? maxLength, FocusNode? focusNode}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLength: maxLength,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}


