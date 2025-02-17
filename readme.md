# API Projesi

## Genel Bilgiler
API projesi **localhost:8080** portu üzerinden çalışmaktadır.
API'ye erişim için aşağıdaki **cURL** komutu kullanılabilir:

```bash
curl --location 'http://localhost:8080/api/deliveries?deliveryStatus=delivered&customerId=79&pageNumber=0&pageSize=10&columnName=deliveryDate&sortDirection=true' \
--header 'Content-Type: application/json' \
--data ''
```

## Port Forwarding
API'yi **Lens** üzerinden veya aşağıdaki komut ile **port-forwarding** yapabilirsiniz:

```bash
kubectl port-forward svc/spring-web-api 8080:8080 -n postgresql-haproxy-pgbouncer
```

---

## Grafana
- **Grafana**, **localhost:3000** üzerinden çalışmaktadır.
- **Grafana Dashboard Bilgileri:** [Dashboard Linki](https://drive.google.com/drive/folders/1AzJibi8CICkJcAFNtlgSfHPTmwLTHD9d?usp=sharing)

---

## Kubernetes ve Docker
Projede **Docker** ve **Kubernetes** kullanılmıştır.
**Lens** üzerinden deployment ve servis yönetimi yapılmıştır.

### Kubernetes Deployment
```bash
kubectl apply -f postgres
kubectl apply -f pgbouncer
kubectl apply -f haproxy
kubectl apply -f prometheus
kubectl apply -f grafana
kubectl apply -f api/java
```

### Kubernetes Pod'a Bağlanma
```bash
kubectl exec -it spring-web-api-85f95b898f-xt2jr -n postgresql-haproxy-pgbouncer -- /bin/sh
```

### Kubernetes LoadBalancer Kullanımı
```bash
kubectl expose deployment spring-web-api --port=8080 --type=LoadBalancer -n postgresql-haproxy-pgbouncer
```
Daha fazla bilgi için: [LoadBalancer](https://www.tkng.io/services/loadbalancer/)

---

## HTTP İstekleri Gönderme
### cURL Alternatifi: Wget Kullanımı
```bash
apt-get update && apt-get install -y wget
wget -qO- http://spring-web-api:8080/api/users
wget -qO- http://localhost:8080/actuator/prometheus
```

---

## JMeter
- **JMeter**, Kubernetes üzerinde çalışmamaktadır. Windows veya Mac için manuel kurulum gerekmektedir.
- **Kurulum:**
```bash
brew install jmeter
```
- **Test Yapısı:**
  - `jmeter` klasörü altında `CSV Data Set Config.jmx` ve `data.csv` dosyaları yer almaktadır.
  - `data.csv` dosyası, test edilecek kullanıcı listesini içermektedir.

---

## Veritabanı Yapısı
Tüm veritabanı sorguları **db** klasörü altında bulunmaktadır.
- **Index ve Partition Yapısı Mevcut**
- PostgreSQL üzerinde **index, constraint ve partition kullanımı** detayları için aşağıdaki yazılar incelenebilir:
  - [PostgreSQL'de Index, Constraint ve Partition Kullanımı](https://medium.com/@emreatalay22/postgresqlde-index-constraint-ve-partition-kullan%C4%B1m%C4%B1-derinlemesine-i%CC%87nceleme-878eaaadacaa)
  - [PostgreSQL Transaction Tipleri](https://medium.com/@emreatalay22/postgresql-transaction-tipleri-ve-kullan%C4%B1m-%C3%B6rnekleri-1301ff1ae630)
  - [PostgreSQL Join ve Operatörler](https://medium.com/@emreatalay22/postgresql-join-ve-operat%C3%B6rler-5c18f883849c)

### Ortak Sequence Oluşturma
```sql
CREATE SEQUENCE delivery_id_seq
    START 1
    INCREMENT 1;
```

### Partition Tablolar
```sql
CREATE TABLE delivery (
    id BIGINT NOT NULL DEFAULT nextval('delivery_id_seq'),
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    delivery_date TIMESTAMP NOT NULL,
    delivery_status VARCHAR(50) NOT NULL,
    shipping_address TEXT,
    payment_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (delivery_date);

CREATE TABLE delivery_2023 PARTITION OF delivery
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE delivery_2024 PARTITION OF delivery
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

### Örnek SQL Sorguları
```sql
SELECT DISTINCT ON (customer_id)
    delivery_status, customer_id
FROM delivery
WHERE delivery_date >= '2023-01-01'
  AND delivery_date <= '2025-12-31'
ORDER BY customer_id, RANDOM()
LIMIT 1000;
```

---

## Hikari Connection Pool Yönetimi
- **Maksimum Bağlantı Sayısı:**
```properties
spring.datasource.hikari.maximumPoolSize=100
```
- **Minimum Idle Ayarı:**
```properties
spring.datasource.hikari.minimumIdle=10
```
- **Bağlantı Zaman Aşımı:**
```properties
spring.datasource.hikari.connectionTimeout=30000
```
- **Bağlantı Ömrü:**
```properties
spring.datasource.hikari.maxLifetime=1800000
```
Daha fazla bilgi için: [HikariCP Performans Optimizasyonu](https://medium.com/@mukitulislamratul/maximizing-hikaricp-performance-in-spring-boot-applications-f7ee8474410a)

---

## Grafana ve Prometheus
### Grafana Monitoring
Örnek **Prometheus HTTP İstek Sayacı**:
```yaml
http_server_requests_seconds_count
{__name__="http_server_requests_seconds_count", application="MYAPPNAME", instance="spring-web-api:8080", status="200", uri="/api/deliveries"}
```
Toplam istek oranı hesaplamak için:
```yaml
sum(rate(http_server_requests_seconds_count{application="MYAPPNAME", instance=~"$exported_instance"}[1m])) by (instance, uri, status)
```
- **Grafana Template:** [Grafana Dashboard](https://drive.google.com/drive/folders/1AzJibi8CICkJcAFNtlgSfHPTmwLTHD9d?usp=sharing)

### Prometheus Yönetimi
```bash
kubectl get serviceaccount -n postgresql-haproxy-pgbouncer
kubectl get role,rolebinding -n postgresql-haproxy-pgbouncer
kubectl describe pod prometheus-5dd6fc6c8c-59vwd -n postgresql-haproxy-pgbouncer
```

---

## Kaynaklar
- **HikariCP Bağlantı Yönetimi:** [HikariCP Wiki](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing)
- **Kubernetes Load Balancer:** [TKNG LoadBalancer](https://www.tkng.io/services/loadbalancer/)

Bu doküman, **API projesi** ile ilgili tüm kurulum, kullanım ve optimizasyon süreçlerini kapsamaktadır.

