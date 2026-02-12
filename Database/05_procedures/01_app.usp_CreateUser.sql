CREATE OR ALTER PROCEDURE app.usp_CreateUser
    @UserName VARCHAR(100),
    @Email    VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO app.Users (UserName, Email)
        VALUES (@UserName, @Email);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
