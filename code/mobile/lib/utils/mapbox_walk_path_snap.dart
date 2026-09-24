import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:pet_trail/utils/geo_utils.dart';

/// Mapbox Map Matching accepts at most 100 coordinates per request.
const int mapboxMatchingMaxInputPoints = 90;

List<LatLng> dedupeCloseConsecutivePoints(
  List<LatLng> points, {
  double minSeparationMeters = 4,
}) {
  if (points.length < 2) return List<LatLng>.from(points);
  final out = <LatLng>[points.first];
  for (var i = 1; i < points.length; i++) {
    final p = points[i];
    final last = out.last;
    final km = haversineDistance(
      last.latitude,
      last.longitude,
      p.latitude,
      p.longitude,
    );
    if (km * 1000 >= minSeparationMeters) {
      out.add(p);
    }
  }
  if (out.length < 2 && points.length >= 2) {
    return [points.first, points.last];
  }
  return out;
}

List<LatLng> subsamplePathToMaxPoints(List<LatLng> points, int maxPoints) {
  final cleaned = dedupeCloseConsecutivePoints(points);
  if (cleaned.length <= maxPoints) return cleaned;
  final out = <LatLng>[];
  for (var i = 0; i < maxPoints; i++) {
    final t = maxPoints == 1 ? 0.0 : i / (maxPoints - 1);
    final idx = (t * (cleaned.length - 1)).round().clamp(0, cleaned.length - 1);
    out.add(cleaned[idx]);
  }
  return dedupeCloseConsecutivePoints(out, minSeparationMeters: 2);
}

/// Returns a dense path snapped to walkable roads, or `null` if the API fails.
Future<List<LatLng>?> fetchMapboxWalkingMatchedPath({
  required List<LatLng> rawPoints,
  required String mapboxAccessToken,
}) async {
  if (mapboxAccessToken.isEmpty || rawPoints.length < 2) return null;
  final sampled = subsamplePathToMaxPoints(rawPoints, mapboxMatchingMaxInputPoints);
  if (sampled.length < 2) return null;

  final coordPath = sampled
      .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
      .join(';');
  final encodedPath = Uri.encodeComponent(coordPath);
  final uri = Uri.parse(
    'https://api.mapbox.com/matching/v5/mapbox/walking/$encodedPath'
    '?geometries=geojson&overview=full&steps=false'
    '&access_token=${Uri.encodeQueryComponent(mapboxAccessToken)}',
  );

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'];
    if (code != null && code != 'Ok') return null;
    final matchings = body['matchings'] as List<dynamic>?;
    if (matchings == null || matchings.isEmpty) return null;
    final geometry = matchings.first['geometry'] as Map<String, dynamic>?;
    if (geometry == null || geometry['type'] != 'LineString') return null;
    final coords = geometry['coordinates'] as List<dynamic>?;
    if (coords == null || coords.length < 2) return null;

    final out = <LatLng>[];
    for (final c in coords) {
      if (c is! List || c.length < 2) continue;
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      out.add(LatLng(lat, lng));
    }
    return out.length >= 2 ? out : null;
  } catch (_) {
    return null;
  }
}
