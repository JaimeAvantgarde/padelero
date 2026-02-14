/// Configuración del partido de pádel.
enum DeuceType {
  goldenPoint, // Siguiente punto gana
  advantages,  // Necesitas 2 puntos de diferencia (AD-40 → Juego)
}

enum TieBreakType {
  normal,      // Primero a 7, diferencia de 2
  superTieBreak, // Primeros a 10, diferencia de 2 (último set)
}

class MatchConfig {
  const MatchConfig({
    this.numberOfSets = 3,
    this.deuceType = DeuceType.advantages, // En pádel 40-40 suele ser ventajas
    this.lastSetTieBreak = TieBreakType.normal,
    this.firstServer = 1, // 1 o 2 — quién saca primero
  });

  final int numberOfSets; // 1, 3, o 5
  final DeuceType deuceType;
  final TieBreakType lastSetTieBreak;
  final int firstServer; // 1 o 2

  MatchConfig copyWith({
    int? numberOfSets,
    DeuceType? deuceType,
    TieBreakType? lastSetTieBreak,
    int? firstServer,
  }) {
    return MatchConfig(
      numberOfSets: numberOfSets ?? this.numberOfSets,
      deuceType: deuceType ?? this.deuceType,
      lastSetTieBreak: lastSetTieBreak ?? this.lastSetTieBreak,
      firstServer: firstServer ?? this.firstServer,
    );
  }

  Map<String, dynamic> toJson() => {
        'numberOfSets': numberOfSets,
        'deuceType': deuceType.name,
        'lastSetTieBreak': lastSetTieBreak.name,
        'firstServer': firstServer,
      };

  factory MatchConfig.fromJson(Map<String, dynamic> json) => MatchConfig(
        numberOfSets: json['numberOfSets'] as int? ?? 3,
        deuceType: DeuceType.values.firstWhere(
          (e) => e.name == json['deuceType'],
          orElse: () => DeuceType.advantages,
        ),
        lastSetTieBreak: TieBreakType.values.firstWhere(
          (e) => e.name == json['lastSetTieBreak'],
          orElse: () => TieBreakType.normal,
        ),
        firstServer: json['firstServer'] as int? ?? 1,
      );
}
