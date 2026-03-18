class LoadoutPreset {
  final String name;
  final Map<String, int> weaponCounts;

  const LoadoutPreset({
    required this.name,
    required this.weaponCounts,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weaponCounts': weaponCounts,
  };

  factory LoadoutPreset.fromJson(Map<String, dynamic> json) => LoadoutPreset(
    name: json['name'] as String,
    weaponCounts: Map<String, int>.from(json['weaponCounts'] as Map),
  );
}
