IF OBJECT_ID('app.Transactions','U') IS NULL
BEGIN
    PRINT 'Creating Transactions table';
CREATE TABLE app.Transactions
(
    TransactionId   BIGINT IDENTITY PRIMARY KEY,
    AccountId       INT NOT NULL,
    Amount          DECIMAL(18,2) NOT NULL,
    TransactionType VARCHAR(20) NOT NULL,
    CreatedDate     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Transactions_Accounts 
        FOREIGN KEY (AccountId) REFERENCES app.Accounts(AccountId)
);
END
ELSE
    PRINT 'Transactions table already exists';