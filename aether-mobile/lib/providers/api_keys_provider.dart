// lib/providers/api_keys_provider.dart
//
// ExchangeKey listesini backend'den çeker ve CRUD işlemlerini backend'e iletir.
// AsyncNotifier kullanılıyor: loading/error state'i otomatik yönetilir.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exchange_key.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

// Geriye dönük uyumluluk için eski ApiKey tipi korunuyor (profile_screen kullanıyor)
class ApiKey {
  final String id;
  final String exchange; // displayName
  final String mask;     // maskedApiKey
  final bool canTrade;
  final bool canRead;
  final bool active;

  const ApiKey({
    required this.id,
    required this.exchange,
    required this.mask,
    this.canRead = true,
    this.canTrade = false,
    this.active = true,
  });

  factory ApiKey.fromModel(ExchangeKeyModel m) => ApiKey(
        id:       m.id,
        exchange: m.displayName,
        mask:     m.maskedApiKey,
        canRead:  m.canRead,
        canTrade: m.canTrade,
        active:   m.status.toUpperCase().contains('ACTIVE'),
      );

  ApiKey copyWith({String? exchange, String? mask, bool? canRead, bool? canTrade, bool? active}) =>
      ApiKey(
        id:       id,
        exchange: exchange ?? this.exchange,
        mask:     mask     ?? this.mask,
        canRead:  canRead  ?? this.canRead,
        canTrade: canTrade ?? this.canTrade,
        active:   active   ?? this.active,
      );
}

// ── Notifier ────────────────────────────────────────────────────────────

class ApiKeysNotifier extends AsyncNotifier<List<ApiKey>> {
  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<List<ApiKey>> build() async {
    final models = await _api.getExchangeKeys();
    return models.map(ApiKey.fromModel).toList();
  }

  /// Backend'e POST atar, başarılı olursa listeyi yeniler.
  Future<void> addKey({
    required String exchangeName, // enum string: "BINANCE" vs.
    required String apiKey,
    required String secretKey,
    bool canRead  = true,
    bool canTrade = false,
  }) async {
    final model = await _api.addExchangeKey(
      exchangeName: exchangeName,
      apiKey:       apiKey,
      secretKey:    secretKey,
      canRead:      canRead,
      canTrade:     canTrade,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, ApiKey.fromModel(model)]);
  }

  /// Backend'e DELETE atar, başarılı olursa listeden kaldırır.
  Future<void> removeKey(String id) async {
    await _api.deleteExchangeKey(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((k) => k.id != id).toList());
  }

  /// Yerel düzenleme (backend'in edit endpoint'i olmadığından sadece UI günceller).
  /// update ismi AsyncNotifier.update ile çakıştığından editLocal kullanılıyor.
  void editLocal(String id, String exchange, String mask) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((k) => k.id == id ? k.copyWith(exchange: exchange, mask: mask) : k).toList(),
    );
  }
}

final apiKeysProvider =
    AsyncNotifierProvider<ApiKeysNotifier, List<ApiKey>>(ApiKeysNotifier.new);
