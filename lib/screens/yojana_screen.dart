import 'package:flutter/material.dart';
import '../utils/polly_tts.dart';
import '../widgets/voice_mic_bar.dart';

class YojanaScreen extends StatefulWidget {
  const YojanaScreen({super.key});
  @override
  State<YojanaScreen> createState() => _YojanaScreenState();
}

class _YojanaScreenState extends State<YojanaScreen> {
  final PollyTts _tts = PollyTts();
  final TextEditingController _search = TextEditingController();
  final Set<String> _expanded = {};

  static const _green = Color(0xFF1B5E20);
  static const _cream = Color(0xFFF3F1E7);

  static const _yojanas = [
    {
      'title': 'प्रधानमंत्री किसान योजना',
      'subtitle': '₹6000 वार्षिक थेट मदत',
      'icon': '🌾',
      'color': Color(0xFF2E7D32),
      'details': 'पात्रता: 2 हेक्टरपर्यंत जमीन असलेले शेतकरी.\n'
          'लाभ: दरवर्षी ₹6000 तीन हप्त्यांत थेट बँक खात्यात.\n'
          'अर्ज: pmkisan.gov.in वर ऑनलाइन किंवा CSC केंद्रावर.\n'
          'कागदपत्रे: आधार, बँक पासबुक, जमीन उतारा.',
    },
    {
      'title': 'महाडीबीटी यांत्रिकीकरण',
      'subtitle': 'ट्रॅक्टर व उपकरण अनुदान',
      'icon': '🚜',
      'color': Color(0xFF1565C0),
      'details': 'पात्रता: महाराष्ट्रातील शेतकरी.\n'
          'लाभ: ट्रॅक्टर, रोटाव्हेटर, थ्रेशर यावर 40-50% अनुदान.\n'
          'अर्ज: mahadbt.maharashtra.gov.in वर ऑनलाइन.\n'
          'कागदपत्रे: आधार, 7/12 उतारा, बँक तपशील.',
    },
    {
      'title': 'ठिबक सिंचन योजना',
      'subtitle': 'पाणी बचत व सिंचन अनुदान',
      'icon': '💧',
      'color': Color(0xFF00838F),
      'details': 'पात्रता: सर्व शेतकरी.\n'
          'लाभ: ठिबक व तुषार सिंचनावर 55-80% अनुदान.\n'
          'अर्ज: महाडीबीटी पोर्टलवर.\n'
          'फायदा: 40-50% पाण्याची बचत, उत्पादन वाढ.',
    },
    {
      'title': 'पीक विमा योजना (PMFBY)',
      'subtitle': 'नैसर्गिक आपत्तीत नुकसान भरपाई',
      'icon': '🛡️',
      'color': Color(0xFF6A1B9A),
      'details': 'पात्रता: सर्व शेतकरी (कर्जदार व बिगर कर्जदार).\n'
          'लाभ: दुष्काळ, पूर, गारपीट यामुळे नुकसान झाल्यास भरपाई.\n'
          'प्रीमियम: खरीप 2%, रब्बी 1.5%.\n'
          'अर्ज: बँक किंवा CSC केंद्रावर.',
    },
    {
      'title': 'किसान क्रेडिट कार्ड',
      'subtitle': 'कमी व्याजदरात शेती कर्ज',
      'icon': '💳',
      'color': Color(0xFFE65100),
      'details': 'पात्रता: सर्व शेतकरी.\n'
          'लाभ: 4% व्याजदरात ₹3 लाखांपर्यंत कर्ज.\n'
          'वापर: बियाणे, खत, कीडनाशक खरेदी.\n'
          'अर्ज: जवळच्या बँकेत किंवा ऑनलाइन.',
    },
    {
      'title': 'मागेल त्याला शेततळे',
      'subtitle': 'पाणी साठवण अनुदान',
      'icon': '🏞️',
      'color': Color(0xFF558B2F),
      'details': 'पात्रता: महाराष्ट्रातील शेतकरी.\n'
          'लाभ: शेततळे बांधण्यासाठी 100% अनुदान.\n'
          'आकार: 15×15×3 मीटर मानक आकार.\n'
          'अर्ज: ग्रामपंचायत किंवा कृषी विभागात.',
    },
  ];

  @override
  void dispose() {
    _search.dispose();
    _tts.stop();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(_yojanas);
    return _yojanas.where((y) =>
        y['title'].toString().toLowerCase().contains(q) ||
        y['subtitle'].toString().toLowerCase().contains(q) ||
        y['details'].toString().toLowerCase().contains(q)).toList().cast();
  }

  // keyword → yojana title mapping
  static const _voiceYojanaMap = <String, String>{
    'किसान': 'प्रधानमंत्री किसान योजना',
    'pmkisan': 'प्रधानमंत्री किसान योजना',
    'pm kisan': 'प्रधानमंत्री किसान योजना',
    'महाडीबीटी': 'महाडीबीटी यांत्रिकीकरण',
    'mahadbt': 'महाडीबीटी यांत्रिकीकरण',
    'यांत्रिकीकरण': 'महाडीबीटी यांत्रिकीकरण',
    'yantrikaran': 'महाडीबीटी यांत्रिकीकरण',
    'ट्रॅक्टर': 'महाडीबीटी यांत्रिकीकरण',
    'tractor': 'महाडीबीटी यांत्रिकीकरण',
    'ठिबक': 'ठिबक सिंचन योजना',
    'thibak': 'ठिबक सिंचन योजना',
    'सिंचन': 'ठिबक सिंचन योजना',
    'sinchan': 'ठिबक सिंचन योजना',
    'drip': 'ठिबक सिंचन योजना',
    'विमा': 'पीक विमा योजना (PMFBY)',
    'vima': 'पीक विमा योजना (PMFBY)',
    'pmfby': 'पीक विमा योजना (PMFBY)',
    'insurance': 'पीक विमा योजना (PMFBY)',
    'क्रेडिट': 'किसान क्रेडिट कार्ड',
    'credit': 'किसान क्रेडिट कार्ड',
    'kcc': 'किसान क्रेडिट कार्ड',
    'कर्ज': 'किसान क्रेडिट कार्ड',
    'karj': 'किसान क्रेडिट कार्ड',
    'शेततळे': 'मागेल त्याला शेततळे',
    'shetale': 'मागेल त्याला शेततळे',
    'तळे': 'मागेल त्याला शेततळे',
    'magel': 'मागेल त्याला शेततळे',
  };

  void _handleVoice(String spoken) {
    final lower = spoken.toLowerCase();
    String? matchedTitle;
    for (final e in _voiceYojanaMap.entries) {
      if (lower.contains(e.key)) { matchedTitle = e.value; break; }
    }
    if (matchedTitle != null) {
      // Find the yojana and speak it directly
      final yojana = _yojanas.firstWhere(
        (y) => y['title'] == matchedTitle,
        orElse: () => {},
      );
      if (yojana.isNotEmpty) {
        setState(() {
          _expanded.add(matchedTitle!);
          _search.text = '';
        });
        _speak(yojana);
        return;
      }
    }
    // Fallback — use spoken text as search filter
    _search.text = spoken;
    setState(() {});
  }

  Future<void> _speak(Map<String, dynamic> y) async {
    await _tts.speak('${y['title']}. ${y['subtitle']}. ${y['details']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'योजना शोधा...',
                prefixIcon: const Icon(Icons.search, color: _green),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          // Voice bar
          VoiceMicBar(
            tts: _tts,
            hintText: 'बोला: "पीक विमा" किंवा "किसान कार्ड"',
            onResult: _handleVoice,
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _buildCard(_filtered[i]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> y) {
    final title = y['title'] as String;
    final color = y['color'] as Color;
    final expanded = _expanded.contains(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Colored top banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Row(children: [
            Text(y['icon'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(y['subtitle'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        // Actions + expandable details
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _actionBtn('वाचा', Icons.article_rounded, color, () {
                setState(() {
                  if (expanded) _expanded.remove(title);
                  else _expanded.add(title);
                });
              }),
              const SizedBox(width: 8),
              _actionBtn('ऐका', Icons.volume_up_rounded, color, () => _speak(y)),
            ]),
            if (expanded) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(y['details'] as String,
                    style: const TextStyle(fontSize: 13.5, height: 1.7)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('शासकीय योजना', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('शेतकऱ्यांसाठी सरकारी मदत', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const Text('📋', style: TextStyle(fontSize: 32)),
      ]),
    );
  }
}
