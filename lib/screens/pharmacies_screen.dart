import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  _PharmaciesScreenState createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  Position? _currentPosition;
  List<Map<String, dynamic>> _pharmacies = [];
  final MapController _mapController = MapController();
  bool _isLoading = true;
  int? _selectedPharmacyIndex;
  bool _locationServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationServices();
  }

  Future<void> _checkLocationServices() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      setState(() => _isLoading = false);
      return;
    }
    await _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _getCurrentLocation();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() => _currentPosition = position);
      await _fetchNearbyPharmacies();
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isLoading = false);
      _showErrorSnackbar(tr("location_error"));
    }
  }

  Future<void> _fetchNearbyPharmacies() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _pharmacies = [];
      _selectedPharmacyIndex = null;
    });

    try {
      final pharmacies = await _fetchPharmaciesFromOverpass();
      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => _isLoading = false);
      _showErrorSnackbar(tr("fetch_pharmacies_error"));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPharmaciesFromOverpass() async {
    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    final overpassQuery = """
      [out:json];
      node["amenity"="pharmacy"](around:20000,$lat,$lon);
      out body;
      >;
      out skel qt;
    """;

    final response = await http.get(Uri.parse(
        "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}"));

    if (response.statusCode != 200) {
      throw Exception('Failed to load pharmacies');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    return _processPharmacyData(data['elements']);
  }

  List<Map<String, dynamic>> _processPharmacyData(List<dynamic> elements) {
    final pharmacies =
        elements.where((e) => e['type'] == 'node').map((element) {
      final tags = element['tags'] ?? {};
      final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            element['lat'],
            element['lon'],
          ) /
          1000;

      return {
        'id': element['id'],
        'name': tags['name:en'] ?? tags['name'] ?? tr("unknown_pharmacy"),
        'address': tags['addr:full'] ??
            tags['addr:street'] ??
            tr("address_not_available"),
        'phone': tags['phone'] ?? tags['contact:phone'] ?? tr("no_phone"),
        'lat': element['lat'],
        'lon': element['lon'],
        'distance': distance.toStringAsFixed(1),
        'opening_hours': tags['opening_hours'] ?? tr("not_specified"),
      };
    }).toList();

    pharmacies.sort((a, b) =>
        double.parse(a['distance']).compareTo(double.parse(b['distance'])));

    return pharmacies;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _zoomToPharmacy(int index) {
    final pharmacy = _pharmacies[index];
    _mapController.move(
      LatLng(pharmacy['lat'], pharmacy['lon']),
      16.0,
    );
    setState(() => _selectedPharmacyIndex = index);
  }

  Future<void> _launchMaps(double lat, double lon) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorSnackbar(tr("maps_error"));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorSnackbar(tr("call_error"));
    }
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.medi_spot',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              child: Container(
                child: Icon(
                  Icons.person_pin_circle,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
            ),
            ..._pharmacies.asMap().entries.map((entry) {
              final index = entry.key;
              final pharmacy = entry.value;
              return Marker(
                point: LatLng(pharmacy['lat'], pharmacy['lon']),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPharmacyIndex = index),
                  child: Icon(
                    Icons.local_pharmacy,
                    size: 40,
                    color: _selectedPharmacyIndex == index
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPharmacyList() {
    if (_pharmacies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              tr("no_pharmacies_found"),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = _pharmacies[index];
        return _buildPharmacyCard(pharmacy, index);
      },
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _zoomToPharmacy(index),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_pharmacy,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      pharmacy['address'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.directions_walk,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${pharmacy['distance']} km',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            pharmacy['opening_hours'],
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pharmacy['phone'] != tr("no_phone"))
                    IconButton(
                      icon: Icon(Icons.phone, color: Colors.green),
                      iconSize: 30,
                      onPressed: () => _makePhoneCall(pharmacy['phone']),
                    ),
                  IconButton(
                    icon: Icon(Icons.directions, color: Colors.blue),
                    iconSize: 30,
                    onPressed: () =>
                        _launchMaps(pharmacy['lat'], pharmacy['lon']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("pharmacies")),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNearbyPharmacies,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 50, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        _locationServiceEnabled
                            ? tr("location_permission_denied")
                            : tr("location_service_disabled"),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkLocationServices,
                        child: Text(tr("enable_location")),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildMap(),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildPharmacyList(),
                    ),
                  ],
                ),
    );
  }
}
