import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _initialized = false;
  String _email = '';
  String _role = 'applicant';

  User get _user => FirebaseAuth.instance.currentUser!;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.collection('users').doc(_user.uid);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _docRef.get();
      final data = doc.data() ?? <String, dynamic>{};

      if (!mounted) return;

      _nameCtrl.text = (data['displayName'] as String?) ??
          (_user.displayName ?? '').trim();
      _headlineCtrl.text = (data['headline'] as String?) ?? '';
      _locationCtrl.text = (data['location'] as String?) ?? '';
      _bioCtrl.text = (data['bio'] as String?) ?? '';

      final skills = (data['skills'] as List?)?.cast<String>() ?? <String>[];
      _skillsCtrl.text = skills.join(', ');

      _email = (data['email'] as String?) ?? (_user.email ?? '');
      _role = (data['role'] as String?) ?? 'applicant';
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final displayName = _nameCtrl.text.trim();
    final headline = _headlineCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    try {
      await _docRef.set({
        'displayName': displayName,
        'headline': headline,
        'location': location,
        'bio': bio,
        'skills': skills,
        'email': _email,
        'role': _role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if ((_user.displayName ?? '').trim() != displayName) {
        await _user.updateDisplayName(displayName);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _loadProfile();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: $_email'),
                          const SizedBox(height: 4),
                          Text('Role: ${_role.toUpperCase()}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value?.trim().isEmpty ?? true)) {
                          return 'Name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _headlineCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Headline',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _skillsCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Skills (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
