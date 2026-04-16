import 'package:flutter/material.dart';
import '../utils/polly_tts.dart';

class NewsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final PollyTts _tts = PollyTts();

  static const Color _teal = Color(0xFF00897B);
  static const Color _bg = Color(0xFFF5F7F6);

  bool _speaking = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) {
        setState(() => _speaking = false);
      }
      return;
    }

    final title = (widget.news['title'] ?? '').toString().trim();
    final description = (widget.news['description'] ?? '').toString().trim();

    final textToSpeak = [
      if (title.isNotEmpty) title,
      if (description.isNotEmpty) description,
    ].join('. ');

    if (textToSpeak.isEmpty) return;

    setState(() => _speaking = true);
    await _tts.speak(textToSpeak);

    if (mounted) {
      setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.news;
    final title = (item['title'] ?? '').toString().trim();
    final source = (item['source'] ?? '').toString().trim();
    final date = (item['date'] ?? '').toString().trim();
    final description = (item['description'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'बातमी तपशील',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSpeak,
            tooltip: _speaking ? 'थांबवा' : 'ऐका',
            icon: Icon(
              _speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
              color: _teal,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Text(
                          source.isEmpty ? 'कृषी बातमी' : '✅ $source',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title.isEmpty ? 'बातमी शीर्षक उपलब्ध नाही' : title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  const Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        color: _teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'सविस्तर माहिती',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    description.isEmpty
                        ? (title.isEmpty
                            ? 'या बातमीसाठी सविस्तर माहिती उपलब्ध नाही.'
                            : title)
                        : description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _toggleSpeak,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _speaking ? Colors.red.shade400 : _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                ),
                label: Text(
                  _speaking ? 'थांबवा' : 'बातमी ऐका',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}