import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/disease_detection_service.dart';

const _teal     = Color(0xFF00897B);
const _tealDark = Color(0xFF00695C);
const _bg       = Color(0xFFF5F7F6);

class PikRogScanner extends StatefulWidget {
  const PikRogScanner({super.key});
  @override
  State<PikRogScanner> createState() => _PikRogScannerState();
}

class _PikRogScannerState extends State<PikRogScanner>
    with SingleTickerProviderStateMixin {
  final _diseaseService = DiseaseDetectionService();
  final _picker = ImagePicker();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  File? _imageFile;
  bool  _analyzing = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _diseaseService.testModel();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _imageFile = null;
        _result = null;
        _analyzing = false;
      });

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (xfile == null) return;
    setState(() {
      _imageFile = File(xfile.path);
      _analyzing = true;
      _result = null;
    });
    try {
      final result = await _diseaseService.detectDisease(_imageFile!);
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      debugPrint('Disease detection error: $e');
    }
  }

  Future<void> _downloadReport() async {
    if (_result == null) return;
    final r = _result!;
    final knowledge = r['knowledge'] is Map
        ? Map<String, dynamic>.from(r['knowledge'])
        : <String, dynamic>{};

    final diseaseName =
        knowledge['disease_name']?.toString() ?? r['className']?.toString() ?? 'Unknown';
    final crop = knowledge['crop']?.toString() ?? '';
    final cause = knowledge['cause']?.toString() ?? '';
    final advisory = knowledge['advisory']?.toString() ?? '';
    final confidence = r['confidencePercent'] as int;

    final symptoms = (knowledge['symptoms'] is List)
        ? List<String>.from(knowledge['symptoms'])
        : <String>[];
    final prevention = (knowledge['prevention'] is List)
        ? List<String>.from(knowledge['prevention'])
        : <String>[];
    final medicines = (knowledge['medicines'] is List)
        ? List.from(knowledge['medicines'])
        : <dynamic>[];

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('00897B'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('AgroVani — Pik Rog Report',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Date: ${DateTime.now().toString().substring(0, 10)}',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
            ]),
          ),
          pw.SizedBox(height: 20),
          if (crop.isNotEmpty) _pdfRow('Pik', crop),
          _pdfRow('Rog', diseaseName),
          _pdfRow('Vishwas', '$confidence%'),
          if (cause.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Karan', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(cause, style: const pw.TextStyle(fontSize: 12)),
          ],
          if (symptoms.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Lakshane', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...symptoms.map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(children: [
                    pw.Text('• '),
                    pw.Expanded(child: pw.Text(s, style: const pw.TextStyle(fontSize: 12))),
                  ]),
                )),
          ],
          if (advisory.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Salla', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(advisory, style: const pw.TextStyle(fontSize: 12)),
          ],
          if (prevention.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Pratibandh', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...prevention.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(children: [
                    pw.Text('• '),
                    pw.Expanded(child: pw.Text(p, style: const pw.TextStyle(fontSize: 12))),
                  ]),
                )),
          ],
          if (medicines.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Aushadhe', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...medicines.map((m) {
              final text = m is Map
                  ? '${m['name'] ?? ''} — ${m['dosage'] ?? ''}'
                  : m.toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(children: [
                  pw.Text('• '),
                  pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 12))),
                ]),
              );
            }),
          ],
          pw.Spacer(),
          pw.Divider(),
          pw.Text('AgroVani — Shetkaryansathi, Shetkaryanni',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: _imageFile == null ? _buildCaptureView() : _buildResultView(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('पीक रोग स्कॅनर',
                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('फोटो काढा आणि रोग ओळखा',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          ]),
        ),
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: Text('🔬', style: TextStyle(fontSize: 24))),
        ),
      ]),
    );
  }

  // ── Capture view ────────────────────────────────────────────────────────────
  Widget _buildCaptureView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Tips card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📌 चांगल्या फोटोसाठी टिप्स',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFFF57F17))),
          SizedBox(height: 10),
          _TipRow(icon: '☀️', text: 'चांगल्या प्रकाशात फोटो घ्या'),
          _TipRow(icon: '🔍', text: 'प्रभावित भाग जवळून दाखवा'),
          _TipRow(icon: '📐', text: 'फोटो स्थिर ठेवा, blur नको'),
          _TipRow(icon: '🌿', text: 'फक्त एकच पान/भाग फ्रेममध्ये ठेवा'),
        ]),
      ),
      const SizedBox(height: 24),
      // Camera button
      ScaleTransition(
        scale: _pulseAnim,
        child: GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_tealDark, _teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: const Column(children: [
              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 40),
              SizedBox(height: 10),
              Text('कॅमेरा उघडा',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('रिअल-टाइम फोटो काढा',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Gallery button
      GestureDetector(
        onTap: () => _pickImage(ImageSource.gallery),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _teal, width: 2),
            boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Column(children: [
            Icon(Icons.photo_library_rounded, color: _teal, size: 36),
            SizedBox(height: 8),
            Text('गॅलरीतून निवडा',
                style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('आधीचा फोटो वापरा',
                style: TextStyle(color: Colors.black45, fontSize: 12.5)),
          ]),
        ),
      ),
    ]);
  }

  // ── Result view ─────────────────────────────────────────────────────────────
  Widget _buildResultView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Image preview
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          Image.file(_imageFile!, width: double.infinity, height: 220, fit: BoxFit.cover),
          if (_analyzing)
            Container(
              width: double.infinity, height: 220,
              color: Colors.black54,
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 14),
                Text('AI विश्लेषण सुरू आहे...',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('कृपया थांबा', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          if (!_analyzing)
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('विश्लेषण पूर्ण',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      if (_analyzing)
        _analyzingCard()
      else if (_result != null)
        _resultCard(_result!),
    ]);
  }

  Widget _analyzingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200)),
      child: const Column(children: [
        CircularProgressIndicator(color: _teal),
        SizedBox(height: 16),
        Text('AI मॉडेल फोटो तपासत आहे...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('रोग, कीड आणि पोषण कमतरता तपासली जात आहे',
            style: TextStyle(fontSize: 12.5, color: Colors.black54)),
      ]),
    );
  }

  Widget _resultCard(Map<String, dynamic> r) {
    final confidence = r['confidencePercent'] as int;
    final className = r['className']?.toString() ?? 'Unknown';
    final knowledge = r['knowledge'] is Map
        ? Map<String, dynamic>.from(r['knowledge'])
        : <String, dynamic>{};

    final diseaseName = knowledge['disease_name']?.toString() ?? className;
    final cause = knowledge['cause']?.toString() ?? '';
    final advisory = knowledge['advisory']?.toString() ?? '';

    final symptoms = (knowledge['symptoms'] is List)
        ? List<String>.from(knowledge['symptoms'])
        : <String>['माहिती उपलब्ध नाही'];
    final prevention = (knowledge['prevention'] is List)
        ? List<String>.from(knowledge['prevention'])
        : <String>['माहिती उपलब्ध नाही'];
    final medicines = (knowledge['medicines'] is List)
        ? List.from(knowledge['medicines'])
        : <dynamic>[];

    final confColor = confidence >= 80
        ? Colors.green.shade700
        : confidence >= 60
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Confidence + disease name
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: confColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: confColor.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: confColor.withValues(alpha: 0.15),
            child: Text('$confidence%',
                style: TextStyle(color: confColor, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(diseaseName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: confColor)),
              const SizedBox(height: 4),
              Text('विश्वास: $confidence%',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      _listCard('📋 लक्षणे', symptoms, const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      const SizedBox(height: 12),
      if (cause.isNotEmpty) ...[
        _infoCard('🔍 कारण', cause, const Color(0xFFFCE4EC), const Color(0xFFC62828)),
        const SizedBox(height: 12),
      ],
      if (advisory.isNotEmpty) ...[
        _infoCard('💡 सल्ला', advisory, const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
        const SizedBox(height: 12),
      ],
      _listCard('🛡️ प्रतिबंध', prevention, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      if (medicines.isNotEmpty) ...[
        const SizedBox(height: 12),
        _listCard(
          '💊 औषधांची माहिती',
          medicines.map((m) {
            if (m is Map) {
              final name = m['name']?.toString() ?? '';
              final dosage = m['dosage']?.toString() ?? '';
              final app = m['application']?.toString() ?? '';
              return '$name — $dosage${app.isNotEmpty ? " ($app)" : ""}';
            }
            return m.toString();
          }).toList(),
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      ],
      const SizedBox(height: 20),
      // PDF download
      GestureDetector(
        onTap: _downloadReport,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_tealDark, _teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('PDF अहवाल डाउनलोड करा',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      // New scan
      GestureDetector(
        onTap: _reset,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _teal, width: 1.5),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.refresh_rounded, color: _teal, size: 20),
            SizedBox(width: 8),
            Text('नवीन स्कॅन करा',
                style: TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ]);
  }

  Widget _infoCard(String title, String text, Color bg, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: accent)),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 13, height: 1.55)),
      ]),
    );
  }

  Widget _listCard(String title, List items, Color bg, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: accent)),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
                Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 13, height: 1.5))),
              ]),
            )),
      ]),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String icon;
  final String text;
  const _TipRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: Colors.black87))),
      ]),
    );
  }
}
