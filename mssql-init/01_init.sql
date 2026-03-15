-- ============================================================
-- FeatureFlow — MS SQL Server Initialisation
-- Run by the mssql-init one-shot container after startup.
-- Enables CDC on all 5 repo databases + creates app user.
-- ============================================================

-- Wait for SQL Agent to start (CDC depends on it)
WAITFOR DELAY '00:00:15';
GO

-- ============================================================
-- REPO 1 — applicant_profiles + loan_facilities
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'repo1_credit')
    CREATE DATABASE repo1_credit;
GO

USE repo1_credit;
GO

EXEC sys.sp_cdc_enable_db;
GO

CREATE TABLE IF NOT EXISTS dbo.applicant_profiles (
    applicant_hash_id       VARCHAR(20)     NOT NULL PRIMARY KEY,
    id_number_hash          VARCHAR(64),
    age_band                VARCHAR(10),
    gender                  VARCHAR(10),
    employment_status       VARCHAR(30),
    employer_sector         VARCHAR(50),
    province                VARCHAR(30),
    income_quintile         VARCHAR(5),
    employment_stability_index DECIMAL(5,4),
    payment_to_income_ratio    DECIMAL(6,4),
    demographic_risk_score     DECIMAL(8,2),
    existing_exposure_band  VARCHAR(20),
    created_at              DATETIME2       DEFAULT GETDATE(),
    updated_at              DATETIME2       DEFAULT GETDATE()
);

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'applicant_profiles',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO

CREATE TABLE IF NOT EXISTS dbo.loan_facilities (
    facility_id             VARCHAR(20)     NOT NULL PRIMARY KEY,
    applicant_hash_id       VARCHAR(20)     NOT NULL,
    facility_type_encoded   TINYINT,
    facility_type_label     VARCHAR(30),
    origination_date        DATE,
    tenure_months           SMALLINT,
    original_amount         DECIMAL(15,2),
    outstanding_balance     DECIMAL(15,2),
    interest_rate           DECIMAL(6,4),
    interest_rate_margin    DECIMAL(6,4),
    ltv_ratio               DECIMAL(6,4),
    expected_loss_band      VARCHAR(10),
    created_at              DATETIME2       DEFAULT GETDATE(),
    updated_at              DATETIME2       DEFAULT GETDATE()
);

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'loan_facilities',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO

-- ============================================================
-- REPO 2 — patient_clinical_profiles
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'repo2_healthcare')
    CREATE DATABASE repo2_healthcare;
GO

USE repo2_healthcare;
GO

EXEC sys.sp_cdc_enable_db;
GO

CREATE TABLE IF NOT EXISTS dbo.patient_clinical_profiles (
    patient_hash_id         VARCHAR(20)     NOT NULL PRIMARY KEY,
    age_band                VARCHAR(10),
    gender                  VARCHAR(10),
    province                VARCHAR(30),
    charlson_comorbidity_index  SMALLINT,
    elixhauser_score            SMALLINT,
    frailty_indicator       VARCHAR(20),
    social_determinants_score DECIMAL(5,2),
    primary_diagnosis_code  VARCHAR(10),
    primary_diagnosis_desc  VARCHAR(200),
    chronic_conditions_count TINYINT,
    created_at              DATETIME2       DEFAULT GETDATE(),
    updated_at              DATETIME2       DEFAULT GETDATE()
);

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'patient_clinical_profiles',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO

-- ============================================================
-- REPO 3 — product_sales_transactions
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'repo3_supplychain')
    CREATE DATABASE repo3_supplychain;
GO

USE repo3_supplychain;
GO

EXEC sys.sp_cdc_enable_db;
GO

CREATE TABLE IF NOT EXISTS dbo.product_sales_transactions (
    transaction_id          VARCHAR(30)     NOT NULL PRIMARY KEY,
    sku_id                  VARCHAR(30)     NOT NULL,
    node_id                 VARCHAR(20)     NOT NULL,
    customer_segment        VARCHAR(30),
    quantity_sold           INT,
    unit_price              DECIMAL(12,2),
    gross_revenue           DECIMAL(15,2),
    discount_applied        DECIMAL(6,4),
    channel                 VARCHAR(20),
    promo_flag              BIT             DEFAULT 0,
    transaction_date        DATE            NOT NULL,
    created_at              DATETIME2       DEFAULT GETDATE()
);

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'product_sales_transactions',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO

-- ============================================================
-- REPO 4 — policyholder_profiles
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'repo4_insurance')
    CREATE DATABASE repo4_insurance;
GO

USE repo4_insurance;
GO

EXEC sys.sp_cdc_enable_db;
GO

CREATE TABLE IF NOT EXISTS dbo.policyholder_profiles (
    policyholder_hash_id    VARCHAR(20)     NOT NULL PRIMARY KEY,
    age_band                VARCHAR(10),
    gender                  VARCHAR(10),
    province                VARCHAR(30),
    smoker_flag             BIT             DEFAULT 0,
    bmi_band                VARCHAR(20),
    occupation_risk_band    VARCHAR(20),
    lifestyle_risk_score    DECIMAL(5,4),
    health_declaration_flag BIT             DEFAULT 0,
    income_band             VARCHAR(20),
    created_at              DATETIME2       DEFAULT GETDATE(),
    updated_at              DATETIME2       DEFAULT GETDATE()
);

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'policyholder_profiles',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO

-- ============================================================
-- REPO 5 — subscriber_lifecycle
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'repo5_telecom')
    CREATE DATABASE repo5_telecom;
GO

USE repo5_telecom;
GO

EXEC sys.sp_cdc_enable_db;
GO

CREATE TABLE IF NOT EXISTS dbo.subscriber_lifecycle (
    subscriber_hash_id      VARCHAR(20)     NOT NULL PRIMARY KEY,
    activation_date         DATE,
    tenure_months           SMALLINT,
    contract_type           VARCHAR(20),
    current_plan_id         VARCHAR(20),
    handset_category        VARCHAR(30),
    province                VARCHAR(30),
    clv_band                VARCHAR(20),
    churn_risk_score        DECIMAL(5,4),
    last_interaction_days   SMALLINT,
    loyalty_tier            VARCHAR(20),
    created_at              DATETIME2       DEFAULT GETDATE(),
    updated_at              DATETIME2       DEFAULT GETDATE()
);

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'subscriber_lifecycle',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO

-- ── Application login ──────────────────────────────────────
USE master;
GO
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'featureflow_app')
BEGIN
    CREATE LOGIN featureflow_app WITH PASSWORD = 'App_FeatureFlow_2024!';
END
GO

PRINT 'MSSQL init complete';
GO
