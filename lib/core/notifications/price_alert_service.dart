import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';

import '../../features/crypto/data/models/crypto_model.dart';
import '../../features/crypto/data/repositories/crypto_repository.dart';
import '../../features/portfolio/data/models/portfolio_model.dart';
import '../../features/portfolio/data/services/portfolio_service.dart';
import '../errors/result.dart';
import '../local/session_service.dart';

class _PositionSnapshot {
  final String id;
  final String name;
  final String symbol;
  final double quantity;
  final double averageBuyPrice;

  const _PositionSnapshot({
    required this.id,
    required this.name,
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
  });
}

class _PositionAccumulator {
  final String id;
  final String name;
  final String symbol;
  double quantity = 0;
  double averageBuyPrice = 0;

  _PositionAccumulator({
    required this.id,
    required this.name,
    required this.symbol,
  });

  void apply(PortfolioModel tx) {
    final qty = tx.quantity;

    if (qty > 0) {
      final newQty = quantity + qty;
      if (newQty <= 0) {
        quantity = 0;
        averageBuyPrice = 0;
        return;
      }

      final weightedTotal = (averageBuyPrice * quantity) + (tx.price * qty);
      quantity = newQty;
      averageBuyPrice = weightedTotal / newQty;
      return;
    }

    if (qty < 0) {
      final sellQty = (-qty).clamp(0, quantity);
      quantity -= sellQty;
      if (quantity <= 0) {
        quantity = 0;
        averageBuyPrice = 0;
      }
    }
  }

  _PositionSnapshot toSnapshot() {
    return _PositionSnapshot(
      id: id,
      name: name,
      symbol: symbol,
      quantity: quantity,
      averageBuyPrice: averageBuyPrice,
    );
  }
}

class PriceAlertService {
  PriceAlertService._();

  static final PriceAlertService instance = PriceAlertService._();

  static const Duration _checkInterval = Duration(seconds: 120);
  static const Duration _initialBackoff = Duration(seconds: 30);
  static const int _maxBackoffSeconds = 300;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final PortfolioService _portfolioService = PortfolioService();
  final SessionService _sessionService = SessionService();
  final CryptoRepository _cryptoRepository = CryptoRepository();

  final ValueNotifier<bool> isCheckingPrices = ValueNotifier<bool>(false);
  final ValueNotifier<String?> checkingMessage = ValueNotifier<String?>(null);

  Timer? _timer;
  bool _isChecking = false;
  DateTime? _cooldownUntil;
  Duration _backoff = _initialBackoff;

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notifications.initialize(settings: initSettings);

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iOSImpl = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iOSImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void startMonitoring() {
    _timer?.cancel();

    _checkPortfolioPrices();
    _timer = Timer.periodic(_checkInterval, (_) {
      _checkPortfolioPrices();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkPortfolioPrices() async {
    if (_sessionService.currentUserEmail == null) {
      return;
    }

    final now = DateTime.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return;
    }

    if (_isChecking) return;
    _isChecking = true;
    isCheckingPrices.value = true;
    checkingMessage.value = 'Checking latest prices for your holdings...';

    try {
      final positions = _buildOpenPositions(_portfolioService.getTransactions());
      if (positions.isEmpty) {
        _resetBackoff();
        return;
      }

      final result = await _cryptoRepository.getCryptosByIds(
        ids: positions.keys.toList(),
      );

      if (result is ResultFailure<List<CryptoModel>>) {
        final message = result.failure.message.toLowerCase();
        if (message.contains('(429)') || message.contains('rate limit')) {
          _applyBackoff();
          checkingMessage.value = 'Rate limit hit. Retrying shortly...';
          return;
        }

        return;
      }

      _resetBackoff();
      final marketCoins = (result as ResultSuccess<List<CryptoModel>>).data;
      for (final coin in marketCoins) {
        final position = positions[coin.id];
        if (position == null || position.averageBuyPrice <= 0) {
          continue;
        }

        await _maybeNotifyPriceIncrease(position: position, coin: coin);
      }
    } finally {
      _isChecking = false;
      isCheckingPrices.value = false;
      checkingMessage.value = null;
    }
  }

  Map<String, _PositionSnapshot> _buildOpenPositions(
    List<PortfolioModel> transactions,
  ) {
    final map = <String, _PositionAccumulator>{};

    for (final tx in transactions) {
      final existing = map[tx.id] ??
          _PositionAccumulator(
            id: tx.id,
            name: tx.name,
            symbol: tx.symbol,
          );

      existing.apply(tx);
      map[tx.id] = existing;
    }

    final snapshots = <String, _PositionSnapshot>{};
    for (final entry in map.entries) {
      final snapshot = entry.value.toSnapshot();
      if (snapshot.quantity > 0 && snapshot.averageBuyPrice > 0) {
        snapshots[entry.key] = snapshot;
      }
    }

    return snapshots;
  }

  Future<void> _maybeNotifyPriceIncrease({
    required _PositionSnapshot position,
    required CryptoModel coin,
  }) async {
    final email = _sessionService.currentUserEmail;
    if (email == null) return;

    final key = 'price_alert::$email::${position.id}';
    final box = Hive.box('alerts');

    final lastCheckedPriceRaw = box.get('$key::last_checked_price');
    final lastCheckedPrice = lastCheckedPriceRaw is num
        ? lastCheckedPriceRaw.toDouble()
        : null;

    final hasIncreased = lastCheckedPrice != null &&
        coin.currentPrice > lastCheckedPrice;

    if (hasIncreased) {
      final increaseAmount = coin.currentPrice - lastCheckedPrice;
      final increasePct = (increaseAmount / lastCheckedPrice) * 100;

      final notificationId = key.hashCode.abs() % 100000;
      await _notifications.show(
        id: notificationId,
        title: '${position.symbol.toUpperCase()} price increased',
        body: 'Prev: Rs ${lastCheckedPrice.toStringAsFixed(2)} | '
            'Now: Rs ${coin.currentPrice.toStringAsFixed(2)} '
            '(+${increaseAmount.toStringAsFixed(4)}, ${increasePct.toStringAsFixed(2)}%)',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'price_alerts',
            'Price Alerts',
            channelDescription: 'Alerts when owned coin price increases',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }

    await box.put('$key::last_checked_price', coin.currentPrice);
  }

  void _applyBackoff() {
    _cooldownUntil = DateTime.now().add(_backoff);

    final next = _backoff.inSeconds * 2;
    _backoff = Duration(
      seconds: next > _maxBackoffSeconds ? _maxBackoffSeconds : next,
    );
  }

  void _resetBackoff() {
    _cooldownUntil = null;
    _backoff = _initialBackoff;
  }
}
