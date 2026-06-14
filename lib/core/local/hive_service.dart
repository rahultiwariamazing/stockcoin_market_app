// File: lib/core/local/hive_service.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:hive/hive.dart';
import 'session_service.dart';

class HiveService {

  final Box _box = Hive.box('portfolio');
  final SessionService _sessionService = SessionService();

  String _portfolioKey(String email) => 'portfolio::$email';

  void saveTransaction(Map<String, dynamic> data) {
    final email = _sessionService.currentUserEmail;
    if (email == null) {
      throw StateError('No active user session');
    }

    final key = _portfolioKey(email);
    final rawList = _box.get(key, defaultValue: <dynamic>[]) as List;
    final transactions = rawList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    transactions.add(data);
    _box.put(key, transactions);
  }

  List<Map<String, dynamic>> getTransactions() {
    final email = _sessionService.currentUserEmail;
    if (email == null) {
      return [];
    }

    final key = _portfolioKey(email);
    final rawList = _box.get(key, defaultValue: <dynamic>[]) as List;

    return rawList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void clear() {
    final email = _sessionService.currentUserEmail;
    if (email == null) {
      return;
    }

    _box.delete(_portfolioKey(email));
  }
}
