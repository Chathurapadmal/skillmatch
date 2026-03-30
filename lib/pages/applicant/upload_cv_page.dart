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

              /// HEADER
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
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.description_rounded, size: 40, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Seamless CV Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Upload your CV and let AI extract\nskills instantly',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [

                        /// Upload Card
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
                            ),
                            child: Column(
                              children: [
                                _uploading
                                    ? const CircularProgressIndicator()
                                    : const Icon(Icons.cloud_upload, size: 40),
                                const SizedBox(height: 10),
                                const Text("Upload your CV"),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// TEXT FIELD (FIXED HEIGHT)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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

                        /// BUTTON
                        GestureDetector(
                          onTap: _extracting || _uploading
                              ? null
                              : _extractAndReturn,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
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
                                      ),
                                    ),
                            ),
                          ),
                        ),

                      ],
                    ),
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