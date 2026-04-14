import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _editing = false;
  bool _saving  = false;

  final _villageCtrl  = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _areaCtrl     = TextEditingController();
  String _selectedSoil  = 'काळी माती';
  String _selectedState = 'महाराष्ट्र';
  Set<String> _selectedCrops = {};

  static const _teal  = Color(0xFF00897B);
  static const _light = Color(0xFFE0F2F1);

  final _soils  = ['काळी माती', 'लाल माती', 'गाळाची माती', 'वालुकामय', 'चिकणमाती'];
  final _states = ['महाराष्ट्र', 'कर्नाटक', 'मध्य प्रदेश', 'गुजरात', 'राजस्थान'];
  final _allCrops = [
    {'key': 'Cotton',      'label': 'कापूस',    'icon': '🌱'},
    {'key': 'Jowar',       'label': 'ज्वारी',   'icon': '🌾'},
    {'key': 'Wheat',       'label': 'गहू',       'icon': '🌿'},
    {'key': 'Onion',       'label': 'कांदा',     'icon': '🧅'},
    {'key': 'Soybean',     'label': 'सोयाबीन',  'icon': '🫛'},
    {'key': 'Tur',         'label': 'तूर',       'icon': '🫘'},
    {'key': 'Sugarcane',   'label': 'ऊस',        'icon': '🎋'},
    {'key': 'Tomato',      'label': 'टोमॅटो',   'icon': '🍅'},
    {'key': 'Gram',        'label': 'हरभरा',     'icon': '🫘'},
    {'key': 'Maize',       'label': 'मका',       'icon': '🌽'},
    {'key': 'Groundnut',   'label': 'शेंगदाणा', 'icon': '🥜'},
    {'key': 'Pomegranate', 'label': 'डाळिंब',   'icon': '🍎'},
    {'key': 'Sunflower',   'label': 'सूर्यफूल', 'icon': '🌻'},
    {'key': 'Bajra',       'label': 'बाजरी',     'icon': '🌾'},
    {'key': 'Grape',       'label': 'द्राक्षे', 'icon': '🍇'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        _data          = data;
        _loading       = false;
        _villageCtrl.text  = (data['village']    ?? '').toString();
        _districtCtrl.text = (data['district']   ?? '').toString();
        _areaCtrl.text     = (data['area_acres'] ?? '').toString();
        _selectedSoil  = (data['soil_type'] ?? 'काळी माती').toString();
        _selectedState = (data['state']     ?? 'महाराष्ट्र').toString();
        _selectedCrops = Set<String>.from(
            (data['crops'] as List<dynamic>? ?? []).map((e) => e.toString()));
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'village':    _villageCtrl.text.trim(),
      'district':   _districtCtrl.text.trim(),
      'state':      _selectedState,
      'area_acres': _areaCtrl.text.trim(),
      'soil_type':  _selectedSoil,
      'crops':      _selectedCrops.toList(),
    });
    await _load();
    if (!mounted) return;
    setState(() { _editing = false; _saving = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('माहिती जतन केली ✅'), backgroundColor: _teal),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  IconData _avatarIcon() {
    final gender = (_data['gender'] ?? '').toString();
    // महिला starts with म (codepoint 2350)
    if (gender.isNotEmpty && gender.codeUnitAt(0) == 2350) {
      return Icons.face_3_rounded; // female
    }
    return Icons.face_rounded; // male / default
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
        title: const Text('माझे प्रोफाइल',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: _teal),
              onPressed: () => setState(() => _editing = true),
            ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red, size: 18),
            label: const Text('लॉगआउट', style: TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Avatar
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: _light,
                    shape: BoxShape.circle,
                    border: Border.all(color: _teal, width: 2),
                  ),
                  child: Center(
                    child: Icon(_avatarIcon(), color: _teal, size: 52),
                  ),
                ),
                const SizedBox(height: 12),
                Text((_data['name'] ?? '').toString(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text((_data['phone'] ?? '').toString(),
                    style: const TextStyle(color: Colors.black45, fontSize: 14)),
                const SizedBox(height: 4),
                Text((_data['email'] ?? '').toString(),
                    style: const TextStyle(color: Colors.black45, fontSize: 13)),
                const SizedBox(height: 24),

                _infoCard('🔒 खाते माहिती', [
                  _row(Icons.phone_outlined, 'मोबाइल', (_data['phone'] ?? '-').toString()),
                  _row(Icons.email_outlined, 'ईमेल', (_data['email'] ?? '-').toString()),
                  _row(Icons.person_outline, 'लिंग', (_data['gender'] ?? '-').toString()),
                ]),
                const SizedBox(height: 16),

                if (!_editing) ...[
                  _infoCard('📍 स्थान माहिती', [
                    _row(Icons.location_on_outlined, 'गाव', (_data['village'] ?? '-').toString()),
                    _row(Icons.map_outlined, 'जिल्हा', (_data['district'] ?? '-').toString()),
                    _row(Icons.flag_outlined, 'राज्य', (_data['state'] ?? '-').toString()),
                  ]),
                  const SizedBox(height: 16),
                  _infoCard('🌾 शेती माहिती', [
                    _row(Icons.landscape_outlined, 'माती प्रकार', (_data['soil_type'] ?? '-').toString()),
                    _row(Icons.straighten_outlined, 'जमीन', '${(_data['area_acres'] ?? '-')} एकर'),
                  ]),
                  const SizedBox(height: 16),
                  _infoCard('🌱 माझी पिके', [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: (_selectedCrops.isEmpty
                            ? <String>['पिके निवडलेली नाहीत']
                            : _selectedCrops.toList())
                            .map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(20)),
                          child: Text(c, style: const TextStyle(color: _teal, fontWeight: FontWeight.w600, fontSize: 13)),
                        )).toList(),
                      ),
                    ),
                  ]),
                ] else ...[
                  _editSection('📍 स्थान माहिती'),
                  const SizedBox(height: 10),
                  _editField(_villageCtrl, 'गाव'),
                  const SizedBox(height: 10),
                  _editField(_districtCtrl, 'जिल्हा'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: _dropDecor('राज्य'),
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedState = v!),
                  ),
                  const SizedBox(height: 20),
                  _editSection('🌾 शेती माहिती'),
                  const SizedBox(height: 10),
                  _editField(_areaCtrl, 'जमीन (एकर)', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('माती प्रकार', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
                  ),
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
                  const SizedBox(height: 20),
                  _editSection('🌱 पिके निवडा'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _allCrops.map((c) {
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
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _editing = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black54,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('रद्द करा'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('जतन करा', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 30),
              ]),
            ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 8),
      ...children,
    ]),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 18, color: _teal),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: Colors.black45, fontSize: 13)),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _editSection(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
  );

  Widget _editField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  InputDecoration _dropDecor(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
