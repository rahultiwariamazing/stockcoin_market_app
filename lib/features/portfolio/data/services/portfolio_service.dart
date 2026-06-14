// File: lib/features/portfolio/data/services/portfolio_service.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:hive/hive.dart';
import '../../../../core/local/session_service.dart';
import '../models/portfolio_model.dart';

/// ✅ Portfolio Service (Local DB using Hive)
class PortfolioService {

  /// ✅ Reference to Hive box
  final Box box = Hive.box('portfolio');
  final SessionService _sessionService = SessionService();

  String _portfolioKey(String email) => 'portfolio::$email';

  String? get _currentUserEmail => _sessionService.currentUserEmail;

  /// ✅ Save new transaction
  void addTransaction(PortfolioModel model) {
    final email = _currentUserEmail;
    if (email == null) {
      throw StateError('No active user session');
    }

    final key = _portfolioKey(email);
    final rawList = box.get(key, defaultValue: <dynamic>[]) as List;

    final transactions = rawList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    transactions.add(model.toMap());
    box.put(key, transactions);
  }

  /// ✅ Get all transactions
  List<PortfolioModel> getTransactions() {
    final email = _currentUserEmail;
    if (email == null) {
      return [];
    }

    final key = _portfolioKey(email);
    final data = (box.get(key, defaultValue: <dynamic>[]) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return data
        .map((e) => PortfolioModel.fromMap(e))
        .toList();
  }
}