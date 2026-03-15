-- Run after DB creation; SQL Server Agent must be running
USE featureflow;
GO
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'featureflow' AND is_cdc_enabled = 1)
BEGIN
  EXEC sys.sp_cdc_enable_db;
END
GO
