import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/app_config.dart';
import '../utils/polly_tts.dart';

const _teal     = Color(0xFF00897B);
const _tealDark = Color(0xFF00695C);
const _bg       = Color(0xFFF5F7F6);

// ── Message model ─────────────────────────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser;
  final DateTime time;
  _Msg({required this.text, required this.isUser}) : time = DateTime.now();
}

// ── Main screen ───────────────────────────────────────────────────────────────
class KrushiDoctor extends StatefulWidget {
  const KrushiDoctor({super.key});
  @override
  State<KrushiDoctor> createState() => _KrushiDoctorState();
}

class _KrushiDoctorState extends State<KrushiDoctor> {
  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_tealDark, _teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: Row(children: [
              const SizedBox(width: 8),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('कृषी डॉक्टर',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('तुमच्या पिकाबद्दल विचारा',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ]),
              ),
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('🩺', style: TextStyle(fontSize: 24))),
              ),
            ]),
          ),

          // Body — info cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('कृषी डॉक्टर काय करू शकतो?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _featureCard('🌱', 'पीक रोग निदान',
                    'पानावर डाग, पिवळेपणा, करपा — कोणत्याही लक्षणाबद्दल विचारा'),
                _featureCard('🧪', 'खत सल्ला',
                    'कोणते खत, किती प्रमाणात, कधी द्यायचे — सर्व माहिती'),
                _featureCard('💧', 'पाणी व सिंचन',
                    'पिकाला किती पाणी लागते, कधी द्यायचे'),
                _featureCard('🌾', 'सामान्य शेती सल्ला',
                    'हवामान, पेरणी, काढणी — कोणताही प्रश्न विचारा'),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _teal.withValues(alpha: 0.2)),
                  ),
                  child: const Row(children: [
                    Text('💬', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'खालील बटण दाबा आणि तुमचा प्रश्न मराठीत विचारा',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _tealDark),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),

      // Floating chat button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChat,
        backgroundColor: _teal,
        elevation: 6,
        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
        label: const Text('डॉक्टरशी बोला',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _featureCard(String emoji, String title, String sub) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 3),
          Text(sub, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        ])),
      ]),
    );
  }
}

// ── Chat bottom sheet ─────────────────────────────────────────────────────────
class _ChatSheet extends StatefulWidget {
  const _ChatSheet();
  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _tts = PollyTts();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _msgs = <_Msg>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Greeting
    _msgs.add(_Msg(
      text: 'नमस्कार! मी कृषी डॉक्टर आहे. तुमच्या पिकाबद्दल काय जाणून घ्यायचे आहे?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _tts.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    _controller.clear();

    setState(() {
      _msgs.add(_Msg(text: query, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await apiPost(
        '$kBaseUrl/query',
        body: json.encode({'query': query}),
      );
      final payload = json.decode(res.body) as Map;
      final reply = payload['fulfillmentText']?.toString() ?? 'माहिती उपलब्ध नाही.';

      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg(text: reply, isUser: false));
        _loading = false;
      });
      _scrollToBottom();
      _tts.speak(reply);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg(text: 'सर्व्हरशी कनेक्ट होता आले नाही.', isUser: false));
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle + header
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Center(child: Text('🩺', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('कृषी डॉक्टर',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _tealDark)),
                    Text('ऑनलाइन', style: TextStyle(fontSize: 11.5, color: Colors.green)),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black45),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
          ]),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (_loading && i == _msgs.length) return _typingBubble();
              return _bubble(_msgs[i]);
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: const InputDecoration(
                    hintText: 'प्रश्न विचारा...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(_controller.text),
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(_Msg msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _teal : const Color(0xFFF0F4F3),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            msg.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 10,
              color: isUser ? Colors.white60 : Colors.black38,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(0), _dot(150), _dot(300),
        ]),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 7, height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
