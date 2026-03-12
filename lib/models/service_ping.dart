class ServicePing {
  final String name;
  final String target;
  final String method;
  final double currentPing;
  final double jitter;
  final List<double> history;

  ServicePing({
    required this.name,
    required this.target,
    this.method = 'smart',
    required this.currentPing,
    required this.jitter,
    required this.history,
  });

  factory ServicePing.fromJson(Map<String, dynamic> json) {
    return ServicePing(
      name: json['name'] ?? 'Unknown',
      target: json['target'] ?? '0.0.0.0',
      method: json['method'] ?? 'smart',
      currentPing: (json['ping'] ?? 0).toDouble(),
      jitter: (json['jitter'] ?? 0).toDouble(),
      history: json['history'] != null
          ? List<double>.from(json['history'].map((v) => v.toDouble()))
          : List.generate(15, (_) => (json['ping'] ?? 0).toDouble()),
    );
  }
}
