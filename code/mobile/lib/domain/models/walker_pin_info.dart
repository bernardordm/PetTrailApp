class WalkerPinInfo {
  const WalkerPinInfo({
    required this.walkPrice,
    required this.averageRideTime,
    required this.averageRating,
  });

  final double? walkPrice;
  final double? averageRideTime;
  final double? averageRating;

  factory WalkerPinInfo.fromJson(Map<String, dynamic> json) {
    return WalkerPinInfo(
      walkPrice: _toDouble(json['walkPrice']),
      averageRideTime: _toDouble(json['averageRideTime']),
      averageRating: _toDouble(json['averageRating']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
