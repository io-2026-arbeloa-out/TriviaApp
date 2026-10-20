enum SessionStatus {
  inProgress,
  finished,
  waiting,
  aborted;

  String toJson() => name;

  static SessionStatus fromJson(dynamic json) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => throw FormatException('Unknown session status: $json'),
    );
  }
}

enum RoundPhase {
  answering,
  resolving,
  finished;

  static RoundPhase fromJson(dynamic value) => values.firstWhere(
    (phase) => phase.name == value,
    orElse: () => throw FormatException('Unknown round phase: $value'),
  );
}
