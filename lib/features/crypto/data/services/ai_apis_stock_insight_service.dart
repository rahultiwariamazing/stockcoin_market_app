import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/groq_ai_config.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../models/ai_stock_insight.dart';

// MAUI map: Dedicated API service for AI insight card on details screen.
// This class handles only request/response concerns, not widget state.
class AiApisStockInsightService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String _apiKey;

  AiApisStockInsightService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? GroqAiConfig.resolveApiKey();

  static String get _endpoint => const String.fromEnvironment(
        'AI_CHAT_COMPLETIONS_ENDPOINT',
        defaultValue: GroqAiConfig.endpoint,
      );

  static String get _model => const String.fromEnvironment(
        'GROQ_MODEL',
        defaultValue: GroqAiConfig.model,
      );

  Future<Result<AiStockInsight>> fetchInsight({
    required String stockName,
    required double currentPrice,
    required double changePercent,
  }) async {
    // Guard: fail fast with typed validation error if key is missing.
    if (_apiKey.trim().isEmpty) {
      return const ResultFailure(
        AppFailure(
          type: FailureType.validation,
          message:
              'Missing AI API key. Add AI_API_KEY (or GROQ_API_KEY) in secrets.local.json, then run: flutter run --dart-define-from-file=secrets.local.json',
        ),
      );
    }

    final prompt = '''
You are a financial education assistant.
Explain the stock movement in beginner-friendly language.
Provide a learning-oriented recommendation: BUY, HOLD, or AVOID.
Do not provide direct financial advice.
Always include this exact disclaimer text: "This is not financial advice."

Stock data:
- Name: $stockName
- Current price: ${currentPrice.toStringAsFixed(2)}
- Change percent (24h): ${changePercent.toStringAsFixed(2)}%

Return ONLY strict JSON with keys:
{
  "marketExplanation": "string",
  "recommendation": "BUY|HOLD|AVOID",
  "disclaimer": "This is not financial advice."
}
''';

    try {
  // Groq chat-completions call with minimal payload shape: model + messages.
      final response = await _client
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
        }),
      )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        // Map common status codes into user-friendly typed failures.
        if (response.statusCode == 401 || response.statusCode == 403) {
          return ResultFailure(
            AppFailure(
              type: FailureType.validation,
              message:
                  'AI provider key is invalid or expired. Update AI_API_KEY (or GROQ_API_KEY) and restart the app.',
              cause: response.body,
            ),
          );
        }

        if (response.statusCode == 429) {
          return ResultFailure(
            AppFailure(
              type: FailureType.server,
              message:
                  'Groq rate limit reached. Please wait and try again shortly.',
              cause: response.body,
            ),
          );
        }

        return ResultFailure(
          AppFailure(
            type: FailureType.server,
            message:
                'AI service failed (${response.statusCode}). Please try again.',
            cause: response.body,
          ),
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Groq returns choices[0].message.content for chat completions.
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return const ResultFailure(
          AppFailure(
            type: FailureType.parsing,
            message: 'AI response was empty.',
          ),
        );
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final rawContent = (message?['content'] ?? '').toString().trim();
      if (rawContent.isEmpty) {
        return const ResultFailure(
          AppFailure(
            type: FailureType.parsing,
            message: 'AI response content is empty.',
          ),
        );
      }

      final normalizedJson = _extractJson(rawContent);
      final parsed = jsonDecode(normalizedJson) as Map<String, dynamic>;

      final explanation =
          (parsed['marketExplanation'] ?? '').toString().trim();
      final recRaw = (parsed['recommendation'] ?? '').toString().trim();
      final disclaimer =
          (parsed['disclaimer'] ?? 'This is not financial advice.')
              .toString()
              .trim();

      if (explanation.isEmpty || recRaw.isEmpty) {
        return const ResultFailure(
          AppFailure(
            type: FailureType.parsing,
            message: 'AI response format is invalid.',
          ),
        );
      }

      return ResultSuccess(
        AiStockInsight(
          marketExplanation: explanation,
          recommendation: _mapRecommendation(recRaw),
          disclaimer: disclaimer.isEmpty
              ? 'This is not financial advice.'
              : disclaimer,
        ),
      );
    } on TimeoutException catch (e) {
      // Typed timeout helps UI show specific retry messaging.
      return ResultFailure(
        AppFailure(
          type: FailureType.timeout,
          message: 'AI request timed out. Please try again.',
          cause: e,
        ),
      );
    } on SocketException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.network,
          message: 'Unable to reach AI service. Check internet and retry.',
          cause: e,
        ),
      );
    } on http.ClientException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.network,
          message: 'Network error while contacting AI service. Please retry.',
          cause: e,
        ),
      );
    } on FormatException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.parsing,
          message: 'AI response format was invalid. Please try again.',
          cause: e,
        ),
      );
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  String _extractJson(String raw) {
    // LLM may wrap JSON in markdown fences; normalize before decoding.
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');

    if (start == -1 || end == -1 || end <= start) {
      return cleaned;
    }

    return cleaned.substring(start, end + 1);
  }

  RecommendationType _mapRecommendation(String value) {
    // Tolerant mapping to handle slight text variations from model output.
    final normalized = value.toLowerCase();
    if (normalized.contains('buy')) return RecommendationType.buy;
    if (normalized.contains('avoid')) return RecommendationType.avoid;
    return RecommendationType.hold;
  }
}
