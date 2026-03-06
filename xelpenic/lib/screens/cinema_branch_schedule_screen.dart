import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/seat_selection_screen.dart';

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
  final Set<String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateOptions = List.generate(
      7,
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
          'st_id, st_time, st_movie_id, st_tt_id, st_cm_id, '
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
          movie: movie ?? {'movie_id': movieId},
        ),
      );

      final times = schedule.theatres.putIfAbsent(theaterName, () => []);
      times.add(
        _ShowtimeItem(
          showtimeData: row,
          dateTime: stTime.toLocal(),
          formattedTime: _formatTime(stTime.toLocal()),
        ),
      );
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

  String _formatThaiDayName(DateTime date) {
    final today = DateTime.now();
    if (date.day == today.day &&
        date.month == today.month &&
        date.year == today.year) {
      return 'วันนี้';
    }

    const thaiDays = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
    return thaiDays[date.weekday % 7];
  }

  void _toggleFormatFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
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
                  Text(
                    widget.cinema['cm_address']?.toString().trim().isNotEmpty ==
                            true
                        ? widget.cinema['cm_address'].toString()
                        : (widget.cinema['cm_map_url']?.toString() ?? '-'),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dateOptions.length,
                      itemBuilder: (_, index) {
                        final date = _dateOptions[index];
                        return _DateChip(
                          text: date.day.toString().padLeft(2, '0'),
                          dayName: _formatThaiDayName(date),
                          selected: _selectedDateIndex == index,
                          onTap: () {
                            setState(() {
                              _selectedDateIndex = index;
                              _scheduleFuture = _fetchSchedule();
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _movieFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final label = _movieFilters[index];
                        final isSelected = _selectedFilters.contains(label);

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _toggleFormatFilter(label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFCBAE82)
                                  : Colors.white,
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
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
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
                    .map(
                      (movie) => _MovieShowtimeCard(
                        movie: movie,
                        cinemaName: widget.cinema['cm_name']?.toString() ?? '-',
                        selectedDate: _dateOptions[_selectedDateIndex],
                      ),
                    )
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
    required this.dayName,
    required this.onTap,
    this.selected = false,
  });

  final String text;
  final String dayName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        margin: const EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFE4CCA2)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCFB994)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 0.95,
              ),
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
    required this.movie,
  });

  final String title;
  final String genre;
  final String duration;
  final String? posterUrl;
  final Map<String, List<_ShowtimeItem>> theatres;
  final Map<String, dynamic> movie;
}

class _ShowtimeItem {
  const _ShowtimeItem({
    required this.showtimeData,
    required this.dateTime,
    required this.formattedTime,
  });

  final Map<String, dynamic> showtimeData;
  final DateTime dateTime;
  final String formattedTime;
}

class _MovieShowtimeCard extends StatelessWidget {
  const _MovieShowtimeCard({
    required this.movie,
    required this.cinemaName,
    required this.selectedDate,
  });

  final _MovieSchedule movie;
  final String cinemaName;
  final DateTime selectedDate;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
                    children: theatreEntry.value.map((showtime) {
                      final now = DateTime.now();
                      final isExpired = showtime.dateTime.isBefore(now);
                      final isToday = _isSameDay(selectedDate, now);
                      final isCurrentBookable = !isExpired && isToday;

                      return InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: isExpired
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeatSelectionScreen(
                                      movie: movie.movie,
                                      cinemaName: cinemaName,
                                      theaterName: theatreEntry.key,
                                      showTime: DateFormat(
                                        'HH:mm',
                                      ).format(showtime.dateTime),
                                      showtimeData: showtime.showtimeData,
                                    ),
                                  ),
                                );
                              },
                        child: Container(
                          width: 78,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isExpired
                                ? const Color(0xFFB9BDC2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isExpired
                                  ? const Color(0xFFB9BDC2)
                                  : isCurrentBookable
                                  ? const Color(0xFFE0B56A)
                                  : Colors.black87,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            showtime.formattedTime,
                            style: TextStyle(
                              color: isExpired
                                  ? Colors.white
                                  : isCurrentBookable
                                  ? const Color(0xFFE0B56A)
                                  : Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
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
