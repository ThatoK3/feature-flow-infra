-- ============================================================
-- FeatureFlow — MySQL Replica Initialisation
-- Connects to primary and starts replication.
-- Runs after mysql-primary is healthy.
-- ============================================================

-- Wait for primary to be reachable and GTID-ready
-- (The container entrypoint already handles startup ordering)

STOP REPLICA;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST             = 'mysql-primary',
    SOURCE_PORT             = 3306,
    SOURCE_USER             = 'replicator',
    SOURCE_PASSWORD         = 'change_me_repl',
    SOURCE_AUTO_POSITION    = 1,
    SOURCE_SSL              = 0;

START REPLICA;

-- Verify
SHOW REPLICA STATUS\G;

SELECT 'MySQL replica init complete' AS status;
