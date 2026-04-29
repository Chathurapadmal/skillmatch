import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../shared/chat_overlay.dart';

class AdminProfilePage extends StatefulWidget {
  final UserModel adminUser;

  const AdminProfilePage({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _searchCtrl = TextEditingController();

  bool _addingUser = false;
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('users');

  Future<void> _toggleBlocked({
    required String userId,
    required bool currentValue,
  }) async {
    if (userId == widget.adminUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot block your own account.')),
      );
      return;
    }

    try {
      await _usersRef.doc(userId).update({
        'isBlocked': !currentValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update block status.')),
      );
    }
  }

  Future<void> _updateRole({
    required String userId,
    required String currentRole,
    required String newRole,
  }) async {
    if (userId == widget.adminUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot change your own role from this screen.'),
        ),
      );
      return;
    }

    if (currentRole == newRole) return;

    try {
      await _usersRef.doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to ${newRole.toUpperCase()}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user role.')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    if (userId == widget.adminUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete user'),
            content: const Text(
              'This will delete the user profile document. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await _usersRef.doc(userId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user.')),
      );
    }
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'applicant';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add user'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty || !input.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Display name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'applicant',
                        child: Text('Applicant'),
                      ),
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('Company'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedRole = value);
                    },
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.pop(context, true);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );

    if (created != true) {
      emailCtrl.dispose();
      nameCtrl.dispose();
      return;
    }

    setState(() => _addingUser = true);
    try {
      final email = emailCtrl.text.trim().toLowerCase();
      final displayName = nameCtrl.text.trim().isEmpty
          ? email.split('@').first
          : nameCtrl.text.trim();
      final doc = _usersRef.doc();

      await doc.set({
        'uid': doc.id,
        'email': email,
        'displayName': displayName,
        'role': selectedRole,
        'isBlocked': false,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create user.')),
      );
    } finally {
      emailCtrl.dispose();
      nameCtrl.dispose();
      if (mounted) {
        setState(() => _addingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('User Control Center', style: TextStyle(color: Colors.white),),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF1565C0)],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addingUser ? null : _showAddUserDialog,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          icon: _addingUser
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_add_alt_1_rounded),
          label: Text(_addingUser ? 'Adding...' : 'Add User'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) =>
                    setState(() => _search = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _usersRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    if (_search.isEmpty) return true;
                    final data = doc.data();
                    final name =
                        (data['displayName'] as String? ?? '').toLowerCase();
                    final email =
                        (data['email'] as String? ?? '').toLowerCase();
                    return name.contains(_search) || email.contains(_search);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final name =
                          (data['displayName'] as String?) ?? 'Unknown';
                      final email = (data['email'] as String?) ?? '-';
                      final role = (data['role'] as String?) ?? 'applicant';
                      final isBlocked = (data['isBlocked'] as bool?) ?? false;
                      final isSelf = doc.id == widget.adminUser.uid;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(label: Text(role.toUpperCase())),
                                  if (isBlocked)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Chip(
                                        label: Text('BLOCKED'),
                                        backgroundColor: Color(0xFFFFE2E2),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    child: DropdownButtonFormField<String>(
                                      value: role,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'applicant',
                                          child: Text('Applicant'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'company',
                                          child: Text('Company'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'admin',
                                          child: Text('Admin'),
                                        ),
                                      ],
                                      onChanged: isSelf
                                          ? null
                                          : (value) {
                                              if (value == null) return;
                                              _updateRole(
                                                userId: doc.id,
                                                currentRole: role,
                                                newRole: value,
                                              );
                                            },
                                      decoration: const InputDecoration(
                                        labelText: 'Role',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: isSelf
                                        ? null
                                        : () => _toggleBlocked(
                                              userId: doc.id,
                                              currentValue: isBlocked,
                                            ),
                                    icon: Icon(
                                      isBlocked
                                          ? Icons.lock_open_rounded
                                          : Icons.block_rounded,
                                    ),
                                    label:
                                        Text(isBlocked ? 'Unblock' : 'Block'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: isSelf
                                        ? null
                                        : () => _deleteUser(doc.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
