IF OBJECT_ID('audit.TransactionsAudit','U') IS NULL
BEGIN
    PRINT 'Creating TransactionsAudit table';
CREATE TABLE audit.TransactionsAudit
(
    AuditId        BIGINT IDENTITY PRIMARY KEY,
    TransactionId BIGINT,
    ActionType    VARCHAR(20),
    ActionBy      SYSNAME,
    ActionDate    DATETIME2 DEFAULT SYSUTCDATETIME()
);
END
ELSE
    PRINT 'TransactionsAudit table already exists';