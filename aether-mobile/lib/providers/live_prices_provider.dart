// lib/providers/live_prices_provider.dart
//
// Backend'in her 5 saniyede /topic/prices'a STOMP üzerinden push ettiği
// canlı fiyatları dinler. Endpoint SockJS ile kayıtlı
// (WebSocketConfig: registry.addEndpoint("/ws").withSockJS()), ama
// SockJS'in kendisi yerine onun altındaki ham WebSocket upgrade path'i
// olan "/ws/websocket" kullanılıyor — Spring SockJS endpoint'leri bunu
// STOMP-over-WebSocket istemcileri için standart olarak destekler.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';

import 'app_providers.dart';

class LivePricesNotifier extends StateNotifier<Map<String, double>> {
  StompClient? _client;

  LivePricesNotifier() : super(const {}) {
    _connect();
  }

  void _connect() {
    final wsUrl = apiBaseUrlWs('/ws/websocket');
    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {},
        onStompError: (dynamic frame) {},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame connectFrame) {
    _client?.subscribe(
      destination: '/topic/prices',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          final symbol = data['symbol'] as String?;
          final price = (data['price'] as num?)?.toDouble();
          if (symbol != null && price != null) {
            state = {...state, symbol: price};
          }
        } catch (_) {
          // ignore malformed frames
        }
      },
    );
  }

  @override
  void dispose() {
    _client?.deactivate();
    super.dispose();
  }
}

final livePricesProvider = StateNotifierProvider<LivePricesNotifier, Map<String, double>>(
  (ref) => LivePricesNotifier(),
);
