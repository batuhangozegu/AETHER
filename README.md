# AETHER — Kripto Risk Yönetimi ve Portföy Yönetim Platformu

AETHER, kullanıcı ile kripto para borsaları arasında konumlanan akıllı bir backend platformudur.
Her emirden önce matematiksel risk hesaplaması yaparak duygusal kararların önüne geçer.

## Geliştirici Notu

Bu proje AI-assisted development metodolojisiyle geliştirilmektedir.
Backend mimarisi, veritabanı tasarımı ve iş mantığı Java/Spring Boot ile yazılmakta;
mobil arayüz ise backend API'lerini uçtan uca test etmek amacıyla sunum katmanı olarak kullanılmaktadır.

Projenin bir diğer amacı, Java ekosisteminin temellerini sağlamlaştırarak Spring Boot ile
clean architecture, güvenlik mimarisi ve servis katmanı tasarımı konularında
sağlam bir backend geliştirme altyapısı oluşturmaktır.

## Teknolojiler

**Backend**
- Java 21 / Spring Boot 4.x
- Spring Security + JWT
- AES-256 API Key şifreleme
- Flyway (veritabanı migration yönetimi)
- XChange (Binance entegrasyonu)

**Veritabanı**
- PostgreSQL

**Mobil**
- Flutter + Riverpod (state management)
- Dio (HTTP client + JWT interceptor)

## Tamamlanan Özellikler (Backend + Flutter Entegrasyonu)

| Özellik | Backend | Flutter |
|---|---|---|
| Kimlik Doğrulama (kayıt / giriş / JWT) | ✅ | ✅ |
| Borsa API Anahtarı Yönetimi | ✅ | ✅ |
| Borsa Bakiyesi (`/exchange/{id}/balance`) | ✅ | ✅ |
| Risk Profili (oluştur / güncelle) | ✅ | ✅ |
| Risk Hesaplama (lot büyüklüğü) | ✅ | ✅ |
| Emir Yönetimi (aç / kapat / listele) | ✅ | ✅ |
| Portföy Özeti (`/portfolio/summary`) | ✅ | ✅ |
| Portföy Dağılımı (`/portfolio/breakdown`) | ✅ | ✅ |

## API Endpoint'leri

```
POST /api/v1/auth/register
POST /api/v1/auth/login

GET  /api/v1/exchanges
POST /api/v1/exchanges
DEL  /api/v1/exchanges/{id}

GET  /api/v1/exchange/{id}/balance?asset=USDT

GET  /api/v1/risk/profile
PUT  /api/v1/risk/profile
POST /api/v1/risk/calculate

GET  /api/v1/trades/active
POST /api/v1/trades/order
POST /api/v1/trades/{id}/close

GET  /api/v1/portfolio/summary?exchangeKeyId=
GET  /api/v1/portfolio/breakdown?exchangeKeyId=
```

## Planlanan Özellikler (Sonraki Fazlar)

- **Faz 7 — Market Service**: coin listesi, mum verisi (klines), WebSocket + Redis canlı fiyat akışı
- **Faz 8 — Refactor**: `UserLookupService` (user bulma tekrarını merkezileştirme), `PnLCalculator` (Trade + Portfolio impl'lerindeki duplicate calculatePnL'yi ortak utility'ye taşıma), `PortfolioServiceImpl.getBreakdown()` derleme hatası düzeltmesi
- Bildirim sistemi
- İki faktörlü doğrulama (2FA) — backend servisi hazır, mobil entegrasyon bekliyor

## Flutter Mimari Notları

- Her ekran kendi Riverpod `FutureProvider`/`Provider`'ını tanımlıyor
- `ApiService` singleton — `apiServiceProvider` üzerinden erişiliyor
- JWT interceptor: her isteğe otomatik `Authorization: Bearer <token>` ekler, 401'de token'ı siler
- Exchange Key yoksa portfolio endpoint'leri fallback olarak `getExchangeBalance` (USDT) kullanıyor

## Kurulum

### Backend
```bash
# PostgreSQL başlat ve borsa_db oluştur
createdb borsa_db

# application.yml içindeki DB şifresini düzenle
# Sonra:
cd backend
./mvnw spring-boot:run
```

### Flutter
```bash
cd aether-mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> **Emülatörde** Android emülatörü için host IP `10.0.2.2` (localhost proxy).
> Fiziksel cihazda bilgisayarın LAN IP'sini kullan.
