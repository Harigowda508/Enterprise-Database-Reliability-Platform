CREATE OR ALTER PROCEDURE app.usp_CreateAccount
    @UserId INT,
    @AccountType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO app.Accounts (UserId, AccountType)
        VALUES (@UserId, @AccountType);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
