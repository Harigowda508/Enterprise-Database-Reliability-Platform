/* ===============================
   PRIMARY KEY
   =============================== */
IF NOT EXISTS (
    SELECT 1 
    FROM sys.key_constraints 
    WHERE name = 'PK__Users__1788CC4CB0E83982'
      AND parent_object_id = OBJECT_ID('app.Users')
)
BEGIN
    ALTER TABLE app.Users
    ADD CONSTRAINT PK__Users__1788CC4CB0E83982 
    PRIMARY KEY (UserId);
END;
GO

/* ===============================
   UNIQUE CONSTRAINT
   =============================== */
IF NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE name in ('UQ_Users_UserName','UQ__Users__A9D10534C6F266BA')
      AND parent_object_id = OBJECT_ID('app.Users')
)
BEGIN
    ALTER TABLE app.Users
    ADD CONSTRAINT UQ_Users_UserName 
    UNIQUE (UserName);
END;
GO

/* ===============================
   FOREIGN KEY
   =============================== */
IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name in ('PK__Accounts__349DA5A6C8D49CD1','FK_Accounts_Users')
)
BEGIN
    ALTER TABLE app.Accounts
    ADD CONSTRAINT PK__Accounts__349DA5A6C8D49CD1
    FOREIGN KEY (UserId)
    REFERENCES app.Users(UserId);
END;
GO

/* ===============================
   CHECK CONSTRAINT
   =============================== */
IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Transactions_Amount'
)
BEGIN
    ALTER TABLE app.Transactions
    ADD CONSTRAINT CK_Transactions_Amount
    CHECK (Amount > 0);
END;
GO

/* ===============================
   DEFAULT CONSTRAINT
   =============================== */
IF NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints dc
    JOIN sys.columns c 
        ON dc.parent_object_id = c.object_id
       AND dc.parent_column_id = c.column_id
    WHERE dc.name in('DF__Users__CreatedDa__68487DD7','DF__Users__IsActive__6754599E')
      AND OBJECT_NAME(dc.parent_object_id) = 'Users'
)
BEGIN
    ALTER TABLE app.Users
    ADD CONSTRAINT DF_Users_CreatedDate
    DEFAULT SYSDATETIME() FOR CreatedDate;
END;
GO
