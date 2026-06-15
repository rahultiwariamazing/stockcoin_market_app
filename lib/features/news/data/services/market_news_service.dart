import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../models/market_news_article.dart';

class MarketNewsPage {
  final List<MarketNewsArticle> articles;
  final bool hasMore;

  const MarketNewsPage({
    required this.articles,
    required this.hasMore,
  });
}

class MarketNewsService {
  final Dio _dio;

  MarketNewsService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://cointelegraph.com/',
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
              ),
            );

  Future<MarketNewsPage> fetchNewsPage({
    required int page,
    int pageSize = 10,
  }) async {
    final response = await _dio.get<String>('rss');
    final body = response.data;

    if (body == null || body.trim().isEmpty) {
      throw Exception('News feed is empty');
    }

    final document = XmlDocument.parse(body);
    final itemNodes = document.findAllElements('item').toList();

    final start = max(0, (page - 1) * pageSize);
    if (start >= itemNodes.length) {
      return const MarketNewsPage(articles: [], hasMore: false);
    }

    final end = min(start + pageSize, itemNodes.length);
    final slice = itemNodes.sublist(start, end);

    final articles = slice
        .map((item) {
          final title = _readNodeText(item, 'title', fallback: 'Untitled');
          final link = _readNodeText(item, 'link');
          final descriptionHtml = _readNodeText(item, 'description');
          final description = _stripHtml(descriptionHtml);
          final pubDateRaw = _readNodeText(item, 'pubDate');
          final creator = _readNodeText(item, 'dc:creator', fallback: 'Cointelegraph');
          final guid = _readNodeText(item, 'guid', fallback: link);
          final imageUrl = _readImageUrl(item, descriptionHtml);

          return MarketNewsArticle(
            id: guid.isEmpty ? '${title}_${pubDateRaw}' : guid,
            title: title,
            summary: description.isEmpty ? 'No summary available.' : description,
            source: creator,
            url: link,
            imageUrl: imageUrl,
            publishedAt: _parseDate(pubDateRaw),
          );
        })
        .where((article) => article.title.trim().isNotEmpty)
        .toList();

    return MarketNewsPage(
      articles: articles,
      hasMore: end < itemNodes.length,
    );
  }

  String _readNodeText(
    XmlElement element,
    String nodeName, {
    String fallback = '',
  }) {
    final nodes = element.findElements(nodeName);
    if (nodes.isEmpty) return fallback;
    return nodes.first.innerText.trim();
  }

  String _readImageUrl(XmlElement item, String descriptionHtml) {
    final mediaNodes = item.findElements('media:content');
    final mediaContent = mediaNodes.isEmpty ? null : mediaNodes.first;
    final directImage = mediaContent?.getAttribute('url')?.trim() ?? '';
    if (directImage.isNotEmpty) return directImage;

    final match = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false)
        .firstMatch(descriptionHtml);
    return match?.group(1)?.trim() ?? '';
  }

  String _stripHtml(String html) {
    final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime _parseDate(String value) {
    if (value.isEmpty) return DateTime.now();

    try {
      return HttpDate.parse(value).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}
