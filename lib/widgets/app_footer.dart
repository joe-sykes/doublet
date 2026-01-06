import 'package:flutter/material.dart';

import '../screens/privacy_policy_screen.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text('© $year Daily Doublet', style: textStyle),
              Text('•', style: textStyle),
              TextButton(
                onPressed: () => showPrivacyPolicy(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              Text('•', style: textStyle),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Made for Mills ', style: textStyle),
                  const Text('❤️', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
