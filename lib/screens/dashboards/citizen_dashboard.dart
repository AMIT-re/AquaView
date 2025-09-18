import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/location_search_sheet.dart';
import '../../services/mock_data.dart';
import '../../services/dwlr_service.dart';
import '../welcome_screen.dart';
import '../feedback_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
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
  Position? _position;
  String? _locationError;
  DwlrReading? _dwlr;
  Stream<Position>? _positionStream;
  double? _latitude;
  double? _longitude;
  bool _locating = false;

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
        _position = pos;
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locating = false;
      });
      _loadDwlr();
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
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
                                        _position = Position(
                                          latitude: selected!.latitude,
                                          longitude: selected!.longitude,
                                          timestamp: DateTime.now(),
                                          accuracy: 0.0,
                                          altitude: 0.0,
                                          heading: 0.0,
                                          speed: 0.0,
                                          speedAccuracy: 0.0,
                                          altitudeAccuracy: 0.0,
                                          headingAccuracy: 0.0,
                                        );
                                      });
                                      _loadDwlr();
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
    final waterQuality = MockDataService.getWaterQuality;
    final alerts = MockDataService.getCitizenAlerts();

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
                case 'use_current_location':
                  _useCurrentLocation();
                  break;
                case 'change_location':
                  _promptChangeLocation();
                  break;
                case 'report_issue':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Issue reported. Thank you!')),
                  );
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
                value: 'refresh_location',
                child: Text('Refresh location'),
              ),
              PopupMenuItem(
                value: 'use_current_location',
                child: Text('Use my location'),
              ),
              PopupMenuItem(
                value: 'change_location',
                child: Text('Change location...'),
              ),
              PopupMenuItem(
                value: 'report_issue',
                child: Text('Report issue'),
              ),
              PopupMenuItem(
                value: 'feedback',
                child: Text('Report & Feedback'),
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
            _buildSectionTitle('Location'),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 24),
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
            
            // ...existing code...

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
