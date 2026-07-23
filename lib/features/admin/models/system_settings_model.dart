class SystemSettingsModel {
  final double pilotRatePerAcre;
  final double copilotRatePerAcre;

  SystemSettingsModel({
    required this.pilotRatePerAcre,
    required this.copilotRatePerAcre,
  });

  Map<String, dynamic> toMap() {
    return {
      'pilotRatePerAcre': pilotRatePerAcre,
      'copilotRatePerAcre': copilotRatePerAcre,
    };
  }

  factory SystemSettingsModel.fromMap(Map<String, dynamic> map) {
    return SystemSettingsModel(
      pilotRatePerAcre: (map['pilotRatePerAcre'] as num?)?.toDouble() ?? 50.0,
      copilotRatePerAcre: (map['copilotRatePerAcre'] as num?)?.toDouble() ?? 30.0,
    );
  }
}
