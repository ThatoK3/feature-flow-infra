# FeatureFlow — Synthetic Data Generators & Feature Store Repositories

This package contains **5 production-quality feature store repository definitions** and their matching **synthetic data generators**, covering South African regulated industries. Each repository is a fully enriched Feast architecture JSON ready to import into FeatureFlow, paired with a Python script that generates 150,000 rows of realistic training data.

---

## Repository Overview

| # | Repository | Domain | Nodes | Feature Views | Features | Edges |
|---|-----------|--------|-------|---------------|----------|-------|
| 1 | `credit_risk_ml_platform` | Credit & Lending | 16 | 5 | 26 | 17 |
| 2 | `healthcare_analytics_ml` | Healthcare | 16 | 5 | 23 | 17 |
| 3 | `supply_chain_demand_forecasting` | Supply Chain | 16 | 5 | 24 | 17 |
| 4 | `insurance_pricing_ml_platform` | Insurance | 16 | 5 | 26 | 18 |
| 5 | `telecom_customer_churn_ml` | Telecommunications | 16 | 5 | 26 | 19 |

Each repository follows the same structural pattern: **5 data sources → 4 entities → 5 feature views → 2 feature services**.

---

## Repository Definitions (JSON)

### Repo 1 — credit_risk_ml_platform

**Owner:** Model Risk Management Team
**Location:** `/opt/feast/credit_risk`
**Description:** Credit risk assessment ML platform for retail and corporate lending. Implements POPIA Section 71 automated decision-making safeguards, SARB model governance requirements, and SHAP/LIME explainability. Supports PD model training, IFRS 9 provisioning, and bias monitoring.

**Data Sources:** Core Banking SQL Server, Credit Bureau MySQL, Document Store MongoDB, Risk Ratings PostgreSQL, Training Archives S3

**Entities:** Applicant, LoanFacility, CreditBureauProfile, CollateralAsset

**Feature Views:**

| Feature View | Type | Features |
|---|---|---|
| ApplicantRiskProfile | batch | age_band, employment_stability_index, income_quintile, existing_exposure_band, payment_to_income_ratio, demographic_risk_score |
| BureauHistoryAggregated | batch | adverse_listing_flag, payment_history_score, enquiry_count_90d, accounts_active_count, worst_status_12m |
| FacilityRiskMetrics | batch | facility_type_encoded, ltv_ratio, tenure_months, interest_rate_margin, expected_loss_band |
| CollateralValuationFeatures | batch | collateral_type_category, valuation_confidence_score, ltv_after_valuation, insurance_coverage_flag, revaluation_frequency_months |
| HistoricalTrainingFeatures | batch | outcome_default_flag, application_year_quarter, economic_cycle_indicator, model_version_used, demographic_parity_group |

**Compliance:** POPIA Section 71, SARB Model Risk Governance, NCA Section 81, IFRS 9, NCR

---

### Repo 2 — healthcare_analytics_ml

**Owner:** Clinical Analytics Team
**Location:** `/opt/feast/healthcare`
**Description:** Healthcare predictive analytics platform for patient outcomes, readmission risk, and resource optimisation. POPIA-compliant with HPCSA and NHI-ready data governance.

**Data Sources:** Clinical EMR PostgreSQL, Billing & Claims SQL Server, Laboratory LIMS MongoDB, Pharmacy Dispensing MySQL, IoT Monitoring Kafka

**Entities:** Patient, ClinicalEpisode, HealthcareProvider, CareProtocol

**Feature Views:**

| Feature View | Type | Features |
|---|---|---|
| PatientRiskProfile | batch | age_band, charlson_comorbidity_index, elixhauser_score, frailty_indicator, social_determinants_score |
| EpisodeOutcomeFeatures | batch | length_of_stay_days, drg_weight, icu_flag, discharge_disposition, readmission_30d_risk_score |
| ProviderWorkloadFeatures | batch | provider_experience_band, current_caseload, specialty_demand_index, shift_pattern_type, burnout_risk_indicator |
| ProtocolAdherenceFeatures | batch | protocol_adherence_percentage, deviation_count, pathway_completion_flag, expected_outcome_achievement |
| NLPClinicalFeatures | batch | sentiment_score, symptom_mention_count, medication_adherence_mention, social_support_indicator |

**Compliance:** POPIA, HPCSA, NHI Data Governance, SAHPRA

---

### Repo 3 — supply_chain_demand_forecasting

**Owner:** Supply Chain Analytics Team
**Location:** `/opt/feast/supply_chain`
**Description:** Supply chain demand forecasting and inventory optimisation platform for retail and manufacturing. Integrates IoT sensor streams, supplier risk scoring, and external event signals.

**Data Sources:** ERP System PostgreSQL, Demand Planning SQL Server, Supplier Portal MongoDB, IoT Sensor Kafka, External Market S3

**Entities:** Product, SupplyChainNode, Supplier, ForecastCycle

**Feature Views:**

| Feature View | Type | Features |
|---|---|---|
| ProductDemandProfile | batch | demand_velocity_class, seasonality_strength_index, trend_direction, price_elasticity_band, substitution_risk_score |
| NodeOperationalFeatures | batch | current_utilization_rate, capacity_constraint_flag, inbound_lead_time_days, outbound_lead_time_days, seasonal_capacity_factor |
| SupplierRiskFeatures | batch | supplier_tier, ontime_delivery_rate, quality_defect_rate, financial_stability_score, geopolitical_risk_band |
| ForecastAccuracyFeatures | batch | historical_wape, bias_direction, forecast_revision_count, promotional_lift_factor, external_event_impact |
| IoTSensorFeatures | **stream** | warehouse_temperature_status, equipment_health_score, energy_consumption_anomaly, space_utilization_realtime |

**Note:** IoTSensorFeatures uses a streaming feature view via Kafka.

---

### Repo 4 — insurance_pricing_ml_platform

**Owner:** Actuarial Data Science Team
**Location:** `/opt/feast/insurance`
**Description:** Insurance pricing and risk segmentation ML platform for life, funeral, and vehicle cover. POPIA Section 11 compliant with actuarial audit trails and catastrophe risk modelling.

**Data Sources:** Policy Admin SQL Server, Claims History PostgreSQL, Actuarial Reserves MongoDB, Reinsurance Treaties MySQL, Geospatial Risk S3

**Entities:** Policyholder, InsurancePolicy, ClaimsRecord, RiskZone

**Feature Views:**

| Feature View | Type | Features |
|---|---|---|
| PolicyholderRiskProfile | batch | age_band, gender_pricing_factor, smoking_status, occupation_risk_class, income_stability_band, geographic_risk_zone |
| ClaimsExperienceFeatures | batch | claim_frequency_3yr, average_claim_cost_band, claim_cause_category, time_since_last_claim_months, no_claims_bonus_level |
| PolicyCoverageFeatures | batch | product_type, sum_assured_band, premium_payment_term, waiting_period_status, rider_benefits_count |
| ActuarialSegmentationFeatures | batch | base_rate_segment, risk_adjustment_factor, lapse_rate_expectation, expense_loading_percentage, profit_margin_target |
| CatastropheRiskFeatures | batch | flood_risk_zone, earthquake_risk_score, windstorm_exposure_band, crime_risk_index, weather_event_frequency |

**Compliance:** POPIA Section 11, FSCA, Short-Term Insurance Act, Long-Term Insurance Act

---

### Repo 5 — telecom_customer_churn_ml

**Owner:** Customer Intelligence Team
**Location:** `/opt/feast/telecom`
**Description:** Telecommunications customer churn prediction and lifetime value optimisation. POPIA-compliant with ICASA regulatory requirements. Includes real-time network experience streaming features.

**Data Sources:** BSS/OSS PostgreSQL, Network Analytics Kafka, Customer Care SQL Server, Product Catalogue MongoDB, Revenue Management MySQL

**Entities:** Subscriber, Subscription, NetworkDevice, CustomerInteraction

**Feature Views:**

| Feature View | Type | Features |
|---|---|---|
| SubscriberLifecycleFeatures | batch | tenure_months_band, contract_type, payment_method_stability, autopay_enrollment_flag, customer_lifetime_value_band, churn_risk_score_current |
| BillingBehaviourFeatures | batch | payment_punctuality_score, average_monthly_spend_band, billing_dispute_count_6m, payment_method_change_frequency, arpu_trend_direction |
| NetworkExperienceFeatures | **stream** | average_data_speed_experience, call_drop_rate_experience, network_congestion_exposure, device_capability_match, roaming_usage_flag |
| ProductEngagementFeatures | batch | plan_utilization_rate, data_overage_frequency, bundle_affinity_score, plan_change_frequency, value_added_service_uptake |
| InteractionSentimentFeatures | **stream** | recent_sentiment_score, complaint_escalation_flag, service_call_frequency_30d, digital_channel_adoption_score, satisfaction_prediction |

**Compliance:** POPIA, ICASA, ECT Act, Consumer Protection Act

---

## Synthetic Data Generators

Each generator is a standalone Python script with **no external dependencies** (stdlib only — `csv`, `random`, `os`, `datetime`). All generators produce **150,000 rows** in chunks of 10,000 to manage memory.

### Running the Generators

```bash
# No pip install required
python3 generate_repo1_credit.py        # → credit_risk_150k.csv       (~40 MB)
python3 generate_repo2_healthcare.py    # → healthcare_150k.csv         (~22 MB)
python3 generate_repo3_supplychain.py   # → supply_chain_150k.csv       (~20 MB)
python3 generate_repo4_insurance.py     # → insurance_150k.csv          (~25 MB)
python3 generate_repo5_telecom.py       # → telecom_churn_150k.csv      (~22 MB)
```

All generators use `random.seed(42)` for full reproducibility.

### Data Design Principles

**Realistic distributions** — values are drawn from Gaussian distributions parameterised on real-world domain knowledge, not uniform random. For example, `ltv_ratio` in the credit repo has mean 0.71, std 0.22, capped at 2.0; `charlson_comorbidity_index` in healthcare has mean 2.3, std 2.8.

**Correlated features** — where domain logic demands it, features are correlated. In the credit repo, `outcome_default_flag` is driven by `payment_history_score`, `adverse_listing_flag`, and `payment_to_income_ratio`. In healthcare, `readmission_30d_risk_score` increases with comorbidity index and age.

**Realistic null rates** — features that are nullable in the schema have calibrated null rates. For example, `frailty_indicator` is null for 21.7% of patients, `sentiment_score` is null when no clinical note is available (10.7% of episodes).

**South African name pools** — all person-facing repos use gender-correct, ethnically diverse South African name pools spanning Afrikaans/Cape Dutch, Zulu/Nguni, Sotho/Tswana, Xhosa, Venda/Tsonga, Indian, Cape Malay, and English communities.

**Regulatory realism** — features tagged `popia-pii`, `sarb-governed`, `ncr-regulated` in the repo JSON are generated with appropriate care: PII fields are hashed or binned, demographic features are anonymised, and target variables follow realistic base rates.

### Output Schema Summary

| Generator | Output File | Key Entity ID | Target Variable | Base Rate |
|---|---|---|---|---|
| credit | credit_risk_150k.csv | `applicant_id` | `outcome_default_flag` | ~8.7% |
| healthcare | healthcare_150k.csv | `patient_hash_id` | `readmission_within_30d` | ~11% |
| supply chain | supply_chain_150k.csv | `product_sku` | `stockout_occurred` | ~6% |
| insurance | insurance_150k.csv | `policy_id` | `claim_occurred_12m` | ~14% |
| telecom | telecom_churn_150k.csv | `subscriber_id` | `churned_within_90d` | ~18% |

---

## Importing into FeatureFlow

1. Log in to FeatureFlow and open the repository list
2. Click **Create New** — opens the canvas in a new tab with `?new`
3. Click the **Import** button in the toolbar and select the relevant `repo_N_enriched.json`
4. The canvas loads all nodes, edges, and feature metadata automatically
5. Click **Push** to save to the backend

All 5 JSON files are ready to import as-is — positions, connections, feature metadata, TTLs, security classifications, and descriptions are all populated.

---

## File Structure

```
data_gen_repos/
├── generate_repo1_credit.py          # Credit risk data generator
├── generate_repo2_healthcare.py      # Healthcare analytics generator
├── generate_repo3_supplychain.py     # Supply chain generator
├── generate_repo4_insurance.py       # Insurance pricing generator
├── generate_repo5_telecom.py         # Telecom churn generator
├── repo_1_enriched.json              # credit_risk_ml_platform repo
├── repo_2_enriched.json              # healthcare_analytics_ml repo
├── repo_3_enriched.json              # supply_chain_demand_forecasting repo
├── repo_4_enriched.json              # insurance_pricing_ml_platform repo
└── repo_5_enriched.json              # telecom_customer_churn_ml repo
```

---

## Compliance & Regulatory Context

All repositories and generated data are designed with South African regulatory frameworks in mind.

| Regulation | Applies To |
|---|---|
| **POPIA** (Protection of Personal Information Act) | All repos — PII handling, purpose limitation, data minimisation |
| **SARB** model governance | credit, insurance — model risk, stress testing |
| **NCA** (National Credit Act) | credit — affordability assessment, NCR compliance |
| **IFRS 9** | credit — ECL staging, provisioning |
| **FSCA** | insurance — pricing fairness, actuarial standards |
| **ICASA** | telecom — consumer protection, data handling |
| **HPCSA / NHI** | healthcare — patient data governance |
| **ECT Act** | telecom — electronic communications |

No real personal data is used. All names, IDs, and PII-adjacent fields are synthetically generated.
