import 'package:flutter/material.dart';
import '../welcome_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/mock_data.dart';
import '../../services/geocoding_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class IndustryDashboard extends StatefulWidget {
  const IndustryDashboard({Key? key}) : super(key: key);

  @override
  State<IndustryDashboard> createState() => _IndustryDashboardState();
}

class _IndustryDashboardState extends State<IndustryDashboard> {
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  bool _isLocating = false;
  String? _locationError;
  final TextEditingController _locationController = TextEditingController();
  final List<String> sectors = [
    'All Sectors',
    'Textile',
    'Food Processing',
    'Chemical',
    'Steel',
    'Pharmaceutical',
    'Automobile',
    'Paper',
    'Electronics',
    'Other',
  ];
  String selectedSector = 'All Sectors';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Industry Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'sos':
                  _callMinistryOfJalShakti();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'sos',
                child: Text('Call Ministry of Jal Shakti'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location input field
            Row(
              children: [
                const Text('Location:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter place name',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF222222),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (val) async {
                          setState(() {
                            _isLocating = true;
                            _locationError = null;
                          });
                          try {
                            final results = await GeocodingService.search(val);
                            if (results.isNotEmpty) {
                              setState(() {
                                _selectedLocation = results.first.position;
                                _selectedLocationName = results.first.displayName;
                                _isLocating = false;
                              });
                            } else {
                              setState(() {
                                _locationError = 'Location not found.';
                                _isLocating = false;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              _locationError = 'Error locating place.';
                              _isLocating = false;
                            });
                          }
                        },
                      ),
                      if (_isLocating)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_selectedLocationName != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Located: $_selectedLocationName',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                ),
              ),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _locationError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Select Sector:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedSector,
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: sectors.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedSector = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Groundwater Usage by Sector'),
            _buildGroundwaterUsageChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Industrial Risk Zones'),
            _buildRiskZonesHeatmap(),
            const SizedBox(height: 24),
            _buildSectionTitle('Citizen Awareness'),
            _buildCitizenAlerts(),
            const SizedBox(height: 24),
            _buildSectionTitle('Future Forecast'),
            _buildFutureForecast(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }


  // Example sector usage and risk data
  final Map<String, double> sectorUsage = {
    'Textile': 18,
    'Food Processing': 12,
    'Chemical': 22,
    'Steel': 15,
    'Pharmaceutical': 10,
    'Automobile': 8,
    'Paper': 7,
    'Electronics': 5,
    'Other': 3,
  };
  final Map<String, String> sectorRisk = {
    'Textile': 'High',
    'Food Processing': 'Medium',
    'Chemical': 'High',
    'Steel': 'Medium',
    'Pharmaceutical': 'Low',
    'Automobile': 'Low',
    'Paper': 'Medium',
    'Electronics': 'Low',
    'Other': 'Low',
  };

  Widget _buildGroundwaterUsageChart() {
    // Use mock location-based data if available
    double agriculture = 60.0;
    double domestic = 20.0;
    double sectorVal = 0;
    if (_selectedLocation != null) {
      // Example: change values based on latitude/longitude bands (mock logic)
      final lat = _selectedLocation!.latitude;
      if (lat < 10) {
        agriculture = 50.0;
        domestic = 25.0;
      } else if (lat < 23.5) {
        agriculture = 65.0;
        domestic = 15.0;
      } else if (lat < 35) {
        agriculture = 55.0;
        domestic = 25.0;
      } else {
        agriculture = 70.0;
        domestic = 10.0;
      }
    }
    if (selectedSector == 'All Sectors') {
      sectorVal = sectorUsage.values.reduce((a, b) => a + b);
    } else if (sectorUsage.containsKey(selectedSector)) {
      sectorVal = sectorUsage[selectedSector]!;
    }
    // Optionally, tweak sectorVal based on location (mock)
    if (_selectedLocation != null) {
      sectorVal = (sectorVal * (0.9 + (_selectedLocation!.latitude % 0.2))).clamp(1, 100);
    }
    final data = [
      {'sector': 'Agriculture', 'usage': agriculture},
      {'sector': 'Domestic', 'usage': domestic},
      {'sector': selectedSector, 'usage': sectorVal},
    ];
    final barGroups = List.generate(data.length, (i) {
      final usage = data[i]['usage'] as double;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: usage,
            color: i == 2 ? Colors.orangeAccent : Colors.blueAccent,
            width: 24,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.white10,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          data[idx]['sector'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data[group.x.toInt()]['sector']}: ${rod.toY.toInt()}%',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskZonesHeatmap() {
    // Show risk color based on selected sector
    String risk = 'Low';
    if (selectedSector != 'All Sectors' && sectorRisk.containsKey(selectedSector)) {
      risk = sectorRisk[selectedSector]!;
    }
    Color riskColor;
    switch (risk) {
      case 'High':
        riskColor = Colors.red;
        break;
      case 'Medium':
        riskColor = Colors.yellow;
        break;
      default:
        riskColor = Colors.green;
    }
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  selectedSector == 'All Sectors'
                      ? 'Select a sector to view risk zone.'
                      : '$selectedSector Sector: $risk Risk',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.square, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('Low Risk', style: TextStyle(color: Colors.white70)),
                SizedBox(width: 16),
                Icon(Icons.square, color: Colors.yellow, size: 16),
                SizedBox(width: 4),
                Text('Medium Risk', style: TextStyle(color: Colors.white70)),
                SizedBox(width: 16),
                Icon(Icons.square, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text('High Risk', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCitizenAlerts() {
    final alerts = MockDataService.getIndustryAlerts();
    return Column(
      children: alerts.map((alert) => Card(
        color: alert.severity == 'warning' ? Colors.orange[700] : Colors.green[700],
        child: ListTile(
          leading: Icon(
            alert.severity == 'warning' ? Icons.warning : Icons.check_circle,
            color: Colors.white,
          ),
          title: Text(alert.message, style: const TextStyle(color: Colors.white)),
          subtitle: Text('Type: ${alert.type}', style: const TextStyle(color: Colors.white70)),
        ),
      )).toList(),
    );
  }

  Widget _buildFutureForecast() {
    final forecast = MockDataService.getSeasonalForecast();
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Groundwater Demand Forecast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(forecast, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text('Suggestions for Sustainable Use:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('- Adopt rainwater harvesting\n- Recycle and reuse water\n- Monitor and report illegal extraction\n- Invest in water-efficient technologies', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
            break;
          case 1:
            // Stay on dashboard
            break;
          case 2:
            // Profile (not implemented)
            break;
        }
      },
    );
  }

  Future<void> _callMinistryOfJalShakti() async {
    final uri = Uri(scheme: 'tel', path: '01123766369');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}