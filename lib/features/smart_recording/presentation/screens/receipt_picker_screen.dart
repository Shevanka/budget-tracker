import 'package:flutter/material.dart';

/// Screen allowing the user to select or capture a receipt photo via camera/gallery.
class ReceiptPickerScreen extends StatelessWidget {
  const ReceiptPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Receipt Scanner',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Capture a photo or pick an image from gallery'),
          ],
        ),
      ),
    );
  }
}
