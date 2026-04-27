import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/ai_service.dart';
import '../shared/chat_overlay.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);

class DashboardTab extends StatefulWidget {
  final bool firebaseEnabled;
  final String? startupMessage;

  const DashboardTab({
    super.key,
    this.firebaseEnabled = true,
    this.startupMessage,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _loading = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.startupMessage ?? "Tap the button to test AI";
  }

  Future<void> _testFirebaseConnection() async {
    if (!widget.firebaseEnabled) {
      setState(() {
        _status =
            "Firebase test is disabled on this platform. Run on Android, iOS, Web, macOS, or Windows.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _status = "Testing Firebase connection...";
    });

    try {
      final app = Firebase.app();

      await FirebaseFirestore.instance
          .collection('_connection_test')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() {
        _status =
            "✅ Firebase connected\nApp: ${app.name}\nProject: ${app.options.projectId}";
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = "❌ Firebase connection failed\n${e.runtimeType}: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _testAI() async {
    setState(() {
      _loading = true;
      _status = "Calling AI...";
    });

    try {
      final result = await AiService.testAI().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception(
          'Request timed out after 45s — this is usually App Check token/API propagation. Retry in 2-3 minutes.',
        ),
      );

      if (!mounted) return;

      setState(() {
        _status =
            result?.trim().isNotEmpty == true ? result! : "AI returned no text";
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = "AI error type: ${e.runtimeType}\n$e";
      });

      debugPrint("AI ERROR TYPE: ${e.runtimeType}");
      debugPrint("AI ERROR: $e");
      debugPrintStack();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatOverlay(
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Dashboard',
            style: TextStyle(color: _navy),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navy, _primary, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dashboard,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to SkillMatch',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your dashboard for tracking job matches and career progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _loading ? null : _testAI,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primary,
                            ),
                          )
                        : const Text(
                            "Test AI",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    onPressed: (!_loading && widget.firebaseEnabled)
                        ? _testFirebaseConnection
                        : null,
                    child: const Text(
                      "Test Firebase",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}