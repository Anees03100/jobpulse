import 'package:flutter/material.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import 'package:jobpulse/widgets/butons/secondary_button.dart';
import 'package:jobpulse/widgets/cards/app_card.dart';
import 'package:jobpulse/widgets/cards/opportunity_card.dart';
import 'package:jobpulse/widgets/cards/selectable_chip.dart';
import 'package:jobpulse/widgets/indicators/match_score_badge.dart';
import 'package:jobpulse/widgets/inputs/app_text_field.dart';

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
          PrimaryButton(
            label: 'Delete',
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
          SelectableChip(label: "he", selected: true, onTap: () {}),
          SelectableChip(label: "she", selected: false, onTap: () {}),
          MatchScoreBadge(score: 85, compact: true),
          MatchScoreCircle(score: 90, label: 'Good Match'),
          AppCard(child: Text('This is an AppCard')),
          AppTextField(
            label: 'Enter text',
            onChanged: (value) {
              // Handle text change
            },
          ),
          OpportunityCard(
            title: 'Software Engineer',
            company: 'Tech Corp',
            location: 'San Francisco, CA',
            type: 'Full-time',
            matchScore: 90,
            postedTime: '2 days ago',
            skills: ['Flutter', 'Dart', 'Firebase'],
            isSaved: false,
            onTap: () {
              // Handle card tap
            },
            onSaveToggle: () {
              // Handle save toggle
            },
          ),
        ],
      ),
    );
  }
}
