
-- Create a non-clustered index on the ORDERS table for the OrderDate column.
-- This index helps improve performance for queries filtering or sorting orders by date.
CREATE NONCLUSTERED INDEX idx_Orders_OrderDate
ON ORDERS (OrderDate);
GO

-- Create a non-clustered index on the ORDER_DETAILS table for the OrderID column.
-- This index speeds up join operations and lookups when retrieving order details for a given order.
CREATE NONCLUSTERED INDEX idx_OrderDetails_OrderID
ON ORDER_DETAILS (OrderID);
GO

-- Create a non-clustered composite index on the RESERVATION table for the ReservationDate and RestaurantID columns.
-- This index improves performance for queries that filter by reservation date and restaurant.
CREATE NONCLUSTERED INDEX idx_Reservation_Date_Restaurant
ON RESERVATION (ReservationDate, RestaurantID);
GO