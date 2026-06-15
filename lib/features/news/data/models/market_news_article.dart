class MarketNewsArticle {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;

  const MarketNewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
  });

  factory MarketNewsArticle.fromMap(Map<String, dynamic> map) {
    final sourceInfo = map['source_info'];
    final sourceName = sourceInfo is Map<String, dynamic>
        ? (sourceInfo['name']?.toString() ?? 'Unknown source')
        : 'Unknown source';

    final publishedOn = map['published_on'];
    final publishedSeconds = publishedOn is int
        ? publishedOn
        : int.tryParse(publishedOn?.toString() ?? '') ?? 0;

    return MarketNewsArticle(
      id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? 'Untitled',
      summary: map['body']?.toString() ?? 'No summary available.',
      source: sourceName,
      url: map['url']?.toString() ?? '',
      imageUrl: map['imageurl']?.toString() ?? '',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        publishedSeconds * 1000,
        isUtc: true,
      ).toLocal(),
    );
  }
}
