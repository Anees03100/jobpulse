class JobModel {
  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.description,
    required this.url,
    required this.postedAt,
    required this.source,
    this.skills = const [],
    this.isRemote = false,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String type; // e.g. 'Full-time', 'Internship' (best-effort from source)
  final String description;
  final String url;
  final DateTime postedAt;
  final String source; // 'Adzuna', etc.
  final List<String> skills; // extracted from title/description
  final bool isRemote;

  factory JobModel.fromAdzuna(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final description = (json['description'] as String? ?? '').trim();
    final combinedText = '$title $description'.toLowerCase();

    return JobModel(
      id: 'adzuna_${json['id']}',
      title: title,
      company: json['company']?['display_name'] ?? 'Unknown Company',
      location: json['location']?['display_name'] ?? 'Unknown Location',
      type: json['contract_time'] ?? json['contract_type'] ?? 'Full-time',
      description: description,
      url: json['redirect_url'] ?? '',
      postedAt: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      source: 'Adzuna',
      skills: _extractSkills(combinedText),
      isRemote: combinedText.contains('remote'),
    );
  }

  factory JobModel.fromJooble(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final snippet = (json['snippet'] as String? ?? '').trim();
    final combinedText = '$title $snippet'.toLowerCase();

    return JobModel(
      id: 'jooble_${json['id']}',
      title: title,
      company: (json['company'] as String?)?.trim().isNotEmpty == true
          ? json['company']
          : 'Unknown Company',
      location: json['location'] ?? 'Pakistan',
      type: json['type'] ?? 'Full-time',
      description: snippet,
      url: json['link'] ?? '',
      postedAt: DateTime.tryParse(json['updated'] ?? '') ?? DateTime.now(),
      source: 'Jooble',
      skills: _extractSkills(combinedText),
      isRemote: combinedText.contains('remote'),
    );
  }

  /// Very simple keyword-matching skill extraction — checks description/title
  /// text against a known skill vocabulary. Good enough for v1; can be
  /// swapped for a smarter NLP approach later.
  static List<String> _extractSkills(String text) {
    const knownSkills = [
      'flutter',
      'dart',
      'firebase',
      'react',
      'node.js',
      'java',
      'python',
      'php',
      'android',
      'ios',
      'kotlin',
      'swift',
      'ui/ux',
      'figma',
      'machine learning',
      'data science',
      'artificial intelligence',
      'javascript',
      'typescript',
      'sql',
      'aws',
      'docker',
    ];
    return knownSkills.where((skill) => text.contains(skill)).toList();
  }
}
