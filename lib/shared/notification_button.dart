import 'package:flutter/material.dart';
import 'package:skillmatch/shared/menu_button.dart';
import 'package:skillmatch/shared/notifications_center_screen.dart';
import 'package:skillmatch/theme/app_theme.dart';

class ApplicantNotificationButton extends StatelessWidget {
  final Color iconColor;

  const ApplicantNotificationButton({
    super.key,
    this.iconColor = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: Icon(Icons.notifications_outlined, color: iconColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsCenterScreen(),
              ),
            );
          },
        ),
        const ApplicantDashboardMenuButton(),
      ],
    );
  }
}
