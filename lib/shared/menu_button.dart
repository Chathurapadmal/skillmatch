import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillmatch/pages/applicant/profile/profilepage.dart';
import 'package:skillmatch/pages/applicant/settings/help_support_screen.dart';
import 'package:skillmatch/pages/applicant/settings/privacy_security_screen.dart';
import 'package:skillmatch/services/auth_service.dart';
import 'package:skillmatch/theme/app_theme.dart';
import 'package:skillmatch/theme/skillmatch_theme.dart';
import 'backend_settings_dialog.dart';

class ApplicantDashboardMenuButton extends StatefulWidget {
  final String? displayName;
  final String? email;

  const ApplicantDashboardMenuButton({
    super.key,
    this.displayName,
    this.email,
  });

  @override
  State<ApplicantDashboardMenuButton> createState() =>
      _ApplicantDashboardMenuButtonState();
}

class _ApplicantDashboardMenuButtonState
    extends State<ApplicantDashboardMenuButton> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  void _toggleMenu() {
    if (_overlayEntry == null) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }

  void _showMenu() {
    final overlay = Overlay.of(context);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    const menuWidth = 280.0;
    const menuHeight = 245.0;

    final left = buttonOffset.dx.clamp(12.0, screenSize.width - menuWidth - 12);
    final top = buttonOffset.dy + buttonSize.height + 10;
    final isTooLow = top + menuHeight > screenSize.height - 16;
    final resolvedTop = isTooLow
        ? (buttonOffset.dy - menuHeight - 10)
            .clamp(12.0, screenSize.height - menuHeight - 12)
        : top;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: resolvedTop,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Opacity(
                      opacity: (scale - 0.92) / 0.08,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topRight,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: SkillMatchTheme.menuGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildMenuContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _openProfile() async {
    _hideMenu();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  Future<void> _openHelp() async {
    _hideMenu();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
    );
  }

  Future<void> _openPrivacy() async {
    _hideMenu();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
    );
  }

  void _openBackendSettings() {
    _hideMenu();
    if (!mounted) return;
    showBackendSettingsDialog(context);
  }

  Future<void> _signOut() async {
    _hideMenu();
    await AuthService.signOut();
  }

  Widget _buildMenuContent() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final resolvedEmail =
        (widget.email ?? currentUser?.email ?? '').trim().isEmpty
            ? 'No email'
            : (widget.email ?? currentUser?.email ?? '').trim();
    final resolvedName =
        (widget.displayName ?? currentUser?.displayName ?? '').trim().isEmpty
            ? resolvedEmail
            : (widget.displayName ?? currentUser?.displayName ?? '').trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resolvedEmail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _MenuActionTile(
          icon: Icons.person_outline,
          label: 'My Profile',
          onTap: _openProfile,
        ),
        _MenuActionTile(
          icon: Icons.support_agent_outlined,
          label: 'Help & Support',
          onTap: _openHelp,
        ),
        _MenuActionTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy & Security',
          onTap: _openPrivacy,
        ),
        _MenuActionTile(
          icon: Icons.router_outlined,
          label: 'Backend Server',
          onTap: _openBackendSettings,
        ),
        _MenuActionTile(
          icon: Icons.logout,
          label: 'Sign Out',
          iconColor: Colors.white,
          labelColor: Colors.white,
          onTap: _signOut,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menu',
      icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ),
      onPressed: _toggleMenu,
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;

  const _MenuActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
    this.labelColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
