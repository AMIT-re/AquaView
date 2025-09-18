import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/mock_data.dart';
import '../welcome_screen.dart';
import '../feedback_screen.dart';
import '../widgets/location_search_sheet.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  String? _selectedState;
  String? _selectedDistrict;

  // Helper: get state center coordinates
  LatLng? _getStateCenter(String? state) {
    switch (state) {
      case 'Uttar Pradesh':
        return const LatLng(27.0, 80.0);
      case 'Maharashtra':
        return const LatLng(19.7515, 75.7139);
      case 'Bihar':
        return const LatLng(25.0961, 85.3131);
      case 'West Bengal':
        return const LatLng(22.9868, 87.8550);
      case 'Madhya Pradesh':
        return const LatLng(22.9734, 78.6569);
      case 'Tamil Nadu':
        return const LatLng(11.1271, 78.6569);
      case 'Rajasthan':
        return const LatLng(27.0238, 74.2179);
      case 'Karnataka':
        return const LatLng(15.3173, 75.7139);
      case 'Gujarat':
        return const LatLng(22.2587, 71.1924);
      case 'Andhra Pradesh':
        return const LatLng(15.9129, 79.7400);
      default:
        return null;
    }
  }

  // Helper: get district center coordinates
  LatLng? _getDistrictCenter(String? state, String? district) {
    if (state == 'Uttar Pradesh') {
      switch (district) {
        case 'Gautam Buddha Nagar':
          return const LatLng(28.4744, 77.5040);
        case 'Lucknow':
          return const LatLng(26.8467, 80.9462);
        case 'Varanasi':
          return const LatLng(25.3176, 82.9739);
      }
    } else if (state == 'Maharashtra') {
      switch (district) {
        case 'Mumbai':
          return const LatLng(19.0760, 72.8777);
        case 'Pune':
          return const LatLng(18.5204, 73.8567);
        case 'Nagpur':
          return const LatLng(21.1458, 79.0882);
      }
    }
    // Add more as needed
    return null;
  }
  double? _latitude;
  double? _longitude;
  bool _locating = false;

  String get _seasonalForecastText {
    if (_latitude != null && _longitude != null) {
      return MockDataService.getSeasonalForecastFor(latitude: _latitude!, longitude: _longitude!);
    }
    return MockDataService.getSeasonalForecast();
  }

  String get _soilCompatibilityText {
    if (_latitude != null && _longitude != null) {
      return MockDataService.getSoilCompatibilityFor(latitude: _latitude!, longitude: _longitude!);
    }
    return MockDataService.getSoilCompatibility();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() => _locating = false);
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }

  Future<void> _promptChangeLocation() async {
    final initialCenter = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(20.5937, 78.9629);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        LatLng? selected;
        bool fetchingLocal = false;
        final mapController = MapController();
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (_) => LocationSearchSheet(
                                    onPicked: (name, pos) {
                                      setLocalState(() {
                                        selected = pos;
                                      });
                                      mapController.move(pos, 13);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search, color: Color(0xFF2196F3)),
                              label: const Text('Search place', style: TextStyle(color: Color(0xFF2196F3))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2196F3)),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: initialCenter,
                              initialZoom: 5,
                              onTap: (tapPosition, point) {
                                setLocalState(() {
                                  selected = point;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.aquaview',
                                tileProvider: NetworkTileProvider(),
                              ),
                              if (selected != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: selected!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_on, color: Color(0xFF2196F3), size: 36),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: fetchingLocal
                                  ? null
                                  : () async {
                                      setLocalState(() => fetchingLocal = true);
                                      try {
                                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                        if (!serviceEnabled) {
                                          await Geolocator.openLocationSettings();
                                          serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                          if (!serviceEnabled) {
                                            setLocalState(() => fetchingLocal = false);
                                            return;
                                          }
                                        }

                                        LocationPermission permission = await Geolocator.checkPermission();
                                        if (permission == LocationPermission.denied) {
                                          permission = await Geolocator.requestPermission();
                                          if (permission == LocationPermission.denied) {
                                            setLocalState(() => fetchingLocal = false);
                                            return;
                                          }
                                        }
                                        if (permission == LocationPermission.deniedForever) {
                                          setLocalState(() => fetchingLocal = false);
                                          return;
                                        }

                                        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
                                        final here = LatLng(pos.latitude, pos.longitude);
                                        setLocalState(() {
                                          selected = here;
                                          fetchingLocal = false;
                                        });
                                        // Center the map and zoom in to the current location
                                        mapController.move(here, 13);
                                      } catch (e) {
                                        setLocalState(() => fetchingLocal = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Could not get location: $e')),
                                          );
                                        }
                                      }
                                    },
                              icon: fetchingLocal
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location, color: Color(0xFF2196F3)),
                              label: const Text('Use my location', style: TextStyle(color: Color(0xFF2196F3))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2196F3)),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selected == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _latitude = selected!.latitude;
                                        _longitude = selected!.longitude;
                                      });
                                      Navigator.pop(context);
                                    },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Farmer Dashboard'),
        actions: [
          if (_locating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'use_current_location':
                  _useCurrentLocation();
                  break;
                case 'change_location':
                  _promptChangeLocation();
                  break;
                case 'feedback':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'use_current_location',
                child: Text('Use my location'),
              ),
              PopupMenuItem(
                value: 'change_location',
                child: Text('Change location...'),
              ),
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
            // Location controls & preview
            _buildSectionTitle('Location'),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 24),
            // Seasonal Forecast
            _buildSectionTitle('Seasonal Forecast'),
            const SizedBox(height: 16),
            _buildSeasonalForecastCard(_seasonalForecastText),
            const SizedBox(height: 24),
            // Soil-Silt Compatibility
            _buildSectionTitle('Soil-Silt Compatibility'),
            const SizedBox(height: 16),
            _buildSoilCompatibilityCard(_soilCompatibilityText),
            const SizedBox(height: 24),
            // Water Quality Reports
            _buildSectionTitle('Water Quality Reports'),
            const SizedBox(height: 16),
            _buildReportsCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildLocationCard() {
    // State and district dropdowns for auto-zoom
    final List<String> states = [
      'Uttar Pradesh', 'Maharashtra', 'Bihar', 'West Bengal', 'Madhya Pradesh',
      'Tamil Nadu', 'Rajasthan', 'Karnataka', 'Gujarat', 'Andhra Pradesh',
      // ... add more as needed
    ];
    final Map<String, List<String>> districtsByState = {
      'Uttar Pradesh': ['Gautam Buddha Nagar', 'Lucknow', 'Varanasi'],
      'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
      // ... add more as needed
    };
    String? selectedState = _selectedState;
    String? selectedDistrict = _selectedDistrict;
    final mapController = MapController();

    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Use my location'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _promptChangeLocation,
                  icon: const Icon(Icons.place, color: Color(0xFF2196F3)),
                  label: const Text('Change location', style: TextStyle(color: Color(0xFF2196F3))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
                const Spacer(),
                if (_latitude != null && _longitude != null)
                  Text(
                    '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedState,
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
                        // Optionally auto-zoom to state center
                        final center = _getStateCenter(value);
                        if (center != null) {
                          mapController.move(center, 7);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedDistrict,
                    hint: const Text('Select District', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    items: (selectedState != null && districtsByState[selectedState] != null)
                        ? districtsByState[selectedState]!.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: const TextStyle(color: Colors.white)),
                            )).toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                        // Optionally auto-zoom to district center
                        final center = _getDistrictCenter(selectedState, value);
                        if (center != null) {
                          mapController.move(center, 11);
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
                child: Builder(
                  builder: (context) {
                    final center = (_latitude != null && _longitude != null)
                        ? LatLng(_latitude!, _longitude!)
                        : const LatLng(20.5937, 78.9629);
                    final zoom = (_latitude != null && _longitude != null) ? 12.0 : 4.0;
                    return FlutterMap(
                      mapController: mapController,
                      key: ValueKey('${center.latitude.toStringAsFixed(5)},${center.longitude.toStringAsFixed(5)}-$zoom'),
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
                        if (_latitude != null && _longitude != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: center,
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.location_on, color: Color(0xFF2196F3), size: 32),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildReportsCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildReportItem(
              icon: Icons.calendar_today,
              title: 'Daily Report',
              onTap: () {},
            ),
            const Divider(color: Colors.white24),
            _buildReportItem(
              icon: Icons.calendar_view_week,
              title: 'Weekly Report',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
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

  Widget _buildSoilCompatibilityCard(String description) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalForecastCard(String description) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cloud,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
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
          icon: Icon(Icons.agriculture),
          label: 'Farmer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: 'Info',
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
            // Info (not implemented)
            break;
        }
      },
    );
  }
}

