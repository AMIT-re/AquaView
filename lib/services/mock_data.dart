class WaterQualityData {
  const WaterQualityData({
    required this.ph,
    required this.tds,
    required this.impurities,
    required this.status,
    required this.trend,
  });

  final double ph;
  final int tds;
  final String impurities;
  final String status;
  final String trend;
}

class WaterLevelData {
  const WaterLevelData({
    required this.currentLevel,
    required this.forecast24h,
    required this.status,
    required this.trend,
    required this.historicalData,
  });

  final double currentLevel;
  final double forecast24h;
  final String status;
  final String trend;
  final List<double> historicalData;
}

class AlertData {
  const AlertData({
    required this.type,
    required this.message,
    required this.severity,
    this.timestamp,
  });

  final String type;
  final String message;
  final String severity;
  final DateTime? timestamp;
}

class MockDataService {

  static const WaterQualityData getWaterQuality = WaterQualityData(
    ph: 7.2,
    tds: 250,
    impurities: 'Low',
    status: 'Safe',
    trend: 'Stable',
  );

  static const WaterLevelData getWaterLevel = WaterLevelData(
    currentLevel: 12.5,
    forecast24h: 12.8,
    status: 'Rising',
    trend: 'Stable Rise',
    historicalData: [11.8, 12.0, 12.2, 12.3, 12.4, 12.5, 12.5],
  );

  static List<AlertData> getCitizenAlerts() {
    return const [
      AlertData(
        type: 'system_status',
        message: 'All systems normal. Your water is safe.',
        severity: 'info',
        timestamp: null,
      ),
    ];
  }

  static List<AlertData> getFarmerAlerts() {
    return const [
      AlertData(
        type: 'water_scarcity',
        message: 'Groundwater levels are stable this season.',
        severity: 'info',
        timestamp: null,
      ),
    ];
  }

  static List<AlertData> getIndustryAlerts() {
    return const [
      AlertData(
        type: 'compliance',
        message: 'No discharge allowed due to groundwater impact.',
        severity: 'warning',
        timestamp: null,
      ),
    ];
  }

  static String getWaterSource() {
    return 'Groundwater\nWell #42 - Community Supply';
  }

  static String getSoilCompatibility() {
    return 'Your soil type is compatible with silt-based irrigation methods. This ensures optimal water retention and nutrient absorption for your crops.';
  }

  static String getSeasonalForecast() {
    return 'Based on our ML models, groundwater levels are expected to remain stable this season. Recharge rates are projected to match depletion, ensuring a consistent water supply for your agricultural needs.';
  }
}
