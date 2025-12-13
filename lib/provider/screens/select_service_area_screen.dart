import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/button.dart';
import '../widgets/colors.dart';
import 'confirm_info_screen.dart';

class SelectServiceAreaScreen extends StatefulWidget {
  const SelectServiceAreaScreen({super.key});

  @override
  State<SelectServiceAreaScreen> createState() =>
      _SelectServiceAreaScreenState();
}

class _SelectServiceAreaScreenState extends State<SelectServiceAreaScreen> {
  final TextEditingController searchController = TextEditingController();
  List<String> _suggestions = [];
  List<Map<String, String>> _selectedAreas = [];
  bool _showSuggestions = false;

  // Map related variables
  late GoogleMapController mapController;
  LatLng _center = LatLng(37.7749, -122.4194); // Default: San Francisco
  Set<Marker> markers = {};
  Set<Polygon> serviceAreaPolygons = {};
  bool isLoading = false;
  String errorMessage = '';

  // Sample zip codes and cities data
  final List<Map<String, String>> _zipCodeData = [
    {'zip': '62704', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62703', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62705', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62701', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62702', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62706', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62707', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62708', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62709', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62710', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62711', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62712', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62715', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62716', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62719', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62722', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62723', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62726', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62736', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62739', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62746', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62756', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62757', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62761', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62762', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62763', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62764', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62765', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62766', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62767', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62769', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62777', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62781', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62786', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62791', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62794', 'city': 'Springfield', 'state': 'IL'},
    {'zip': '62796', 'city': 'Springfield', 'state': 'IL'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing service areas
    _selectedAreas = [
      {'zip': '62704', 'city': 'Springfield', 'state': 'IL'},
      {'zip': '62703', 'city': 'Springfield', 'state': 'IL'},
      {'zip': '62705', 'city': 'Springfield', 'state': 'IL'},
    ];
    _getCurrentLocation();
    _updateServiceAreaMarkers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Map Functions
  void _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Location services are disabled.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'Location permissions are permanently denied';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _center,
          infoWindow: InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _searchByZipCode() async {
    if (searchController.text.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      List<Location> locations = await locationFromAddress(searchController.text);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng newLocation = LatLng(location.latitude, location.longitude);

        setState(() {
          _center = newLocation;
          // Keep existing markers but add search marker
          markers.add(
            Marker(
              markerId: MarkerId('searched_${searchController.text}'),
              position: newLocation,
              infoWindow: InfoWindow(
                title: 'Searched: ${searchController.text}',
                snippet: 'Tap to add to service areas',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        });

        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 12.0),
        );
      } else {
        setState(() {
          errorMessage = 'No location found for this zip code';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error searching for zip code: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onZipCodeChanged(String value) {
    if (value.length >= 2) {
      setState(() {
        _suggestions = _zipCodeData
            .where((item) => item['zip']!.startsWith(value))
            .map((item) => '${item['zip']} - ${item['city']}, ${item['state']}')
            .take(5)
            .toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectZipCode(String suggestion) async {
    final parts = suggestion.split(' - ');
    final zip = parts[0];
    final cityState = parts[1].split(', ');

    final newArea = {
      'zip': zip,
      'city': cityState[0],
      'state': cityState[1],
    };

    if (!_selectedAreas.any((area) => area['zip'] == zip)) {
      setState(() {
        _selectedAreas.add(newArea);
        searchController.clear();
        _showSuggestions = false;
      });

      await _addServiceAreaMarker(zip);
      _updateServiceAreaPolygons();
    }
  }

  void _removeArea(Map<String, String> area) {
    setState(() {
      _selectedAreas.removeWhere((item) => item['zip'] == area['zip']);
      markers.removeWhere((marker) => marker.markerId.value == 'service_${area['zip']}');
    });
    _updateServiceAreaPolygons();
  }

  Future<void> _addServiceAreaMarker(String zipCode) async {
    try {
      List<Location> locations = await locationFromAddress(zipCode);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId('service_$zipCode'),
              position: LatLng(location.latitude, location.longitude),
              infoWindow: InfoWindow(
                title: 'Service Area: $zipCode',
                snippet: 'Part of your service coverage',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        });
      }
    } catch (e) {
      print('Error adding service area marker: $e');
    }
  }

  void _updateServiceAreaMarkers() async {
    for (var area in _selectedAreas) {
      await _addServiceAreaMarker(area['zip']!);
    }
  }

  void _updateServiceAreaPolygons() {
    Set<Polygon> polygons = {};

    if (_selectedAreas.isNotEmpty) {
      _createDemoPolygon().then((polygon) {
        setState(() {
          serviceAreaPolygons = {polygon};
        });
      });
    } else {
      setState(() {
        serviceAreaPolygons.clear();
      });
    }
  }

  Future<Polygon> _createDemoPolygon() async {
    List<LatLng> polygonCoords = [];
    const double radius = 0.02;

    if (_selectedAreas.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(_selectedAreas.first['zip']!);
        if (locations.isNotEmpty) {
          double centerLat = locations.first.latitude;
          double centerLng = locations.first.longitude;

          for (int i = 0; i < 360; i += 10) {
            double angle = i * 3.14159 / 180;
            double lat = centerLat + radius * cos(angle);
            double lng = centerLng + radius * sin(angle);
            polygonCoords.add(LatLng(lat, lng));
          }
        }
      } catch (e) {
        print('Error creating polygon: $e');
      }
    }

    return Polygon(
      polygonId: PolygonId('service_area'),
      points: polygonCoords,
      strokeWidth: 2,
      strokeColor: Color(0xFF0E7A60),
      fillColor: Color(0xFF0E7A60).withOpacity(0.3),
    );
  }

  void _clearSearchMarkers() {
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value.startsWith('searched_'));
    });
  }

  void _zoomToServiceAreas() async {
    if (_selectedAreas.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(_selectedAreas.first['zip']!);
        if (locations.isNotEmpty) {
          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(locations.first.latitude, locations.first.longitude),
              10.0,
            ),
          );
        }
      } catch (e) {
        print('Error zooming to service areas: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KoreColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Service Area",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfirmInfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Zip Codes",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Search Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KoreColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: searchController,
                              onChanged: _onZipCodeChanged,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "select your zip code",
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon: Icon(Icons.search, color: KoreColors.textLight),
                            onPressed: _searchByZipCode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                isLoading
                    ? CircularProgressIndicator()
                    : Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF0E7A60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: _searchByZipCode,
                  ),
                ),
              ],
            ),

            // Suggestions Dropdown
            if (_showSuggestions)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KoreColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: _suggestions.map((suggestion) {
                    return ListTile(
                      title: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => _selectZipCode(suggestion),
                      trailing: Icon(Icons.add_circle_outline, color: Color(0xFF0E7A60)),
                    );
                  }).toList(),
                ),
              ),

            // Error Message
            if (errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 12),

            // Selected Service Areas Chips
            if (_selectedAreas.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Selected Areas (${_selectedAreas.length})",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.zoom_in_map, color: Color(0xFF0E7A60), size: 20),
                        onPressed: _zoomToServiceAreas,
                        tooltip: 'Zoom to Service Areas',
                      ),
                      IconButton(
                        icon: Icon(Icons.clear_all, color: Colors.grey, size: 20),
                        onPressed: _clearSearchMarkers,
                        tooltip: 'Clear Search Markers',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedAreas.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final area = _selectedAreas[index];
                        return _ZipChip(
                          zip: '${area['zip']} - ${area['city']}, ${area['state']}',
                          onRemove: () => _removeArea(area),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Interactive Google Map
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KoreColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 11.0,
                        ),
                        markers: markers,
                        polygons: serviceAreaPolygons,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                      ),

                      // Map Legend
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Current', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Searched', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Service', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Confirm button (full width)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7A60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfirmInfoScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Confirm",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getCurrentLocation,
            child: Icon(Icons.my_location, size: 20),
            backgroundColor: Colors.blue,
            mini: true,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _zoomToServiceAreas,
            child: Icon(Icons.zoom_in_map, size: 20),
            backgroundColor: Color(0xFF0E7A60),
            mini: true,
          ),
        ],
      ),
    );
  }
}

/// Small green pill-like zip chip with remove button (matches screenshot)
class _ZipChip extends StatelessWidget {
  final String zip;
  final VoidCallback onRemove;

  const _ZipChip({required this.zip, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle_outlined, size: 8, color: Color(0xFF0E7A60)),
          const SizedBox(width: 6),
          Text(
            zip,
            style: const TextStyle(color: Color(0xFF0E7A60), fontSize: 12),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Color(0xFF0E7A60)),
          ),
        ],
      ),
    );
  }
}