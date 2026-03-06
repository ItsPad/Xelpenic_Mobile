import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/cinema_branch_schedule_screen.dart';
import 'package:xelpenic/screens/notificationscreen.dart';

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

  String _searchText = '';
  final Set<int> _favoriteCinemas = {};
  final Set<String> _selectedFilters = {};

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
  // รันทั้งคู่พร้อมกัน ใครเสร็จก่อนทำก่อน
  Future.wait([
    _getLocation(),
    _fetchCinemas(),
  ]);
}

  Future<void> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();

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

  List<String> _extractCinemaFormats(Map<String, dynamic> cinema) {
    final dynamic rawFormats = cinema['formats'] ?? cinema['cm_formats'];
    if (rawFormats is List) {
      return rawFormats.map((item) => item.toString()).toList();
    }
    if (rawFormats is String) {
      return rawFormats
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  bool _matchesSelectedFormats(Map<String, dynamic> cinema) {
    if (_selectedFilters.isEmpty) return true;

    final cinemaFormats = _extractCinemaFormats(cinema);

    if (cinemaFormats.isEmpty) {
      return true;
    }

    return cinemaFormats.any(_selectedFilters.contains);
  }

  void _searchCinema(String text) {
    setState(() {
      _searchText = text.toLowerCase();
      _applyFilters();
    });
  }

  void _toggleFavorite(int cinemaId) {
    setState(() {
      if (_favoriteCinemas.contains(cinemaId)) {
        _favoriteCinemas.remove(cinemaId);
      } else {
        _favoriteCinemas.add(cinemaId);
      }
      _applyFilters();
    });
  }

  void _toggleFormatFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
      _applyFilters();
    });
  }

  void _applyFilters() {
    final source = _selectedTopTab == 1
        ? _cinemas.where((c) => _favoriteCinemas.contains(c['cm_id'])).toList()
        : _cinemas;

    _filteredCinemas = source.where((cinema) {
      final name = cinema['cm_name'].toString().toLowerCase();
      final matchesSearch = name.contains(_searchText);
      final matchesFormat = _matchesSelectedFormats(cinema);
      return matchesSearch && matchesFormat;
    }).toList();
  }

  void _openMap({Map<String, dynamic>? focusCinema}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinemaMapScreen(
          cinemas: _filteredCinemas,
          currentPosition: _currentPosition,
          focusCinema: focusCinema,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearbyCinemas = _filteredCinemas
        .where((c) => c['latitude'] != null && c['longitude'] != null)
        .take(3)
        .toList();

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
                    _buildMapLauncher(),
                    const SizedBox(height: 20),
                    if (_selectedTopTab == 0) ...[
                      const Text(
                        'ใกล้เคียง',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (nearbyCinemas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('ยังไม่มีสาขาใกล้เคียงในรายการนี้'),
                        )
                      else
                        ...nearbyCinemas.map(_buildCinemaItem),
                      const SizedBox(height: 12),
                      const Text(
                        'สาขาทั้งหมด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      const Text(
                        'สาขาที่ชอบ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_filteredCinemas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ยังไม่มีสาขาที่ตรงกับเงื่อนไขที่เลือก'),
                      )
                    else
                      ..._filteredCinemas.map(_buildCinemaItem),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMapLauncher() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _openMap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EFE6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBAE82)),
        ),
        child: const Row(
          children: [
            Icon(Icons.map_outlined, color: Color(0xFF8B5E3C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'เปิดแผนที่โรงหนัง',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8B5E3C)),
          ],
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
            _applyFilters();
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
      ],
    );
  }

  Widget _buildFilterTags() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final label = _filters[index];
          final isSelected = _selectedFilters.contains(label);

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _toggleFormatFilter(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCBAE82) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFCBAE82)
                      : Colors.brown.shade200,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
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
              icon: const Icon(Icons.map_outlined, color: Colors.brown),
              onPressed: () => _openMap(focusCinema: cinema),
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

class CinemaMapScreen extends StatefulWidget {
  const CinemaMapScreen({
    required this.cinemas,
    required this.currentPosition,
    this.focusCinema,
    super.key,
  });

  final List<Map<String, dynamic>> cinemas;
  final Position? currentPosition;
  final Map<String, dynamic>? focusCinema;

  @override
  State<CinemaMapScreen> createState() => _CinemaMapScreenState();
}

class _CinemaMapScreenState extends State<CinemaMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCinemaId;
  String _query = '';

  String _normalizeText(dynamic value) {
    return value?.toString().toLowerCase().trim() ?? '';
  }

  List<Map<String, dynamic>> get _searchMatches {
    if (_query.trim().isEmpty) return widget.cinemas;

    final query = _query.toLowerCase().trim();
    return widget.cinemas.where((cinema) {
      final name = _normalizeText(cinema['cm_name']);
      final mapInfo = _normalizeText(cinema['cm_map_url']);
      return name.contains(query) || mapInfo.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _visibleCinemas {
    return _searchMatches;
  }

  Map<String, dynamic>? get _selectedCinema {
    if (_selectedCinemaId == null) return null;
    for (final cinema in widget.cinemas) {
      if (cinema['cm_id'] == _selectedCinemaId) {
        return cinema;
      }
    }
    return null;
  }

  LatLng get _defaultCenter {
    final focus = widget.focusCinema;
    if (focus != null &&
        focus['latitude'] != null &&
        focus['longitude'] != null) {
      return LatLng(focus['latitude'], focus['longitude']);
    }
    if (widget.currentPosition != null) {
      return LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }
    return const LatLng(13.736717, 100.523186);
  }

  @override
  void initState() {
    super.initState();
    _selectedCinemaId = widget.focusCinema?['cm_id'] as int?;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _moveToCinema(Map<String, dynamic> cinema) {
    if (cinema['latitude'] == null || cinema['longitude'] == null) return;

    _mapController.move(LatLng(cinema['latitude'], cinema['longitude']), 15);

    setState(() {
      _selectedCinemaId = cinema['cm_id'] as int?;
    });
  }

  void _onMapSearchChanged(String value) {
    setState(() {
      _query = value;
    });

    final matches = _searchMatches;
    if (value.trim().isNotEmpty && matches.length == 1) {
      _moveToCinema(matches.first);
    }
  }

  void _submitMapSearch() {
    final matches = _searchMatches;
    if (matches.isNotEmpty) {
      _moveToCinema(matches.first);
    }
  }

  void _openCinemaListSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final cinemas = _visibleCinemas;
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'รายการโรงภาพยนตร์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: cinemas.length,
                    itemBuilder: (_, index) {
                      final cinema = cinemas[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.amber,
                        ),
                        title: Text(
                          cinema['cm_name']?.toString() ?? '-',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          cinema['cm_map_url']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _moveToCinema(cinema);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCinema = _selectedCinema;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _defaultCenter, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.xel.xelpenic',
              ),
              MarkerLayer(markers: _buildMapMarkers()),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: _onMapSearchChanged,
                            onSubmitted: (_) => _submitMapSearch(),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาโรงภาพยนตร์',
                              hintStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        _onMapSearchChanged('');
                                      },
                                      icon: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.white38,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (selectedCinema != null)
                    _buildSelectedCinemaCard(selectedCinema),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: selectedCinema != null ? 150 : 30,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'my-location-btn',
                  mini: true,
                  backgroundColor: const Color.fromARGB(255, 206, 181, 106),
                  onPressed: () {
                    if (widget.currentPosition == null) return;
                    _mapController.move(
                      LatLng(
                        widget.currentPosition!.latitude,
                        widget.currentPosition!.longitude,
                      ),
                      14,
                    );
                  },
                  child: const Icon(Icons.near_me, color: Colors.black),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'cinema-list-btn',
                  backgroundColor: const Color.fromARGB(255, 206, 179, 99),
                  onPressed: _openCinemaListSheet,
                  icon: const Icon(Icons.list, color: Colors.black),
                  label: const Text(
                    'รายการ',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCinemaCard(Map<String, dynamic> cinema) {
    final address = cinema['cm_map_url']?.toString().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XELPENIC ${cinema['cm_name']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (address == null || address.isEmpty)
                ? 'ไม่มีข้อมูลตำแหน่งที่ตั้ง'
                : address,
            style: const TextStyle(color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.amber),
              foregroundColor: Colors.amber,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CinemaBranchScheduleScreen(cinema: cinema),
                ),
              );
            },
            icon: const Icon(Icons.local_movies_outlined),
            label: const Text('ดูโรงภาพยนตร์'),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMapMarkers() {
    final markers = <Marker>[];

    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.red, size: 32),
        ),
      );
    }

    for (final cinema in _visibleCinemas) {
      if (cinema['latitude'] == null || cinema['longitude'] == null) {
        continue;
      }

      final cinemaId = cinema['cm_id'] as int?;
      final selected = cinemaId != null && cinemaId == _selectedCinemaId;

      markers.add(
        Marker(
          width: 42,
          height: 42,
          point: LatLng(cinema['latitude'], cinema['longitude']),
          child: GestureDetector(
            onTap: () => _moveToCinema(cinema),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xFFD44A4A)
                    : const Color(0xFFB88352),
                border: Border.all(
                  color: Colors.white,
                  width: selected ? 2.5 : 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'X',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
