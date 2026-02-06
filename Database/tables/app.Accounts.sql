CREATE TABLE app.Accounts
(
    AccountId     INT IDENTITY PRIMARY KEY,
    UserId        INT NOT NULL,
    AccountType   VARCHAR(50) NOT NULL,
    Balance       DECIMAL(18,2) NOT NULL DEFAULT 0,
    CreatedDate  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Accounts_Users 
        FOREIGN KEY (UserId) REFERENCES app.Users(UserId)
);
