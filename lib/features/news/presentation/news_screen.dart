import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../data/models/market_news_article.dart';
import '../data/services/market_news_service.dart';

enum NewsSortOption {
  newest,
  oldest,
  alphabeticAz,
  alphabeticZa,
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final MarketNewsService _newsService = MarketNewsService();
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 8;

  List<MarketNewsArticle> _articles = const [];
  String? _errorMessage;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  NewsSortOption _sortOption = NewsSortOption.newest;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refreshNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshNews() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final page = await _newsService.fetchNewsPage(
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _articles = _applySorting(page.articles);
        _hasMore = page.hasMore;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load latest market news. Pull down or tap refresh.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || _isLoadingInitial || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final page = await _newsService.fetchNewsPage(
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _currentPage = nextPage;
        _articles = _applySorting([..._articles, ...page.articles]);
        _hasMore = page.hasMore;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load more news right now.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMoreNews();
    }
  }

  String _formatPublishedAt(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  List<MarketNewsArticle> _applySorting(List<MarketNewsArticle> input) {
    final sorted = [...input];

    switch (_sortOption) {
      case NewsSortOption.newest:
        sorted.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case NewsSortOption.oldest:
        sorted.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
        break;
      case NewsSortOption.alphabeticAz:
        sorted.sort(
          (a, b) => _sortTitleKey(a.title).compareTo(_sortTitleKey(b.title)),
        );
        break;
      case NewsSortOption.alphabeticZa:
        sorted.sort(
          (a, b) => _sortTitleKey(b.title).compareTo(_sortTitleKey(a.title)),
        );
        break;
    }

    return sorted;
  }

  String _sortTitleKey(String title) {
    return title.trim().toLowerCase();
  }

  void _onSortChanged(NewsSortOption value) {
    if (_sortOption == value) return;

    setState(() {
      _sortOption = value;
      _articles = _applySorting(_articles);
    });
  }

  String _sortLabel(NewsSortOption option) {
    switch (option) {
      case NewsSortOption.newest:
        return 'Newest';
      case NewsSortOption.oldest:
        return 'Oldest';
      case NewsSortOption.alphabeticAz:
        return 'A-Z';
      case NewsSortOption.alphabeticZa:
        return 'Z-A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _articles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market News'),
        leading: PopupMenuButton<NewsSortOption>(
          tooltip: 'Sort news',
          initialValue: _sortOption,
          onSelected: _onSortChanged,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: NewsSortOption.newest,
              child: Text('Sort by Date: Newest'),
            ),
            PopupMenuItem(
              value: NewsSortOption.oldest,
              child: Text('Sort by Date: Oldest'),
            ),
            PopupMenuItem(
              value: NewsSortOption.alphabeticAz,
              child: Text('Sort by Name: A-Z'),
            ),
            PopupMenuItem(
              value: NewsSortOption.alphabeticZa,
              child: Text('Sort by Name: Z-A'),
            ),
          ],
          icon: const Icon(Icons.sort_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoadingInitial ? null : _refreshNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(hasContent),
    );
  }

  Widget _buildBody(bool hasContent) {
    if (_isLoadingInitial && !hasContent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && !hasContent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshNews,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: _articles.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHero();
          }

          if (index == _articles.length + 1) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!_hasMore) {
              return const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(
                  child: Text(
                    'You are all caught up.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          }

          final article = _articles[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildNewsCard(article),
          );
        },
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.95),
            const Color(0xFF0F3D99),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.newspaper_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Crypto Market Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_articles.length} articles loaded',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sorted: ${_sortLabel(_sortOption)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(MarketNewsArticle article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              if (article.url.isEmpty) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Link: ${article.url}')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumb(article),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5E6270),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                article.source,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF2C3550),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            Text(
                              _formatPublishedAt(article.publishedAt),
                              style: const TextStyle(
                                color: Color(0xFF79829A),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(MarketNewsArticle article) {
    if (article.imageUrl.isEmpty) {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE8EEFF),
        ),
        child: Icon(
          Icons.article_outlined,
          color: AppColors.primary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        article.imageUrl,
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFE8EEFF),
          ),
          child: Icon(
            Icons.article_outlined,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
