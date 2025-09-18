import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GroundwaterSite {
  final int siteId;
  final String siteName;
  final String district;
  final double lat;
  final double lon;
  final String type;

  GroundwaterSite({
    required this.siteId,
    required this.siteName,
    required this.district,
    required this.lat,
    required this.lon,
    required this.type,
  });

  factory GroundwaterSite.fromJson(Map<String, dynamic> json) {
    return GroundwaterSite(
      siteId: json['OBJECTID'],
      siteName: json['SITENAME'] ?? "Unknown",
      district: json['DISTRICT'] ?? "Unknown",
      lat: (json['LATITUDE'] ?? 0).toDouble(),
      lon: (json['LONGITUDE'] ?? 0).toDouble(),
      type: json['SITETYPE'] ?? "N/A",
    );
  }
}

class GroundwaterService {
  static Future<List<GroundwaterSite>> fetchSites() async {
    final url = Uri.parse(
      "https://arc.indiawris.gov.in/server/rest/services/eSwis/GWSITESALL/MapServer/0/query"
      "?where=STATE%3D%27UTTAR+PRADESH%27+AND+DISTRICT%3D%27GAUTAM+BUDDHA+NAGAR%27&outFields=*&f=json",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception("API error: ${response.statusCode} ${response.reasonPhrase}");
      }
      final data = jsonDecode(response.body);
      final features = data['features'] as List?;
      if (features == null || features.isEmpty) {
        throw Exception("No sites found for Gautam Buddha Nagar");
      }
      return features.map((e) => GroundwaterSite.fromJson(e['attributes'])).toList();
    } catch (e) {
      throw Exception("Failed to fetch groundwater data: $e");
    }
  }
}
