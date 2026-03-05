import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MovieDetailScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late YoutubePlayerController _controller;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // 1. จัดการตัวเล่นวิดีโอ (เทคนิคพิเศษข้อ 3.3)
    final trailerUrl = widget.movie['movie_trailer'] ?? "";
    final videoId = YoutubePlayer.convertUrlToId(trailerUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? 'dQw4w9WgXcQ',
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  // 2. ฟังก์ชันดึงสาขา รอบฉาย และข้อมูลโรงภาพยนตร์ (Join 3 ตาราง)
  Future<List<Map<String, dynamic>>> _getShowtimes() async {
    final data = await _supabase
        .from('cinema')
        .select(
          '*, showtime!inner(*, theater(*))',
        ) // ดึงรอบฉายและข้อมูลโรงไปพร้อมกัน
        .eq('showtime.st_movie_id', widget.movie['movie_id']);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ส่วน Banner วิดีโอ
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.brown,
            flexibleSpace: FlexibleSpaceBar(
              background: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.brown,
                  handleColor: Colors.brown,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อเรื่องและประเภท
                  Text(
                    widget.movie['movie_title'] ?? 'ไม่ทราบชื่อภาพยนตร์',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${widget.movie['movie_genre'] ?? ''} • ${widget.movie['movie_duration'] ?? '0'} นาที",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // เรื่องย่อ
                  const Text(
                    "เรื่องย่อ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.movie['movie_desc'] ?? 'ไม่มีข้อมูลเนื้อเรื่อง',
                    style: const TextStyle(color: Colors.black87, height: 1.5),
                  ),

                  const Divider(height: 40),

                  // ส่วนแสดงสาขาและรอบฉาย
                  const Text(
                    "เลือกรอบฉาย",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildCinemaList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Widget รายการสาขาโรงหนัง
  Widget _buildCinemaList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getShowtimes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.brown),
            ),
          );
        }

        final cinemas = snapshot.data ?? [];
        if (cinemas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "ไม่มีรอบฉายสำหรับภาพยนตร์เรื่องนี้ในขณะนี้",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cinemas.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cinema = cinemas[index];
            final List showtimes = cinema['showtime'];

            // --- หัวใจสำคัญ: จัดกลุ่มรอบฉายตามชื่อโรงภาพยนตร์ ---
            Map<String, List<dynamic>> groupedShowtimes = {};
            for (var st in showtimes) {
              String theaterName =
                  st['theater']?['tt_name'] ?? 'โรงภาพยนตร์ทั่วไป';
              if (!groupedShowtimes.containsKey(theaterName)) {
                groupedShowtimes[theaterName] =
                    []; // ถ้ายังไม่มีชื่อโรงนี้ ให้สร้างกลุ่มใหม่
              }
              groupedShowtimes[theaterName]!.add(
                st,
              ); // เอารอบเวลาใส่เข้าไปในโรงนั้นๆ
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                initiallyExpanded: index == 0, // ให้สาขาแรกกางออกอัตโนมัติ
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: cinema['cm_image_url'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.theaters,
                      color: Colors.brown,
                      size: 40,
                    ),
                  ),
                ),
                title: Text(
                  cinema['cm_name'] ?? 'XELPENIC สาขา',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  "5.33 กม.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.brown,
                ),

                // ส่วนแสดงผลโรงภาพยนตร์และเวลาที่อยู่ข้างใน
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // วนลูปตามกลุ่มโรงภาพยนตร์ที่เราจัดไว้
                      children: groupedShowtimes.entries.map((entry) {
                        String theaterName = entry.key;
                        List<dynamic> timesInThisTheater = entry.value;

                        // เรียงเวลาจากน้อยไปมาก (ป้องกันเวลาสลับกัน)
                        timesInThisTheater.sort(
                          (a, b) => DateTime.parse(
                            a['st_time'],
                          ).compareTo(DateTime.parse(b['st_time'])),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. ส่วนหัว: ชื่อโรงภาพยนตร์ (เช่น THEATER 3 | เสียง TH | 2D)
                              Row(
                                children: [
                                  Text(
                                    theaterName.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // 2. ส่วนกล่องเวลา: เอาเวลาทั้งหมดในโรงนี้มาโชว์
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: timesInThisTheater.map((st) {
                                  DateTime time = DateTime.parse(st['st_time']);
                                  String formattedTime = DateFormat(
                                    'HH:mm',
                                  ).format(time);

                                  return InkWell(
                                    onTap: () {
                                      // TODO: ไปหน้าเลือกที่นั่ง
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'เลือก $theaterName รอบ $formattedTime น.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 5),
                              const Divider(
                                color: Colors.black12,
                              ), // เส้นคั่นระหว่างโรง
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
