-- Debezium connector user (needs REPLICATION SLAVE + CLIENT + SELECT)
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'debezium_pass_change_me';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

-- Replication user for the replica to connect with
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY 'changeme_repl';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
