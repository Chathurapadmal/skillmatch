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
    setState(() => _uploading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md'],
      );

      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.single;
      String content = '';

      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (!kIsWeb && file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (!mounted) return;

      if (content.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read text from the selected file.')),
        );
        return;
      }

      setState(() {
        _cvTextCtrl.text = content;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${file.name} successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload CV file.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _extractAndReturn() async {
    final cvText = _cvTextCtrl.text.trim();
    if (cvText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or paste your CV text first.')),
      );
      return;
    }

    setState(() => _extracting = true);
    try {
      final parsed = await AIService.extractCvProfile(cvText);
      if (!mounted) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract data from CV.')),
      );
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Upload CV',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [

              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B5FFF), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [

                    Positioned(
                      right: -20,
                      top: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Positioned(
                      left: -30,
                      bottom: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Seamless CV Upload',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Upload your CV and let AI extract\nskills instantly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [

                      GestureDetector(
                        onTap: _uploading || _extracting ? null : _pickCvFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF7C3AED).withOpacity(0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _uploading
                                  ? const CircularProgressIndicator()
                                  : Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF5B5FFF),
                                            Color(0xFF7C3AED)
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                              const SizedBox(height: 14),
                              const Text(
                                "Upload your CV",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Supports TXT, MD (or paste below)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _cvTextCtrl,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText: "Paste your CV text here...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      GestureDetector(
                        onTap: _extracting || _uploading
                            ? null
                            : _extractAndReturn,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5B5FFF),
                                Color(0xFF7C3AED)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: _extracting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Extract to Profile",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}