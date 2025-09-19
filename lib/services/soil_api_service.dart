// import 'dart:math';
import 'package:latlong2/latlong.dart';

class SoilQuality {
  final String region;
  final String soilType;
  final String quality;
  final List<String> suitableCrops;
  final double ph;
  final double organicCarbon;

  SoilQuality({
    required this.region,
    required this.soilType,
    required this.quality,
    required this.suitableCrops,
    required this.ph,
    required this.organicCarbon,
  });
}

class SoilApiService {
  // Mock: Returns soil quality for a given location (lat/lng)
  static Future<SoilQuality> getSoilQualityForLocation(LatLng location) async {
    // In a real app, call an API here. This is a mock for Indian regions.
    final regions = [
      {
        'region': 'Indo-Gangetic Plain',
        'soilType': 'Alluvial',
        'quality': 'High',
        'crops': ['Wheat', 'Rice', 'Sugarcane', 'Maize'],
        'ph': 7.2,
        'organicCarbon': 0.7,
      },
      {
        'region': 'Deccan Plateau',
        'soilType': 'Black (Regur)',
        'quality': 'Medium',
        'crops': ['Cotton', 'Soybean', 'Sorghum', 'Pulses'],
        'ph': 7.8,
        'organicCarbon': 0.6,
      },
      {
        'region': 'Coastal Plains',
        'soilType': 'Laterite',
        'quality': 'Medium',
        'crops': ['Coconut', 'Cashew', 'Rice', 'Spices'],
        'ph': 6.5,
        'organicCarbon': 0.5,
      },
      {
        'region': 'Western Rajasthan',
        'soilType': 'Desert',
        'quality': 'Low',
        'crops': ['Millets', 'Barley', 'Mustard'],
        'ph': 8.1,
        'organicCarbon': 0.3,
      },
      {
        'region': 'Eastern India',
        'soilType': 'Red & Yellow',
        'quality': 'Medium',
        'crops': ['Paddy', 'Groundnut', 'Potato'],
        'ph': 6.8,
        'organicCarbon': 0.4,
      },
    ];
    // Simple mock: pick region by lat bands
    final lat = location.latitude;
    Map<String, dynamic> regionData;
    if (lat >= 25 && lat <= 30) {
      regionData = regions[0]; // Indo-Gangetic Plain
    } else if (lat >= 15 && lat < 25) {
      regionData = regions[1]; // Deccan Plateau
    } else if (lat < 15 && lat > 8) {
      regionData = regions[2]; // Coastal Plains
    } else if (lat >= 23 && lat < 29 && location.longitude < 78) {
      regionData = regions[3]; // Western Rajasthan
    } else {
      regionData = regions[4]; // Eastern India
    }
    await Future.delayed(const Duration(milliseconds: 400));
    return SoilQuality(
      region: regionData['region'],
      soilType: regionData['soilType'],
      quality: regionData['quality'],
      suitableCrops: List<String>.from(regionData['crops']),
      ph: regionData['ph'],
      organicCarbon: regionData['organicCarbon'],
    );
  }
}
