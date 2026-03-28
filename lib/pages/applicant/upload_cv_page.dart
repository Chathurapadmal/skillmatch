import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/aiserv.dart';
import '../../shared/chat_overlay.dart';

class UploadCvPage extends StatefulWidget {
  final String initialCvText;
  final bool returnResultOnExtract;

  const UploadCvPage({
    super.key,
    this.initialCvText = '',
    this.returnResultOnExtract = true,
  });

  @override
  State<UploadCvPage> createState() => _UploadCvPageState();
}

class _UploadCvPageState extends State<UploadCvPage> {
  late final TextEditingController _cvTextCtrl;

  bool _uploading = false;
  bool _extracting = false;
  double _analysisProgress = 0.45;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _cvTextCtrl = TextEditingController(text: widget.initialCvText);
  }

  @override
  void dispose() {
    _cvTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCvFile() async {
    setState(() {
      _uploading = true;
      _analysisProgress = 0.10;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        // UI is designed like PDF/DOCX upload.
        // Current reading logic works best for text-based files.
        allowedExtensions: const ['txt', 'md', 'pdf', 'docx'],
      );

      if (picked == null || picked.files.isEmpty) {
        if (mounted) {
          setState(() {
            _uploading = false;
            _analysisProgress = 0.0;
          });
        }
        return;
      }

      final file = picked.files.single;
      final extension = (file.extension ?? '').toLowerCase();

      setState(() {
        _selectedFileName = file.name;
        _analysisProgress = 0.30;
      });

      String content = '';

      // Current implementation can directly read text files.
      if (extension == 'txt' || extension == 'md') {
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!, allowMalformed: true);
        } else if (!kIsWeb && file.path != null) {
          content = await File(file.path!).readAsString();
        }
      } else {
        // Honest fallback for binary files until PDF/DOCX parsing is added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'UI supports PDF/DOCX, but actual PDF/DOCX text extraction needs an extra parser package.',
            ),
          ),
        );
      }

      if (!mounted) return;

      if (content.trim().isNotEmpty) {
        setState(() {
          _cvTextCtrl.text = content;
          _analysisProgress = 0.45;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${file.name} successfully.')),
        );
      } else {
        setState(() {
          _analysisProgress = 0.20;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload CV file.')),
      );
      setState(() {
        _analysisProgress = 0.0;
      });
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _extractAndReturn() async {
    final cvText = _cvTextCtrl.text.trim();

    if (cvText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload or paste your CV text first.'),
        ),
      );
      return;
    }

    setState(() {
      _extracting = true;
      _analysisProgress = 0.65;
    });

    try {
      final parsed = await AIService.extractCvProfile(cvText);

      if (!mounted) return;

      setState(() {
        _analysisProgress = 1.0;
      });

      final result = {
        'cvText': cvText,
        'aiSkills': parsed['skills'] ?? <String>[],
        'certifications': parsed['certifications'] ?? <Map<String, dynamic>>[],
      };

      if (widget.returnResultOnExtract) {
        Navigator.pop(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Extracted ${(result['aiSkills'] as List).length} skills and '
              '${(result['certifications'] as List).length} certifications.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analysisProgress = 0.45;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to extract skills and certifications from CV.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _extracting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5A5FF0);
    const Color softBg = Color(0xFFF5F6FB);
    const Color uploadBg = Color(0xFFECEEFF);
    const Color borderColor = Color(0xFF8C98FF);
    const Color textDark = Color(0xFF111111);
    const Color textMuted = Color(0xFF6B7280);

    final busy = _uploading || _extracting;

    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F7F8),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Upload CV',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu, color: primary, size: 30),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Start your journey',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload your resume to get matched with top internships and personalized roadmaps.',
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.6,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                // Upload card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: uploadBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: borderColor,
                      radius: 20,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 26,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.18),
                            ),
                            child: const Icon(
                              Icons.upload_file_outlined,
                              color: primary,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Drag and drop your file',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Supported: PDF, DOCX (Max 5MB)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF92A0B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_selectedFileName != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _selectedFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: busy ? null : _pickCvFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                disabledBackgroundColor: primary.withOpacity(0.6),
                                elevation: 8,
                                shadowColor: primary.withOpacity(0.28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                _uploading ? 'Uploading...' : 'Upload PDF / DOCX',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Status row
                Row(
                  children: [
                    const Icon(Icons.autorenew, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _extracting
                            ? 'Analyzing your CV...'
                            : _uploading
                                ? 'Uploading your CV...'
                                : 'Analyzing your CV...',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${(_analysisProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _analysisProgress.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: const Color(0xFF2E3445),
                    valueColor: const AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9CA3AF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6B7280).withOpacity(0.35),
                    ),
                  ),
                  child: const Text(
                    '"Our AI is identifying your key skills and potential career paths based on your academic background and project experience..."',
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.55,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Hidden text area kept for current extraction flow
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _cvTextCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 14.5),
                      decoration: const InputDecoration(
                        hintText: 'CV extracted text will appear here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _extractAndReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _extracting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      _extracting ? 'Extracting...' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.radius = 12,
    this.strokeWidth = 1.4,
    this.dashWidth = 7,
    this.dashSpace = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}