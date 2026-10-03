import 'package:flutter/material.dart';

class SmartRecordingReviewScreen extends StatelessWidget {
  const SmartRecordingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recording Review'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Draft Transactions Review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Confirm, edit, or discard detected receipts and notifications'),
          ],
        ),
      ),
    );
  }
}
