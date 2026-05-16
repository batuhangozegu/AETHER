import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiKey {
  final String id, exchange, mask;
  final bool active;
  const ApiKey({required this.id, required this.exchange, required this.mask, this.active = true});
  ApiKey copyWith({String? exchange, String? mask, bool? active}) => ApiKey(
    id: id, exchange: exchange ?? this.exchange, mask: mask ?? this.mask, active: active ?? this.active);
}

class ApiKeysNotifier extends StateNotifier<List<ApiKey>> {
  ApiKeysNotifier() : super(const [
    ApiKey(id: '1', exchange: 'Binance', mask: '****4291'),
    ApiKey(id: '2', exchange: 'Bybit',   mask: '****8830'),
  ]);
  void add(String exchange, String mask) =>
      state = [...state, ApiKey(id: '${DateTime.now().millisecondsSinceEpoch}', exchange: exchange, mask: mask)];
  void remove(String id) => state = state.where((k) => k.id != id).toList();
  void update(String id, String exchange, String mask) =>
      state = state.map((k) => k.id == id ? k.copyWith(exchange: exchange, mask: mask) : k).toList();
}

final apiKeysProvider = StateNotifierProvider<ApiKeysNotifier, List<ApiKey>>((_) => ApiKeysNotifier());
