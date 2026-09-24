class NearbyWalker {
  const NearbyWalker({
    required this.identifier,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String identifier;
  final String name;
  final double latitude;
  final double longitude;

  factory NearbyWalker.fromJson(Map<String, dynamic> json) {
    return NearbyWalker(
      identifier: json['id']?.toString() ?? json['identifier']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latitude: _asDouble(json['latitude']) ?? 0,
      longitude: _asDouble(json['longitude']) ?? 0,
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
