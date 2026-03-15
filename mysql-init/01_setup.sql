USE healthcare;

CREATE TABLE IF NOT EXISTS bureau_consumer_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id VARCHAR(50),
    credit_score INT,
    bureau_data JSON,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS episodes_of_care (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id VARCHAR(50),
    episode_date DATE,
    outcome VARCHAR(100),
    details TEXT
);

-- Create Debezium user (replace 'debezium_pass' with your actual password from .env)
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'debezium_pass';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
