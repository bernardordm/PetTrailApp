class ProfileData {
  const ProfileData({
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.document,
    this.walkPrice,
    this.available,
    this.averageRideTime,
    this.averageRating,
    this.photoUrl,
  });

  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? document;
  final double? walkPrice;
  final bool? available;
  final int? averageRideTime;
  final double? averageRating;
  final String? photoUrl;
}
