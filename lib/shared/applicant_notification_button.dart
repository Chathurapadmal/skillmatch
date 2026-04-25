import 'package:flutter/material.dart';

class ApplicantNotificationButton extends StatelessWidget {
  const ApplicantNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifications clicked")),
        );
      },
    );
  }
}
