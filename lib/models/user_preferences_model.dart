class UserPreferences {
  const UserPreferences({
    this.opportunityTypes = const [],
    this.skills = const [],
    this.country,
    this.cities = const [],
    this.remote = false,
    this.hybrid = false,
  });

  final List<String> opportunityTypes;
  final List<String> skills;
  final String? country;
  final List<String> cities;
  final bool remote;
  final bool hybrid;

  UserPreferences copyWith({
    List<String>? opportunityTypes,
    List<String>? skills,
    String? country,
    List<String>? cities,
    bool? remote,
    bool? hybrid,
  }) {
    return UserPreferences(
      opportunityTypes: opportunityTypes ?? this.opportunityTypes,
      skills: skills ?? this.skills,
      country: country ?? this.country,
      cities: cities ?? this.cities,
      remote: remote ?? this.remote,
      hybrid: hybrid ?? this.hybrid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opportunityTypes': opportunityTypes,
      'skills': skills,
      'country': country,
      'cities': cities,
      'remote': remote,
      'hybrid': hybrid,
    };
  }
}
