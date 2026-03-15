-- ============================================================
-- FeatureFlow — PostgreSQL Initialisation
-- Runs as POSTGRES_USER on the primary at first startup
-- Creates:
--   - featureflow database (already created via env)
--   - Debezium replication user + slot
--   - Application user
--   - 5 schemas (one per repo) with tables
-- ============================================================

-- ── Replication user (for streaming replication + Debezium) ──
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'replicator') THEN
    CREATE ROLE replicator WITH LOGIN REPLICATION
      PASSWORD 'change_me_repl';
  END IF;
END $$;

GRANT pg_read_all_data TO replicator;

-- ── Application user ──────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'featureflow_app') THEN
    CREATE ROLE featureflow_app WITH LOGIN
      PASSWORD 'app_change_me';
  END IF;
END $$;

-- ── Debezium logical replication slot ─────────────────────────
-- Created here so it survives container restarts.
-- Debezium connector will reuse it via slot.name config.
SELECT pg_create_logical_replication_slot('debezium_slot', 'pgoutput')
WHERE NOT EXISTS (
  SELECT FROM pg_replication_slots WHERE slot_name = 'debezium_slot'
);

-- ── Publication for all tables ────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_publication WHERE pubname = 'featureflow_pub') THEN
    CREATE PUBLICATION featureflow_pub FOR ALL TABLES;
  END IF;
END $$;

-- ==============================================================
-- REPO 1 — collateral_valuations
-- ==============================================================
CREATE SCHEMA IF NOT EXISTS repo1;

CREATE TABLE IF NOT EXISTS repo1.collateral_valuations (
    id                          BIGSERIAL PRIMARY KEY,
    applicant_hash_id           VARCHAR(20)    NOT NULL,
    facility_id                 VARCHAR(20)    NOT NULL,
    collateral_type_category    VARCHAR(50),
    valuation_method            VARCHAR(30)    CHECK (valuation_method IN
                                    ('AVM','Physical','Drive-by','Desktop','Broker')),
    valuation_confidence_score  NUMERIC(5,4),
    market_value                NUMERIC(15,2),
    outstanding_balance         NUMERIC(15,2),
    ltv_after_valuation         NUMERIC(6,4),
    insurance_coverage_flag     BOOLEAN        DEFAULT FALSE,
    insurance_expiry_date       DATE,
    revaluation_frequency_months SMALLINT,
    next_revaluation_date       DATE,
    valuation_date              DATE           NOT NULL,
    created_at                  TIMESTAMPTZ    DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r1_cv_applicant  ON repo1.collateral_valuations(applicant_hash_id);
CREATE INDEX IF NOT EXISTS idx_r1_cv_facility   ON repo1.collateral_valuations(facility_id);
CREATE INDEX IF NOT EXISTS idx_r1_cv_val_date   ON repo1.collateral_valuations(valuation_date);
ALTER TABLE repo1.collateral_valuations REPLICA IDENTITY FULL;

GRANT SELECT, INSERT, UPDATE ON repo1.collateral_valuations TO featureflow_app;

-- ==============================================================
-- REPO 2 — protocol_adherence
-- ==============================================================
CREATE SCHEMA IF NOT EXISTS repo2;

CREATE TABLE IF NOT EXISTS repo2.protocol_adherence (
    id                          BIGSERIAL PRIMARY KEY,
    patient_hash_id             VARCHAR(20)    NOT NULL,
    episode_id                  VARCHAR(20)    NOT NULL,
    protocol_id                 VARCHAR(20)    NOT NULL,
    protocol_name               VARCHAR(100),
    adherence_percentage        NUMERIC(5,2),
    deviation_count             SMALLINT       DEFAULT 0,
    pathway_completion_flag     BOOLEAN,
    expected_outcome_achievement VARCHAR(20)   CHECK (expected_outcome_achievement IN
                                    ('Exceeded','Met','Partial','Not Met')),
    audit_timestamp             TIMESTAMPTZ    NOT NULL,
    created_at                  TIMESTAMPTZ    DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r2_pa_patient  ON repo2.protocol_adherence(patient_hash_id);
CREATE INDEX IF NOT EXISTS idx_r2_pa_episode  ON repo2.protocol_adherence(episode_id);
CREATE INDEX IF NOT EXISTS idx_r2_pa_protocol ON repo2.protocol_adherence(protocol_id);
ALTER TABLE repo2.protocol_adherence REPLICA IDENTITY FULL;

GRANT SELECT, INSERT, UPDATE ON repo2.protocol_adherence TO featureflow_app;

-- ==============================================================
-- REPO 3 — forecast_accuracy_tracking
-- ==============================================================
CREATE SCHEMA IF NOT EXISTS repo3;

CREATE TABLE IF NOT EXISTS repo3.forecast_accuracy (
    id                          BIGSERIAL PRIMARY KEY,
    sku_id                      VARCHAR(30)    NOT NULL,
    node_id                     VARCHAR(20)    NOT NULL,
    forecast_horizon_days       SMALLINT,
    forecast_model_version      VARCHAR(30),
    forecast_mape               NUMERIC(8,4),
    forecast_bias               NUMERIC(8,4),
    forecast_rmse               NUMERIC(12,4),
    actual_demand               NUMERIC(12,2),
    predicted_demand            NUMERIC(12,2),
    stockout_flag               BOOLEAN        DEFAULT FALSE,
    overstock_flag              BOOLEAN        DEFAULT FALSE,
    forecast_date               DATE           NOT NULL,
    created_at                  TIMESTAMPTZ    DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r3_fa_sku    ON repo3.forecast_accuracy(sku_id);
CREATE INDEX IF NOT EXISTS idx_r3_fa_node   ON repo3.forecast_accuracy(node_id);
CREATE INDEX IF NOT EXISTS idx_r3_fa_date   ON repo3.forecast_accuracy(forecast_date);
ALTER TABLE repo3.forecast_accuracy REPLICA IDENTITY FULL;

GRANT SELECT, INSERT, UPDATE ON repo3.forecast_accuracy TO featureflow_app;

-- ==============================================================
-- REPO 4 — actuarial_segmentation
-- ==============================================================
CREATE SCHEMA IF NOT EXISTS repo4;

CREATE TABLE IF NOT EXISTS repo4.actuarial_segmentation (
    id                          BIGSERIAL PRIMARY KEY,
    policyholder_hash_id        VARCHAR(20)    NOT NULL,
    policy_id                   VARCHAR(20)    NOT NULL,
    product_type                VARCHAR(30)    CHECK (product_type IN
                                    ('Life','Funeral','Vehicle','Building','Contents','GAP')),
    mortality_rate_band         VARCHAR(10),
    lapse_probability_score     NUMERIC(5,4),
    claim_frequency_band        VARCHAR(20),
    actuarial_risk_class        VARCHAR(10),
    net_premium_rate            NUMERIC(8,4),
    expense_loading_rate        NUMERIC(6,4),
    profit_margin_estimate      NUMERIC(8,4),
    ifrs17_measurement_model    VARCHAR(20)    CHECK (ifrs17_measurement_model IN
                                    ('GMM','PAA','VFA')),
    segmentation_date           DATE           NOT NULL,
    created_at                  TIMESTAMPTZ    DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r4_as_holder  ON repo4.actuarial_segmentation(policyholder_hash_id);
CREATE INDEX IF NOT EXISTS idx_r4_as_policy  ON repo4.actuarial_segmentation(policy_id);
CREATE INDEX IF NOT EXISTS idx_r4_as_date    ON repo4.actuarial_segmentation(segmentation_date);
ALTER TABLE repo4.actuarial_segmentation REPLICA IDENTITY FULL;

GRANT SELECT, INSERT, UPDATE ON repo4.actuarial_segmentation TO featureflow_app;

-- ==============================================================
-- REPO 5 — service_plan_engagement
-- ==============================================================
CREATE SCHEMA IF NOT EXISTS repo5;

CREATE TABLE IF NOT EXISTS repo5.service_plan_engagement (
    id                          BIGSERIAL PRIMARY KEY,
    subscriber_hash_id          VARCHAR(20)    NOT NULL,
    plan_id                     VARCHAR(20)    NOT NULL,
    plan_type                   VARCHAR(30)    CHECK (plan_type IN
                                    ('Prepaid','Postpaid','Hybrid','IoT','Business')),
    monthly_arpu                NUMERIC(10,2),
    data_bundle_utilisation_pct NUMERIC(5,2),
    voice_minutes_used          NUMERIC(8,2),
    sms_count                   INTEGER,
    vas_subscriptions_active    SMALLINT       DEFAULT 0,
    roaming_flag                BOOLEAN        DEFAULT FALSE,
    plan_upgrade_flag           BOOLEAN        DEFAULT FALSE,
    plan_downgrade_flag         BOOLEAN        DEFAULT FALSE,
    churn_risk_score            NUMERIC(5,4),
    nps_response_score          SMALLINT       CHECK (nps_response_score BETWEEN 0 AND 10),
    engagement_month            DATE           NOT NULL,
    created_at                  TIMESTAMPTZ    DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ    DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r5_spe_subscriber ON repo5.service_plan_engagement(subscriber_hash_id);
CREATE INDEX IF NOT EXISTS idx_r5_spe_plan        ON repo5.service_plan_engagement(plan_id);
CREATE INDEX IF NOT EXISTS idx_r5_spe_month       ON repo5.service_plan_engagement(engagement_month);
ALTER TABLE repo5.service_plan_engagement REPLICA IDENTITY FULL;

GRANT SELECT, INSERT, UPDATE ON repo5.service_plan_engagement TO featureflow_app;

-- ── Grant schema usage ─────────────────────────────────────
GRANT USAGE ON SCHEMA repo1, repo2, repo3, repo4, repo5 TO featureflow_app;
GRANT USAGE ON SCHEMA repo1, repo2, repo3, repo4, repo5 TO replicator;

-- ── Trigger: auto-update updated_at ───────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  tbl RECORD;
BEGIN
  FOR tbl IN
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname IN ('repo1','repo2','repo3','repo4','repo5')
  LOOP
    EXECUTE format(
      'CREATE OR REPLACE TRIGGER trg_%s_%s_updated_at
       BEFORE UPDATE ON %I.%I
       FOR EACH ROW EXECUTE FUNCTION update_updated_at()',
      tbl.schemaname, tbl.tablename, tbl.schemaname, tbl.tablename
    );
  END LOOP;
END $$;

\echo 'PostgreSQL init complete'
