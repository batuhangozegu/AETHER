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
import '../models/order.dart';
import '../models/order_request.dart';
import '../models/risk_profile.dart';
import '../models/transaction.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

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

    // JWT interceptor — her isteğe token ekler, 401'de token siler
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
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token');
        }
        handler.next(error);
      },
    ));
  }

  // ── AUTH ──────────────────────────────────────────────────────────────

  /// POST /api/v1/auth/login
  Future<String> login(String email, String password) async {
    final res = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    return token;
  }

  /// Token'ı sil (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
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
  /// Döner: [ { symbol, amount, usdValue, allocationPct } ]
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

  // ── ORDERS (geçmiş için aktif emirler) ─────────────────────────────────

  /// GET /api/v1/trades/active → active orders'ı Transaction olarak döndürür
  /// (Backend'de kapalı emir listesi endpointi henüz yok)
  Future<List<Transaction>> getTransactions({
    String side = 'all',
    int page = 0,
    int size = 20,
  }) async {
    final orders = await getActiveOrders();
    return orders.map((o) => Transaction.fromOrder(o)).toList();
  }
}
