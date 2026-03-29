import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Supabase Storage Setup'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
            value: 'cv bucket\nprofile bucket',
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

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
