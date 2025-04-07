USE RestaurantDB;
GO

-- =======================================
-- STORED PROCEDURES
-- =======================================

-- 1. Insert Order, Details, and Payment
CREATE OR ALTER PROCEDURE sp_InsertOrderWithDetailsAndPayment
    @CustomerID INT,
    @RestaurantID INT,
    @ReservationID INT = NULL,
    @DishID INT,
    @Quantity INT,
    @PaymentType NVARCHAR(20),
    @CardNumber NVARCHAR(16) = NULL,
    @ExpirationDate DATE = NULL,
    @CVV CHAR(4) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @OrderID INT,
        @PaymentID INT,
        @Price DECIMAL(10,2),
        @Subtotal DECIMAL(10,2),
        @Message NVARCHAR(255);

    -- Get price of the dish
    SELECT @Price = Price FROM DISH WHERE DishID = @DishID;

    IF @Price IS NULL
    BEGIN
        SET @Message = 'Invalid DishID';
        SELECT NULL AS OrderID, NULL AS PaymentID, @Message AS Message;
        RETURN;
    END

    SET @Subtotal = @Price * @Quantity;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert into ORDERS
        INSERT INTO ORDERS (CustomerID, RestaurantID, ReservationID)
        VALUES (@CustomerID, @RestaurantID, @ReservationID);

        SET @OrderID = SCOPE_IDENTITY();

        -- Insert into ORDER_DETAILS
        INSERT INTO ORDER_DETAILS (OrderID, DishID, Quantity, Subtotal)
        VALUES (@OrderID, @DishID, @Quantity, @Subtotal);

        -- Insert into PAYMENT
        INSERT INTO PAYMENT (OrderID, PaymentType, Amount)
        VALUES (@OrderID, @PaymentType, @Subtotal);

        SET @PaymentID = SCOPE_IDENTITY();

        -- If payment is card-based, insert into CARD_PAYMENT
        IF @PaymentType IN ('Credit Card', 'Debit Card')
        BEGIN
            IF @CardNumber IS NULL OR @ExpirationDate IS NULL OR @CVV IS NULL
            BEGIN
                ROLLBACK;
                SET @Message = 'Card details required for card payments';
                SELECT NULL AS OrderID, NULL AS PaymentID, @Message AS Message;
                RETURN;
            END

            INSERT INTO CARD_PAYMENT (PaymentID, CardNumber, ExpirationDate, CVV)
            VALUES (@PaymentID, @CardNumber, @ExpirationDate, @CVV);
        END

        COMMIT;
        SET @Message = 'Order placed successfully';
        SELECT @OrderID AS OrderID, @PaymentID AS PaymentID, @Message AS Message;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        SET @Message = 'An error occurred: ' + ERROR_MESSAGE();
        SELECT NULL AS OrderID, NULL AS PaymentID, @Message AS Message;
    END CATCH
END;
GO

-- 2. Get Reservations by Status
CREATE OR ALTER PROCEDURE sp_GetReservationListByStatus
    @Status NVARCHAR(20),
    @Date DATE = NULL,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT 
            R.ReservationID,
            C.FullName AS CustomerName,
            C.Contact AS CustomerContact,
            R.ReservationDate,
            R.TimeSlot,
            R.PartySize,
            R.Status
        FROM RESERVATION R
        INNER JOIN CUSTOMER C ON R.CustomerID = C.CustomerID
        WHERE R.Status = @Status
          AND (@Date IS NULL OR R.ReservationDate = @Date)
        ORDER BY R.ReservationDate, R.TimeSlot;

        IF @@ROWCOUNT = 0
            SET @Message = 'No reservations found for the given status/date.';
        ELSE
            SET @Message = 'Reservation list fetched successfully.';

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        SET @Message = 'Error fetching reservation list: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- 3. Get Top Dishes Sold
CREATE OR ALTER PROCEDURE sp_GetTopDishesSold
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @TopN INT = 10,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Core query
        SELECT TOP (@TopN)
            D.DishID,
            D.Name AS DishName,
            SUM(OD.Quantity) AS TotalQuantitySold,
            SUM(OD.Subtotal) AS TotalRevenue
        FROM ORDER_DETAILS OD
        INNER JOIN DISH D ON OD.DishID = D.DishID
        INNER JOIN ORDERS O ON OD.OrderID = O.OrderID
        WHERE 
            (@StartDate IS NULL OR CAST(O.OrderDate AS DATE) >= @StartDate)
            AND (@EndDate IS NULL OR CAST(O.OrderDate AS DATE) <= @EndDate)
        GROUP BY D.DishID, D.Name
        ORDER BY TotalQuantitySold DESC;

        -- Check if any rows were returned
        IF @@ROWCOUNT = 0
            SET @Message = 'No dishes sold in the given period.';
        ELSE
            SET @Message = 'Top dishes fetched successfully.';

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        SET @Message = 'Error fetching top dishes: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- =======================================
-- VIEWS
-- =======================================

-- 1. Low Stock Inventory
CREATE OR ALTER VIEW vw_LowStockInventory AS
SELECT
    I.InventoryID,
    R.Name AS RestaurantName,
    I.IngredientName,
    I.StockLevel,
    I.ReorderThreshold,
    I.LastRestockedDate,
    S.Name AS SupplierName,
    S.ContactPerson,
    S.ContactNumber
FROM INVENTORY I
JOIN RESTAURANT R ON I.RestaurantID = R.RestaurantID
JOIN SUPPLIER S ON I.SupplierID = S.SupplierID
WHERE I.StockLevel < I.ReorderThreshold;
GO

-- 2. Customer Feedback with Dish Details
CREATE OR ALTER VIEW vw_CustomerFeedbackWithDishDetails AS
SELECT
    F.FeedbackID,
    C.FullName AS CustomerName,
    C.Email,
    F.FeedbackDate,
    F.FeedbackType,
    F.Rating,
    F.Comments,
    O.OrderID,
    D.DishID,
    D.Name AS DishName,
    OD.Quantity,
    OD.Subtotal
FROM FEEDBACK F
JOIN CUSTOMER C ON F.CustomerID = C.CustomerID
JOIN ORDERS O ON F.OrderID = O.OrderID
JOIN ORDER_DETAILS OD ON O.OrderID = OD.OrderID
JOIN DISH D ON OD.DishID = D.DishID;
GO

-- 3. Staff Work Summary
CREATE OR ALTER VIEW vw_StaffWorkSummary AS
SELECT
    S.StaffID,
    ST.FullName,
    ST.Role,
    R.Name AS RestaurantName,
    COUNT(*) AS TotalShifts,
    SUM(DATEDIFF(MINUTE, S.StartTime, S.EndTime) / 60.0) AS TotalHoursWorked
FROM SHIFTS S
JOIN STAFF ST ON S.StaffID = ST.StaffID
JOIN RESTAURANT R ON ST.RestaurantID = R.RestaurantID
GROUP BY S.StaffID, ST.FullName, ST.Role, R.Name;
GO

-- =======================================
-- USER-DEFINED FUNCTIONS
-- =======================================

-- 1. Get Customer Satisfaction Score
CREATE OR ALTER FUNCTION fn_GetCustomerSatisfactionScore
(
    @CustomerID INT
)
RETURNS DECIMAL(3,1)
AS
BEGIN
    DECLARE @AvgRating DECIMAL(3,1);

    SELECT @AvgRating = ROUND(AVG(CAST(Rating AS DECIMAL(3,1))), 1)
    FROM FEEDBACK
    WHERE CustomerID = @CustomerID;

    RETURN ISNULL(@AvgRating, 0);
END;
GO

-- 2. List Supplier Deliverables
CREATE OR ALTER FUNCTION fn_ListSupplierDeliverables
(
    @SupplierID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        I.InventoryID,
        R.Name AS RestaurantName,
        I.IngredientName,
        I.StockLevel,
        I.ReorderThreshold,
        I.LastRestockedDate
    FROM INVENTORY I
    JOIN RESTAURANT R ON I.RestaurantID = R.RestaurantID
    WHERE I.SupplierID = @SupplierID
);
GO

-- 3. Get Average Dish Rating
CREATE OR ALTER FUNCTION fn_GetAverageDishRating
(
    @DishID INT
)
RETURNS DECIMAL(3,1)
AS
BEGIN
    DECLARE @AvgRating DECIMAL(3,1);

    SELECT @AvgRating = ROUND(AVG(CAST(F.Rating AS DECIMAL(3,1))), 1)
    FROM FEEDBACK F
    JOIN ORDERS O ON F.OrderID = O.OrderID
    JOIN ORDER_DETAILS OD ON O.OrderID = OD.OrderID
    WHERE OD.DishID = @DishID;

    RETURN ISNULL(@AvgRating, 0);
END;
GO

-- =======================================
-- DML TRIGGER
-- =======================================

-- Prevent duplicate reservations for same customer/email/contact at same time
CREATE OR ALTER TRIGGER trg_PreventDuplicateReservation
ON RESERVATION
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN CUSTOMER c1 ON i.CustomerID = c1.CustomerID
        JOIN RESERVATION r ON
             r.RestaurantID = i.RestaurantID
         AND r.ReservationDate = i.ReservationDate
         AND r.TimeSlot = i.TimeSlot
         AND r.Status IN ('Confirmed', 'Pending')
        JOIN CUSTOMER c2 ON r.CustomerID = c2.CustomerID
        WHERE
            c1.Email = c2.Email
            OR c1.Contact = c2.Contact
            OR c1.CustomerID = c2.CustomerID
    )
    BEGIN
        RAISERROR('This customer already has a reservation for that time.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;