// lib/providers/market_providers.dart
//
// Shared market-data providers used by both the markets and trade screens.
// Kept in one place so neither screen needs to import the other just to
// reuse real live price / 24h-change data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market.dart';
import 'api_keys_provider.dart';
import 'app_providers.dart';

/// Gerçek fiyat + 24 saatlik değişim verisi — backend'in bağlı borsadan
/// çektiği canlı veriler (`GET /api/v1/markets/coins`).
final marketCoinsProvider = FutureProvider<List<CoinData>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
  if (keys.isEmpty) return [];
  try {
    return await apiService.getMarketCoins(keys.first.id);
  } catch (_) {
    return [];
  }
});
