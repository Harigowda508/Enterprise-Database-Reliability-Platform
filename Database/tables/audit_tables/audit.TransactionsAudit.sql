CREATE TABLE audit.TransactionsAudit
(
    AuditId        BIGINT IDENTITY PRIMARY KEY,
    TransactionId BIGINT,
    ActionType    VARCHAR(20),
    ActionBy      SYSNAME,
    ActionDate    DATETIME2 DEFAULT SYSUTCDATETIME()
);
