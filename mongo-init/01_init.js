// ============================================================
// FeatureFlow — MongoDB Initialisation
// Runs on featureflow-mongo-primary at first startup
// Creates:
//   - Application user with readWrite on all 5 databases
//   - Debezium user with clusterMonitor + readAnyDatabase
//   - Collections with schema validation stubs
// ============================================================

// Switch to admin to create users
db = db.getSiblingDB('admin');

// ── Application user ──────────────────────────────────────
db.createUser({
  user: 'featureflow_app',
  pwd:  'app_change_me',
  roles: [
    { role: 'readWrite', db: 'repo1_loan_documents'      },
    { role: 'readWrite', db: 'repo2_clinical_notes'       },
    { role: 'readWrite', db: 'repo3_supplier_sensors'     },
    { role: 'readWrite', db: 'repo4_policy_assessments'   },
    { role: 'readWrite', db: 'repo5_network_sessions'     },
  ]
});

// ── Debezium user (change stream + oplog access) ──────────
db.createUser({
  user: 'debezium',
  pwd:  'debezium_change_me',
  roles: [
    { role: 'clusterMonitor',    db: 'admin'  },
    { role: 'readAnyDatabase',   db: 'admin'  },
    { role: 'read',              db: 'local'  },
    { role: 'readWrite',         db: 'repo1_loan_documents'  },
    { role: 'readWrite',         db: 'repo2_clinical_notes'  },
    { role: 'readWrite',         db: 'repo3_supplier_sensors'},
    { role: 'readWrite',         db: 'repo4_policy_assessments'},
    { role: 'readWrite',         db: 'repo5_network_sessions'},
  ]
});

// ── repo1: loan application documents ─────────────────────
db = db.getSiblingDB('repo1_loan_documents');
db.createCollection('application_documents', {
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['applicant_hash_id', 'document_type', 'created_at'],
    properties: {
      applicant_hash_id: { bsonType: 'string' },
      document_type:     { bsonType: 'string',
                           enum: ['id_document','proof_of_income','bank_statement',
                                  'payslip','tax_return','financial_statements'] },
      file_reference:    { bsonType: 'string' },
      extracted_text:    { bsonType: 'string' },
      nlp_features: {
        bsonType: 'object',
        properties: {
          income_mentions:    { bsonType: 'int'    },
          employment_signals: { bsonType: 'double' },
          risk_keywords:      { bsonType: 'array'  },
          sentiment_score:    { bsonType: 'double' }
        }
      },
      popia_classification: { bsonType: 'string',
                               enum: ['special_category','financial','general'] },
      created_at:  { bsonType: 'date' },
      updated_at:  { bsonType: 'date' }
    }
  }}
});
db.application_documents.createIndex({ applicant_hash_id: 1 });
db.application_documents.createIndex({ document_type: 1 });
db.application_documents.createIndex({ created_at: -1 });
print('repo1_loan_documents ready');

// ── repo2: clinical notes ──────────────────────────────────
db = db.getSiblingDB('repo2_clinical_notes');
db.createCollection('clinical_notes', {
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['patient_hash_id', 'episode_id', 'note_type', 'created_at'],
    properties: {
      patient_hash_id: { bsonType: 'string' },
      episode_id:      { bsonType: 'string' },
      provider_id:     { bsonType: 'string' },
      note_type:       { bsonType: 'string',
                         enum: ['admission','progress','discharge','referral','nursing'] },
      note_text:       { bsonType: 'string' },
      nlp_features: {
        bsonType: 'object',
        properties: {
          sentiment_score:              { bsonType: 'double' },
          symptom_mention_count:        { bsonType: 'int'    },
          medication_adherence_mention: { bsonType: 'bool'   },
          social_support_indicator:     { bsonType: 'string' }
        }
      },
      created_at: { bsonType: 'date' },
      updated_at: { bsonType: 'date' }
    }
  }}
});
db.clinical_notes.createIndex({ patient_hash_id: 1 });
db.clinical_notes.createIndex({ episode_id: 1 });
db.clinical_notes.createIndex({ created_at: -1 });
print('repo2_clinical_notes ready');

// ── repo3: supplier sensor readings ───────────────────────
db = db.getSiblingDB('repo3_supplier_sensors');
db.createCollection('sensor_readings', {
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['supplier_id', 'node_id', 'sensor_type', 'recorded_at'],
    properties: {
      supplier_id:  { bsonType: 'string' },
      node_id:      { bsonType: 'string' },
      sensor_type:  { bsonType: 'string',
                      enum: ['temperature','humidity','vibration','pressure',
                             'location','weight','camera_quality'] },
      reading_value:     { bsonType: 'double' },
      reading_unit:      { bsonType: 'string' },
      anomaly_flag:      { bsonType: 'bool'   },
      anomaly_score:     { bsonType: 'double' },
      raw_payload:       { bsonType: 'object' },
      recorded_at:       { bsonType: 'date'   }
    }
  }}
});
db.sensor_readings.createIndex({ supplier_id: 1, recorded_at: -1 });
db.sensor_readings.createIndex({ node_id: 1 });
db.sensor_readings.createIndex({ anomaly_flag: 1 });
print('repo3_supplier_sensors ready');

// ── repo4: policy risk assessments ────────────────────────
db = db.getSiblingDB('repo4_policy_assessments');
db.createCollection('risk_assessments', {
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['policyholder_hash_id', 'policy_id', 'assessment_type', 'created_at'],
    properties: {
      policyholder_hash_id: { bsonType: 'string' },
      policy_id:            { bsonType: 'string' },
      assessment_type:      { bsonType: 'string',
                              enum: ['underwriting','renewal','claims','catastrophe'] },
      survey_responses:     { bsonType: 'object' },
      risk_signals: {
        bsonType: 'object',
        properties: {
          lifestyle_risk_score:    { bsonType: 'double' },
          health_declaration_flag: { bsonType: 'bool'   },
          occupation_risk_band:    { bsonType: 'string' },
          smoker_flag:             { bsonType: 'bool'   },
          bmi_band:                { bsonType: 'string' }
        }
      },
      created_at: { bsonType: 'date' },
      updated_at: { bsonType: 'date' }
    }
  }}
});
db.risk_assessments.createIndex({ policyholder_hash_id: 1 });
db.risk_assessments.createIndex({ policy_id: 1 });
db.risk_assessments.createIndex({ created_at: -1 });
print('repo4_policy_assessments ready');

// ── repo5: network sessions ────────────────────────────────
db = db.getSiblingDB('repo5_network_sessions');
db.createCollection('network_sessions', {
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['subscriber_hash_id', 'session_id', 'session_start'],
    properties: {
      subscriber_hash_id: { bsonType: 'string' },
      session_id:         { bsonType: 'string' },
      device_id:          { bsonType: 'string' },
      session_type:       { bsonType: 'string',
                            enum: ['voice','data','sms','roaming','video_streaming'] },
      network_features: {
        bsonType: 'object',
        properties: {
          signal_quality_score:  { bsonType: 'double' },
          data_volume_mb:        { bsonType: 'double' },
          latency_ms:            { bsonType: 'int'    },
          packet_loss_rate:      { bsonType: 'double' },
          handover_count:        { bsonType: 'int'    },
          tower_id:              { bsonType: 'string' }
        }
      },
      session_start: { bsonType: 'date' },
      session_end:   { bsonType: 'date' }
    }
  }}
});
db.network_sessions.createIndex({ subscriber_hash_id: 1, session_start: -1 });
db.network_sessions.createIndex({ session_id: 1 }, { unique: true });
db.network_sessions.createIndex({ 'network_features.tower_id': 1 });
print('repo5_network_sessions ready');

print('MongoDB init complete');
