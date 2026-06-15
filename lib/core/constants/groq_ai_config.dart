class GroqAiConfig {
  GroqAiConfig._();

  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String model = 'llama-3.1-8b-instant';

  // Single fallback location for local debug only.
  static const String _hardcodedApiKey =
      '';

  static String resolveApiKey() {
    final generic =
        const String.fromEnvironment('AI_API_KEY', defaultValue: '').trim();
    if (generic.isNotEmpty) {
      return generic;
    }

    final groq =
        const String.fromEnvironment('GROQ_API_KEY', defaultValue: '').trim();
    if (groq.isNotEmpty) {
      return groq;
    }

    return _hardcodedApiKey.trim();
  }
}
