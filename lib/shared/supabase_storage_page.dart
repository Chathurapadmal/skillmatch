import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupabaseStoragePage extends StatelessWidget {
  const SupabaseStoragePage({super.key});

  static const String projectUrl = 'https://bmliitwxgkgrdpeyeiqu.supabase.co';
  static const String publishableAnonKey =
      'sb_publishable_zSJsdNSg9LaGimkRl9uzeg_5LCG8qns';
  static const String legacyAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtbGlpdHd4Z2tncmRwZXllaXF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3NDc1ODgsImV4cCI6MjA5MDMyMzU4OH0.-HnK_STk2086lJGiuj86umwc6zY1B0WqvaD4VeOvKh4';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text('Supabase Storage Setup'),
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F30),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4052B6),
                Color(0xFF652FE7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InfoCard(
            title: 'Project URL',
            value: projectUrl,
          ),
          SizedBox(height: 10),
          _InfoCard(
            title: 'Anon Key (Publishable)',
            value: publishableAnonKey,
          ),
          SizedBox(height: 10),
          _InfoCard(
            title: 'Anon Key (Legacy)',
            value: legacyAnonKey,
          ),
          SizedBox(height: 10),
          _InfoCard(
            title: 'Buckets Used',
            value: 'cv\nprofile',
            enableCopy: false, 
          ),
          SizedBox(height: 10),
          _InfoCard(
            title: 'How This App Uses Buckets',
            value:
                'Student CV uploads are saved to bucket: cv\nStudent profile icon uploads are saved to bucket: profile\nCompany logo/profile icon uploads are saved to bucket: profile',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final bool enableCopy;

  const _InfoCard({
    required this.title,
    required this.value,
    this.enableCopy = true, 
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8CAFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4052B6),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (enableCopy) //
                IconButton(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(
                    Icons.copy,
                    size: 18,
                    color: Color(0xFF5000D2),
                  ),
                  tooltip: 'Copy',
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(
              color: Color(0xFF595C5D),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}