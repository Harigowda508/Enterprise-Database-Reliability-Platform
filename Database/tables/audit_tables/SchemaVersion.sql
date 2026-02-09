IF OBJECT_ID('monitoring.SchemaVersion','U') IS NULL
BEGIN
    PRINT 'Creating SchemaVersion table';
CREATE TABLE monitoring.SchemaVersion
(
    VersionId     INT IDENTITY PRIMARY KEY,
    VersionNumber VARCHAR(20) NOT NULL,
    AppliedOn     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    AppliedBy     SYSNAME NOT NULL DEFAULT SUSER_SNAME()
);
END
ELSE
    PRINT 'SchemaVersion table already exists';