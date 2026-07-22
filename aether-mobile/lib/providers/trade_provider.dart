// lib/providers/trade_provider.dart
//
// Active orders için Riverpod AsyncNotifier.
// createOrder ve closeOrder işlemleri backend'e bağlı.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

class TradeNotifierState extends AsyncNotifier<List<OrderModel>> {
  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<List<OrderModel>> build() async {
    return _api.getActiveOrders();
  }

  /// Backend'e POST /api/v1/trades/order atar, başarılıysa listeye ekler
  Future<OrderModel> createOrder(CreateOrderPayload payload) async {
    final order = await _api.createOrder(payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, order]);
    return order;
  }

  /// Backend'e POST /api/v1/trades/{id}/close atar, listeyi günceller
  Future<OrderModel> closeOrder(String orderId) async {
    final closed = await _api.closeOrder(orderId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((o) => o.id == orderId ? closed : o).toList(),
    );
    return closed;
  }

  /// Listeyi yenile
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getActiveOrders());
  }
}

final tradeStateProvider =
    AsyncNotifierProvider<TradeNotifierState, List<OrderModel>>(
  TradeNotifierState.new,
);
