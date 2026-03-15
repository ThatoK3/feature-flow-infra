-- ============================================================
-- FeatureFlow — MySQL Primary Initialisation
-- Runs at container first startup.
-- Creates: Debezium user, app user, 5 repo databases + tables.
-- ============================================================

-- ── Debezium user (needs REPLICATION SLAVE + CLIENT) ──────
CREATE USER IF NOT EXISTS 'debezium'@'%'
    IDENTIFIED WITH mysql_native_password BY 'debezium_change_me';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE,
      REPLICATION CLIENT, LOCK TABLES ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

-- ── Application user ──────────────────────────────────────
CREATE USER IF NOT EXISTS 'featureflow_app'@'%'
    IDENTIFIED BY 'app_change_me';

-- ============================================================
-- REPO 1 — bureau_consumer_profiles
-- ============================================================
CREATE DATABASE IF NOT EXISTS repo1_bureau
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE repo1_bureau;

CREATE TABLE IF NOT EXISTS bureau_consumer_profiles (
    id                          BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    consumer_hash_id            VARCHAR(20)     NOT NULL,
    adverse_listing_flag        TINYINT(1)      DEFAULT 0,
    payment_history_score       SMALLINT,
    enquiry_count_90d           TINYINT,
    accounts_active_count       TINYINT,
    worst_status_12m            VARCHAR(10),
    total_outstanding           DECIMAL(15,2),
    credit_utilisation_rate     DECIMAL(5,4),
    months_since_last_default   SMALLINT,
    bureau_query_date           DATE            NOT NULL,
    created_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_consumer (consumer_hash_id),
    INDEX idx_query_date (bureau_query_date)
) ENGINE=InnoDB;

GRANT SELECT, INSERT, UPDATE ON repo1_bureau.* TO 'featureflow_app'@'%';
GRANT SELECT ON repo1_bureau.* TO 'debezium'@'%';

-- ============================================================
-- REPO 2 — episodes_of_care
-- ============================================================
CREATE DATABASE IF NOT EXISTS repo2_episodes
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE repo2_episodes;

CREATE TABLE IF NOT EXISTS episodes_of_care (
    id                          BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    patient_hash_id             VARCHAR(20)     NOT NULL,
    episode_id                  VARCHAR(20)     NOT NULL UNIQUE,
    provider_id                 VARCHAR(20),
    specialty                   VARCHAR(50),
    department                  VARCHAR(50),
    icu_flag                    TINYINT(1)      DEFAULT 0,
    length_of_stay_days         SMALLINT,
    drg_weight                  DECIMAL(7,4),
    discharge_disposition       VARCHAR(40),
    readmission_30d_risk_score  DECIMAL(5,4),
    readmission_within_30d      TINYINT(1)      DEFAULT 0,
    admission_date              DATE            NOT NULL,
    discharge_date              DATE,
    created_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_patient  (patient_hash_id),
    INDEX idx_episode  (episode_id),
    INDEX idx_adm_date (admission_date)
) ENGINE=InnoDB;

GRANT SELECT, INSERT, UPDATE ON repo2_episodes.* TO 'featureflow_app'@'%';
GRANT SELECT ON repo2_episodes.* TO 'debezium'@'%';

-- ============================================================
-- REPO 3 — distribution_node_operations
-- ============================================================
CREATE DATABASE IF NOT EXISTS repo3_nodes
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE repo3_nodes;

CREATE TABLE IF NOT EXISTS node_operations (
    id                          BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    node_id                     VARCHAR(20)     NOT NULL,
    node_type                   VARCHAR(30),
    region                      VARCHAR(30),
    throughput_units_per_day    DECIMAL(12,2),
    capacity_utilisation_pct    DECIMAL(5,2),
    on_time_delivery_rate       DECIMAL(5,4),
    damage_rate                 DECIMAL(5,4),
    stockout_frequency_7d       TINYINT,
    avg_lead_time_days          DECIMAL(5,2),
    labour_efficiency_index     DECIMAL(5,4),
    operation_date              DATE            NOT NULL,
    created_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_node      (node_id),
    INDEX idx_op_date   (operation_date)
) ENGINE=InnoDB;

GRANT SELECT, INSERT, UPDATE ON repo3_nodes.* TO 'featureflow_app'@'%';
GRANT SELECT ON repo3_nodes.* TO 'debezium'@'%';

-- ============================================================
-- REPO 4 — claims_experience
-- ============================================================
CREATE DATABASE IF NOT EXISTS repo4_claims
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE repo4_claims;

CREATE TABLE IF NOT EXISTS claims_experience (
    id                          BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    policyholder_hash_id        VARCHAR(20)     NOT NULL,
    policy_id                   VARCHAR(20)     NOT NULL,
    claim_id                    VARCHAR(20)     UNIQUE,
    product_type                VARCHAR(30),
    claim_type                  VARCHAR(30),
    claim_amount                DECIMAL(15,2),
    approved_amount             DECIMAL(15,2),
    repudiation_flag            TINYINT(1)      DEFAULT 0,
    fraudulent_flag             TINYINT(1)      DEFAULT 0,
    days_to_settlement          SMALLINT,
    claim_frequency_12m         TINYINT,
    claim_date                  DATE            NOT NULL,
    settlement_date             DATE,
    created_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_holder    (policyholder_hash_id),
    INDEX idx_policy    (policy_id),
    INDEX idx_cl_date   (claim_date)
) ENGINE=InnoDB;

GRANT SELECT, INSERT, UPDATE ON repo4_claims.* TO 'featureflow_app'@'%';
GRANT SELECT ON repo4_claims.* TO 'debezium'@'%';

-- ============================================================
-- REPO 5 — billing_behaviour
-- ============================================================
CREATE DATABASE IF NOT EXISTS repo5_billing
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE repo5_billing;

CREATE TABLE IF NOT EXISTS billing_behaviour (
    id                          BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    subscriber_hash_id          VARCHAR(20)     NOT NULL,
    billing_cycle_month         DATE            NOT NULL,
    invoice_amount              DECIMAL(10,2),
    payment_amount              DECIMAL(10,2),
    payment_days_late           SMALLINT        DEFAULT 0,
    payment_method              VARCHAR(30),
    debit_order_flag            TINYINT(1)      DEFAULT 0,
    debit_order_return_flag     TINYINT(1)      DEFAULT 0,
    outstanding_balance         DECIMAL(10,2)   DEFAULT 0,
    suspension_flag             TINYINT(1)      DEFAULT 0,
    dispute_flag                TINYINT(1)      DEFAULT 0,
    created_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_subscriber (subscriber_hash_id),
    INDEX idx_bill_month (billing_cycle_month)
) ENGINE=InnoDB;

GRANT SELECT, INSERT, UPDATE ON repo5_billing.* TO 'featureflow_app'@'%';
GRANT SELECT ON repo5_billing.* TO 'debezium'@'%';

FLUSH PRIVILEGES;

SELECT 'MySQL primary init complete' AS status;
