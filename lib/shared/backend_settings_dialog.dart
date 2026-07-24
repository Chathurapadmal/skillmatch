import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class BackendSettingsDialog extends StatefulWidget {
  const BackendSettingsDialog({Key? key}) : super(key: key);

  @override
  State<BackendSettingsDialog> createState() => _BackendSettingsDialogState();
}

class _BackendSettingsDialogState extends State<BackendSettingsDialog> {
  late TextEditingController _urlController;
  String _currentUrl = '';
  String _statusMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    try {
      final url = await ApiService.getCurrentBackendUrl();
      setState(() {
        _currentUrl = url;
        _urlController.text = url;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading URL: $e';
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _statusMessage = 'URL cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
    });

    try {
      // Try /health first (local development)
      var response = await http
          .get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) {
        // Try /api/health (Vercel deployment)
        response = await http
            .get(Uri.parse('$url/api/health'))
            .timeout(const Duration(seconds: 3));
      }

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = '✓ Connection successful!';
          _currentUrl = url;
        });
      } else {
        setState(
          () => _statusMessage =
              '✗ Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() => _statusMessage = '✗ Connection failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveBackendUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL cannot be empty')),
      );
      return;
    }

    ApiService.setBackendUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backend URL set to: $url')),
    );
    Navigator.of(context).pop(url);
  }

  void _resetToDefault() {
    ApiService.resetBackendUrl();
    _urlController.clear();
    setState(() {
      _statusMessage = 'Reset to auto-detection mode';
      _currentUrl = '';
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Backend Server Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Current Backend URL:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _currentUrl.isNotEmpty ? _currentUrl : 'Auto-detecting...',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Manually Set Backend URL:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'e.g., http://192.168.1.100:5000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                readOnly: _isLoading,
              ),
              const SizedBox(height: 12),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusMessage.startsWith('✓')
                          ? Colors.green
                          : _statusMessage.startsWith('✗')
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: const Text('Test Connection'),
                      onPressed: _isLoading ? null : _testConnection,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save URL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _saveBackendUrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Auto-Detection'),
                onPressed: _resetToDefault,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'How to find your backend server IP:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. On the machine running the backend, open a terminal/command prompt\n'
                      '2. Run: ipconfig (Windows) or ifconfig/hostname -I (Mac/Linux)\n'
                      '3. Look for your local IP (usually starts with 192.168.x.x or 10.0.x.x)\n'
                      '4. Use that IP with port 5000: http://YOUR_IP:5000\n'
                      '5. If running on the same machine: http://localhost:5000',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget to show the backend settings from anywhere
void showBackendSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const BackendSettingsDialog(),
  );
}
