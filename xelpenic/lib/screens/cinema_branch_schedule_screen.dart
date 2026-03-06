import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CinemaBranchScheduleScreen extends StatefulWidget {
  const CinemaBranchScheduleScreen({required this.cinema, super.key});

  final Map<String, dynamic> cinema;

  @override
  State<CinemaBranchScheduleScreen> createState() =>
      _CinemaBranchScheduleScreenState();
}

class _CinemaBranchScheduleScreenState
    extends State<CinemaBranchScheduleScreen> {
  final _supabase = Supabase.instance.client;

  static const List<String> _movieFilters = [
    'IMAX',
    'Dolby Vision+Atmos',
    '4DX',
    'Screen X',
    'KIDS',
    'LED',
  ];

  late final List<DateTime> _dateOptions;
  late Future<List<_MovieSchedule>> _scheduleFuture;
  int _selectedDateIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateOptions = List.generate(
      4,
      (index) => DateTime(now.year, now.month, now.day + index),
    );
    _scheduleFuture = _fetchSchedule();
  }

  Future<List<_MovieSchedule>> _fetchSchedule() async {
    final cinemaId = widget.cinema['cm_id'];
    final selectedDate = _dateOptions[_selectedDateIndex];

    final startDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endDate = startDate.add(const Duration(days: 1));

    final response = await _supabase
        .from('showtime')
        .select(
          'st_id, st_time, st_movie_id, st_tt_id, '
          'movies(movie_id, movie_title, movie_post, movie_genre, movie_duration), '
          'theater(tt_id, tt_name)',
        )
        .eq('st_cm_id', cinemaId)
        .gte('st_time', startDate.toIso8601String())
        .lt('st_time', endDate.toIso8601String())
        .order('st_time', ascending: true);

    final rows = List<Map<String, dynamic>>.from(response);
    final movieMap = <int, _MovieSchedule>{};

    for (final row in rows) {
      final movie = row['movies'] as Map<String, dynamic>?;
      final movieId = (movie?['movie_id'] ?? row['st_movie_id']) as int?;
      if (movieId == null) continue;

      final theater = row['theater'] as Map<String, dynamic>?;
      final theaterName =
          theater?['tt_name']?.toString().trim().isNotEmpty == true
          ? theater!['tt_name'].toString()
          : 'theatre';

      final stTime = DateTime.tryParse(row['st_time']?.toString() ?? '');
      if (stTime == null) continue;

      final schedule = movieMap.putIfAbsent(
        movieId,
        () => _MovieSchedule(
          title: movie?['movie_title']?.toString() ?? '-',
          genre: movie?['movie_genre']?.toString() ?? '-',
          duration: _formatDuration(movie?['movie_duration']),
          posterUrl: movie?['movie_post']?.toString(),
          theatres: {},
        ),
      );

      final times = schedule.theatres.putIfAbsent(theaterName, () => []);
      times.add(_formatTime(stTime.toLocal()));
    }

    return movieMap.values.toList();
  }

  String _formatDuration(dynamic value) {
    final duration = int.tryParse(value?.toString() ?? '');
    if (duration == null || duration <= 0) return 'movie_duration';
    return '$duration นาที';
  }

  String _formatTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatMonth(DateTime dateTime) {
    const months = [
      'ม.ค',
      'ก.พ',
      'มี.ค',
      'เม.ย',
      'พ.ค',
      'มิ.ย',
      'ก.ค',
      'ส.ค',
      'ก.ย',
      'ต.ค',
      'พ.ย',
      'ธ.ค',
    ];
    return months[dateTime.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.cinema['cm_image_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F2F2),
      appBar: AppBar(
        title: const Text('Movie cinema'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            height: 180,
            color: Colors.black12,
            child: imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'X',
                        style: TextStyle(
                          color: Color(0xFFCBAE82),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.cinema['cm_name']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'ที่อยู่ ปัจจุบัน',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_dateOptions.length, (index) {
                      final date = _dateOptions[index];
                      return _DateChip(
                        text: date.day.toString().padLeft(2, '0'),
                        month: _formatMonth(date),
                        selected: _selectedDateIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedDateIndex = index;
                            _scheduleFuture = _fetchSchedule();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 20,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _movieFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, index) => Text(
                        _movieFilters[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<_MovieSchedule>>(
            future: _scheduleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('โหลดรอบฉายไม่สำเร็จ')),
                );
              }

              final movies = snapshot.data ?? [];
              if (movies.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('ยังไม่มีรอบฉายในวันนี้')),
                );
              }

              return Column(
                children: movies
                    .map((movie) => _MovieShowtimeCard(movie: movie))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.text,
    required this.month,
    required this.onTap,
    this.selected = false,
  });

  final String text;
  final String month;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCBAE82) : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black38),
        ),
        child: Column(
          children: [
            Text(
              month,
              style: const TextStyle(fontSize: 8, color: Colors.black87),
            ),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieSchedule {
  _MovieSchedule({
    required this.title,
    required this.genre,
    required this.duration,
    required this.posterUrl,
    required this.theatres,
  });

  final String title;
  final String genre;
  final String duration;
  final String? posterUrl;
  final Map<String, List<String>> theatres;
}

class _MovieShowtimeCard extends StatelessWidget {
  const _MovieShowtimeCard({required this.movie});

  final _MovieSchedule movie;

  @override
  Widget build(BuildContext context) {
    final theatreEntries = movie.theatres.entries.toList();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                    ? Image.network(
                        movie.posterUrl!,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.movie, color: Colors.black45),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      movie.genre,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      movie.duration,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...theatreEntries.map(
            (theatreEntry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theatreEntry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.volume_up, size: 14, color: Color(0xFFB08C55)),
                      SizedBox(width: 4),
                      Text(
                        'TH',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.closed_caption,
                        size: 14,
                        color: Color(0xFFB08C55),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'EN',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: theatreEntry.value.map((time) {
                      return Container(
                        width: 64,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB9BDC2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
