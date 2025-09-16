import 'dart:convert';
import 'package:http/http.dart' as http;

class DwlrReading {
  const DwlrReading({
    required this.ph,
    required this.tds,
    required this.impuritiesDescription,
    required this.hardnessCategory,
    required this.levelMeters,
    required this.trend,
  });

  final double ph;
  final int tds;
  final String impuritiesDescription;
  final String hardnessCategory; // e.g., Soft, Hard, Very Soft
  final double levelMeters;
  final String trend; // Rising/Falling/Stable
}

class DwlrService {
  static Future<DwlrReading?> fetchByLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Placeholder: Public DWLR endpoints differ by state/agency.
      // Here we call a mock endpoint or return synthetic data when unavailable.
      final uri = Uri.parse('https://example.invalid/dwlr?lat=$latitude&lon=$longitude');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return DwlrReading(
          ph: (data['ph'] as num).toDouble(),
          tds: (data['tds'] as num).toInt(),
          impuritiesDescription: data['impurities'] as String? ?? 'Unknown',
          hardnessCategory: data['hardness'] as String? ?? 'Unknown',
          levelMeters: (data['level_m'] as num).toDouble(),
          trend: data['trend'] as String? ?? 'Stable',
        );
      }
    } catch (_) {
      // Fall through to synthetic
    }

    // Synthetic fallback approximated from lat/lon to keep UI functional
    final ph = 6.8 + ((latitude.abs() + longitude.abs()) % 4) / 10.0; // 6.8 - 7.2
    final tds = 200 + ((latitude.abs() * 1000 + longitude.abs() * 1000) % 200).toInt();
    final hardness = tds > 350 ? 'Hard' : tds > 250 ? 'Moderate' : 'Soft';
    final trend = ((latitude.floor() + longitude.floor()) % 3) == 0 ? 'Rising' : 'Stable';
    return DwlrReading(
      ph: double.parse(ph.toStringAsFixed(2)),
      tds: tds,
      impuritiesDescription: tds > 350 ? 'High dissolved solids' : tds > 250 ? 'Moderate' : 'Low',
      hardnessCategory: hardness,
      levelMeters: 10.0 + ((latitude.abs() + longitude.abs()) % 3),
      trend: trend,
    );
  }
}


