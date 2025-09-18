import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/mock_data.dart';
import '../welcome_screen.dart';
import '../feedback_screen.dart';


// State for dropdowns and map controller
class _IndustryMapSection extends StatefulWidget {
  const _IndustryMapSection({Key? key}) : super(key: key);
  @override
  State<_IndustryMapSection> createState() => _IndustryMapSectionState();
}

class _IndustryMapSectionState extends State<_IndustryMapSection> {
  String? _selectedState;
  String? _selectedDistrict;
  final MapController _mapController = MapController();

  static const List<String> states = [
    'Uttar Pradesh', 'Maharashtra', 'Bihar', 'West Bengal', 'Madhya Pradesh',
    'Tamil Nadu', 'Rajasthan', 'Karnataka', 'Gujarat', 'Andhra Pradesh',
  ];
  static const Map<String, List<String>> districtsByState = {
    'Uttar Pradesh': ['Gautam Buddha Nagar', 'Lucknow', 'Varanasi'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
  };

  LatLng? _getStateCenter(String? state) {
    switch (state) {
      case 'Uttar Pradesh': return const LatLng(27.0, 80.0);
      case 'Maharashtra': return const LatLng(19.7515, 75.7139);
      case 'Bihar': return const LatLng(25.0961, 85.3131);
      case 'West Bengal': return const LatLng(22.9868, 87.8550);
      case 'Madhya Pradesh': return const LatLng(22.9734, 78.6569);
      case 'Tamil Nadu': return const LatLng(11.1271, 78.6569);
      case 'Rajasthan': return const LatLng(27.0238, 74.2179);
      case 'Karnataka': return const LatLng(15.3173, 75.7139);
      case 'Gujarat': return const LatLng(22.2587, 71.1924);
      case 'Andhra Pradesh': return const LatLng(15.9129, 79.7400);
      default: return null;
    }
  }
  LatLng? _getDistrictCenter(String? state, String? district) {
    if (state == 'Uttar Pradesh') {
      switch (district) {
        case 'Gautam Buddha Nagar': return const LatLng(28.4744, 77.5040);
        case 'Lucknow': return const LatLng(26.8467, 80.9462);
        case 'Varanasi': return const LatLng(25.3176, 82.9739);
      }
    } else if (state == 'Maharashtra') {
      switch (district) {
        case 'Mumbai': return const LatLng(19.0760, 72.8777);
        case 'Pune': return const LatLng(18.5204, 73.8567);
        case 'Nagpur': return const LatLng(21.1458, 79.0882);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = const LatLng(20.5937, 78.9629);
    double zoom = 4.0;
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    hint: const Text('Select State', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    items: states.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                        _selectedDistrict = null;
                        final center = _getStateCenter(value);
                        if (center != null) {
                          _mapController.move(center, 7);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    hint: const Text('Select District', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    items: (_selectedState != null && districtsByState[_selectedState] != null)
                        ? districtsByState[_selectedState]!.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: const TextStyle(color: Colors.white)),
                            )).toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                        final center = _getDistrictCenter(_selectedState, value);
                        if (center != null) {
                          _mapController.move(center, 11);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: zoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.aquaview',
                      tileProvider: NetworkTileProvider(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IndustryDashboard extends StatelessWidget {
  const IndustryDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alerts = MockDataService.getIndustryAlerts();

  return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2196F3)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Industry Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'feedback') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'feedback',
                child: Text('Report & Feedback'),
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
            _buildSectionTitle('Location Map'),
            const SizedBox(height: 16),
            const _IndustryMapSection(),
            const SizedBox(height: 24),
            // Water Quality Overview
            _buildSectionTitle('Water Quality Overview'),
            const SizedBox(height: 16),
            _buildWaterQualityOverviewCard(),
            const SizedBox(height: 24),
            // Compliance Alerts
            _buildSectionTitle('Compliance Alerts'),
            const SizedBox(height: 16),
            _buildComplianceAlertsCard(alerts),
            const SizedBox(height: 24),
            // Certified Water Sources
            _buildSectionTitle('Certified Water Sources'),
            const SizedBox(height: 16),
            _buildCertifiedSourcesCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildWaterQualityOverviewCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Color(0xFF2196F3),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Water Quality',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Meets industry standards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceAlertsCard(List<AlertData> alerts) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: alerts.map((alert) => _buildAlertItem(alert)).toList(),
        ),
      ),
    );
  }

  Widget _buildAlertItem(AlertData alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.severity == 'warning' 
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.severity == 'warning' 
              ? Colors.red.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            alert.severity == 'warning' 
                ? Icons.warning
                : Icons.info,
            color: alert.severity == 'warning' 
                ? Colors.red
                : Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.type == 'compliance' ? 'Do Not Dump Alert' : 'System Alert',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifiedSourcesCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSourceItem(
              icon: Icons.add_circle,
              title: 'Request Water',
              subtitle: 'Request quality-certified water for industrial use',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
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
}

