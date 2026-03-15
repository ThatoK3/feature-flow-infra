-- Create dedicated replication role used by the standby and Debezium
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = current_setting('POSTGRES_REPLICATION_USER', true)) THEN
    EXECUTE format(
      'CREATE ROLE %I WITH REPLICATION LOGIN PASSWORD %L',
      current_setting('POSTGRES_REPLICATION_USER', true),
      current_setting('POSTGRES_REPLICATION_PASSWORD', true)
    );
  END IF;
END$$;
