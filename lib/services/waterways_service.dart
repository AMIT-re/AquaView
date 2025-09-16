import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WaterSourceMarker {
  const WaterSourceMarker({
    required this.position,
    required this.name,
    required this.type,
  });

  final LatLng position;
  final String name; // e.g., Spring name
  final String type; // e.g., spring
}

class Waterway {
  const Waterway({
    required this.name,
    required this.kind,
    required this.points,
  });

  final String name; // e.g., Ganges
  final String kind; // river|stream|canal|drain|ditch
  final List<LatLng> points;
}

class WaterwaysResult {
  const WaterwaysResult({
    required this.waterways,
    required this.sources,
  });

  final List<Waterway> waterways;
  final List<WaterSourceMarker> sources;
}

class WaterwaysService {
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  static Future<WaterwaysResult> fetchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    final query = _buildQuery(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters);
    http.Response? lastResponse;

    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .post(Uri.parse(endpoint), body: {'data': query})
            .timeout(const Duration(seconds: 25));
        lastResponse = response;

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          return _parseResponseBody(response.body);
        }
      } catch (_) {
        // try next endpoint
      }
    }

    // If all mirrors failed but we have a response, attempt parse once
    if (lastResponse != null && lastResponse.statusCode == 200 && lastResponse.body.isNotEmpty) {
      return _parseResponseBody(lastResponse.body);
    }

    return const WaterwaysResult(waterways: [], sources: []);
  }

  static WaterwaysResult _parseResponseBody(String body) {
    final map = json.decode(body) as Map<String, dynamic>;
    final elements = (map['elements'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final List<Waterway> waterways = [];
    final List<WaterSourceMarker> sources = [];

    for (final e in elements) {
      final type = e['type'] as String?;
      final tags = (e['tags'] as Map<String, dynamic>?) ?? const {};

      if (type == 'way' && tags.containsKey('waterway')) {
        final geometry = (e['geometry'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final points = geometry
            .map((g) => LatLng((g['lat'] as num).toDouble(), (g['lon'] as num).toDouble()))
            .toList(growable: false);
        final name = (tags['name'] as String?) ?? 'Unnamed';
        final kind = (tags['waterway'] as String?) ?? 'unknown';
        if (points.length >= 2) {
          waterways.add(Waterway(name: name, kind: kind, points: points));
        }
      } else if (type == 'node' && tags['natural'] == 'spring') {
        final lat = (e['lat'] as num).toDouble();
        final lon = (e['lon'] as num).toDouble();
        final name = (tags['name'] as String?) ?? 'Spring';
        sources.add(WaterSourceMarker(position: LatLng(lat, lon), name: name, type: 'spring'));
      }
    }

    return WaterwaysResult(waterways: waterways, sources: sources);
  }

  static String _buildQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    // Overpass QL: fetch waterways and springs around a point with geometry for ways
    return '''
[out:json][timeout:25];
(
  way["waterway"~"river|stream|canal|drain|ditch"](around:$radiusMeters,$latitude,$longitude);
  node["natural"="spring"](around:$radiusMeters,$latitude,$longitude);
);
(._;>;);
out body geom;
''';
  }
}
