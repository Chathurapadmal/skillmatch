import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatOverlay extends StatefulWidget {
  final Widget child;

  const ChatOverlay({super.key, required this.child});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // 🔥 Your custom nav height (important)
    const double navBarHeight = 90;

    return Stack(
      children: [
        widget.child,

        /// BACKDROP
        if (_showChat)
          GestureDetector(
            onTap: () => setState(() => _showChat = false),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

        /// CHAT PANEL
        if (_showChat)
          _ChatPanel(
            onClose: () => setState(() => _showChat = false),
          ),

        /// FLOATING BUTTON (FIXED POSITION)
        if (!_showChat)
          Positioned(
            right: 16,
            bottom: safeBottom + navBarHeight,
            child: FloatingActionButton(
              onPressed: () => setState(() => _showChat = true),
              backgroundColor: const Color(0xFF4F8CFF),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final VoidCallback onClose;

  const _ChatPanel({required this.onClose});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageCtrl = TextEditingController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hello! I am SkillMatch AI Support. Ask me anything about internships, applications, notifications, or settings.',
      fromUser: false,
    ),
  ];

  bool _sending = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _animationController.dispose();
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
        reply = 'I could not generate a response.';
      }
    } catch (_) {
      reply = 'Cannot reach chat API. Try again later.';
    }

    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: reply, fromUser: false));
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: safeBottom, // ✅ respects system + nav
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: 10 + safeBottom),
              child: Column(
                children: [
                  /// HEADER
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F8CFF), Color(0xFF7B61FF)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.smart_toy, color: Color(0xFF4F8CFF)),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'SkillMatch AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),

                  /// MESSAGES
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];

                        return Align(
                          alignment: m.fromUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              gradient: m.fromUser
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF4F8CFF),
                                        Color(0xFF7B61FF)
                                      ],
                                    )
                                  : null,
                              color: m.fromUser
                                  ? null
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// INPUT
                  Container(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 16 + safeBottom),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageCtrl,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: "Ask support...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _sending ? null : _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF4F8CFF), Color(0xFF7B61FF)],
                              ),
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
                                : const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
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

class _ChatMessage {
  final String text;
  final bool fromUser;

  const _ChatMessage({
    required this.text,
    required this.fromUser,
  });
}
