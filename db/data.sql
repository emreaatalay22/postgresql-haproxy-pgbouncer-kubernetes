-- Ortak Sequence oluştur
CREATE SEQUENCE delivery_id_seq
    START 1
    INCREMENT 1

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


-- Partitionlar
CREATE TABLE delivery_2023 PARTITION OF delivery
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE delivery_2024 PARTITION OF delivery
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE delivery_2025 PARTITION OF delivery
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- this query is for 20m  data insert   
DO $$
DECLARE
    rand_date TIMESTAMP;
BEGIN
    FOR i IN 1..2000000 LOOP
        -- Random tarih oluştur: 2023 ve 2025 arasında
        rand_date := '2023-01-01'::timestamp + (random() * (EXTRACT(EPOCH FROM '2025-12-31'::timestamp) - EXTRACT(EPOCH FROM '2023-01-01'::timestamp))) * INTERVAL '1 second';
        
        INSERT INTO delivery (customer_id, product_id, delivery_date, delivery_status, shipping_address, payment_status, created_at, updated_at)
        VALUES (
            (i % 1000) + 1, -- customer_id 1-1000 arası
            (i % 500) + 1,  -- product_id 1-500 arası
            rand_date,      -- Teslimat tarihi (rastgele)
            CASE WHEN i % 2 = 0 THEN 'delivered' ELSE 'pending' END, -- Durum
            'Address ' || i, -- Teslimat adresi
            CASE WHEN i % 3 = 0 THEN 'paid' ELSE 'pending' END, -- Ödeme durumu
            rand_date,      -- created_at (aynı tarih)
            rand_date       -- updated_at (aynı tarih)
        );
    END LOOP;
END $$;


CREATE INDEX idx_delivery_customer_status_date 
ON delivery (customer_id, delivery_status, delivery_date);


--random customer
SELECT DISTINCT ON (customer_id) 
    delivery_status, customer_id, delivery_date 
FROM delivery
WHERE delivery_date >= '2023-01-01' 
  AND delivery_date <= '2025-12-31'
ORDER BY customer_id, RANDOM()
LIMIT 1000;





