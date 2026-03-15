-- Enable CDC on the healthcare database
USE healthcare;
GO
EXEC sys.sp_cdc_enable_db;
GO
-- Enable CDC on specific tables (example)
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name = 'hospital_administration',
    @role_name = NULL;
GO
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name = 'healthcare_providers',
    @role_name = NULL;
GO
