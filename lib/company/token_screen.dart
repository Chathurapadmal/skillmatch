import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login_screen.dart';
import '../shared/notifications_center_screen.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final _companyNameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _companyLocationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _companyDescCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Remote');
  final _salaryCtrl = TextEditingController(text: '35000/month');
  final _manualSkillCtrl = TextEditingController();
  final _tokenRoleCtrl = TextEditingController();
  bool _saving = false;
  bool _savingProfile = false;
  bool _creatingToken = false;
  bool _uploadingLogo = false;
  bool _loadingProfile = true;
  int _nav = 0;
  bool _notifyNewApplications = true;
  bool _notifyTopCandidates = true;
  bool _notifyWeeklyReport = false;
  bool _isPaidInternship = true;
  double _minGpa = 3.0;
  String? _selectedIndustry;
  String? _companyLogoBase64;
  final Set<String> _selectedSkills = <String>{};
  List<String> _industryOptions = [];
  static const List<String> _defaultIndustries = [
    'IT & Software',
    'Business & Finance',
    'Medical & Healthcare',
    'Engineering',
    'Design & UX/UI',
    'Education',
    'Marketing & Sales',
    'Legal',
    'Hospitality',
    'Other'
  ];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _tokensCollection =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(_uid)
          .collection('tokens');

  DocumentReference<Map<String, dynamic>> get _companyDoc =>
      FirebaseFirestore.instance.collection('companies').doc(_uid);

  Stream<QuerySnapshot<Map<String, dynamic>>> get _postsStream =>
      _tokensCollection.orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _studentsStream =>
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .limit(100)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _applicationsStream =>
      FirebaseFirestore.instance
          .collection('applications')
          .limit(500)
          .snapshots();

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _industryCtrl.dispose();
    _companyLocationCtrl.dispose();
    _websiteCtrl.dispose();
    _companyDescCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _salaryCtrl.dispose();
    _manualSkillCtrl.dispose();
    _tokenRoleCtrl.dispose();
    super.dispose();
  }

  String _normalizeIndustry(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  void _addIndustryCandidate(Set<String> bucket, String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isNotEmpty) {
      bucket.add(trimmed);
    }
  }

  Future<void> _openExternalUrl(String url, {required String label}) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$label is not available for this candidate yet.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid $label URL.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to open $label right now.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<void> _loadIndustryOptions() async {
    final firebaseIndustries = <String>{};

    try {
      final masterIndustries = await FirebaseFirestore.instance
          .collection('industry_types')
          .limit(200)
          .get();
      for (final doc in masterIndustries.docs) {
        final data = doc.data();
        _addIndustryCandidate(firebaseIndustries, data['name'] as String?);
        _addIndustryCandidate(firebaseIndustries, data['title'] as String?);
      }
    } catch (_) {}

    try {
      final companies = await FirebaseFirestore.instance
          .collection('companies')
          .limit(200)
          .get();
      for (final doc in companies.docs) {
        final data = doc.data();
        _addIndustryCandidate(firebaseIndustries, data['industry'] as String?);
      }
    } catch (_) {}

    try {
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .limit(300)
          .get();
      for (final doc in users.docs) {
        final data = doc.data();
        _addIndustryCandidate(
            firebaseIndustries, (data['industry'] ?? data['field']) as String?);
      }
    } catch (_) {}

    final resolved = firebaseIndustries
        .map((item) => _canonicalIndustry(item) ?? item)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    _industryOptions =
        resolved.isEmpty ? List.from(_defaultIndustries) : resolved;
  }

  String? _canonicalIndustry(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    final validOptions =
        _industryOptions.isEmpty ? _defaultIndustries : _industryOptions;
    if (validOptions.contains(raw)) return raw;

    final normalized = _normalizeIndustry(raw);
    if (normalized == 'healthcare' ||
        normalized == 'medical' ||
        normalized == 'medical & healthcare') {
      return 'Medical & Healthcare';
    }
    if (normalized == 'business' ||
        normalized == 'business & management' ||
        normalized == 'management') {
      return 'Business & Finance';
    }
    if (normalized == 'it' ||
        normalized == 'software' ||
        normalized == 'it and software') {
      return 'IT & Software';
    }

    final normalizedMatch = validOptions.where((option) {
      return _normalizeIndustry(option) == normalized;
    }).toList();
    if (normalizedMatch.isNotEmpty) {
      return normalizedMatch.first;
    }

    if (validOptions.contains('Other')) {
      return 'Other';
    }
    return validOptions.isNotEmpty ? validOptions.first : null;
  }

  Future<void> _loadCompanyProfile() async {
    final uid = _uid;
    if (uid == null) return;

    await _loadIndustryOptions();

    final snapshot = await _companyDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    _companyNameCtrl.text = data['name'] as String? ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Company';
    _selectedIndustry =
        _canonicalIndustry((data['industry'] ?? data['field']) as String?);
    _industryCtrl.text = _selectedIndustry ?? '';
    _companyLocationCtrl.text = data['location'] as String? ?? '';
    _websiteCtrl.text = data['website'] as String? ?? '';
    _companyDescCtrl.text = data['description'] as String? ?? '';
    _companyLogoBase64 = data['profileIconBase64'] as String?;
    _notifyNewApplications = data['notifyNewApplications'] as bool? ?? true;
    _notifyTopCandidates = data['notifyTopCandidates'] as bool? ?? true;
    _notifyWeeklyReport = data['notifyWeeklyReport'] as bool? ?? false;

    if (!mounted) return;
    setState(() => _loadingProfile = false);
  }

  Future<void> _pickCompanyLogo() async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null || !mounted) return;

      setState(() => _uploadingLogo = true);
      final bytes = await picked.readAsBytes();
      final base64Logo = base64Encode(bytes);

      await _companyDoc.set({
        'profileIconBase64': base64Logo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _companyLogoBase64 = base64Logo);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Company profile icon updated.'),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update profile icon: $e'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  void _addManualSkill() {
    final skill = _manualSkillCtrl.text.trim();
    if (skill.isEmpty) return;

    setState(() {
      _selectedSkills.add(skill);
      _manualSkillCtrl.clear();
    });
  }

  void _removeSelectedSkill(String skill) {
    setState(() => _selectedSkills.remove(skill));
  }

  String _displayCompensation(Map<String, dynamic> data) {
    final isPaid = data['isPaid'] as bool?;
    final salary = (data['salary'] as String? ?? '').trim();
    if (isPaid == false) return 'Non-paid';
    if (salary.isEmpty) return 'Paid';
    return 'LKR $salary';
  }

  int _countCompanyApplications(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> appDocs,
      Set<String> internshipIds,
      String companyName,
      String? companyUid) {
    final normalizedCompany = companyName.trim().toLowerCase();
    return appDocs.where((doc) {
      final app = doc.data();
      final internshipId = (app['internshipId'] as String?) ?? '';
      final appCompanyId = (app['companyId'] as String?) ?? '';
      final appCompanyName =
          ((app['company'] as String?) ?? '').trim().toLowerCase();

      return internshipIds.contains(internshipId) ||
          (companyUid != null &&
              companyUid.isNotEmpty &&
              appCompanyId == companyUid) ||
          (normalizedCompany.isNotEmpty && appCompanyName == normalizedCompany);
    }).length;
  }

  String _companyDisplayName() {
    final name = _companyNameCtrl.text.trim();
    if (name.isNotEmpty) return name;
    return FirebaseAuth.instance.currentUser?.displayName ?? 'Company';
  }

  Future<void> _updateApplicationStatus(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> app,
    String status,
  ) async {
    await ref.set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final studentId = (app['studentId'] as String? ?? '').trim();
    if (studentId.isNotEmpty) {
      final internshipTitle =
          (app['title'] as String?)?.trim().isNotEmpty == true
              ? app['title'] as String
              : 'your internship application';

      var body =
          '${_companyDisplayName()} updated your application for $internshipTitle.';
      if (status == 'approved') {
        body =
            '${_companyDisplayName()} approved your application for $internshipTitle.';
      } else if (status == 'rejected') {
        body =
            '${_companyDisplayName()} rejected your application for $internshipTitle.';
      }

      await NotificationService.instance.createInAppNotification(
        recipientId: studentId,
        senderId: _uid,
        type: 'application_status',
        title: 'Application update',
        body: body,
        data: {
          'applicationRef': ref.id,
          'status': status,
        },
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Application marked as ${status.toUpperCase()}.'),
      backgroundColor: AppTheme.success,
    ));
  }

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return 'Not set';
    final dt = ts.toDate();
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString();
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour >= 12 ? 'PM' : 'AM';
    return '$date $hour:$minute $meridiem';
  }

  Future<bool> _scheduleInterview(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> app,
  ) async {
    String mode =
        ((app['interviewType'] as String?) ?? 'online').toLowerCase() ==
                'physical'
            ? 'physical'
            : 'online';
    DateTime selectedDateTime = (app['interviewAt'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 1));
    final linkCtrl =
        TextEditingController(text: (app['interviewLink'] as String?) ?? '');
    final locationCtrl = TextEditingController(
        text: (app['interviewLocation'] as String?) ?? '');
    final tokenCtrl =
        TextEditingController(text: (app['interviewToken'] as String?) ?? '');
    final dateCtrl = TextEditingController(
      text:
          '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}',
    );
    final timeCtrl = TextEditingController(
      text:
          '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
    );

    bool scheduled = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Schedule Interview',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Online'),
                            selected: mode == 'online',
                            onSelected: (_) => setDialogState(() {
                              mode = 'online';
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Physical'),
                            selected: mode == 'physical',
                            onSelected: (_) => setDialogState(() {
                              mode = 'physical';
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          firstDate: DateTime.now(),
                          initialDate: selectedDateTime,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime == null) return;

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          dateCtrl.text =
                              '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}';
                          timeCtrl.text =
                              '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';
                        });
                      },
                      icon: const Icon(Icons.schedule,
                          color: AppTheme.primaryLight),
                      label: Text(
                        'Interview Time: ${_formatDateTime(Timestamp.fromDate(selectedDateTime))}',
                        style: const TextStyle(color: AppTheme.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD) *',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: timeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Time (HH:MM, 24h) *',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (mode == 'online')
                      TextField(
                        controller: linkCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Zoom / Meet Link *',
                          labelStyle: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      TextField(
                        controller: locationCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Physical Location *',
                          labelStyle: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tokenCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Interview Token (optional)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final rawDate = dateCtrl.text.trim();
                    final rawTime = timeCtrl.text.trim();
                    final dateParts = rawDate.split('-');
                    final timeParts = rawTime.split(':');
                    if (dateParts.length != 3 || timeParts.length != 2) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Enter valid date/time format.'),
                        backgroundColor: AppTheme.error,
                      ));
                      return;
                    }

                    final year = int.tryParse(dateParts[0]);
                    final month = int.tryParse(dateParts[1]);
                    final day = int.tryParse(dateParts[2]);
                    final hour = int.tryParse(timeParts[0]);
                    final minute = int.tryParse(timeParts[1]);
                    if (year == null ||
                        month == null ||
                        day == null ||
                        hour == null ||
                        minute == null ||
                        month < 1 ||
                        month > 12 ||
                        day < 1 ||
                        day > 31 ||
                        hour < 0 ||
                        hour > 23 ||
                        minute < 0 ||
                        minute > 59) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Enter valid date/time values.'),
                        backgroundColor: AppTheme.error,
                      ));
                      return;
                    }

                    selectedDateTime = DateTime(year, month, day, hour, minute);
                    if (selectedDateTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Interview time must be in the future.'),
                        backgroundColor: AppTheme.error,
                      ));
                      return;
                    }

                    if (mode == 'online' && linkCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please add Zoom/Meet link.'),
                        backgroundColor: AppTheme.error,
                      ));
                      return;
                    }
                    if (mode == 'physical' &&
                        locationCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please add interview location.'),
                        backgroundColor: AppTheme.error,
                      ));
                      return;
                    }

                    await ref.set({
                      'status': 'interview_scheduled',
                      'interviewType': mode,
                      'interviewAt': Timestamp.fromDate(selectedDateTime),
                      'interviewLink':
                          mode == 'online' ? linkCtrl.text.trim() : '',
                      'interviewLocation':
                          mode == 'physical' ? locationCtrl.text.trim() : '',
                      'interviewToken': tokenCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    final studentId =
                        (app['studentId'] as String? ?? '').trim();
                    if (studentId.isNotEmpty) {
                      final internshipTitle =
                          (app['title'] as String?)?.trim().isNotEmpty == true
                              ? app['title'] as String
                              : 'your internship application';
                      final placeOrMode = mode == 'online'
                          ? 'online interview'
                          : 'physical interview';

                      await NotificationService.instance
                          .createInAppNotification(
                        recipientId: studentId,
                        senderId: _uid,
                        type: 'interview_scheduled',
                        title: 'Interview call scheduled',
                        body:
                            '${_companyDisplayName()} scheduled a $placeOrMode for $internshipTitle at ${_formatDateTime(Timestamp.fromDate(selectedDateTime))}.',
                        data: {
                          'applicationRef': ref.id,
                          'status': 'interview_scheduled',
                          'interviewType': mode,
                        },
                      );
                    }

                    if (!mounted) return;
                    scheduled = true;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Interview schedule sent to student.'),
                      backgroundColor: AppTheme.success,
                    ));
                  },
                  child: const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );

    linkCtrl.dispose();
    locationCtrl.dispose();
    tokenCtrl.dispose();
    dateCtrl.dispose();
    timeCtrl.dispose();

    return scheduled;
  }

  Future<void> _openApplicationDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final app = doc.data();
    final status = (app['status'] as String?) ?? 'applied';
    final interviewType = (app['interviewType'] as String?) ?? '';
    final interviewLink = (app['interviewLink'] as String?) ?? '';
    final interviewLocation = (app['interviewLocation'] as String?) ?? '';
    final interviewToken = (app['interviewToken'] as String?) ?? '';
    final interviewAt = app['interviewAt'] as Timestamp?;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161637),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app['studentName'] as String? ?? 'Student',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(app['studentEmail'] as String? ?? 'No email',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Applied for: ${app['title'] ?? 'Internship'}',
                  style: const TextStyle(color: AppTheme.primaryLight)),
              const SizedBox(height: 8),
              Text('Status: ${status.toUpperCase()}',
                  style: const TextStyle(
                      color: AppTheme.success, fontWeight: FontWeight.w700)),
              if (status == 'interview_scheduled') ...[
                const SizedBox(height: 10),
                Text('Interview: ${interviewType.toUpperCase()}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                Text('Time: ${_formatDateTime(interviewAt)}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                if (interviewType == 'online' && interviewLink.isNotEmpty)
                  Text('Link: $interviewLink',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                if (interviewType == 'physical' && interviewLocation.isNotEmpty)
                  Text('Location: $interviewLocation',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                if (interviewToken.isNotEmpty)
                  Text('Token: $interviewToken',
                      style: const TextStyle(color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _updateApplicationStatus(
                        doc.reference,
                        app,
                        'approved',
                      );
                      if (mounted) Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _updateApplicationStatus(
                        doc.reference,
                        app,
                        'rejected',
                      );
                      if (mounted) Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final sent = await _scheduleInterview(doc.reference, app);
                      if (mounted && sent) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    icon: const Icon(Icons.video_call_outlined),
                    label: const Text('Interview Call'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppliedCandidatesSection(
    Set<String> internshipIds,
    String companyName,
    String? companyUid,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _applicationsStream,
      builder: (context, snapshot) {
        final appDocs = snapshot.data?.docs ?? [];
        final normalizedCompany = companyName.trim().toLowerCase();
        final applied = appDocs.where((doc) {
          final app = doc.data();
          final internshipId = (app['internshipId'] as String?) ?? '';
          final appCompanyId = (app['companyId'] as String?) ?? '';
          final appCompanyName =
              ((app['company'] as String?) ?? '').trim().toLowerCase();
          return internshipIds.contains(internshipId) ||
              (companyUid != null &&
                  companyUid.isNotEmpty &&
                  appCompanyId == companyUid) ||
              (normalizedCompany.isNotEmpty &&
                  appCompanyName == normalizedCompany);
        }).toList();

        applied.sort((a, b) {
          final at = a.data()['appliedAt'] as Timestamp?;
          final bt = b.data()['appliedAt'] as Timestamp?;
          final aMs = at?.millisecondsSinceEpoch ?? 0;
          final bMs = bt?.millisecondsSinceEpoch ?? 0;
          return bMs.compareTo(aMs);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applied Candidates',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              )
            else if (applied.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A42),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF313173)),
                ),
                child: const Text('No applications received yet.',
                    style: TextStyle(color: AppTheme.textMuted)),
              )
            else
              ...applied.take(12).map((doc) {
                final app = doc.data();
                final name =
                    (app['studentName'] as String?)?.trim().isNotEmpty == true
                        ? app['studentName'] as String
                        : ((app['studentEmail'] as String?)?.split('@').first ??
                            'Student');
                final email = (app['studentEmail'] as String?) ?? 'No email';
                final roleTitle = (app['title'] as String?) ?? 'Internship';
                final status = (app['status'] as String?) ?? 'applied';
                return GestureDetector(
                  onTap: () => _openApplicationDetails(doc),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A42),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF313173)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.person_outline,
                              color: AppTheme.primaryLight),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              Text(email,
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Applied for: $roleTitle',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _showPostDetails(Map<String, dynamic> data) async {
    final skills = ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
    final isPaid = data['isPaid'] != false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161637),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'] as String? ?? 'Internship',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${data['location'] ?? 'Remote'} • ${isPaid ? 'Paid' : 'Non-paid'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                isPaid
                    ? 'Compensation: LKR ${(data['salary'] as String? ?? 'Not set')}'
                    : 'Compensation: Non-paid',
                style: const TextStyle(
                    color: AppTheme.primaryLight, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                (data['description'] as String?)?.trim().isNotEmpty == true
                    ? data['description'] as String
                    : 'No description provided.',
                style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text('Required Skills',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (skills.isEmpty)
                const Text('No required skills added yet.',
                    style: TextStyle(color: AppTheme.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map(
                        (skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF23235A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(skill,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPost({bool closeSheet = false}) async {
    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please login again.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter internship title'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one required skill.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final salaryText = _salaryCtrl.text.trim();
    if (_isPaidInternship && salaryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add salary in LKR for paid internship.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _saving = true);
    final token =
        'SK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final companyIndustry =
        _canonicalIndustry(_selectedIndustry ?? _industryCtrl.text.trim()) ??
            'Other';
    final companyName = _companyNameCtrl.text.trim().isEmpty
        ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Company')
        : _companyNameCtrl.text.trim();

    await _tokensCollection.add({
      'type': 'post',
      'title': title,
      'description': _descriptionCtrl.text.trim(),
      'company': companyName,
      'companyId': uid,
      'industry': companyIndustry,
      'location': _locationCtrl.text.trim(),
      'isPaid': _isPaidInternship,
      'salary': _isPaidInternship ? salaryText : '',
      'skills': _selectedSkills.toList(),
      'minGpa': _minGpa,
      'token': token,
      'active': true,
      'shortlisted': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _companyDoc.set({
      'ownerUid': uid,
      'name': companyName,
      'industry': companyIndustry,
      'location': _companyLocationCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'email': FirebaseAuth.instance.currentUser?.email,
      'description': _companyDescCtrl.text.trim(),
      'profileIconBase64': _companyLogoBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('internships').add({
      'title': title,
      'description': _descriptionCtrl.text.trim(),
      'company': companyName,
      'companyId': uid,
      'industry': companyIndustry,
      'location': _locationCtrl.text.trim(),
      'type': _locationCtrl.text.trim(),
      'duration': '3 months',
      'isPaid': _isPaidInternship,
      'stipend': _isPaidInternship ? salaryText : '',
      'salary': _isPaidInternship ? salaryText : '',
      'skills': _selectedSkills.toList(),
      'minGpa': _minGpa,
      'active': true,
      'postedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _saving = false);
    _titleCtrl.clear();
    _descriptionCtrl.clear();
    _manualSkillCtrl.clear();
    setState(() {
      _selectedSkills.clear();
    });
    if (closeSheet && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _createAccessToken() async {
    final role = _tokenRoleCtrl.text.trim();
    final uid = _uid;
    if (uid == null || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter internship role first.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    const maxUses = 10;
    final token =
        'TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    setState(() => _creatingToken = true);
    try {
      await _tokensCollection.add({
        'type': 'access_token',
        'title': role,
        'token': token,
        'maxUses': maxUses,
        'usedCount': 0,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _tokenRoleCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Token generated.'),
        backgroundColor: AppTheme.success,
      ));
    } finally {
      if (mounted) setState(() => _creatingToken = false);
    }
  }

  Future<void> _saveCompanyProfile() async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _savingProfile = true);
    try {
      await _companyDoc.set({
        'ownerUid': uid,
        'name': _companyNameCtrl.text.trim().isEmpty
            ? 'Company'
            : _companyNameCtrl.text.trim(),
        'industry': _canonicalIndustry(
                _selectedIndustry ?? _industryCtrl.text.trim()) ??
            'Other',
        'location': _companyLocationCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'description': _companyDescCtrl.text.trim(),
        'profileIconBase64': _companyLogoBase64,
        'notifyNewApplications': _notifyNewApplications,
        'notifyTopCandidates': _notifyTopCandidates,
        'notifyWeeklyReport': _notifyWeeklyReport,
        'email': FirebaseAuth.instance.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Company settings saved.'),
        backgroundColor: AppTheme.success,
      ));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _togglePostStatus(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final active = data['active'] != false;
    return doc.reference.set({
      'active': !active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deletePost(DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Post deleted.'),
      backgroundColor: AppTheme.warning,
    ));
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Token copied to clipboard.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sign out failed: $e'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  void openPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161637),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Post New Internship',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: _input('Internship Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locationCtrl,
                decoration: _input('Location (Remote/Onsite/Hybrid)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Paid'),
                      selected: _isPaidInternship,
                      onSelected: (_) {
                        setState(() => _isPaidInternship = true);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Non-paid'),
                      selected: !_isPaidInternship,
                      onSelected: (_) {
                        setState(() => _isPaidInternship = false);
                        setModalState(() {});
                      },
                    ),
                  ),
                ],
              ),
              if (_isPaidInternship) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _salaryCtrl,
                  decoration: _input('Salary (LKR) e.g. 35000/month'),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _saving ? null : () => _createPost(closeSheet: true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Post Internship',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: const Color(0xFF1D1D46),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF343472)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF343472)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryLight),
        ),
      );

  Widget _postInput({
    required TextEditingController controller,
    required String hint,
    String? label,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: icon == null ? null : Icon(icon, color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF17173A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF313181), width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF313181), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              const BorderSide(color: AppTheme.primaryLight, width: 1.6),
        ),
      ),
    );
  }

  Widget _settingsBlock({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _settingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF20204E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF313173)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 14)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryLight,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.45),
          )
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final companyName = _companyNameCtrl.text.trim().isEmpty
        ? 'Company'
        : _companyNameCtrl.text.trim();
    final firstLetter = companyName.substring(0, 1).toUpperCase();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final internshipIds = docs
            .where((e) => e.data()['type'] != 'access_token')
            .map((e) => e.id)
            .toSet();
        final activePosts = docs.where((e) {
          final d = e.data();
          return d['active'] != false;
        }).length;
        final shortlisted = docs.fold<int>(0, (total, e) {
          final d = e.data();
          return total + ((d['shortlisted'] as int?) ?? 0);
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    image: (_companyLogoBase64 != null &&
                            _companyLogoBase64!.length > 50)
                        ? DecorationImage(
                            image:
                                MemoryImage(base64Decode(_companyLogoBase64!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(firstLetter,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      Text(
                          (_selectedIndustry ?? 'Recruitment Admin Panel')
                              .toString(),
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('recipientId', isEqualTo: _uid ?? '')
                      .limit(200)
                      .snapshots(),
                  builder: (context, notifSnap) {
                    final unread = (notifSnap.data?.docs ?? []).where((doc) {
                      final data = doc.data();
                      return data['read'] != true;
                    }).length;

                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsCenterScreen(),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A42),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFF313173)),
                            ),
                            child: const Icon(Icons.notifications_none_rounded,
                                color: AppTheme.textSecondary),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 2,
                              top: -4,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07344F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(' Live',
                      style: TextStyle(
                          color: Color(0xFF1AE39A),
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 22),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _applicationsStream,
              builder: (context, appSnapshot) {
                final appDocs = appSnapshot.data?.docs ?? [];
                final totalApplicants = _countCompanyApplications(
                  appDocs,
                  internshipIds,
                  companyName,
                  _uid,
                );

                return Row(
                  children: [
                    Expanded(
                        child: _metricCard(
                            Icons.groups_2_outlined,
                            '$totalApplicants',
                            'Total\nApplicants',
                            const Color(0xFF2D2BB8))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _metricCard(
                            Icons.star_border_rounded,
                            '$shortlisted',
                            'Shortlisted',
                            const Color(0xFF0A8E87))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _metricCard(Icons.work_outline_rounded,
                            '$activePosts', 'Active\nPosts', AppTheme.warning)),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            const Text('Active Internship Posts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B45),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF343488)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.content_paste_off_rounded,
                        color: AppTheme.textMuted, size: 64),
                    const SizedBox(height: 10),
                    const Text('No internship posts yet',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Create your first listing from the Post tab',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  ],
                ),
              )
            else
              ...docs.map((doc) {
                final d = doc.data();
                final isActive = d['active'] != false;
                return GestureDetector(
                  onTap: () => _showPostDetails(d),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A42),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF313173)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.work_outline,
                            color: AppTheme.primaryLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['title'] as String? ?? 'Untitled',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(
                                  '${d['location'] ?? ''}  ${_displayCompensation(d)}',
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.success.withValues(alpha: 0.16)
                                : AppTheme.textMuted.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Paused',
                            style: TextStyle(
                                color: isActive
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            const Text('Top Matched Candidates',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Students ranked by AI match score from their profiles',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF313173)),
              ),
              child: const Text(
                  'Open Candidates tab to review student profiles.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCandidatesPage() {
    final companyIndustry = _normalizeIndustry(
      _selectedIndustry ?? _industryCtrl.text,
    );
    final companyName = _companyNameCtrl.text.trim();
    final companyUid = _uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream,
      builder: (context, postSnapshot) {
        final postDocs = postSnapshot.data?.docs ?? [];
        final internshipIds = postDocs
            .where((e) => e.data()['type'] != 'access_token')
            .map((e) => e.id)
            .toSet();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _studentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryLight));
            }

            var docs = snapshot.data?.docs ?? [];
            if (companyIndustry.isNotEmpty) {
              docs = docs.where((doc) {
                final data = doc.data();
                final studentIndustry = _normalizeIndustry(
                  (data['industry'] ?? data['field']) as String?,
                );
                return studentIndustry == companyIndustry;
              }).toList();
            }

            if (docs.isEmpty) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('demo_users')
                    .limit(50)
                    .snapshots(),
                builder: (context, demoSnap) {
                  var demoDocs = demoSnap.data?.docs ?? [];
                  if (companyIndustry.isNotEmpty) {
                    demoDocs = demoDocs.where((doc) {
                      final data = doc.data();
                      final studentIndustry = _normalizeIndustry(
                        (data['industry'] ?? data['field']) as String?,
                      );
                      return studentIndustry == companyIndustry;
                    }).toList();
                  }

                  if (demoDocs.isEmpty) {
                    return _emptyState(
                      icon: Icons.groups_outlined,
                      title: 'No candidates yet',
                      subtitle: companyIndustry.isEmpty
                          ? 'Student profiles will appear here once registered.'
                          : 'No students found for your selected industry yet.',
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    children: [
                      _buildAppliedCandidatesSection(
                        internshipIds,
                        companyName,
                        companyUid,
                      ),
                      const SizedBox(height: 16),
                      const Text('All Candidates',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ..._buildCandidatesCards(demoDocs),
                    ],
                  );
                },
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              children: [
                _buildAppliedCandidatesSection(
                  internshipIds,
                  companyName,
                  companyUid,
                ),
                const SizedBox(height: 16),
                const Text('All Candidates',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ..._buildCandidatesCards(docs),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openCandidateDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final candidateUid = ((data['uid'] as String?)?.trim().isNotEmpty == true)
        ? (data['uid'] as String).trim()
        : doc.id;
    final name = (data['name'] as String?) ?? 'Unknown Student';
    final email = (data['email'] as String?) ?? 'No email';
    final industry =
        (data['industry'] ?? data['field']) as String? ?? 'Unspecified';
    final age = data['age']?.toString() ?? 'Not specified';
    final experience = (data['cvExperience'] as String?) ??
        (data['experience'] as String?) ??
        'Not specified';
    final skills = ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
    final cvSkills =
        ((data['cvSkills'] as List?) ?? []).map((e) => '$e').toList();
    final summary = (data['cvSummary'] as String?) ?? '';
    final cvFileName = (data['cvFileName'] as String?) ?? '';
    final cvSignedUrl = (data['cvStorageSignedUrl'] as String?) ?? '';
    final verifiedBadges = ((data['verifiedSkills'] as List?) ??
            (data['skillsVerified'] as List?) ??
            (data['verified_skills'] as List?) ??
            <dynamic>[])
        .map((e) => '$e')
        .toList();

    final githubConnected = data['githubConnected'] == true;
    final githubUsername = (data['githubUsername'] as String?) ?? '';
    final githubRepos = data['githubRepos']?.toString() ?? '0';
    final githubFollowers = data['githubFollowers']?.toString() ?? '0';
    final githubStars = data['githubStars']?.toString() ?? '0';
    final githubLanguages =
        ((data['githubLanguages'] as List?) ?? []).map((e) => '$e').toList();

    var credentialTitles = <String>[];
    try {
      final credentials = await FirebaseFirestore.instance
          .collection('users')
          .doc(candidateUid)
          .collection('credentials')
          .limit(10)
          .get();
      credentialTitles = credentials.docs
          .map((c) => (c.data()['title'] as String?) ?? 'Credential')
          .toList();
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161637),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Text('Industry: $industry',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              Text('Age: $age',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              Text('Experience: $experience',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              if (summary.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(summary,
                    style: const TextStyle(color: AppTheme.textMuted)),
              ],
              const SizedBox(height: 14),
              const Text('CV File',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (cvFileName.trim().isNotEmpty)
                Text('File: $cvFileName',
                    style: const TextStyle(color: AppTheme.textSecondary))
              else
                const Text('No CV file metadata found.',
                    style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openExternalUrl(
                    cvSignedUrl,
                    label: 'CV download',
                  ),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download CV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24245C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Skill Test Badges',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (verifiedBadges.isEmpty)
                const Text('No verified skill badges yet.',
                    style: TextStyle(color: AppTheme.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: verifiedBadges
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 14, color: AppTheme.success),
                                const SizedBox(width: 5),
                                Text(skill,
                                    style: const TextStyle(
                                        color: AppTheme.success, fontSize: 12)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 14),
              const Text('All Skills',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (skills.isEmpty)
                const Text('No skills listed.',
                    style: TextStyle(color: AppTheme.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF23235A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(skill,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ))
                      .toList(),
                ),
              if (cvSkills.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('CV Extracted Skills',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cvSkills
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF243B4A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(skill,
                                style: const TextStyle(
                                    color: AppTheme.info, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Certificates',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (credentialTitles.isEmpty)
                const Text('No certificates/credentials found.',
                    style: TextStyle(color: AppTheme.textMuted))
              else
                ...credentialTitles.map((title) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $title',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    )),
              const SizedBox(height: 14),
              const Text('GitHub Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (!githubConnected)
                const Text('GitHub not connected',
                    style: TextStyle(color: AppTheme.textMuted))
              else ...[
                Text('Username: @$githubUsername',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                Text('Repos: $githubRepos',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                Text('Followers: $githubFollowers',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                Text('Stars: $githubStars',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                if (githubLanguages.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...githubLanguages.take(5).map(
                        (lang) => Text('• $lang',
                            style: const TextStyle(color: AppTheme.textMuted)),
                      ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCandidatesCards(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      final name = data['name'] as String? ?? 'Unknown Student';
      final email = data['email'] as String? ?? 'No email';
      final industry =
          (data['industry'] ?? data['field']) as String? ?? 'Unspecified';
      final skills =
          ((data['skills'] as List?) ?? []).map((e) => '$e').toList();

      return GestureDetector(
        onTap: () => _openCandidateDetails(doc),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A42),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF313173)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_outline,
                        color: AppTheme.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        Text(email,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 10),
              Text('Industry: $industry',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (skills.isEmpty)
                const Text('No skills listed yet',
                    style: TextStyle(color: AppTheme.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.take(6).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23235A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(skill,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget buildCandidatesList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      children: _buildCandidatesCards(docs),
    );
  }

  Widget _buildPostPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      children: [
        const Text('Post Internship',
            style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
            'Define requirements and let AI rank candidates automatically.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 18)),
        const SizedBox(height: 20),
        _postInput(
          controller: _titleCtrl,
          label: 'Role Title *',
          hint: 'e.g. Flutter Developer Intern',
          icon: Icons.work_outline,
        ),
        const SizedBox(height: 14),
        _postInput(
          controller: _descriptionCtrl,
          label: 'Job Description',
          hint: 'Describe responsibilities and what interns will learn...',
          maxLines: 4,
        ),
        const SizedBox(height: 14),
        _postInput(
          controller: _locationCtrl,
          label: 'Location',
          hint: 'e.g. Colombo, Sri Lanka',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        const Text('Compensation',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Paid'),
                selected: _isPaidInternship,
                onSelected: (_) => setState(() => _isPaidInternship = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Non-paid'),
                selected: !_isPaidInternship,
                onSelected: (_) => setState(() => _isPaidInternship = false),
              ),
            ),
          ],
        ),
        if (_isPaidInternship) ...[
          const SizedBox(height: 10),
          _postInput(
            controller: _salaryCtrl,
            label: 'Salary (LKR) *',
            hint: 'e.g. 35000/month',
            icon: Icons.payments_outlined,
          ),
        ],
        const SizedBox(height: 16),
        const Text('Required Skills *',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        const Text('Add your own required skills manually.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 10),
        if (_selectedSkills.isEmpty)
          const Text('No skills added yet',
              style: TextStyle(color: AppTheme.textMuted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSkills
                .map(
                  (skill) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23235A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(skill,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeSelectedSkill(skill),
                          child: const Icon(Icons.close,
                              size: 14, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _postInput(
                controller: _manualSkillCtrl,
                label: 'Add Skill Manually',
                hint: 'Type any custom skill',
                icon: Icons.edit_outlined,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addManualSkill,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23235A),
                foregroundColor: AppTheme.primaryLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Minimum GPA: ${_minGpa.toStringAsFixed(1)}',
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        Slider(
          value: _minGpa,
          min: 2.0,
          max: 4.0,
          divisions: 20,
          activeColor: AppTheme.primaryLight,
          inactiveColor: const Color(0xFF313173),
          onChanged: (value) => setState(() => _minGpa = value),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : () => _createPost(),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_circle_outline),
            label: const Text('Post Internship'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Recent Posts',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _postsStream,
          builder: (context, snapshot) {
            final docs = (snapshot.data?.docs ?? [])
                .where((e) => e.data()['type'] != 'access_token')
                .toList();
            if (docs.isEmpty) {
              return _emptyState(
                icon: Icons.post_add_outlined,
                title: 'No posts created',
                subtitle: 'Create your first post using the form above.',
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final active = data['active'] != false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A42),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF313173)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['title'] as String? ?? 'Untitled',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(data['token'] as String? ?? '',
                                style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _togglePostStatus(doc),
                        icon: Icon(
                          active
                              ? Icons.pause_circle_outline
                              : Icons.play_circle,
                          color: active ? AppTheme.warning : AppTheme.success,
                        ),
                        tooltip: active ? 'Pause post' : 'Activate post',
                      ),
                      IconButton(
                        onPressed: () => _deletePost(doc),
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.error),
                        tooltip: 'Delete post',
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTokensPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? [])
            .where((e) => e.data()['type'] == 'access_token')
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          children: [
            const Text('Access Tokens',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Generate unique tokens to invite qualified candidates securely.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _settingsBlock(
              title: 'Generate New Token',
              child: Column(
                children: [
                  _postInput(
                    controller: _tokenRoleCtrl,
                    hint: 'Internship Role',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _creatingToken ? null : _createAccessToken,
                      icon: _creatingToken
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.key_outlined),
                      label: const Text('+ Generate Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Your Tokens',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A42),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF313173)),
                ),
                child: const Text('No tokens yet. Generate one above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 18)),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();
                final token = data['token'] as String? ?? 'N/A';
                final active = data['active'] != false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A42),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF313173)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] as String? ?? 'Untitled',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      SelectableText(token,
                          style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              active ? 'Active' : 'Paused',
                              style: TextStyle(
                                color: active
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToken(token),
                            icon: const Icon(Icons.copy_outlined,
                                color: AppTheme.textSecondary),
                            tooltip: 'Copy token',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildSettingsPage() {
    if (_loadingProfile) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight));
    }

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final firstLetter = (_companyNameCtrl.text.trim().isEmpty
            ? 'C'
            : _companyNameCtrl.text.trim().substring(0, 1))
        .toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Company Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: _savingProfile ? null : _saveCompanyProfile,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            )
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF20204E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF313173)),
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  image: (_companyLogoBase64 != null &&
                          _companyLogoBase64!.length > 50)
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(_companyLogoBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: (_companyLogoBase64 != null &&
                        _companyLogoBase64!.length > 50)
                    ? null
                    : Text(firstLetter,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Signed in as',
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(userEmail,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _uploadingLogo ? null : _pickCompanyLogo,
                      icon: _uploadingLogo
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryLight,
                              ),
                            )
                          : const Icon(Icons.camera_alt_outlined,
                              size: 16, color: AppTheme.primaryLight),
                      label: const Text('Update profile icon',
                          style: TextStyle(color: AppTheme.primaryLight)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.business_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text('Company Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        _postInput(
          controller: _companyNameCtrl,
          label: 'Company Name',
          hint: 'medi center',
          icon: Icons.business_center_outlined,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: (_selectedIndustry != null &&
                  _industryOptions.contains(_selectedIndustry))
              ? _selectedIndustry
              : null,
          decoration: InputDecoration(
            labelText: 'Industry *',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon:
                const Icon(Icons.category_outlined, color: Colors.white),
            filled: true,
            fillColor: const Color(0xFF17173A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: Color(0xFF313181), width: 1.4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: Color(0xFF313181), width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: AppTheme.primaryLight, width: 1.6),
            ),
          ),
          dropdownColor: const Color(0xFF17173A),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          hint: const Text('Select company industry',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          items: _industryOptions
              .map((industry) => DropdownMenuItem<String>(
                    value: industry,
                    child: Text(industry),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedIndustry = value;
              _industryCtrl.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 10),
        _postInput(
          controller: _websiteCtrl,
          label: 'Website URL',
          hint: 'https://yourcompany.com',
          icon: Icons.link,
        ),
        const SizedBox(height: 10),
        _postInput(
          controller: _companyDescCtrl,
          label: 'Company Description',
          hint: 'Tell candidates about your mission and culture',
          maxLines: 4,
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Icon(Icons.notifications_none_rounded, color: AppTheme.info),
            SizedBox(width: 8),
            Text('Notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        _settingToggle(
          title: 'New Applications',
          subtitle: 'When students apply to your internships',
          value: _notifyNewApplications,
          onChanged: (v) => setState(() => _notifyNewApplications = v),
        ),
        _settingToggle(
          title: 'New Top Candidates',
          subtitle: 'When matching candidates join the platform',
          value: _notifyTopCandidates,
          onChanged: (v) => setState(() => _notifyTopCandidates = v),
        ),
        _settingToggle(
          title: 'Weekly Recruitment Report',
          subtitle: 'Summary of applicants and match stats',
          value: _notifyWeeklyReport,
          onChanged: (v) => setState(() => _notifyWeeklyReport = v),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientId', isEqualTo: _uid ?? '')
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data();
              return data['read'] != true;
            }).length;

            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsCenterScreen(),
                  ),
                ),
                icon: const Icon(Icons.inbox_outlined),
                label: Text(unreadCount > 0
                    ? 'Open App Notification Inbox ($unreadCount)'
                    : 'Open App Notification Inbox'),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.manage_accounts_outlined, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Account',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A42),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF313173)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.warning),
                title: const Text('Sign Out',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
                trailing:
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: _logout,
              ),
              const Divider(height: 1, color: Color(0xFF313173)),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppTheme.error),
                title: const Text('Delete Account',
                    style: TextStyle(color: AppTheme.error, fontSize: 20)),
                trailing:
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Delete account flow can be added next.'),
                    backgroundColor: AppTheme.warning,
                  ));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2B1D1D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF8A5A00)),
          ),
          child: const Row(
            children: [
              Icon(Icons.science_outlined, color: AppTheme.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Load Sample Data\nSeeds demo companies, students & internships',
                    style: TextStyle(color: AppTheme.warning, fontSize: 16)),
              ),
              Icon(Icons.upload_outlined, color: AppTheme.warning),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text('SkillMatch Pro - Company Portal v1.0.0',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A42),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF313173)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.textMuted, size: 48),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_nav) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildCandidatesPage();
      case 2:
        return _buildPostPage();
      case 3:
        return _buildTokensPage();
      case 4:
        return _buildSettingsPage();
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121230),
          border: Border(top: BorderSide(color: Color(0xFF23234E))),
        ),
        child: NavigationBar(
          selectedIndex: _nav,
          backgroundColor: Colors.transparent,
          onDestinationSelected: (i) => setState(() => _nav = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view_outlined), label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined), label: 'Candidates'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline), label: 'Post'),
            NavigationDestination(
                icon: Icon(Icons.key_outlined), label: 'Tokens'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 52 / 2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        ],
      ),
    );
  }
}
