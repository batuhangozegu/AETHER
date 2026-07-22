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

**Veritabanı**
- PostgreSQL

**Mobil**
- Flutter

## Tamamlanan Özellikler

- **Kimlik Doğrulama** — JWT tabanlı authentication, kullanıcı kayıt/giriş
- **Borsa API Anahtarı Yönetimi** — AES-256 ile şifrelenmiş API key saklama, ekleme/listeleme/silme
- **Risk Yönetimi** — kullanıcıya özel risk profili (risk yüzdesi, günlük kayıp limiti, hedef risk/ödül oranı), işlem öncesi lot büyüklüğü hesaplama
- **Emir Yönetimi** — pozisyon açma/kapatma, aktif pozisyonları listeleme

## Planlanan Özellikler

- Portföy servisi (bakiye, kâr/zarar takibi)
- Gerçek borsa entegrasyonu (Binance/Bybit API'leri ile emir senkronizasyonu)
- Piyasa verisi servisi ve WebSocket ile canlı fiyat akışı (Redis cache ile)
- Bildirim sistemi
- İki faktörlü doğrulama (2FA)

## Kurulum

*(Yakında eklenecek)*
