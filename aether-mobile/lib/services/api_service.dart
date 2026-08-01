// lib/services/api_service.dart
//
// Spring Boot backend için HTTP servisi.
// Base URL:
//   Geliştirme : http://192.168.68.242:8080  (veya --dart-define=API_BASE_URL=...)
//   Üretim     : https://api.aether.app

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../models/exchange_key.dart';
import '../models/market.dart';
import '../models/notification.dart';
import '../models/order.dart';
import '../models/order_request.dart';
import '../models/price_alarm.dart';
import '../models/risk_profile.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.68.242:8080',
  );

  /// Public alias so other layers (e.g. the WebSocket price stream) can
  /// derive their own URL from the same configured host without duplicating it.
  static const String baseUrl = _baseUrl;

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Debug logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // JWT interceptor — her isteğe token ekler; 401 alınca refresh token ile
    // bir kez yenilemeyi dener, o da başarısız olursa oturumu temizler.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthEndpoint = error.requestOptions.path.startsWith('/api/v1/auth/');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (error.response?.statusCode == 401 && !isAuthEndpoint && !alreadyRetried) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null) {
            try {
              final refreshRes = await Dio(BaseOptions(baseUrl: _baseUrl)).post(
                '/api/v1/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final newToken = refreshRes.data['accessToken'] as String;
              final newRefreshToken = refreshRes.data['refreshToken'] as String?;
              await prefs.setString('jwt_token', newToken);
              if (newRefreshToken != null) await prefs.setString('refresh_token', newRefreshToken);

              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newToken'
                ..extra['retried'] = true;
              final retryRes = await _dio.fetch(retryOptions);
              return handler.resolve(retryRes);
            } catch (_) {
              await prefs.remove('jwt_token');
              await prefs.remove('refresh_token');
            }
          } else {
            await prefs.remove('jwt_token');
          }
        }
        handler.next(error);
      },
    ));
  }

  // ── AUTH ──────────────────────────────────────────────────────────────

  /// POST /api/v1/auth/login
  /// [twoFactorCode] only needs to be passed when the account has 2FA enabled;
  /// if omitted and the account requires it, the backend responds with an
  /// error containing "2FA code required." so the caller can prompt for it.
  Future<String> login(String email, String password, {String? twoFactorCode}) async {
    final res = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
      if (twoFactorCode != null && twoFactorCode.isNotEmpty) 'twoFactorCode': twoFactorCode,
    });
    final token = res.data['accessToken'] as String;
    final refreshToken = res.data['refreshToken'] as String?;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
    return token;
  }

  /// POST /api/v1/auth/register
  Future<String> register(String username, String email, String password) async {
    final res = await _dio.post('/api/v1/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    final token = res.data['accessToken'] as String;
    final refreshToken = res.data['refreshToken'] as String?;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
    return token;
  }

  /// Token'ı sil (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null && token.isNotEmpty;
  }

  // ── EXCHANGE KEYS ──────────────────────────────────────────────────────

  /// GET /api/v1/exchanges
  Future<List<ExchangeKeyModel>> getExchangeKeys() async {
    final res = await _dio.get('/api/v1/exchanges');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ExchangeKeyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/exchanges
  Future<ExchangeKeyModel> addExchangeKey({
    required String exchangeName,
    required String apiKey,
    required String secretKey,
    bool canRead = true,
    bool canTrade = false,
  }) async {
    final res = await _dio.post('/api/v1/exchanges', data: {
      'exchangeName': exchangeName,
      'apiKey': apiKey,
      'secretKey': secretKey,
      'canRead': canRead,
      'canTrade': canTrade,
    });
    return ExchangeKeyModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// DELETE /api/v1/exchanges/{id}
  Future<void> deleteExchangeKey(String id) async {
    await _dio.delete('/api/v1/exchanges/$id');
  }

  // ── EXCHANGE (BALANCE) ─────────────────────────────────────────────────

  /// GET /api/v1/exchange/{id}/balance?asset=USDT
  Future<double> getExchangeBalance(String exchangeKeyId, String asset) async {
    final res = await _dio.get(
      '/api/v1/exchange/$exchangeKeyId/balance',
      queryParameters: {'asset': asset},
    );
    return (res.data as num).toDouble();
  }

  // ── RISK PROFILE ───────────────────────────────────────────────────────

  /// GET /api/v1/risk/profile
  Future<RiskProfile> getRiskProfile() async {
    final res = await _dio.get('/api/v1/risk/profile');
    return RiskProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// PUT /api/v1/risk/profile
  Future<RiskProfile> saveRiskProfile(RiskProfile profile) async {
    final res = await _dio.put(
      '/api/v1/risk/profile',
      data: profile.toJson(),
    );
    return RiskProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/v1/risk/calculate
  /// { symbol, entryPrice, stopLossPrice, accountBalance }
  Future<RiskCalculationResult> calculateRisk(RiskCalculationPayload payload) async {
    final res = await _dio.post(
      '/api/v1/risk/calculate',
      data: payload.toJson(),
    );
    return RiskCalculationResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ── TRADES ─────────────────────────────────────────────────────────────

  /// GET /api/v1/trades/active
  Future<List<OrderModel>> getActiveOrders() async {
    final res = await _dio.get('/api/v1/trades/active');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/trades/order
  Future<OrderModel> createOrder(CreateOrderPayload payload) async {
    final res = await _dio.post('/api/v1/trades/order', data: payload.toJson());
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/v1/trades/{id}/close
  Future<OrderModel> closeOrder(String orderId) async {
    final res = await _dio.post('/api/v1/trades/$orderId/close');
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── PORTFOLIO ──────────────────────────────────────────────────────────

  /// GET /api/v1/portfolio/summary?exchangeKeyId={id}
  /// Döner: { totalBalanceUsd, dailyPnlUsd, dailyPnlPct }
  Future<Portfolio> getPortfolioSummary(String exchangeKeyId) async {
    final res = await _dio.get(
      '/api/v1/portfolio/summary',
      queryParameters: {'exchangeKeyId': exchangeKeyId},
    );
    return Portfolio.fromBackend(res.data as Map<String, dynamic>);
  }

  /// GET /api/v1/portfolio/breakdown?exchangeKeyId={id}
  /// Returns: [ { symbol, amount, usdValue, allocationPct } ]
  Future<List<AssetAllocation>> getPortfolioBreakdown(String exchangeKeyId) async {
    final res = await _dio.get(
      '/api/v1/portfolio/breakdown',
      queryParameters: {'exchangeKeyId': exchangeKeyId},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AssetAllocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── MARKETS ────────────────────────────────────────────────────────────

  /// GET /api/v1/markets/coins?exchangeKeyId={id}
  /// Returns live coin prices for supported symbols
  Future<List<CoinData>> getMarketCoins(String exchangeKeyId) async {
    final res = await _dio.get(
      '/api/v1/markets/coins',
      queryParameters: {'exchangeKeyId': exchangeKeyId},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CoinData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/markets/coins/{symbol}/history?exchangeKeyId={id}&timeframe={tf}
  /// Returns OHLCV candle data for chart display
  Future<List<CandleData>> getCandleHistory(
      String exchangeKeyId, String symbol, String timeframe) async {
    final res = await _dio.get(
      '/api/v1/markets/coins/$symbol/history',
      queryParameters: {
        'exchangeKeyId': exchangeKeyId,
        'timeframe': timeframe,
      },
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CandleData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── TRADE HISTORY ──────────────────────────────────────────────────────

  /// GET /api/v1/trades/history?page=&size=
  /// Returns closed orders as Transaction list for the history screen
  Future<List<Transaction>> getTransactions({
    String side = 'all',
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get('/api/v1/trades/history', queryParameters: {
      'page': page,
      'size': size,
    });
    final list = res.data as List<dynamic>;
    final orders = list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final transactions = orders.map((o) => Transaction.fromOrder(o)).toList();

    if (side == 'all') return transactions;
    return transactions.where((t) => t.side == side).toList();
  }

  // ── PROFILE ─────────────────────────────────────────────────────────────

  /// GET /api/v1/users/profile
  Future<UserProfileModel> getProfile() async {
    final res = await _dio.get('/api/v1/users/profile');
    return UserProfileModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// PUT /api/v1/users/profile
  Future<UserProfileModel> updateProfile({required String username, required String email}) async {
    final res = await _dio.put('/api/v1/users/profile', data: {
      'username': username,
      'email': email,
    });
    return UserProfileModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── EXCHANGE KEY EDIT ──────────────────────────────────────────────────

  /// PUT /api/v1/exchanges/{id}
  Future<ExchangeKeyModel> updateExchangeKey(
    String id, {
    required String apiKey,
    required String secretKey,
    bool canRead = true,
    bool canTrade = false,
  }) async {
    final res = await _dio.put('/api/v1/exchanges/$id', data: {
      'apiKey': apiKey,
      'secretKey': secretKey,
      'canRead': canRead,
      'canTrade': canTrade,
    });
    return ExchangeKeyModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── FAVORITES ──────────────────────────────────────────────────────────

  /// GET /api/v1/favorites
  Future<Set<String>> getFavorites() async {
    final res = await _dio.get('/api/v1/favorites');
    final list = res.data as List<dynamic>;
    return list.map((e) => (e as Map<String, dynamic>)['symbol'] as String).toSet();
  }

  /// POST /api/v1/favorites
  Future<void> addFavorite(String symbol) async {
    await _dio.post('/api/v1/favorites', data: {'symbol': symbol});
  }

  /// DELETE /api/v1/favorites/{symbol}
  Future<void> removeFavorite(String symbol) async {
    await _dio.delete('/api/v1/favorites/$symbol');
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────────────────

  /// GET /api/v1/notifications
  Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get('/api/v1/notifications');
    final list = res.data as List<dynamic>;
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/v1/notifications/{id}/read
  Future<void> markNotificationRead(String id) async {
    await _dio.post('/api/v1/notifications/$id/read');
  }

  /// POST /api/v1/notifications/read-all
  Future<void> markAllNotificationsRead() async {
    await _dio.post('/api/v1/notifications/read-all');
  }

  // ── PRICE ALARMS ───────────────────────────────────────────────────────

  /// GET /api/v1/alarms
  Future<List<PriceAlarmModel>> getAlarms() async {
    final res = await _dio.get('/api/v1/alarms');
    final list = res.data as List<dynamic>;
    return list.map((e) => PriceAlarmModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/v1/alarms
  Future<PriceAlarmModel> createAlarm({
    required String symbol,
    required double targetPrice,
    required String direction, // "ABOVE" | "BELOW"
  }) async {
    final res = await _dio.post('/api/v1/alarms', data: {
      'symbol': symbol,
      'targetPrice': targetPrice,
      'direction': direction,
    });
    return PriceAlarmModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// DELETE /api/v1/alarms/{id}
  Future<void> deleteAlarm(String id) async {
    await _dio.delete('/api/v1/alarms/$id');
  }

  // ── PASSWORD RESET ─────────────────────────────────────────────────────

  /// POST /api/v1/auth/forgot-password
  /// Backend has no email provider wired up yet, so the reset token comes
  /// back directly in the response — see ForgotPasswordResponse on the backend.
  Future<String> forgotPassword(String email) async {
    final res = await _dio.post('/api/v1/auth/forgot-password', data: {'email': email});
    return res.data['resetToken'] as String;
  }

  /// POST /api/v1/auth/reset-password
  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _dio.post('/api/v1/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  // ── 2FA ────────────────────────────────────────────────────────────────

  /// POST /api/v1/auth/2fa/setup — returns {secret, otpAuthUrl}
  Future<(String secret, String otpAuthUrl)> setup2fa() async {
    final res = await _dio.post('/api/v1/auth/2fa/setup');
    return (res.data['secret'] as String, res.data['otpAuthUrl'] as String);
  }

  /// POST /api/v1/auth/2fa/enable
  Future<void> enable2fa(String code) async {
    await _dio.post('/api/v1/auth/2fa/enable', data: {'code': code});
  }

  /// POST /api/v1/auth/2fa/disable
  Future<void> disable2fa(String code) async {
    await _dio.post('/api/v1/auth/2fa/disable', data: {'code': code});
  }
}
