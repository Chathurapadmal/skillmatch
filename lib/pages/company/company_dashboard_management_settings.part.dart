part of 'company_dashboard.dart';

class _InternshipManagementTab extends StatefulWidget {
  final String companyId;
  final String companyName;

  const _InternshipManagementTab({
    required this.companyId,
    required this.companyName,
  });

  @override
  State<_InternshipManagementTab> createState() =>
      _InternshipManagementTabState();
}

class _InternshipManagementTabState extends State<_InternshipManagementTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _aboutRoleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _compensationCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _minGpaCtrl = TextEditingController();

  bool _publishing = false;
  String _mode = 'Remote';
  String _postType = 'Internship';
  String _duration = 'Not specified';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _aboutRoleCtrl.dispose();
    _locationCtrl.dispose();
    _compensationCtrl.dispose();
    _skillsCtrl.dispose();
    _minGpaCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final aboutRole = _aboutRoleCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final compensation = _compensationCtrl.text.trim();
    final minGpaText = _minGpaCtrl.text.trim();
    final minGpa = double.tryParse(minGpaText);

    final skills = _skillsCtrl.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (title.isEmpty || description.isEmpty || skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Title, description, and required skills are required.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    if (minGpaText.isNotEmpty && minGpa == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid number for minimum GPA.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() => _publishing = true);

    try {
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .get();
      final companyData = companyDoc.data() ?? <String, dynamic>{};

      await FirebaseFirestore.instance.collection('internships').add({
        'companyId': widget.companyId,
        'company': widget.companyName,
        'postType': _postType,
        'title': title,
        'description': description,
        'aboutRole': aboutRole,
        'location': location.isEmpty ? _mode : location,
        'type': _mode,
        'duration': _duration,
        'salary': compensation.isEmpty ? 'Negotiable' : compensation,
        'stipend': compensation.isEmpty ? 'Negotiable' : compensation,
        'skills': skills,
        'minimumGpa': minGpa,
        'industry': (companyData['industry'] as String?) ?? '',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _titleCtrl.clear();
      _descCtrl.clear();
      _aboutRoleCtrl.clear();
      _locationCtrl.clear();
      _compensationCtrl.clear();
      _skillsCtrl.clear();
      _minGpaCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Internship post published.'),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to publish internship post: $e'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) {
        setState(() => _publishing = false);
      }
    }
  }

  Future<void> _togglePostStatus(
      DocumentReference<Map<String, dynamic>> ref, bool active) async {
    await ref.set({
      'active': !active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deletePost(DocumentReference<Map<String, dynamic>> ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Internship Post?'),
        content: const Text('This will permanently remove this internship.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ref.delete();
  }

  Widget _buildCreateInternshipPostCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2E86AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.post_add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Internship Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Structure the role, work setup, compensation, and required skills before publishing.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPostFormSection(
                  icon: Icons.badge_outlined,
                  title: 'Role Details',
                  subtitle:
                      'Give applicants a clear overview of the opportunity.',
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Software Engineer Intern',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Role responsibilities and outcomes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aboutRoleCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'About the Role',
                        hintText:
                            'Team, impact, and key expectations for this role',
                        prefixIcon: Icon(Icons.auto_stories_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPostFormSection(
                  icon: Icons.tune_rounded,
                  title: 'Post Setup',
                  subtitle:
                      'Define the post type, work mode, location, and duration.',
                  children: [
                    _buildResponsiveFieldRow([
                      DropdownButtonFormField<String>(
                        value: _postType,
                        decoration: const InputDecoration(
                          labelText: 'Post Type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Internship',
                            child: Text('Internship'),
                          ),
                          DropdownMenuItem(
                            value: 'Job',
                            child: Text('Job'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _postType = value);
                        },
                      ),
                      TextField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Colombo / Remote',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildResponsiveFieldRow([
                      DropdownButtonFormField<String>(
                        value: _mode,
                        decoration: const InputDecoration(
                          labelText: 'Work Mode',
                          prefixIcon: Icon(Icons.laptop_mac_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Remote',
                            child: Text('Remote'),
                          ),
                          DropdownMenuItem(
                            value: 'Onsite',
                            child: Text('Onsite'),
                          ),
                          DropdownMenuItem(
                            value: 'Hybrid',
                            child: Text('Hybrid'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _mode = value);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: _duration,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          prefixIcon: Icon(Icons.schedule_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Not specified',
                            child: Text('Not specified'),
                          ),
                          DropdownMenuItem(
                            value: '1 month',
                            child: Text('1 month'),
                          ),
                          DropdownMenuItem(
                            value: '3 months',
                            child: Text('3 months'),
                          ),
                          DropdownMenuItem(
                            value: '6 months',
                            child: Text('6 months'),
                          ),
                          DropdownMenuItem(
                            value: '12 months',
                            child: Text('12 months'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _duration = value);
                        },
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPostFormSection(
                  icon: Icons.payments_outlined,
                  title: 'Compensation & Eligibility',
                  subtitle:
                      'Set stipend expectations and applicant requirements.',
                  children: [
                    _buildResponsiveFieldRow([
                      TextField(
                        controller: _compensationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Salary/Stipend',
                          hintText: 'LKR 45,000 / month',
                          prefixIcon:
                              Icon(Icons.account_balance_wallet_outlined),
                        ),
                      ),
                      TextField(
                        controller: _minGpaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Minimum GPA',
                          hintText: '3.0',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPostFormSection(
                  icon: Icons.psychology_outlined,
                  title: 'Required Skills',
                  subtitle:
                      'Separate skills with commas so applicants can be matched accurately.',
                  children: [
                    TextField(
                      controller: _skillsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Required Skills',
                        hintText: 'Flutter, Firebase, REST',
                        prefixIcon: Icon(Icons.handyman_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _publishing ? null : _publishPost,
                    icon: _publishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.publish_outlined),
                    label: Text(_publishing ? 'Publishing...' : 'Publish Post'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFormSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponsiveFieldRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCreateInternshipPostCard(),
        const SizedBox(height: 14),
        const Text(
          'Recent Posts',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('internships')
              .where('companyId', isEqualTo: widget.companyId)
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = (snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .toList();
            docs.sort((a, b) {
              final at = a.data()['createdAt'] as Timestamp?;
              final bt = b.data()['createdAt'] as Timestamp?;
              return (bt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(at?.millisecondsSinceEpoch ?? 0);
            });

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            if (docs.isEmpty) {
              return const _EmptyPanel(
                icon: Icons.work_outline,
                message: 'No internship posts yet.',
              );
            }

            return Column(
              children: docs.take(10).map((doc) {
                final data = doc.data();
                final active = data['active'] != false;
                final aboutRole = (data['aboutRole'] as String? ?? '').trim();
                final skills =
                    ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE3F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (data['title'] as String?) ?? 'Internship',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Switch(
                            value: active,
                            activeColor: const Color(0xFF1565C0),
                            onChanged: (_) =>
                                _togglePostStatus(doc.reference, active),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(data['postType'] as String?) ?? 'Internship'} • ${(data['type'] as String?) ?? 'Mode'} • ${(data['location'] as String?) ?? ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${(data['duration'] as String?) ?? 'Not specified'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Compensation: ${(data['salary'] as String?) ?? (data['stipend'] as String?) ?? 'Negotiable'}',
                        style: const TextStyle(color: Color(0xFF1565C0)),
                      ),
                      if (aboutRole.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'About the Role: $aboutRole',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      if (skills.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .take(8)
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      skill,
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _deletePost(doc.reference),
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          label: const Text('Delete',
                              style: TextStyle(color: AppTheme.error)),
                        ),
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
}

class _TokenManagementTab extends StatelessWidget {
  final String companyId;

  const _TokenManagementTab({required this.companyId});

  Future<void> _generateToken(BuildContext context) async {
    final token = _randomToken();
    await FirebaseFirestore.instance.collection('company_tokens').add({
      'companyId': companyId,
      'token': token,
      'role': 'candidate_access',
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Access token generated.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _toggleTokenStatus(
      DocumentReference<Map<String, dynamic>> ref, bool active) async {
    await ref.set({
      'active': !active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _randomToken() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final chars =
        List.generate(16, (_) => alphabet[rand.nextInt(alphabet.length)]);
    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAccessTokenHeader(context),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('company_tokens')
              .where('companyId', isEqualTo: companyId)
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = (snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .toList();
            docs.sort((a, b) {
              final at = a.data()['createdAt'] as Timestamp?;
              final bt = b.data()['createdAt'] as Timestamp?;
              return (bt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(at?.millisecondsSinceEpoch ?? 0);
            });

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            final activeTokens = docs.where((doc) {
              final data = doc.data();
              return data['active'] != false;
            }).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTokenListHeader(
                  totalTokens: docs.length,
                  activeTokens: activeTokens,
                ),
                const SizedBox(height: 10),
                if (docs.isEmpty)
                  const _EmptyPanel(
                    icon: Icons.key_off_outlined,
                    message: 'No tokens created yet.',
                  )
                else
                  ...docs.map((doc) {
                    final data = doc.data();
                    final token = (data['token'] as String?) ?? '';
                    final role =
                        (data['role'] as String?) ?? 'candidate_access';
                    final active = data['active'] != false;
                    final createdAt = data['createdAt'] as Timestamp?;

                    return _buildTokenCard(
                      context: context,
                      token: token,
                      role: role,
                      active: active,
                      createdAt: createdAt,
                      onToggle: () => _toggleTokenStatus(doc.reference, active),
                    );
                  }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccessTokenHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2E86AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Access Tokens',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Generate, copy, pause, and reactivate candidate access tokens for controlled hiring workflows.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3EAF5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1565C0).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.key_outlined,
                          color: Color(0xFF1565C0),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate a New Token',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Creates a secure 16-character token with candidate access permissions.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _generateToken(context),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Generate Token'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildTokenListHeader({
    required int totalTokens,
    required int activeTokens,
  }) {
    final pausedTokens = totalTokens - activeTokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.vpn_key_outlined,
              color: Color(0xFF1565C0),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Token Inventory',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review active and paused access credentials.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _buildCountChip(
                label: 'Total',
                value: '$totalTokens',
                color: const Color(0xFF1565C0),
              ),
              _buildCountChip(
                label: 'Active',
                value: '$activeTokens',
                color: AppTheme.success,
              ),
              if (pausedTokens > 0)
                _buildCountChip(
                  label: 'Paused',
                  value: '$pausedTokens',
                  color: AppTheme.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard({
    required BuildContext context,
    required String token,
    required String role,
    required bool active,
    required Timestamp? createdAt,
    required VoidCallback onToggle,
  }) {
    final statusColor = active ? AppTheme.success : AppTheme.warning;
    final statusLabel = active ? 'ACTIVE' : 'PAUSED';
    final actionLabel = active ? 'Pause Token' : 'Activate Token';
    final actionIcon = active
        ? Icons.pause_circle_outline_rounded
        : Icons.play_circle_outline_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  active ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            token,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(
                          label: statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaChip(
                          icon: Icons.verified_user_outlined,
                          text: 'Role: $role',
                        ),
                        _buildMetaChip(
                          icon: Icons.calendar_today_outlined,
                          text: createdAt == null
                              ? 'Created just now'
                              : 'Created: ${_fmtDate(createdAt)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              final copyButton = OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: token));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Token copied.'),
                    backgroundColor: AppTheme.success,
                  ));
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Token'),
              );
              final toggleButton = TextButton.icon(
                onPressed: onToggle,
                icon: Icon(actionIcon),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: active ? AppTheme.warning : AppTheme.success,
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copyButton,
                    const SizedBox(height: 8),
                    toggleButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: copyButton),
                  const SizedBox(width: 10),
                  Expanded(child: toggleButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5A6C83)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5A6C83),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _CompanySettingsTab extends StatefulWidget {
  final String companyId;
  final String initialCompanyName;
  final String email;

  const _CompanySettingsTab({
    required this.companyId,
    required this.initialCompanyName,
    required this.email,
  });

  @override
  State<_CompanySettingsTab> createState() => _CompanySettingsTabState();
}

class _CompanySettingsTabState extends State<_CompanySettingsTab> {
  static const String _profileBucket = 'profile';

  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();

  bool _notifyNewApplications = true;
  bool _notifyCandidateSuggestions = true;
  bool _darkMode = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;

  static const List<String> _industryOptions = [
    'IT & Software',
    'Business & Management',
    'Design & UX/UI',
    'Engineering',
    'Healthcare',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .get();
    final data = doc.data() ?? <String, dynamic>{};

    if (!mounted) return;

    _nameCtrl.text = (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : widget.initialCompanyName;
    _industryCtrl.text = (data['industry'] as String?) ?? '';
    _websiteCtrl.text = (data['website'] as String?) ?? '';
    _descriptionCtrl.text = (data['description'] as String?) ?? '';
    _logoCtrl.text = (data['logoUrl'] as String?) ?? '';
    _notifyNewApplications = data['notifyNewApplications'] as bool? ?? true;
    _notifyCandidateSuggestions =
        data['notifyCandidateSuggestions'] as bool? ?? true;
    _darkMode = (data['appearanceMode'] as String? ?? 'light') == 'dark';

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .set({
      'name': _nameCtrl.text.trim(),
      'industry': _industryCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'logoUrl': _logoCtrl.text.trim(),
      'notifyNewApplications': _notifyNewApplications,
      'notifyCandidateSuggestions': _notifyCandidateSuggestions,
      'appearanceMode': _darkMode ? 'dark' : 'light',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Company profile and preferences updated.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _pickIndustry() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF161A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _industryOptions
              .map(
                (option) => ListTile(
                  leading: Icon(
                    _industryCtrl.text.trim() == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _industryCtrl.text.trim() == option
                        ? AppTheme.primaryLight
                        : AppTheme.textSecondary,
                  ),
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, option),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    setState(() => _industryCtrl.text = selected);
  }

  Future<void> _uploadCompanyLogoToSupabase() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = file.extension?.toLowerCase() ?? 'jpg';
    final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'jpg';
    final path =
        'companies/${widget.companyId}/logo_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    setState(() => _uploadingLogo = true);
    try {
      final storage = Supabase.instance.client.storage.from(_profileBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final signedUrl = await storage.createSignedUrl(path, 60 * 60 * 24 * 7);
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .set({
        'logoUrl': signedUrl,
        'logoStorageBucket': _profileBucket,
        'logoStoragePath': path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _logoCtrl.text = signedUrl);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Company logo uploaded to Supabase $_profileBucket bucket.'),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('bucket not found') ||
          message.contains('statuscode: 404')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Supabase bucket "profile" not found. Please create it in Supabase Storage.'),
          backgroundColor: AppTheme.warning,
        ));
      } else if (message.contains('statuscode: 403') ||
          message.contains('row-level security') ||
          message.contains('unauthorized') ||
          message.contains('permission denied')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Supabase policy denied upload (403). Allow INSERT/SELECT on bucket "profile" for anon and authenticated roles.'),
          backgroundColor: AppTheme.warning,
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsHeader(),
        const SizedBox(height: 14),
        _buildSettingsSection(
          icon: Icons.business_center_outlined,
          title: 'Company Profile',
          subtitle:
              'Keep your company identity visible to candidates and hiring workflows.',
          children: [
            _buildResponsiveSettingsRow([
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              _buildIndustryPickerTile(),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://company.com',
                prefixIcon: Icon(Icons.language_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Company Description',
                hintText: 'Briefly describe your company, culture, and mission',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSettingsSection(
          icon: Icons.image_outlined,
          title: 'Brand Assets',
          subtitle: 'Add or upload a company logo for a more complete profile.',
          children: [
            TextField(
              controller: _logoCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Company Logo URL',
                hintText: 'Paste a hosted logo URL',
                prefixIcon: Icon(Icons.link_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _buildLogoPreview(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _uploadingLogo ? null : _uploadCompanyLogoToSupabase,
                icon: _uploadingLogo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _uploadingLogo
                      ? 'Uploading logo...'
                      : 'Upload Company Logo (Supabase)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFFB8C7DC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSettingsSection(
          icon: Icons.notifications_active_outlined,
          title: 'Notification Preferences',
          subtitle: 'Choose the company updates you want to receive.',
          children: [
            _buildSettingsSwitchTile(
              icon: Icons.assignment_ind_outlined,
              title: 'New applications',
              subtitle: 'Notify me when candidates apply to company posts.',
              value: _notifyNewApplications,
              onChanged: (value) {
                setState(() => _notifyNewApplications = value);
              },
            ),
            const SizedBox(height: 10),
            _buildSettingsSwitchTile(
              icon: Icons.people_alt_outlined,
              title: 'Candidate suggestions',
              subtitle:
                  'Receive updates about matched or recommended profiles.',
              value: _notifyCandidateSuggestions,
              onChanged: (value) {
                setState(() => _notifyCandidateSuggestions = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSettingsSection(
          icon: Icons.tune_outlined,
          title: 'Workspace Controls',
          subtitle:
              'Manage appearance, storage, policy pages, and account access.',
          children: [
            _buildSettingsSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark appearance mode',
              subtitle: 'Preference is saved for this account.',
              value: _darkMode,
              onChanged: (value) => setState(() => _darkMode = value),
            ),
            const SizedBox(height: 14),
            _buildResponsiveSettingsRow([
              _buildSettingsActionButton(
                icon: Icons.inbox_outlined,
                label: 'Notification Inbox',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsCenterScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsActionButton(
                icon: Icons.cloud_outlined,
                label: 'Supabase Storage',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupabaseStoragePage(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 10),
            _buildResponsiveSettingsRow([
              _buildSettingsActionButton(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              _buildSettingsActionButton(
                icon: Icons.security_outlined,
                label: 'Security',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _SecurityPage(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 10),
            _buildSettingsActionButton(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _TermsOfServicePage(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSaveSettingsButton(),
        const SizedBox(height: 8),
        _buildSignOutButton(),
      ],
    );
  }

  Widget _buildSettingsHeader() {
    final companyName = _nameCtrl.text.trim().isEmpty
        ? widget.initialCompanyName
        : _nameCtrl.text.trim();
    final industry = _industryCtrl.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2E86AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.settings_suggest_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  companyName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeaderPill(
                      icon: Icons.mail_outline,
                      text: widget.email,
                    ),
                    _buildHeaderPill(
                      icon: Icons.apartment_outlined,
                      text: industry.isEmpty ? 'Industry not set' : industry,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildIndustryPickerTile() {
    final industry = _industryCtrl.text.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: _pickIndustry,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Industry',
          prefixIcon: Icon(Icons.apartment_outlined),
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          industry.isEmpty ? 'Select industry' : industry,
          style: TextStyle(
            color: industry.isEmpty ? Colors.black45 : const Color(0xFF1565C0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPreview() {
    final logoUrl = _logoCtrl.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFEAF1FB),
              child: logoUrl.isEmpty
                  ? const Icon(
                      Icons.business,
                      size: 34,
                      color: Color(0xFF1565C0),
                    )
                  : Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.business,
                        size: 34,
                        color: Color(0xFF1565C0),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logo Preview',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  logoUrl.isEmpty
                      ? 'No logo URL added yet. Upload or paste one above.'
                      : 'Logo URL is set and will be saved with your profile.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF1565C0).withValues(alpha: 0.10)
                  : Colors.grey.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: value ? const Color(0xFF1565C0) : Colors.grey,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF1565C0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF1E3A5F),
          side: const BorderSide(
            color: Color(0xFFD5DEEC),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveSettingsButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_outlined, size: 20),
        label: Text(
          _saving ? 'Saving settings...' : 'Save Changes',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: _saving ? 2 : 4,
          shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.3),
          backgroundColor: const Color(0xFF1565C0),
          disabledBackgroundColor:
              const Color(0xFF1565C0).withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton.icon(
        onPressed: () => AuthService.signOut(),
        icon: const Icon(Icons.logout, size: 18, color: AppTheme.error),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.error,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.error.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: AppTheme.error,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveSettingsRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}
// ============================================================================
// Interview Scheduling Dialog
// ============================================================================
