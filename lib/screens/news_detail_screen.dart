import 'package:flutter/material.dart';
import '../utils/polly_tts.dart';

class NewsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> news;
  const NewsDetailScreen({super.key, required this.news});
  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final PollyTts _tts = PollyTts();
  bool _speaking = false;
  static const _teal = Color(0xFF00897B);

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      final text = '${widget.news['title']}. ${widget.news['description'] ?? ''}';
      await _tts.speak(text);
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.news;
    final title = item['title'] as String? ?? '';
    final source = item['source'] as String? ?? '';
    final date = item['date'] as String? ?? '';
    final description = item['description'] as String? ?? title;
    final url = item['link'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
              color: _teal,
            ),
            onPressed: _toggleSpeak,
            tooltip: _speaking ? 'थांबवा' : 'ऐका',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Source + date
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('✅ $source',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
            ),
            const Spacer(),
            if (date.isNotEmpty)
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.black38)),
          ]),
          const SizedBox(height: 16),

          // Title
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.4, color: Colors.black87)),
          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),

          // Description
          Text(
            description.isNotEmpty ? description : title,
            style: const TextStyle(fontSize: 15, height: 1.7, color: Colors.black87),
          ),
          const SizedBox(height: 24),

          // Speaker button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _toggleSpeak,
              style: ElevatedButton.styleFrom(
                backgroundColor: _speaking ? Colors.red.shade400 : _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: Icon(_speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
              label: Text(_speaking ? 'थांबवा' : 'बातमी ऐका',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),

          if (url.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text('स्रोत: $source',
                  style: const TextStyle(fontSize: 12, color: Colors.black38)),
            ),
          ],
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
