enum SessionStatus {
  lobby,
  finished,
  waiting,
  answering,
  resolving,
  aborted;

  String toJson() => name;

  static SessionStatus fromJson(dynamic json) {
    if (json is! String) return SessionStatus.aborted;

    return SessionStatus.values.firstWhere(
          (e) => e.name == json,
      orElse: () => SessionStatus.aborted,
    );
  }
}