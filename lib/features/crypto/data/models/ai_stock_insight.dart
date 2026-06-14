enum RecommendationType {
  buy,
  hold,
  avoid,
}

class AiStockInsight {
  final String marketExplanation;
  final RecommendationType recommendation;
  final String disclaimer;

  const AiStockInsight({
    required this.marketExplanation,
    required this.recommendation,
    required this.disclaimer,
  });

  factory AiStockInsight.fallback() {
    return const AiStockInsight(
      marketExplanation:
          'Unable to generate detailed insight at the moment. Review trend, volume, and recent news before taking any action.',
      recommendation: RecommendationType.hold,
      disclaimer: 'This is not financial advice.',
    );
  }
}
