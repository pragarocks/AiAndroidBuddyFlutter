enum PetStat { patience, snark, wisdom, chaos, care }

class PetProfile {
  final String petId;
  final String name;
  final String species;
  final PetStat peakStat;
  final PetStat dumpStat;
  final String speechStyle;

  const PetProfile({
    required this.petId,
    required this.name,
    required this.species,
    required this.peakStat,
    required this.dumpStat,
    required this.speechStyle,
  });

  factory PetProfile.defaults() => const PetProfile(
    petId: 'axobotl',
    name: 'Axobotl',
    species: 'axolotl',
    peakStat: PetStat.care,
    dumpStat: PetStat.snark,
    speechStyle: 'short and playful',
  );

  Map<String, String> toJson() => {
    'petId': petId, 'name': name, 'species': species,
    'peakStat': peakStat.name, 'dumpStat': dumpStat.name,
    'speechStyle': speechStyle,
  };

  factory PetProfile.fromJson(Map<String, String> j) => PetProfile(
    petId: j['petId']!,
    name: j['name']!,
    species: j['species']!,
    peakStat: PetStat.values.byName(j['peakStat']!),
    dumpStat: PetStat.values.byName(j['dumpStat']!),
    speechStyle: j['speechStyle']!,
  );

  PetProfile copyWith({
    String? petId, String? name, String? species,
    PetStat? peakStat, PetStat? dumpStat, String? speechStyle,
  }) => PetProfile(
    petId: petId ?? this.petId,
    name: name ?? this.name,
    species: species ?? this.species,
    peakStat: peakStat ?? this.peakStat,
    dumpStat: dumpStat ?? this.dumpStat,
    speechStyle: speechStyle ?? this.speechStyle,
  );
}
