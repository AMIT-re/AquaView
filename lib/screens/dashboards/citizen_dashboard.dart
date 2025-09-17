import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/mock_data.dart';
import '../../services/dwlr_service.dart';
import '../welcome_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  Position? _position;
  String? _locationError;
  DwlrReading? _dwlr;
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _locationError = 'Location services are disabled';
          });
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
      // const waterLevel = MockDataService.getWaterLevel;
        });
      // final waterSource = MockDataService.getWaterSource();
      }

      Position? chosen;
      try {
        chosen = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        setState(() {
          _locationError = 'Unable to determine location: $e';
        });
        return;
      }

      if (chosen == null) {
        setState(() {
          _locationError = 'Unable to determine location';
        });
        return;
      }

      if (mounted) {
        setState(() {
          _position = chosen;
          _locationError = null;
        });
      }

      _subscribePositionUpdates();
      _loadDwlr();
    } catch (e) {
      setState(() {
        _locationError = e.toString();
      });
    }
  }

  void _subscribePositionUpdates() {
    _positionStream ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 15),
    );
    _positionStream!.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
      });
    });
  }

  Future<void> _loadDwlr() async {
    final pos = _position;
    if (pos == null) return;
    final reading = await DwlrService.fetchByLocation(latitude: pos.latitude, longitude: pos.longitude);
    if (!mounted) return;
    setState(() {
      _dwlr = reading;
    });
  }

  @override
  Widget build(BuildContext context) {
    const waterQuality = MockDataService.getWaterQuality;
    const waterLevel = MockDataService.getWaterLevel;
    final alerts = MockDataService.getCitizenAlerts();
    final waterSource = MockDataService.getWaterSource();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Water Data',
            onPressed: _loadDwlr,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'refresh_location':
                  _initLocation();
                  break;
                case 'report_issue':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Issue reported. Thank you!')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'refresh_location',
                child: Text('Refresh location'),
              ),
              PopupMenuItem(
                value: 'report_issue',
                child: Text('Report issue'),
              ),
            ],
          ),
        ],
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water Quality Overview
            _buildSectionTitle('Water Quality Overview'),
            const SizedBox(height: 16),
            if (_dwlr == null && _position != null)
              const Center(child: CircularProgressIndicator()),
            if (_dwlr == null && _position == null)
              const Center(child: Text('Waiting for location...', style: TextStyle(color: Colors.white70))),
            if (_dwlr == null && _locationError != null)
              Center(child: Text(_locationError!, style: const TextStyle(color: Colors.red))),
            if (_dwlr != null)
              _buildWaterQualityCard(_dwlr, waterQuality),
            if (_dwlr != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text('Live DWLR data for your location', style: TextStyle(color: Colors.green.shade200, fontSize: 13)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Alerts
            _buildSectionTitle('Alerts'),
            const SizedBox(height: 16),
            _buildAlertsCard(alerts),
            
            const SizedBox(height: 24),
            
            // Water Level
            _buildSectionTitle('Water Level'),
            const SizedBox(height: 16),
            if (_dwlr == null && _position != null)
              const Center(child: CircularProgressIndicator()),
            if (_dwlr == null && _position == null)
              const Center(child: Text('Waiting for location...', style: TextStyle(color: Colors.white70))),
            if (_dwlr == null && _locationError != null)
              Center(child: Text(_locationError!, style: const TextStyle(color: Colors.red))),
            if (_dwlr != null)
              _buildWaterLevelCard(_dwlr, null),
            if (_dwlr != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text('Live DWLR water level', style: TextStyle(color: Colors.green.shade200, fontSize: 13)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Your Water Source
            _buildSectionTitle('Your Water Source'),
            const SizedBox(height: 16),
            if (_dwlr == null && _position != null)
              const Center(child: CircularProgressIndicator()),
            if (_dwlr == null && _position == null)
              const Center(child: Text('Waiting for location...', style: TextStyle(color: Colors.white70))),
            if (_dwlr == null && _locationError != null)
              Center(child: Text(_locationError!, style: const TextStyle(color: Colors.red))),
            if (_dwlr != null)
              _buildWaterSourceCard(_dwlr!),
            if (_dwlr != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text('Live DWLR source info', style: TextStyle(color: Colors.green.shade200, fontSize: 13)),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Water Source Map (current location)
            _buildSectionTitle('Water Source Near You'),
            const SizedBox(height: 16),
            _buildMapCard(),

            const SizedBox(height: 24),

            // Regional Water Hardness
            _buildSectionTitle('Regional Water Hardness'),
            const SizedBox(height: 16),
            _buildWaterHardnessCard(_dwlr?.hardnessCategory),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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

  Widget _buildWaterQualityCard(DwlrReading? dwlr, WaterQualityData fallback) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQualityMetric('pH Level', (dwlr?.ph ?? fallback.ph).toString(), dwlr != null ? 'Live' : fallback.status),
                _buildQualityMetric('TDS (ppm)', (dwlr?.tds ?? fallback.tds).toString(), dwlr != null ? 'Live' : '→ Normal'),
                _buildQualityMetric('Impurities', dwlr?.impuritiesDescription ?? fallback.impurities, dwlr != null ? 'Live' : 'Safe'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMetric(String label, String value, String status) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsCard(List<AlertData> alerts) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                alerts.isNotEmpty ? alerts.first.message : 'No alerts',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterLevelCard(DwlrReading? dwlr, WaterLevelData? data) {
    if (dwlr == null) {
      return Card(
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text('No real-time water level data available', style: TextStyle(color: Colors.white70))),
        ),
      );
    }
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Level',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${dwlr.levelMeters.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      dwlr.trend,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Live data from DWLR sensor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterSourceCard(DwlrReading dwlr) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.water_drop,
              color: Color(0xFF2196F3),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Source: ${dwlr.hardnessCategory} water',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Impurities: ${dwlr.impuritiesDescription}',
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
      ),
    );
  }

  Widget _buildWaterHardnessCard(String? hardness) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _hardnessColor(hardness).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    hardness != null ? 'Hardness: $hardness' : 'Regional water hardness map will be displayed here',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const _HardnessLegend('Hard', Colors.red),
                const _HardnessLegend('Moderate', Colors.orange),
                const _HardnessLegend('Soft', Colors.green),
                const _HardnessLegend('Very Soft', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _hardnessColor(String? hardness) {
    switch ((hardness ?? '').toLowerCase()) {
      case 'hard':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'soft':
        return Colors.green;
      case 'very soft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHardnessLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: SizedBox(
        height: 250,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              _buildMapContent(),
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.4),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Recenter',
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: _initLocation,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _locationError!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_position == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final center = LatLng(_position!.latitude, _position!.longitude);
    final source = _inferWaterSource(center);
    final sourceColor = _sourceColor(source);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.aquaview',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 200,
              height: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: sourceColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Source: $source',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Icon(Icons.location_on, color: sourceColor, size: 32),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _inferWaterSource(LatLng location) {
    // Simple heuristic demo: alternate sources based on coords parity
    final latEven = (location.latitude.abs().floor() % 2) == 0;
    final lngEven = (location.longitude.abs().floor() % 2) == 0;
    if (latEven && lngEven) return 'Nearby River';
    if (latEven && !lngEven) return 'Municipal Well';
    if (!latEven && lngEven) return 'Reservoir';
    return 'Community Borewell';
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'Nearby River':
        return Colors.blue;
      case 'Municipal Well':
        return Colors.teal;
      case 'Reservoir':
        return Colors.indigo;
      case 'Community Borewell':
        return Colors.purple;
      default:
        return const Color(0xFF2196F3);
    }
  }

  Widget _buildBottomNavigationBar() {
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
          icon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: 'Source',
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
            _initLocation();
            break;
          case 2:
            if (_position != null) {
              final name = _inferWaterSource(LatLng(_position!.latitude, _position!.longitude));
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Water Source at Your Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 12),
                      Text('Likely source: $name', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location not available yet')),
              );
            }
            break;
        }
      },
    );
  }
}

class _HardnessLegend extends StatelessWidget {
  const _HardnessLegend(this.label, this.color);
  
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
