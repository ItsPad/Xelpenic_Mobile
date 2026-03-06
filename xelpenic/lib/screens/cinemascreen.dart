import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/notificationscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xelpenic/screens/cinema_branch_schedule_screen.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  final _supabase = Supabase.instance.client;

  Position? _currentPosition;

  List<Map<String, dynamic>> _cinemas = [];
  List<Map<String, dynamic>> _filteredCinemas = [];

  List<Marker> _buildMapMarkers() {
    List<Marker> markers = [];

    /// USER LOCATION (เป็นหมุดแดง)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 35),
        ),
      );
    }

    /// CINEMA MARKERS (เป็นวงกลม X)
    for (var cinema in _cinemas) {
      if (cinema['latitude'] != null && cinema['longitude'] != null) {
        markers.add(
          Marker(
            point: LatLng(cinema['latitude'], cinema['longitude']),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CinemaBranchScheduleScreen(cinema: cinema),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFCBAE82), width: 2),
                ),
                child: const Text(
                  'X',
                  style: TextStyle(
                    color: Color(0xFFCBAE82),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  String _searchText = '';

  Set<int> _favoriteCinemas = {};

  int _selectedTopTab = 0;

  final List<String> _filters = [
    'IMAX',
    'Dolby Vision+Atmos',
    '4DX',
    'Screen X',
    'KIDS',
    'LED',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getLocation();
    await _fetchCinemas();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _fetchCinemas() async {
    final data = await _supabase.from('cinema').select().order('cm_name');

    _cinemas = List<Map<String, dynamic>>.from(data);

    _sortByDistance();

    setState(() {
      _filteredCinemas = _cinemas;
    });
  }

  void _sortByDistance() {
    if (_currentPosition == null) return;

    _cinemas.sort((a, b) {
      final distA = _calculateDistance(a);
      final distB = _calculateDistance(b);
      return distA.compareTo(distB);
    });
  }

  double _calculateDistance(Map<String, dynamic> cinema) {
    if (_currentPosition == null ||
        cinema['latitude'] == null ||
        cinema['longitude'] == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          cinema['latitude'],
          cinema['longitude'],
        ) /
        1000;
  }

  void _searchCinema(String text) {
    setState(() {
      _searchText = text.toLowerCase();

      _filteredCinemas = _cinemas.where((cinema) {
        final name = cinema['cm_name'].toString().toLowerCase();
        return name.contains(_searchText);
      }).toList();
    });
  }

  void _toggleFavorite(int cinemaId) {
    setState(() {
      if (_favoriteCinemas.contains(cinemaId)) {
        _favoriteCinemas.remove(cinemaId);
      } else {
        _favoriteCinemas.add(cinemaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'XELPENIC',
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.brown),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _cinemas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopTabs(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterTags(),
                    const SizedBox(height: 16),

                    /// MAP
                    SizedBox(
                      height: 220,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _currentPosition != null
                              ? LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                )
                              : const LatLng(13.736717, 100.523186),
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),

                          /// MARKERS
                          MarkerLayer(markers: _buildMapMarkers()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'ใกล้เคียง',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ..._filteredCinemas
                        .take(2)
                        .map((cinema) => _buildCinemaItem(cinema)),

                    const SizedBox(height: 24),

                    const Text(
                      'สาขาทั้งหมด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ..._filteredCinemas.map(
                      (cinema) => _buildCinemaItem(cinema),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopTabs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFD4C1A0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabButton('สาขาทั้งหมด', 0),
          _buildTabButton('สาขาที่ชอบ', 1),
          _buildTabButton('ล่าสุด', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTopTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTopTab = index;

            if (index == 1) {
              _filteredCinemas = _cinemas
                  .where((c) => _favoriteCinemas.contains(c['cm_id']))
                  .toList();
            } else {
              _filteredCinemas = _cinemas;
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCBAE82) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: _searchCinema,
              decoration: InputDecoration(
                hintText: 'ค้นหา',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.filter_list, color: Colors.brown),
      ],
    );
  }

  Widget _buildFilterTags() {
    return SizedBox(
      height: 20,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, index) {
          return Text(
            _filters[index],
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCinemaItem(Map<String, dynamic> cinema) {
    final distance = _calculateDistance(cinema);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CinemaBranchScheduleScreen(cinema: cinema),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/x_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'XELPENIC ${cinema['cm_name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${distance.toStringAsFixed(2)} กม.',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _favoriteCinemas.contains(cinema['cm_id'])
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.brown,
              ),
              onPressed: () => _toggleFavorite(cinema['cm_id']),
            ),
          ],
        ),
      ),
    );
  }
}
