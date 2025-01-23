# Restaurant Management System - Proposed Entities and Attributes

This document outlines the entities, attributes, purposes, and relationships for a restaurant management system.

---

## 1. **Restaurant**

- **Attributes**: RestaurantID (PK), Name, Location, ContactNumber, Manager, Capacity
- **Purpose**: Represents individual restaurants, managing their core details.
- **Relationships**:
  - 1:N with Menu, Staff, Inventory, Reservation, and Order.

---

## 2. **Menu**

- **Attributes**: MenuID (PK), RestaurantID (FK), Name, Description, ActiveStatus
- **Purpose**: Manages different menus in the restaurant (e.g., breakfast, lunch, dinner).
- **Relationships**:
  - 1:N with Dish.

---

## 3. **Dish**

- **Attributes**: DishID (PK), MenuID (FK), Name, Price, Ingredients, PreparationTime, IsVegetarian, IsAvailable
- **Purpose**: Tracks all individual dishes served in the restaurant.
- **Relationships**:
  - N:N with Order through OrderDetails.

---

## 4. **Customer**

- **Attributes**: CustomerID (PK), FullName, Email, ContactNumber, Address, LoyaltyPoints
- **Purpose**: Stores customer details and tracks loyalty.
- **Relationships**:
  - 1:N with Reservation and Order.

---

## 5. **Reservation**

- **Attributes**: ReservationID (PK), CustomerID (FK), RestaurantID (FK), ReservationDate, TimeSlot, NumberOfGuests, Status
- **Purpose**: Handles reservations, including date, time, and guest count.
- **Relationships**:
  - 1:1 or 1:N with Order (if reservations convert to orders).

---

## 6. **Order**

- **Attributes**: OrderID (PK), CustomerID (FK), RestaurantID (FK), ReservationID (FK, Optional), OrderDate, TotalAmount, PaymentMethod, Status
- **Purpose**: Tracks food orders made by customers.
- **Relationships**:
  - N:N with Dish through OrderDetails.

---

## 7. **OrderDetails** (Associative Entity)

- **Attributes**: OrderDetailID (PK), OrderID (FK), DishID (FK), Quantity, Subtotal
- **Purpose**: Resolves the N:N relationship between Order and Dish.

---

## 8. **Staff**

- **Attributes**: StaffID (PK), RestaurantID (FK), FullName, Role (e.g., Chef, Waiter, Manager), ContactNumber, Salary, HireDate
- **Purpose**: Tracks staff working at the restaurant, their roles, and salaries.
- **Relationships**:
  - 1:N with Shifts.

---

## 9. **Shifts** (Associative Entity)

- **Attributes**: ShiftID (PK), StaffID (FK), ShiftDate, StartTime, EndTime
- **Purpose**: Tracks staff working hours and scheduling.
- **Relationships**:
  - 1:N with Staff.

---

## 10. **Supplier**

- **Attributes**: SupplierID (PK), Name, ContactPerson, ContactNumber, SuppliesCategory, Address
- **Purpose**: Manages suppliers for the restaurant's inventory.
- **Relationships**:
  - 1:N with Inventory.

---

## 11. **Inventory**

- **Attributes**: InventoryID (PK), RestaurantID (FK), IngredientName, StockLevel, LastRestockedDate, SupplierID (FK)
- **Purpose**: Tracks the ingredients and stock levels for dishes.
- **Relationships**:
  - 1:N with Restaurant.

---

## 12. **Feedback**

- **Attributes**: FeedbackID (PK), CustomerID (FK), DishID (FK), Rating, Comments, FeedbackDate
- **Purpose**: Records customer feedback on dishes for quality improvement.
- **Relationships**:
  - 1:N with Dish and Customer.

---

This README provides a comprehensive overview of the entities and their relationships in the restaurant management system. For further details or modifications, please refer to the project documentation.
