
IF OBJECT_ID('app.Users','U') IS NULL
BEGIN
    PRINT 'Creating Users table';
    CREATE TABLE app.Users
(
    UserId        INT IDENTITY PRIMARY KEY,
    UserName      VARCHAR(100) NOT NULL,
    Email         VARCHAR(150) NOT NULL UNIQUE,
    IsActive      BIT NOT NULL DEFAULT 1,
    CreatedDate  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
END
ELSE
    PRINT 'Users table already exists';