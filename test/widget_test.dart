// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:jobpulse/models/job_model.dart';
import 'package:jobpulse/models/user_preferences_model.dart';
import 'package:jobpulse/services/matching/matching_engine.dart';

void main() {
  testWidgets('JobPulse smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('JobPulse'),
          ),
        ),
      ),
    );

    expect(find.text('JobPulse'), findsOneWidget);
  });

  group('MatchingEngine Location & Recency Tests', () {
    const rawalpindiPrefs = UserPreferences(
      country: 'Pakistan',
      cities: ['Rawalpindi'],
      skills: ['Flutter', 'Dart'],
      remote: false,
    );

    final now = DateTime.now();

    final rawalpindiJob = JobModel(
      id: '1',
      title: 'Flutter Developer',
      company: 'Tech House',
      location: 'Rawalpindi, Pakistan',
      type: 'Full-time',
      description: 'Flutter and Dart',
      url: 'https://example.com/1',
      postedAt: now.subtract(const Duration(hours: 2)),
      source: 'Test',
      skills: const ['flutter', 'dart'],
    );

    final islamabadTwinCityJob = JobModel(
      id: '2',
      title: 'Senior Flutter Developer',
      company: 'Twin City Tech',
      location: 'Islamabad, Pakistan',
      type: 'Full-time',
      description: 'Flutter mobile',
      url: 'https://example.com/2',
      postedAt: now.subtract(const Duration(days: 1)),
      source: 'Test',
      skills: const ['flutter'],
    );

    final usJobFrom317DaysAgo = JobModel(
      id: '3',
      title: 'Mobile Application Developer',
      company: 'US Tech',
      location: 'San Leandro, CA',
      type: 'Full-time',
      description: 'Flutter and Dart',
      url: 'https://example.com/3',
      postedAt: now.subtract(const Duration(days: 317)),
      source: 'Jooble',
      skills: const ['flutter', 'dart'],
    );

    final staleRawalpindiJob50DaysAgo = JobModel(
      id: '4',
      title: 'Junior Developer',
      company: 'Old Corp',
      location: 'Rawalpindi, Pakistan',
      type: 'Full-time',
      description: 'Flutter mobile',
      url: 'https://example.com/4',
      postedAt: now.subtract(const Duration(days: 50)),
      source: 'Jooble',
      skills: const ['flutter'],
    );

    test('rejects foreign location jobs when Pakistan/Rawalpindi is selected', () {
      expect(MatchingEngine.isLocationEligible(usJobFrom317DaysAgo, rawalpindiPrefs), isFalse);
      expect(MatchingEngine.isLocationEligible(rawalpindiJob, rawalpindiPrefs), isTrue);
      expect(MatchingEngine.isLocationEligible(islamabadTwinCityJob, rawalpindiPrefs), isTrue);
    });

    test('scoreAndSort filters out stale jobs (> 45 days) and foreign jobs', () {
      final input = [
        usJobFrom317DaysAgo,
        staleRawalpindiJob50DaysAgo,
        islamabadTwinCityJob,
        rawalpindiJob,
      ];

      final results = MatchingEngine.scoreAndSort(input, rawalpindiPrefs);

      // Only the 2 fresh Pakistan/Rawalpindi/Islamabad jobs should be present
      expect(results.length, equals(2));
      final ids = results.map((r) => r.job.id).toList();
      expect(ids.contains('3'), isFalse); // 317 days ago US job filtered out
      expect(ids.contains('4'), isFalse); // 50 days ago stale job filtered out
    });

    test('scoreAndSort displays recent listed jobs on top (newest first)', () {
      final input = [
        islamabadTwinCityJob, // 1 day ago
        rawalpindiJob,         // 2 hours ago
      ];

      final results = MatchingEngine.scoreAndSort(input, rawalpindiPrefs);

      expect(results.first.job.id, equals('1')); // 2 hours ago is on TOP
      expect(results.last.job.id, equals('2'));  // 1 day ago is below
    });
  });
}
