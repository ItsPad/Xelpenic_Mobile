import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'seat_selection_screen.dart';


class MovieDetailScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late YoutubePlayerController _controller;
  final _supabase = Supabase.instance.client;

  // คุมโทนสี หรูหรา ขาว-ดำ-ทอง
  final Color goldColor = const Color(0xFFDDAA55);
  final Color blackColor = const Color(0xFF141414); // ดำลึกๆ ดูพรีเมียม
  final Color greyBorder = Colors.grey.shade200;

  DateTime _selectedDate = DateTime.now();
  final List<DateTime> _dateList = [];

  @override
  void initState() {
    super.initState();
    final trailerUrl = widget.movie['movie_trailer'] ?? "";
    final videoId = YoutubePlayer.convertUrlToId(trailerUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? 'dQw4w9WgXcQ',
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    for (int i = 0; i < 7; i++) {
      _dateList.add(DateTime.now().add(Duration(days: i)));
    }
  }

  Future<List<Map<String, dynamic>>> _getShowtimes() async {
    final data = await _supabase
        .from('cinema')
        .select('*, showtime!inner(*, theater(*))')
        .eq('showtime.st_movie_id', widget.movie['movie_id']);

    return List<Map<String, dynamic>>.from(data);
  }

  String _getThaiDayName(DateTime date, int index) {
    if (index == 0) return "วันนี้";
    const thaiDays = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
    return thaiDays[date.weekday % 7];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังขาวล้วน มินิมอลสุด
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: blackColor,
            iconTheme: IconThemeData(color: goldColor),
            flexibleSpace: FlexibleSpaceBar(
              background: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressColors: ProgressBarColors(
                  playedColor: goldColor,
                  handleColor: goldColor,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ), // เพิ่ม Padding ให้ดูโปร่ง
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie['movie_title'] ?? 'ไม่ทราบชื่อภาพยนตร์',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: blackColor,
                      letterSpacing: 0.5, // เพิ่มช่องไฟให้ดูแพง
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${widget.movie['movie_genre'] ?? ''}  |  ${widget.movie['movie_duration'] ?? '0'} MIN",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "SYNOPSIS", // ใช้ภาษาอังกฤษบางจุดช่วยเพิ่มความ Luxury
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: goldColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.movie['movie_desc'] ?? 'ไม่มีข้อมูลเนื้อเรื่อง',
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.8, // เพิ่มความห่างบรรทัดให้อ่านง่าย
                      fontSize: 14,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: greyBorder, thickness: 1),
                  ),

                  // ส่วนเลือกวันที่
                  _buildDateSelector(),
                  const SizedBox(height: 30),

                  Text(
                    "SHOWTIMES",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: blackColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCinemaList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // แถบเลือกวันที่ (Minimalist Black & Gold)
  // แถบเลือกวันที่ (แก้ไขวงเล็บและเพิ่ม Gradient)
  Widget _buildDateSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dateList.length,
        itemBuilder: (context, index) {
          DateTime date = _dateList[index];
          bool isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 55,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                // ถ้าเลือกให้แสดง Gradient ถ้าไม่เลือกให้เป็นสีขาว
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color.fromARGB(255, 223, 186, 121),
                        ], // ไล่โทนขาว-ทอง
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(
                  8,
                ), // เพิ่มความโค้งมนให้กล่อง
                border: Border.all(width: 1, color: const Color(0xFFB09260)),
              ),
              // child ต้องอยู่ "ใน" Container นะครับ
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getThaiDayName(date, index),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      // เปลี่ยนสีตัวหนังสือตอนเลือกเป็นสีดำเพื่อให้ตัดกับพื้นหลัง Gradient ขาว-ทอง
                      color: isSelected ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black87 : blackColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCinemaList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getShowtimes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                color: goldColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final allCinemas = snapshot.data ?? [];

        // กรองวันที่
        final filteredCinemas = allCinemas
            .map((cinema) {
              final List allShowtimes = cinema['showtime'] ?? [];
              final filteredShowtimes = allShowtimes.where((st) {
                DateTime stTime = DateTime.parse(st['st_time']).toLocal();
                return stTime.year == _selectedDate.year &&
                    stTime.month == _selectedDate.month &&
                    stTime.day == _selectedDate.day;
              }).toList();

              return {...cinema, 'showtime': filteredShowtimes};
            })
            .where((cinema) => (cinema['showtime'] as List).isNotEmpty)
            .toList();

        if (filteredCinemas.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.theaters_outlined,
                    size: 40,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "NO SHOWTIMES AVAILABLE",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredCinemas.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final cinema = filteredCinemas[index];
            final List showtimes = cinema['showtime'];

            Map<String, List<dynamic>> groupedShowtimes = {};
            for (var st in showtimes) {
              String theaterName = st['theater']?['tt_name'] ?? 'THEATER';
              if (!groupedShowtimes.containsKey(theaterName)) {
                groupedShowtimes[theaterName] = [];
              }
              groupedShowtimes[theaterName]!.add(st);
            }

            // --- เปลี่ยนพื้นหลังเป็นสีดำ คุมโทน Luxury ---
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                collapsedIconColor: goldColor, // ลูกศรตอนปิดเป็นสีทอง
                iconColor: goldColor, // ลูกศรตอนเปิดเป็นสีทอง
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: const Border(),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: cinema['cm_image_url'] ?? '',
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade900,
                      child: Icon(Icons.theaters, color: goldColor, size: 24),
                    ),
                  ),
                ),
                title: Text(
                  cinema['cm_name'] ?? 'XELPENIC CINEMA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color.fromARGB(255, 223, 186, 121),
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groupedShowtimes.entries.map((entry) {
                        String theaterName = entry.key;
                        List<dynamic> timesInThisTheater = entry.value;

                        timesInThisTheater.sort(
                          (a, b) => DateTime.parse(
                            a['st_time'],
                          ).compareTo(DateTime.parse(b['st_time'])),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    theaterName.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color.fromARGB(255, 223, 186, 121),
                                      letterSpacing: 1,
                                    ), // ชื่อโรงสีขาว
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'TH',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: goldColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '2D',
                                      style: TextStyle(
                                        color: blackColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ), // ตัวหนังสือ 2D เป็นสีดำเพื่อตัดกับป้ายสีทอง
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: timesInThisTheater.map((st) {
                                  DateTime time = DateTime.parse(
                                    st['st_time'],
                                  ).toLocal();
                                  String formattedTime = DateFormat(
                                    'HH:mm',
                                  ).format(time);

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SeatSelectionScreen(
                                            movie: widget.movie,
                                            cinemaName:
                                                cinema['cm_name'] ??
                                                'Unknown Cinema',
                                            theaterName: theaterName,
                                            showTime: formattedTime,
                                            showtimeData:
                                                st, // ส่งข้อมูลก้อนนี้ไปเพื่อใช้บันทึกตั๋ว (มี st_id, st_tt_id ฯลฯ)
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .transparent, // ปล่อยใสให้เห็นพื้นหลังสีดำ
                                        border: Border.all(
                                          color: goldColor,
                                          width: 1.2,
                                        ), // เส้นกรอบทอง
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color:
                                              goldColor, // ตัวหนังสือเวลาสีทอง
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              Divider(
                                color: Colors.white.withOpacity(0.1),
                                thickness: 1,
                              ), // เส้นคั่นสีเทาเข้มๆ ไม่กวนสายตา
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
