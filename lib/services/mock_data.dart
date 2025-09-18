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

  // Location-aware variants (mocked heuristics)
  static String getSoilCompatibilityFor({required double latitude, required double longitude}) {
    final latEven = latitude.abs().floor() % 2 == 0;
    final lngEven = longitude.abs().floor() % 2 == 0;
    if (latEven && lngEven) {
      return 'Loam-dominant soil with good silt compatibility. Recommended: drip irrigation and mulching.';
    } else if (latEven && !lngEven) {
      return 'Sandy-loam mix; moderate silt compatibility. Recommended: shorter watering intervals and organic compost.';
    } else if (!latEven && lngEven) {
      return 'Clay-rich soil; high silt compatibility but risk of waterlogging. Recommended: raised beds and controlled irrigation.';
    } else {
      return 'Alluvial soil; balanced silt compatibility. Recommended: sprinkler systems and periodic soil aeration.';
    }
  }

  static String getSeasonalForecastFor({required double latitude, required double longitude}) {
    final latBand = latitude.abs();
    if (latBand < 10) {
      return 'Equatorial band: Expect frequent short showers; groundwater recharge moderate. Plan for staggered irrigation windows.';
    } else if (latBand < 23.5) {
      return 'Tropical band: Monsoon likelihood high this season; recharge above average. Consider rainwater harvesting.';
    } else if (latBand < 35) {
      return 'Subtropical band: Intermittent rainfall expected; stable to slight decline in groundwater. Optimize irrigation schedules.';
    } else {
      return 'Temperate band: Low precipitation periods likely; recharge below average. Prioritize efficient water use.';
    }
  }
}
