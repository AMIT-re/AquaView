import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/waterways_service.dart';
import '../services/app_state.dart';

class WaterMapScreen extends StatefulWidget {
  const WaterMapScreen({super.key});

  @override
  State<WaterMapScreen> createState() => _WaterMapScreenState();
}

class _WaterMapScreenState extends State<WaterMapScreen> {
  Future<void> _retryLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        setState(() {
          _loading = false;
          _error = 'Location permission denied. Please enable location services and restart the app.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final center = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentCenter = center;
        _loading = false;
      });
      _mapController.move(center, 13);
      await _loadData(center);
    } catch (e) {
      setState(() {
        _error = 'Could not get current location. Make sure location is enabled in your emulator/device.';
        _loading = false;
      });
    }
  }
  final MapController _mapController = MapController();
  LatLng? _currentCenter;
  bool _loading = true;
  String? _error;
  WaterwaysResult? _data;
  int _radiusMeters = 5000;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        setState(() {
          _loading = false;
          _error = 'Location permission denied. Please enable location services and restart the app.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final center = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentCenter = center;
      });
      // Move map to current location after fetching
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(center, 13);
      });
      await _loadData(center);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadData(LatLng center) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await WaterwaysService.fetchNearby(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: _radiusMeters,
      );
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load waterways.';
        _loading = false;
      });
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  List<Polyline> _buildWaterwayPolylines() {
    final result = <Polyline>[];
    final theme = Theme.of(context);
    final waterways = _data?.waterways ?? [];

    for (final w in waterways) {
      Color color;
      switch (w.kind) {
        case 'river':
          color = Colors.blueAccent.shade100;
          break;
        case 'stream':
          color = Colors.lightBlueAccent;
          break;
        case 'canal':
          color = Colors.cyanAccent;
          break;
        case 'drain':
        case 'ditch':
          color = Colors.blueGrey.shade300;
          break;
        default:
          color = theme.colorScheme.secondary;
      }
      result.add(Polyline(points: w.points, color: color, strokeWidth: 3.0));
    }

    return result;
  }

  List<Marker> _buildSourceMarkers() {
    final markers = <Marker>[];
    final sources = _data?.sources ?? [];
    for (final s in sources) {
      markers.add(Marker(
        width: 46,
        height: 46,
        point: s.position,
        child: Tooltip(
          message: '${s.name} (${s.type})',
          child: const Icon(Icons.forest, color: Colors.lightGreenAccent, size: 28),
        ),
      ));
    }
    if (_currentCenter != null) {
      markers.add(Marker(
        width: 44,
        height: 44,
        point: _currentCenter!,
        child: const Icon(Icons.my_location, color: Colors.white, size: 26),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
  // final appState = context.watch<AppState>();
    final center = _currentCenter ?? const LatLng(20.5937, 78.9629); // Fallback center: India

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await _retryLocation();
            },
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            onSelected: (v) {
              setState(() {
                _radiusMeters = v;
              });
              if (_currentCenter != null) {
                unawaited(_loadData(_currentCenter!));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 2000, child: Text('Radius: 2 km')),
              PopupMenuItem(value: 5000, child: Text('Radius: 5 km')),
              PopupMenuItem(value: 10000, child: Text('Radius: 10 km')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentCenter == null && !_loading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Location unavailable. Please ensure location is enabled on your device/emulator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retryLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (_currentCenter != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                onMapReady: () {
                  if (_currentCenter != null) {
                    _mapController.move(_currentCenter!, 13);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.aquaview',
                  tileProvider: NetworkTileProvider(),
                ),
                if ((_data?.waterways.isNotEmpty ?? false))
                  PolylineLayer(polylines: _buildWaterwayPolylines()),
                if ((_data?.sources.isNotEmpty ?? false) || _currentCenter != null)
                  MarkerLayer(markers: _buildSourceMarkers()),
              ],
            ),
          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_error != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 20,
              child: Material(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (_currentCenter != null)
            Positioned(
              right: 16,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: _retryLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
        ],
      ),
    );

  }
}
