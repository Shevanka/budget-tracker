import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            subtitle: const Text('Manage spending and income categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.categoryManager.path),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Budget Setup'),
            subtitle: const Text('Configure monthly budget limits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.budgetSetup.path),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Smart Recording Review'),
            subtitle: const Text('Review intercepted notifications and receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.smartRecordingReview.path),
          ),
        ],
      ),
    );
  }
}
