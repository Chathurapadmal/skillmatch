part of 'company_dashboard.dart';

class _InterviewSchedulingDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String companyId;

  const _InterviewSchedulingDialog({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.companyId,
  });

  @override
  State<_InterviewSchedulingDialog> createState() =>
      _InterviewSchedulingDialogState();
}

class _InterviewSchedulingDialogState
    extends State<_InterviewSchedulingDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _interviewType = 'online';
  final _locationCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _scheduling = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _linkCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleInterview() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _scheduling = true);

    try {
      final interviewDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Find or create application document
      final appQuery = await FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: widget.studentId)
          .where('companyId', isEqualTo: widget.companyId)
          .limit(1)
          .get();

      if (appQuery.docs.isEmpty) {
        // Create new application record with interview details
        await FirebaseFirestore.instance.collection('applications').add({
          'studentId': widget.studentId,
          'companyId': widget.companyId,
          'studentName': widget.studentName,
          'studentEmail': widget.studentEmail,
          'status': 'interview_scheduled',
          'interviewDate': interviewDateTime,
          'interviewType': _interviewType,
          'interviewLocation': _locationCtrl.text.trim(),
          'interviewLink': _linkCtrl.text.trim(),
          'interviewToken': _tokenCtrl.text.trim(),
          'appliedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing application with interview details
        await appQuery.docs.first.reference.update({
          'status': 'interview_scheduled',
          'interviewDate': interviewDateTime,
          'interviewType': _interviewType,
          'interviewLocation': _locationCtrl.text.trim(),
          'interviewLink': _linkCtrl.text.trim(),
          'interviewToken': _tokenCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Send notification to student
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': widget.studentId,
        'type': 'interview_scheduled',
        'title': 'Interview Scheduled!',
        'message':
            'Your interview with ${widget.companyId} has been scheduled. Check your applications for details.',
        'companyName': widget.companyId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interview scheduled and student notified.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling interview: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _scheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule Interview',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Student: ${widget.studentName}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Interview Date'),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Select date'
                      : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),

              // Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Interview Time'),
                subtitle: Text(
                  _selectedTime == null
                      ? 'Select time'
                      : _selectedTime!.format(context),
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.access_time_outlined),
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),

              // Interview Type Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interview Type',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(label: Text('Online'), value: 'online'),
                      ButtonSegment(
                          label: Text('In-Person'), value: 'inperson'),
                      ButtonSegment(label: Text('Phone'), value: 'phone'),
                    ],
                    selected: <String>{_interviewType},
                    onSelectionChanged: (newSelection) {
                      setState(() => _interviewType = newSelection.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location/Link Input
              if (_interviewType == 'inperson')
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Interview Location',
                    hintText: 'Office address or meeting room',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                )
              else
                TextField(
                  controller: _linkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Link',
                    hintText: 'Zoom/Teams/Google Meet URL',
                    prefixIcon: Icon(Icons.link_outlined),
                  ),
                ),
              const SizedBox(height: 12),

              // Access Token Input
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  labelText: 'Optional Access Token',
                  hintText: 'Meeting code, password, etc.',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _scheduling ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _scheduling ? null : _scheduleInterview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    child: _scheduling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Schedule Interview'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Analytics Tab
// ============================================================================

class _CompanyAnalyticsTab extends StatefulWidget {
  final String companyId;

  const _CompanyAnalyticsTab({required this.companyId});

  @override
  State<_CompanyAnalyticsTab> createState() => _CompanyAnalyticsTabState();
}

class _CompanyAnalyticsTabState extends State<_CompanyAnalyticsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('companyId', isEqualTo: widget.companyId)
          .snapshots(),
      builder: (context, appSnapshot) {
        if (!appSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final applications = appSnapshot.data!.docs;
        final totalApps = applications.length;
        final approved =
            applications.where((d) => d['status'] == 'approved').length;
        final rejected =
            applications.where((d) => d['status'] == 'rejected').length;
        final interviewed = applications
            .where(
                (d) => d['status'] == 'approved' && d['interviewDate'] != null)
            .length;
        final hired = applications.where((d) => d['status'] == 'hired').length;

        int pending = totalApps - approved - rejected;

        // Calculate percentages
        final approvalRate = totalApps > 0 ? (approved / totalApps) * 100 : 0.0;
        final interviewRate =
            approved > 0 ? (interviewed / approved) * 100 : 0.0;
        final hireRate = approved > 0 ? (hired / approved) * 100 : 0.0;

        // Group by job post
        final appsByPost = <String, int>{};
        for (var app in applications) {
          final postId = app['internshipId'] as String?;
          if (postId != null) {
            appsByPost[postId] = (appsByPost[postId] ?? 0) + 1;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Funnel Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE3F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Funnel',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stage 1: Total Applications
                  _FunnelStage(
                    label: 'Total Applications',
                    count: totalApps,
                    percentage: 100.0,
                    color: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 12),
                  // Stage 2: Pending Review
                  _FunnelStage(
                    label: 'Pending Review',
                    count: pending,
                    percentage: totalApps > 0 ? (pending / totalApps) * 100 : 0,
                    color: const Color(0xFFFFB020),
                  ),
                  const SizedBox(height: 12),
                  // Stage 3: Approved
                  _FunnelStage(
                    label: 'Approved / Shortlisted',
                    count: approved,
                    percentage: approvalRate,
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: 12),
                  // Stage 4: Interviewed
                  _FunnelStage(
                    label: 'Interviewed',
                    count: interviewed,
                    percentage:
                        totalApps > 0 ? (interviewed / totalApps) * 100 : 0,
                    color: const Color(0xFF8A5BFF),
                  ),
                  const SizedBox(height: 12),
                  // Stage 5: Hired
                  _FunnelStage(
                    label: 'Hired',
                    count: hired,
                    percentage: totalApps > 0 ? (hired / totalApps) * 100 : 0,
                    color: const Color(0xFF18C17C),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Key Metrics
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Approval Rate',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${approvalRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Interview Rate',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${interviewRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF8A5BFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hire Rate',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hireRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF18C17C),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Applications per Job Post
            if (appsByPost.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE3F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Applications by Job Post',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...appsByPost.entries.map((entry) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('internships')
                            .doc(entry.key)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final postTitle =
                              snapshot.data?['title'] as String? ??
                                  'Unknown Post';
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      postTitle,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF1565C0).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${entry.value} applications',
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FunnelStage extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _FunnelStage({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Gradient? gradient;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(16),
        border: gradient == null
            ? Border.all(color: const Color(0xFFDCE3F0))
            : null,
        boxShadow: [
          BoxShadow(
            color: gradient != null
                ? color.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gradient != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: gradient != null ? Colors.white : color,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: gradient != null ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: gradient != null
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Privacy Policy Page
// ============================================================================

class _PrivacyPolicyPage extends StatelessWidget {
  const _PrivacyPolicyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Last Updated: March 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'At SkillMatch, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform.\n\n'
                  '1. Information We Collect\n'
                  'We collect information you provide directly, such as your company details, contact information, and application data.\n\n'
                  '2. How We Use Your Information\n'
                  'We use your information to operate the platform, improve services, and communicate with you about your account.\n\n'
                  '3. Data Security\n'
                  'We implement appropriate security measures to protect your personal information against unauthorized access.\n\n'
                  '4. Your Rights\n'
                  'You have the right to access, correct, or delete your personal data.\n\n'
                  'For more information, please contact our support team.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Security Page
// ============================================================================

class _SecurityPage extends StatelessWidget {
  const _SecurityPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Security',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Center',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Use a strong password with mix of characters\n'
                  '• Enable two-factor authentication (coming soon)\n'
                  '• Review active sessions regularly\n'
                  '• Do not share your login credentials\n'
                  '• Logout when using shared devices',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data Protection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• All data is encrypted in transit and at rest\n'
                  '• We use industry-standard security protocols\n'
                  '• Regular security audits are conducted\n'
                  '• Access logs are maintained for compliance',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Report a Security Issue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you discover a security vulnerability, please email our security team at security@skillmatch.app',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Terms of Service Page
// ============================================================================

class _TermsOfServicePage extends StatelessWidget {
  const _TermsOfServicePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Effective Date: March 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By using SkillMatch, you agree to these Terms of Service.\n\n'
                  '1. Use License\n'
                  'Permission is granted to temporarily download material from the SkillMatch platform for personal, non-commercial transitory viewing only.\n\n'
                  '2. Disclaimer\n'
                  'The materials on SkillMatch are provided on an "as is" basis. SkillMatch makes no warranties or representations regarding the accuracy or completeness of the information.\n\n'
                  '3. Limitations\n'
                  'In no event shall SkillMatch or its suppliers be liable for damages arising out of or related to your use of the platform.\n\n'
                  '4. User Responsibilities\n'
                  'You are responsible for maintaining confidentiality of your account and password. You agree to notify us immediately of any unauthorized use.\n\n'
                  '5. Modification of Terms\n'
                  'We may revise these terms at any time without notice. Your continued use constitutes acceptance of revised terms.\n\n'
                  'For clarifications, contact support@skillmatch.app',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0).withValues(alpha: 0.5),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
