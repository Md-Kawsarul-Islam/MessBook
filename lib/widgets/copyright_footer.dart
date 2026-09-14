import 'package:flutter/material.dart';

class CopyrightFooter extends StatelessWidget {
  final Color textColor;

  const CopyrightFooter({super.key, this.textColor = Colors.grey});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '© $currentYear Md Kawsarul Islam. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Developer & Admin: Md Kawsarul Islam',
            style: TextStyle(fontSize: 12, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Contact: info.kawsarulislam@gmail.com',
            style: TextStyle(fontSize: 12, color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
