-- USERS
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('app.Users')
      AND type = 1
)
BEGIN
    CREATE CLUSTERED INDEX CX_Users_UserId
    ON app.Users (UserId);
END;
GO

-- Accounts by User
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('app.Accounts')
      AND name = 'IX_Accounts_UserId'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Accounts_UserId
    ON app.Accounts (UserId)
    INCLUDE (AccountType, Balance);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('app.Transactions')
      AND name = 'IX_Transactions_Report'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_Report
    ON app.Transactions (CreatedDate)
    INCLUDE (Amount, TransactionType, AccountId);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('app.Transactions')
      AND name = 'IX_Transactions_Active'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Transactions_Active
    ON app.Transactions (AccountId)
    WHERE TransactionType = 'ONLINE';
END;
GO



