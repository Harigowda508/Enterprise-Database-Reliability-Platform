CREATE OR ALTER PROCEDURE app.usp_PostTransaction
    @AccountId INT,
    @Amount DECIMAL(18,2),
    @TransactionType VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO app.Transactions (AccountId, Amount, TransactionType)
        VALUES (@AccountId, @Amount, @TransactionType);

        DECLARE @TransactionId BIGINT = SCOPE_IDENTITY();

        INSERT INTO audit.TransactionsAudit
        (
            TransactionId,
            ActionType,
            ActionBy
        )
        VALUES
        (
            @TransactionId,
            'INSERT',
            SUSER_SNAME()
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
