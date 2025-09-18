import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingPlace {
  const GeocodingPlace({required this.displayName, required this.position});

  final String displayName;
  final LatLng position;
}

class GeocodingService {
  static Future<List<GeocodingPlace>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeQueryComponent(query)}&format=json&limit=10&addressdetails=0',
    );
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'AquaView/1.0 (https://example.com)',
      },
    );
    if (response.statusCode != 200) return [];
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      final name = (item['display_name']?.toString() ?? '').trim();
      if (lat == null || lon == null || name.isEmpty) {
        return null;
      }
      return GeocodingPlace(displayName: name, position: LatLng(lat, lon));
    }).whereType<GeocodingPlace>().toList();
  }
}






