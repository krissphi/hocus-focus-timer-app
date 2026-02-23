import 'package:flutter/material.dart';

class DialogLayout extends StatelessWidget {
  const DialogLayout({
    super.key,
    required this.isEditing,
    required this.onSave,
    required this.buildFormFields,
  });

  final bool isEditing;
  final VoidCallback onSave;
  final Widget Function(BuildContext context) buildFormFields;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing == true ? 'Edit Activity' : 'Add Activity'),
      content: SingleChildScrollView(
        child: SizedBox(width: 420, child: buildFormFields(context)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onSave,
          child: Text(isEditing == true ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
