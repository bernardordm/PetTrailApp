class WalkerReport {
  final DateTime? startDate;
  final DateTime? endDate;

  final double totalEarnings;
  final double totalDistanceMeters;
  final int totalTimeSeconds;
  final double completionRate;
  final double averageTimeSeconds;
  final double averageDistanceMeters;
  final double averageRating;

  WalkerReport({
    required this.startDate,
    required this.endDate,
    required this.totalEarnings,
    required this.totalDistanceMeters,
    required this.totalTimeSeconds,
    required this.completionRate,
    required this.averageTimeSeconds,
    required this.averageDistanceMeters,
    required this.averageRating,
  });

  factory WalkerReport.fromJson(Map<String, dynamic> json) {
    final period = json['period'];

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return WalkerReport(
      startDate: period is Map ? parseDate(period['startDate']) : null,
      endDate: period is Map ? parseDate(period['endDate']) : null,
      totalEarnings: parseDouble(json['totalEarnings']),
      totalDistanceMeters: parseDouble(json['totalDistanceMeters']),
      totalTimeSeconds: parseInt(json['totalTimeSeconds']),
      completionRate: parseDouble(json['completionRate']),
      averageTimeSeconds: parseDouble(json['averageTimeSeconds']),
      averageDistanceMeters: parseDouble(json['averageDistanceMeters']),
      averageRating: parseDouble(json['averageRating']),
    );
  }
}
