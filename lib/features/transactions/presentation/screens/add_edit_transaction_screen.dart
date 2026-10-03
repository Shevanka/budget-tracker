import 'package:flutter/material.dart';

class AddEditTransactionScreen extends StatelessWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
  });

  final String? transactionId;

  bool get isEditing => transactionId != null && transactionId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEditing ? Icons.edit_note : Icons.add_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isEditing
                  ? 'Editing Transaction ($transactionId)'
                  : 'Record New Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
