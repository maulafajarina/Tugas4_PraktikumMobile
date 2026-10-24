import 'package:tugas4/article.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tugas4/api_service.dart';

void main() {
  runApp(const MyApp());
}

// Supaya pull-to-refresh bisa ditarik pakai mouse (Chrome/desktop)
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Berita',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      home: NewsScreen(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Article>> _articlesFuture;

  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // Key untuk memicu animasi RefreshIndicator dari tombol reload
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _articlesFuture = ApiService().fetchArticles();

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 300;
      if (shouldShow != _showBackToTop) {
        setState(() => _showBackToTop = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Dipanggil oleh pull-to-refresh maupun tombol reload
  Future<void> _refreshArticles() async {
    final future = ApiService().fetchArticles();
    setState(() {
      _articlesFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder
    }
  }

  // Tombol reload: tampilkan animasi refresh lalu muat ulang berita
  void _reload() {
    _refreshKey.currentState?.show();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMessage(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text('Aplikasi Berita'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshArticles,
        child: FutureBuilder<List<Article>>(
          future: _articlesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return _buildMessage('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final articles = snapshot.data!;
              return ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Card(
                    child: ListTile(
                      leading: article.urlToImage != null
                          ? Image.network(
                              article.urlToImage!,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.image),
                      title: Text(article.title),
                      subtitle:
                          Text(article.description ?? 'Tidak ada deskripsi'),
                    ),
                  );
                },
              );
            } else {
              return _buildMessage('Tidak ada berita');
            }
          },
        ),
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.lightBlue,
              tooltip: 'Kembali ke atas',
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}