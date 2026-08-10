# ─────────────────────────────────────────
# Stage 1 – Build
# ─────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Önce sadece pom.xml ve Maven wrapper'ı kopyala
# (dependency cache için)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline -q

# Kaynak kodu kopyala ve jar oluştur
COPY src ./src
RUN ./mvnw package -DskipTests -q

# ─────────────────────────────────────────
# Stage 2 – Runtime (sadece JRE, küçük image)
# ─────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Jar dosyasını kopyala
COPY --from=builder /app/target/*.jar app.jar

# Spring Boot portu
EXPOSE 8080

# Prodüksiyon profili ile başlat
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "app.jar"]
