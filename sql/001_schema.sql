CREATE TABLE workers (
       worker_id      TEXT PRIMARY KEY,
       full_name      TEXT NOT NULL,
       national_id    TEXT UNIQUE,
       phone          TEXT,
       start_date     DATE NOT NULL DEFAULT CURRENT_DATE,
       end_date       DATE,
       notes          TEXT
   );

   CREATE TABLE rates (
       rate_id            SERIAL PRIMARY KEY,
       effective_date     DATE NOT NULL UNIQUE,
       rate_kes_per_kg    NUMERIC(8,2) NOT NULL CHECK (rate_kes_per_kg > 0),
       set_by             TEXT
   );

   CREATE TABLE receipts (
       receipt_id         BIGSERIAL PRIMARY KEY,
       receipt_no         TEXT UNIQUE NOT NULL,
       centre_name        TEXT NOT NULL,
       centre_code        TEXT,
       factory_name       TEXT,
       factory_code       TEXT,
       farmer_ktda_id     TEXT NOT NULL,
       farmer_name        TEXT NOT NULL,
       plucked_at         TIMESTAMP NOT NULL,
       tare_weight_kg     NUMERIC(5,2) NOT NULL DEFAULT 0,
       bag_count          INT NOT NULL,
       net_total_kg       NUMERIC(7,2) NOT NULL,
       mtd_kg_printed     NUMERIC(8,2),
       clerk_name         TEXT,
       clerk_id           TEXT,
       photo_path         TEXT,
       ocr_raw_text       TEXT,
       confirmed_by_human BOOLEAN NOT NULL DEFAULT FALSE,
       captured_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );

   CREATE TABLE receipt_bags (
       bag_id           BIGSERIAL PRIMARY KEY,
       receipt_id       BIGINT NOT NULL REFERENCES receipts(receipt_id) ON DELETE CASCADE,
       bag_no           INT NOT NULL,
       act_wt_kg        NUMERIC(5,2) NOT NULL,
       net_wt_kg        NUMERIC(5,2) NOT NULL,
       worker_id        TEXT REFERENCES workers(worker_id),
       rate_kes_per_kg  NUMERIC(8,2) NOT NULL,
       pay_kes          NUMERIC(10,2) GENERATED ALWAYS AS (net_wt_kg * rate_kes_per_kg) STORED,
       UNIQUE (receipt_id, bag_no)
   );

   CREATE INDEX idx_bags_worker ON receipt_bags(worker_id);
   CREATE INDEX idx_bags_receipt ON receipt_bags(receipt_id);

   CREATE OR REPLACE VIEW v_payments_due AS
   SELECT
       b.bag_id,
       r.receipt_no,
       r.plucked_at::date            AS pluck_date,
       date_trunc('month', r.plucked_at)::date AS month_start,
       EXTRACT(YEAR  FROM r.plucked_at)::INT AS year,
       EXTRACT(MONTH FROM r.plucked_at)::INT AS month,
       w.worker_id,
       w.full_name,
       b.bag_no,
       b.act_wt_kg,
       b.net_wt_kg,
       b.rate_kes_per_kg,
       b.pay_kes,
       r.centre_name,
       r.clerk_name
   FROM receipt_bags b
   JOIN receipts r ON r.receipt_id = b.receipt_id
   JOIN workers w  ON w.worker_id  = b.worker_id;