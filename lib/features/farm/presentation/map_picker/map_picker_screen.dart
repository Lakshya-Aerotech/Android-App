import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  String _statusMessage = 'Initializing...';
  bool _isLoading = true;
  
  // Default location: Hyderabad
  static const LatLng _defaultLocation = LatLng(17.3850, 78.4867);

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
      return;
    }

    await _handleLocationFlow();
  }

  Future<void> _handleLocationFlow() async {
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
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(
          const Duration(seconds: 12),
        );

        final currentLatLng = LatLng(position.latitude, position.longitude);
        _setMapPosition(currentLatLng);
      } catch (e) {
        debugPrint('Geolocator Error: $e');
        _useDefaultLocation('Unable to determine location.');
      }

    } catch (e) {
      debugPrint('Location Flow Exception: $e');
      _useDefaultLocation('Error getting location.');
    }
  }

  void _useDefaultLocation(String reason) {
    debugPrint('Using fallback location: $reason');
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$reason Using default location.')),
    );
    
    _setMapPosition(_defaultLocation);
  }

  void _setMapPosition(LatLng location) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _isLoading = false;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selectedLocation != null) {
                _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
              }
            },
            onTap: (latLng) {
              setState(() {
                _selectedLocation = latLng;
              });
            },
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
        ],
      ),
    );
  }
}
