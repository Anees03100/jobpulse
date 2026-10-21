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

  factory JobModel.fromSkillzDunya(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    String orgName = 'Pakistan Employer';
    if (json['organization'] is Map<String, dynamic>) {
      orgName = (json['organization']['title'] as String?)?.trim() ?? 'Pakistan Employer';
    }

    final citiesList = <String>[];
    if (json['cities'] is List) {
      for (final c in json['cities']) {
        if (c is Map && c['title'] != null) {
          citiesList.add(c['title'].toString());
        }
      }
    }
    final location = citiesList.isNotEmpty
        ? '${citiesList.join(', ')}, Pakistan'
        : 'Pakistan';

    final education = json['education_required'] as String? ?? '';
    final salary = json['salary_range'] as String? ?? '';
    final description = [
      title,
      if (education.isNotEmpty) 'Education: $education',
      if (salary.isNotEmpty) 'Scale: $salary',
    ].join('. ');

    final combinedText = '$title $description'.toLowerCase();

    return JobModel(
      id: 'skillz_${json['id']}',
      title: title,
      company: orgName,
      location: location,
      type: json['is_government'] == true ? 'Government' : 'Full-time',
      description: description,
      url: json['apply_url'] ?? json['url'] ?? '',
      postedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      source: 'SkillzDunya',
      skills: _extractSkills(combinedText),
      isRemote: combinedText.contains('remote'),
    );
  }

  factory JobModel.fromRemotive(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final rawDesc = (json['description'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .trim();
    final description = rawDesc.length > 300
        ? '${rawDesc.substring(0, 300)}...'
        : rawDesc;
    final combinedText = '$title $description'.toLowerCase();
    final candLoc = (json['candidate_required_location'] as String? ?? 'Worldwide').trim();

    return JobModel(
      id: 'remotive_${json['id']}',
      title: title,
      company: json['company_name'] ?? 'Tech Company',
      location: candLoc.isEmpty ? 'Remote (Worldwide)' : 'Remote ($candLoc)',
      type: json['job_type'] ?? 'Full-time',
      description: description,
      url: json['url'] ?? '',
      postedAt: DateTime.tryParse(json['publication_date'] ?? '') ?? DateTime.now(),
      source: 'Remotive',
      skills: _extractSkills(combinedText),
      isRemote: true,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'type': type,
      'description': description,
      'url': url,
      'postedAt': postedAt.toIso8601String(),
      'source': source,
      'skills': skills,
      'isRemote': isRemote,
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id'],
      title: map['title'],
      company: map['company'],
      location: map['location'],
      type: map['type'],
      description: map['description'],
      url: map['url'],
      postedAt: DateTime.tryParse(map['postedAt'] ?? '') ?? DateTime.now(),
      source: map['source'],
      skills: List<String>.from(map['skills'] ?? []),
      isRemote: map['isRemote'] ?? false,
    );
  }
}
