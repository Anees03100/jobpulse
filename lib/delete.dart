import 'package:flutter/material.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import 'package:jobpulse/widgets/butons/secondary_button.dart';

class Delete extends StatefulWidget {
  const Delete({super.key});

  @override
  State<Delete> createState() => _DeleteState();
}

class _DeleteState extends State<Delete> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete')),
      body: Column(
        children: [
          const Center(
            child: Text(
              'Daniyal',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          PrimaryButton(
            label: 'De',
            onPressed: () {
              // Handle delete action
            },
          ),
          SecondaryButton(
            label: 'Cancel',
            onPressed: () {
              // Handle cancel action
            },
          ),
        ],
      ),
    );
  }
}
