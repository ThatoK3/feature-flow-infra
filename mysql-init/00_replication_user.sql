-- ============================================================
-- FeatureFlow — MySQL Replication User
-- Must run on primary before replica connects.
-- ============================================================

CREATE USER IF NOT EXISTS 'replicator'@'%'
    IDENTIFIED WITH mysql_native_password BY 'change_me_repl';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;

SELECT 'MySQL replication user created' AS status;
