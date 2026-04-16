import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _lightTeal = Color(0xFFE0F2F1);
  static const Color _bg = Color(0xFFF5F7F6);

  final TextEditingController _villageCtrl = TextEditingController();
  final TextEditingController _districtCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();

  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  String _selectedSoil = 'काळी माती';
  String _selectedState = 'महाराष्ट्र';
  Set<String> _selectedCrops = {};

  final List<String> _soils = const [
    'काळी माती',
    'लाल माती',
    'गाळाची माती',
    'वालुकामय',
    'चिकणमाती',
  ];

  final List<String> _states = const [
    'महाराष्ट्र',
    'कर्नाटक',
    'मध्य प्रदेश',
    'गुजरात',
    'राजस्थान',
  ];

  final List<Map<String, String>> _allCrops = const [
    {'key': 'Cotton', 'label': 'कापूस', 'icon': '🌱'},
    {'key': 'Jowar', 'label': 'ज्वारी', 'icon': '🌾'},
    {'key': 'Wheat', 'label': 'गहू', 'icon': '🌿'},
    {'key': 'Onion', 'label': 'कांदा', 'icon': '🧅'},
    {'key': 'Soybean', 'label': 'सोयाबीन', 'icon': '🫛'},
    {'key': 'Tur', 'label': 'तूर', 'icon': '🫘'},
    {'key': 'Sugarcane', 'label': 'ऊस', 'icon': '🎋'},
    {'key': 'Tomato', 'label': 'टोमॅटो', 'icon': '🍅'},
    {'key': 'Gram', 'label': 'हरभरा', 'icon': '🫘'},
    {'key': 'Maize', 'label': 'मका', 'icon': '🌽'},
    {'key': 'Groundnut', 'label': 'शेंगदाणा', 'icon': '🥜'},
    {'key': 'Pomegranate', 'label': 'डाळिंब', 'icon': '🍎'},
    {'key': 'Sunflower', 'label': 'सूर्यफूल', 'icon': '🌻'},
    {'key': 'Bajra', 'label': 'बाजरी', 'icon': '🌾'},
    {'key': 'Grape', 'label': 'द्राक्षे', 'icon': '🍇'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data() ?? <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _data = data;
        _villageCtrl.text = (data['village'] ?? '').toString();
        _districtCtrl.text = (data['district'] ?? '').toString();
        _areaCtrl.text = (data['area_acres'] ?? '').toString();
        _selectedSoil = (data['soil_type'] ?? 'काळी माती').toString();
        _selectedState = (data['state'] ?? 'महाराष्ट्र').toString();
        _selectedCrops =
            Set<String>.from((data['crops'] as List? ?? []).map((e) => '$e'));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('प्रोफाइल लोड करता आले नाही.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'village': _villageCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'state': _selectedState,
        'area_acres': _areaCtrl.text.trim(),
        'soil_type': _selectedSoil,
        'crops': _selectedCrops.toList(),
      });

      await _loadProfile();

      if (!mounted) return;

      setState(() {
        _editing = false;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('माहिती जतन केली ✅'),
          backgroundColor: _teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('माहिती जतन करता आली नाही.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  bool _isFemale() {
    final gender = (_data['gender'] ?? '').toString().trim().toLowerCase();

    return gender.contains('female') ||
        gender.contains('woman') ||
        gender.contains('girl') ||
        gender.contains('महिला') ||
        gender.contains('स्त्री');
  }

  IconData _avatarIcon() {
    return _isFemale() ? Icons.face_3_rounded : Icons.face_rounded;
  }

  String _valueOf(String key) {
    final value = (_data[key] ?? '').toString().trim();
    return value.isEmpty ? '-' : value;
  }

  @override
  Widget build(BuildContext context) {
    final name = _valueOf('name');
    final phone = _valueOf('phone');
    final email = _valueOf('email');
    final gender = _valueOf('gender');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'माझे प्रोफाइल',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_editing)
            IconButton(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, color: _teal),
            ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red, size: 18),
            label: const Text(
              'लॉगआउट',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _teal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              child: Column(
                children: [
                  _buildProfileHeader(name, phone, email),
                  const SizedBox(height: 16),
                  _buildAccountCard(gender),
                  const SizedBox(height: 16),
                  if (!_editing) ...[
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildFarmCard(),
                    const SizedBox(height: 16),
                    _buildCropsCard(),
                  ] else ...[
                    _buildEditForm(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String name, String phone, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 2,
              ),
            ),
            child: Icon(
              _avatarIcon(),
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(String gender) {
    return _infoCard(
      title: '🔒 खाते माहिती',
      children: [
        _infoRow(Icons.phone_outlined, 'मोबाइल', _valueOf('phone')),
        _infoRow(Icons.email_outlined, 'ईमेल', _valueOf('email')),
        _infoRow(Icons.person_outline, 'लिंग', gender),
      ],
    );
  }

  Widget _buildLocationCard() {
    return _infoCard(
      title: '📍 स्थान माहिती',
      children: [
        _infoRow(Icons.location_on_outlined, 'गाव', _valueOf('village')),
        _infoRow(Icons.map_outlined, 'जिल्हा', _valueOf('district')),
        _infoRow(Icons.flag_outlined, 'राज्य', _valueOf('state')),
      ],
    );
  }

  Widget _buildFarmCard() {
    final area = _valueOf('area_acres');

    return _infoCard(
      title: '🌾 शेती माहिती',
      children: [
        _infoRow(Icons.landscape_outlined, 'माती प्रकार', _valueOf('soil_type')),
        _infoRow(
          Icons.straighten_outlined,
          'जमीन',
          area == '-' ? '-' : '$area एकर',
        ),
      ],
    );
  }

  Widget _buildCropsCard() {
    return _infoCard(
      title: '🌱 माझी पिके',
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedCrops.isEmpty
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _lightTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'पिके निवडलेली नाहीत',
                      style: TextStyle(
                        color: _teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ]
              : _selectedCrops.map((crop) {
                  final cropData = _allCrops.firstWhere(
                    (e) => e['key'] == crop,
                    orElse: () => {
                      'key': crop,
                      'label': crop,
                      'icon': '🌿',
                    },
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _lightTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cropData['icon']} ${cropData['label']}',
                      style: const TextStyle(
                        color: _teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📍 स्थान माहिती',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _editField(_villageCtrl, 'गाव'),
          const SizedBox(height: 10),
          _editField(_districtCtrl, 'जिल्हा'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedState,
            decoration: _inputDecoration('राज्य'),
            items: _states
                .map(
                  (state) => DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedState = value);
              }
            },
          ),
          const SizedBox(height: 20),
          const Text(
            '🌾 शेती माहिती',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _editField(
            _areaCtrl,
            'जमीन (एकर)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const Text(
            'माती प्रकार',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _soils.map((soil) {
              final selected = _selectedSoil == soil;
              return GestureDetector(
                onTap: () => setState(() => _selectedSoil = soil),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _teal : _lightTeal,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    soil,
                    style: TextStyle(
                      color: selected ? Colors.white : _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            '🌱 पिके निवडा',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCrops.map((crop) {
              final key = crop['key']!;
              final selected = _selectedCrops.contains(key);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCrops.remove(key);
                    } else {
                      _selectedCrops.add(key);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _teal : _lightTeal,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(crop['icon']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        crop['label']!,
                        style: TextStyle(
                          color: selected ? Colors.white : _teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    setState(() => _editing = false);
                    await _loadProfile();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('रद्द करा'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'जतन करा',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _teal),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}