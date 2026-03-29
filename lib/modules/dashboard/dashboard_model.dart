class DashboardModel {
  final double riskScore;
  final int dependencies;
  final int vulnerabilities;

  DashboardModel({
    required this.riskScore,
    required this.dependencies,
    required this.vulnerabilities,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      riskScore: (json['riskScore'] ?? 0).toDouble(),
      dependencies: (json['dependencies'] ?? 0) as int,
      vulnerabilities: (json['vulnerabilities'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "riskScore": riskScore,
      "dependencies": dependencies,
      "vulnerabilities": vulnerabilities,
    };
  }
}
