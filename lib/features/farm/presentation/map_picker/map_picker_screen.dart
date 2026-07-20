import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  String _statusMessage = 'Initializing...';
  bool _isLoading = true;
  
  // Default location: Hyderabad
  static final LatLng _defaultLocation = LatLng(17.3850, 78.4867);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.initialLocation != null) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _isLoading = false;
      });
      // Small delay to ensure map controller is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _selectedLocation != null) {
          _mapController.move(_selectedLocation!, 15);
        }
      });
      return;
    }

    await _handleLocationFlow();
  }

  Future<void> _handleLocationFlow() async {
    // Prevent multiple simultaneous location requests
    if (_isLoading && _selectedLocation != null) return;
    
    setState(() => _isLoading = true);
    try {
      // 1. Check if Location Services are enabled
      setState(() => _statusMessage = 'Checking GPS status...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showGpsDialog();
        // Check again after dialog
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _useDefaultLocation('GPS is disabled.');
          return;
        }
      }

      // 2. Check Location Permission
      setState(() => _statusMessage = 'Requesting Location Permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showSettingsDialog();
        _useDefaultLocation('Permission permanently denied.');
        return;
      }

      // 3. Retrieve Current Location
      setState(() => _statusMessage = 'Getting Current Location...');
      
      try {
        // Try to get last known position first for a quick response
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && _selectedLocation == null) {
          final lastLatLng = LatLng(lastPosition.latitude, lastPosition.longitude);
          _setMapPosition(lastLatLng, isLoading: true);
        }

        // Try getting current position with high accuracy first
        Position? position;
        try {
          setState(() => _statusMessage = 'Fetching Precise GPS Lock...');
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 12),
            ),
          );
        } catch (e) {
          debugPrint('High accuracy failed, trying medium: $e');
          setState(() => _statusMessage = 'Weak signal, trying medium accuracy...');
          // Fallback to medium accuracy if high fails or times out
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          );
        }

        if (position != null) {
          final currentLatLng = LatLng(position.latitude, position.longitude);
          _setMapPosition(currentLatLng);
        } else if (_selectedLocation == null) {
          _useDefaultLocation('Unable to determine location.');
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Geolocator Error: $e');
        
        // If we managed to get a last known position earlier, we are good enough
        if (_selectedLocation != null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Using last known location. Precise location unavailable.')),
          );
        } else {
          _useDefaultLocation('Unable to determine location.');
        }
      }

    } catch (e) {
      debugPrint('Location Flow Exception: $e');
      _useDefaultLocation('Error getting location.');
    }
  }

  void _useDefaultLocation(String reason) {
    debugPrint('Using fallback location: $reason');
    if (!mounted) return;
    
    // Only use default if we haven't found any location at all
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$reason Using default location.')),
      );
      _setMapPosition(_defaultLocation);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason)),
      );
    }
  }

  void _setMapPosition(LatLng location, {bool isLoading = false}) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _isLoading = isLoading;
    });
    _mapController.move(location, 15);
  }

  Future<void> _showGpsDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Disabled'),
        content: const Text('Please enable location services to find your farm automatically.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Location permission is permanently denied. Please enable it in app settings to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Farm Location'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _defaultLocation,
              initialZoom: 15,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lakshya_aerotech.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: PrimaryButton(
              text: 'Confirm Location',
              onPressed: _isLoading || _selectedLocation == null
                  ? null
                  : () => Navigator.pop(context, _selectedLocation),
            ),
          ),
          
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _handleLocationFlow(),
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
