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

  // ── PORTFOLIO / MARKET (mock — backend'de henüz yok) ──────────────────

  Future<Portfolio> getPortfolio() async {
    return _mockPortfolio();
  }

  Future<List<Asset>> getHoldings() async {
    return _mockHoldings();
  }

  Future<List<double>> getPriceHistory(String symbol,
      {String interval = '1d'}) async {
    return _mockPriceHistory();
  }

  Future<List<Transaction>> getTransactions({
    String side = 'all',
    int page = 0,
    int size = 20,
  }) async {
    return _mockTransactions();
  }

  Future<User> getUser() async {
    return _mockUser();
  }

  // ── MOCK DATA ──────────────────────────────────────────────────────────

  Portfolio _mockPortfolio() => const Portfolio(
        balance: 84273.52,
        pnl24h: 1842.17,
        pnl24hPercent: 2.23,
      );

  List<Asset> _mockHoldings() => const [
        Asset(
          symbol: 'BTC',
          name: 'Bitcoin',
          amount: 0.4827,
          avgPrice: 58420.00,
          currentPrice: 67234.12,
          sparkline: [62, 64, 63, 65, 67, 66, 68, 67, 69, 70, 68, 72],
        ),
        Asset(
          symbol: 'ETH',
          name: 'Ethereum',
          amount: 6.4120,
          avgPrice: 2840.50,
          currentPrice: 3127.80,
          sparkline: [28, 27, 29, 30, 28, 31, 30, 32, 31, 33, 32, 34],
        ),
        Asset(
          symbol: 'SOL',
          name: 'Solana',
          amount: 48.50,
          avgPrice: 142.80,
          currentPrice: 156.42,
          sparkline: [14, 15, 14, 13, 15, 16, 15, 14, 16, 15, 16, 17],
        ),
        Asset(
          symbol: 'AVAX',
          name: 'Avalanche',
          amount: 124.00,
          avgPrice: 36.20,
          currentPrice: 32.18,
          sparkline: [38, 37, 36, 35, 36, 34, 35, 33, 34, 33, 32, 31],
        ),
        Asset(
          symbol: 'LINK',
          name: 'Chainlink',
          amount: 320.50,
          avgPrice: 14.80,
          currentPrice: 16.34,
          sparkline: [14, 15, 14, 16, 15, 16, 17, 16, 17, 16, 17, 18],
        ),
      ];

  List<double> _mockPriceHistory() => const [
        62, 63.5, 62.8, 64.2, 65.1, 64.5, 66.3,
        65.8, 67.0, 66.4, 67.8, 68.2, 67.6, 68.9, 67.234,
      ];

  List<Transaction> _mockTransactions() => const [
        Transaction(
          id: 't1', date: '14 May 2026', time: '14:23',
          side: 'buy', symbol: 'BTC',
          price: 67234.12, amount: 0.0125, total: 840.43,
        ),
        Transaction(
          id: 't2', date: '14 May 2026', time: '09:48',
          side: 'sell', symbol: 'AVAX',
          price: 32.18, amount: 24.50, total: 788.41,
        ),
        Transaction(
          id: 't3', date: '13 May 2026', time: '21:15',
          side: 'buy', symbol: 'ETH',
          price: 3127.80, amount: 0.420, total: 1313.68,
        ),
        Transaction(
          id: 't4', date: '12 May 2026', time: '16:02',
          side: 'buy', symbol: 'SOL',
          price: 156.42, amount: 8.50, total: 1329.57,
        ),
        Transaction(
          id: 't5', date: '11 May 2026', time: '11:30',
          side: 'sell', symbol: 'LINK',
          price: 16.34, amount: 80.00, total: 1307.20,
        ),
        Transaction(
          id: 't6', date: '10 May 2026', time: '08:45',
          side: 'buy', symbol: 'BTC',
          price: 66148.50, amount: 0.0180, total: 1190.67,
        ),
        Transaction(
          id: 't7', date: '09 May 2026', time: '19:22',
          side: 'sell', symbol: 'ETH',
          price: 3098.20, amount: 0.150, total: 464.73,
        ),
        Transaction(
          id: 't8', date: '08 May 2026', time: '13:08',
          side: 'buy', symbol: 'SOL',
          price: 148.90, amount: 12.00, total: 1786.80,
        ),
      ];

  User _mockUser() => const User(
        id: 'u1',
        name: 'Mert Kaya',
        email: 'mert.kaya@borsa.app',
        initials: 'MK',
        kycVerified: true,
        totalBalance: 84273.52,
        pnlPercent: 2.23,
      );
}
