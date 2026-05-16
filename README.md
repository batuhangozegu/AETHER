# AETHER - Kripto Risk Yönetimi ve Portföy Simülasyon Sistemi

AETHER, kullanıcı ile kripto para borsaları arasında konumlanan, duygusal kararları engelleyerek her emirden önce soğukkanlı matematiksel hesaplamalar yapan akıllı bir backend ve risk yönetimi platformudur.

## 🎯 Proje Odak Noktası ve Geliştirici Notu
Bu projenin asıl şaheseri ve ana odak noktası **kurumsal düzeyde kurgulanan Backend mimarisidir**. Projede yer alan mobil arayüz (`aether-mobile/` klasörü), backend API'lerinin ürettiği verileri canlı olarak test edebilmek ve sistemi uçtan uca çalışır halde sunabilmek amacıyla **yapay zeka asistanları yardımıyla hızlıca üretilmiş bir "Sunum Katmanı"dır.** Projenin mimari ağırlığı, veri tabanı tasarımı ve iş mantığı tamamen Java tarafında geliştirilecektir.

## 🛠️ Kullanılan Teknolojiler
- **Backend:** Java 17 / Spring Boot 3.x
- **Veritabanı:** PostgreSQL (Finansal veri tutarlılığı için)
- **Önbellek (Cache):** Redis (Anlık fiyat verileri için)
- **Bağlantı Katmanı:** Spring WebFlux WebClient (Asenkron borsa entegrasyonu)
- **Güvenlik:** Spring Security + JWT & AES-256 (API Key şifreleme)

---

## 📋 Yol Haritası & Yapılacaklar Listesi (To-Do)

### 🧱 Aşama 1: Temel Altyapı ve Güvenlik
- [ ] Spring Boot projesinin iskeletinin oluşturulması ve bağımlılıkların (JPA, Security, Redis) eklenmesi.
- [ ] PostgreSQL veritabanı şemasının tasarlanması ve Entity sınıflarının (User, Portfolio, Asset, Transaction) yazılması.
- [ ] JWT tabanlı stateless kimlik doğrulama filtrelerinin ve kayıt/giriş API'lerinin tamamlanması.

### 🧮 Aşama 2: Faz 1 - Sanal Simülatör ve Risk Motoru
- [ ] Matematiksel pozisyon büyüklüğü hesaplama formülünün (`RiskEngineService`) kodlanması.
- [ ] Sanal alım-satım (Paper Trading) emir motorunun yazılması.
- [ ] İşlem sonrası cüzdan bakiyesi düşme, varlık ekleme ve ortalama maliyet hesaplama logiclerinin kurulması.
- [ ] Binance API'sinden asenkron `WebClient` ile fiyat çekilerek Redis'e 5 saniyelik TTL ile kaydedilmesi katmanı.

### 🔐 Aşama 3: Faz 2 - Canlı Entegrasyon ve Profil Güvenliği
- [ ] Profil ekranından girilecek borsa API anahtarlarının veritabanına `AES-256` ile şifrelenerek kaydedilmesi altyapısı.
- [ ] API anahtarlarının istemciye gönderilmeden önce DTO katmanında maskelenmesi.
- [ ] Gerçek emirlerin Binance API'sine doğrudan iletilmesi ve borsa üzerinde eşzamanlı Stop-Loss emri zincirinin tetiklenmesi.
- [ ] Gelişmiş finansal hata yönetimi (Exception Handling) ve rollback mekanizmaları.