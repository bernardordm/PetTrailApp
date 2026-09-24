class Tour {
  const Tour({
    required this.identifier,
    required this.status,
    required this.walkerIdentifier,
    required this.tutorIdentifier,
    required this.petIdentifier,
    required this.createdAt,
    required this.updatedAt,
    this.confirmationCode,
    this.startedAt,
    this.finishedAt,
    this.price,
    this.walkerName,
    this.tutorName,
    this.petName,
    this.totalTimeSeconds,
    this.distanceMeters,
    this.path,
    this.rating,
  });

  final String identifier;
  final String status;
  final String walkerIdentifier;
  final String tutorIdentifier;
  final String petIdentifier;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? confirmationCode;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final double? price;
  final String? walkerName;
  final String? tutorName;
  final String? petName;
  final int? totalTimeSeconds;
  final double? distanceMeters;
  final Map<String, dynamic>? path;
  final int? rating;

  factory Tour.fromJson(Map<String, dynamic> json) {
    String? walkerName;
    final walker = json['walker'];
    if (walker is Map<String, dynamic>) {
      final walkerUser = walker['user'];
      if (walkerUser is Map<String, dynamic>) {
        walkerName = walkerUser['name'] as String?;
      }
    }

    String? tutorName;
    final tutor = json['tutor'];
    if (tutor is Map<String, dynamic>) {
      final tutorUser = tutor['user'];
      if (tutorUser is Map<String, dynamic>) {
        tutorName = tutorUser['name'] as String?;
      }
    }

    String? petName;
    final pet = json['pet'];
    if (pet is Map<String, dynamic>) {
      petName = pet['name'] as String?;
    }

    return Tour(
      identifier: json['identifier'] as String,
      status: json['status'] as String,
      walkerIdentifier: json['walker_identifier'] as String,
      tutorIdentifier: json['tutor_identifier'] as String,
      petIdentifier: json['pet_identifier'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      confirmationCode: json['confirmation_code'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      walkerName: walkerName,
      tutorName: tutorName,
      petName: petName,
      totalTimeSeconds: json['total_time_seconds'] as int?,
      distanceMeters: json['distance_meters'] != null
          ? double.tryParse(json['distance_meters'].toString())
          : null,
      path: json['path'] as Map<String, dynamic>?,
      rating: json['rating'] as int?,
    );
  }
}
