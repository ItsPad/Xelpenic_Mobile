import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xelpenic/screens/notificationscreen.dart';

class NowShowingScreen extends StatefulWidget {
  const NowShowingScreen({super.key});

  @override
  State<NowShowingScreen> createState() => _NowShowingScreenState();
}

class _NowShowingScreenState extends State<NowShowingScreen> {
  final _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _nowShowingMoveis;

  final List<String> _categories = [
    'กำลังฉาย',
    'IMAX',
    '4DX',
    'Atmos+',
    'ScreenX',
    'Kids',
  ];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  void _fetchMovies() {
    _nowShowingMoveis = _supabase
        .from('movies')
        .select()
        .eq('movie_showing', true)
        .order('movie_release', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () => {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))
            }
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFB09260)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            Expanded(child: _buildMovieGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFCFB994),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
                //เพิ่ม filter ในอนาคตต่อไปรอก่อนนะ
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCFB994)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF6A6868),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildMovieGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _nowShowingMoveis,
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());//ระหว่างรอให้โชว์วงกลมหมุนๆ
        }
        if(snapshot.hasError) {
          return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
        }
        final movies = snapshot.data ?? [];
        if(movies.isEmpty) {
          return const Center(child: Text('ไม่มีภาพยนตร์กำลังฉาย'));
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, //2 column
            childAspectRatio: 0.55, // ปรับสัดส่วนการ์ด
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index){
            final movie = movies[index];
            return _buildMovieCard(movie);
          },
        );
      },
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie){
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  movie['movie_post'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, StackTrace) => Container(
                    color:Colors.grey.shade300,
                    child: const Icon(Icons.movie, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              movie['movie_title']?.toString().toUpperCase() ?? 'Unknow Title',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              movie['movie_genre']?.toString().toUpperCase() ?? 'Unknow Genre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              movie['movie_release'] ?? 'N/A',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              )
            )
          ]
        )
      )
    );
  }
}
