import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/groq_ai_config.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../models/chat_message.dart';

// MAUI map: Chat API service used by Insights screen ViewModel/stateful UI.
// Keeps network + prompt logic outside widget code.
class GroqChatService {
  static const Duration _requestTimeout = Duration(seconds: 25);

  // System policy for chat behavior and safety boundaries.
  static const String _systemPrompt =
      'You are a financial learning assistant inside a mobile app.\n\n'
      'You primarily answer questions related to:\n'
      '- Bitcoin\n'
      '- Cryptocurrency\n'
      '- Indian stock market\n'
      '- Investing basics\n\n'
      'You may handle simple friendly small-talk like greetings (for example: hello, how are you) in a short and polite way.\n\n'
      'Refuse content about terrorism, violence, sexual/romantic explicit topics, or vulgar chat with:\n'
      '"Sorry, I cannot help with that."\n\n'
      'Keep responses simple, beginner-friendly, and short.\n'
      'Do not give financial advice. Add \"This is not financial advice.\" when needed.';

  final http.Client _client;
  final String _apiKey;

  GroqChatService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? GroqAiConfig.resolveApiKey();

  Future<Result<String>> fetchReply({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    // Guard: typed validation error when API key is unavailable.
    if (_apiKey.isEmpty) {
      return const ResultFailure(
        AppFailure(
          type: FailureType.validation,
          message:
              'Missing AI API key. Add AI_API_KEY or GROQ_API_KEY and restart app.',
        ),
      );
    }

    // Build full chat context: policy + limited recent history + current user input.
    final messages = <Map<String, String>>[
      const {'role': 'system', 'content': _systemPrompt},
      ..._mapHistory(history),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      // Groq chat-completions request.
      final response = await _client
          .post(
            Uri.parse(GroqAiConfig.endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': GroqAiConfig.model,
              'messages': messages,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        // Map status codes to typed, UI-friendly failures.
        if (response.statusCode == 401 || response.statusCode == 403) {
          return ResultFailure(
            AppFailure(
              type: FailureType.validation,
              message: 'Invalid Groq API key. Please update it and retry.',
              cause: response.body,
            ),
          );
        }

        if (response.statusCode == 429) {
          return ResultFailure(
            AppFailure(
              type: FailureType.server,
              message: 'Rate limit reached. Please retry in a moment.',
              cause: response.body,
            ),
          );
        }

        return ResultFailure(
          AppFailure(
            type: FailureType.server,
            message: 'Chat service failed (${response.statusCode}).',
            cause: response.body,
          ),
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Expected shape: choices[0].message.content
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return const ResultFailure(
          AppFailure(
            type: FailureType.parsing,
            message: 'AI response was empty.',
          ),
        );
      }

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      final content = (message?['content'] ?? '').toString().trim();

      if (content.isEmpty) {
        return const ResultFailure(
          AppFailure(
            type: FailureType.parsing,
            message: 'AI response content is empty.',
          ),
        );
      }

      return ResultSuccess(content);
    } on TimeoutException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.timeout,
          message: 'Response timed out. Try again.',
          cause: e,
        ),
      );
    } on SocketException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.network,
          message: 'No internet connection.',
          cause: e,
        ),
      );
    } on http.ClientException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.network,
          message: 'Network error while contacting AI service.',
          cause: e,
        ),
      );
    } on FormatException catch (e) {
      return ResultFailure(
        AppFailure(
          type: FailureType.parsing,
          message: 'Invalid AI response format.',
          cause: e,
        ),
      );
    } catch (e) {
      return ResultFailure(AppFailure.fromException(e));
    }
  }

  List<Map<String, String>> _mapHistory(List<ChatMessage> history) {
    // Keep only recent turns to control latency and token usage.
    final recent = history.length > 12
        ? history.sublist(history.length - 12)
        : List<ChatMessage>.from(history);

    return recent
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();
  }
}
