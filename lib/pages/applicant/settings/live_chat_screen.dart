import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../shared/notification_button.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFDCE3F0);
const Color _mutedText = Color(0xFF64748B);

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Hello! I am SkillMatch AI Support. Ask me anything about internships, applications, notifications, or settings.',
      fromUser: false,
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _sending = true;
      _messageCtrl.clear();
    });

    final history = _messages
        .map((m) => '${m.fromUser ? 'User' : 'AI'}: ${m.text}')
        .toList();

    String reply;
    try {
      reply = await ApiService.sendMessage(
        text,
        recentMessages: history,
      );
      if (reply.trim().isEmpty) {
        reply = 'I could not generate a response right now. Please try again.';
      }
    } catch (_) {
      reply =
          'I can\'t reach the chat API right now. Please check backend and try again.';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, fromUser: false));
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text('Live AI Chat Support'),
        actions: const [ApplicantNotificationButton(iconColor: _navy)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final bubbleColor = m.fromUser ? _primary : Colors.white;
                final bubbleBorder = m.fromUser ? _accent : _cardBorder;
                final textColor = m.fromUser ? Colors.white : _navy;

                return Align(
                  alignment:
                      m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 290),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bubbleBorder),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _cardBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      style: const TextStyle(color: _navy),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask support... ',
                        hintStyle: const TextStyle(color: _mutedText),
                        filled: true,
                        fillColor: _background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: _primary,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
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
}

class _ChatMessage {
  final String text;
  final bool fromUser;

  const _ChatMessage({required this.text, required this.fromUser});
}