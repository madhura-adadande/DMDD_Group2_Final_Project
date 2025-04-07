import streamlit as st
import matplotlib.pyplot as plt
from database import run_query, execute_query

st.set_page_config(layout="wide")
st.title("🍽️ RestaurantDB Dashboard")

# Main Menu remains unchanged.
page = st.sidebar.selectbox("Menu", [
    "🏠 Home", "📦 Inventory", "🧑 Customers", "🧾 Orders",
    "🛎️ Reservations", "👩‍🍳 Staff"
])

# =========================
# 🏠 HOME PAGE
# =========================
if page == "🏠 Home":
    st.header("Welcome to RestaurantDB")

    orders_today = run_query("SELECT COUNT(*) FROM ORDERS WHERE CAST(OrderDate AS DATE) = CAST(GETDATE() AS DATE)").iloc[0, 0]
    total_customers = run_query("SELECT COUNT(*) FROM CUSTOMER").iloc[0, 0]
    revenue_today = run_query("SELECT ISNULL(SUM(Amount),0) FROM PAYMENT WHERE CAST(TransactionDate AS DATE)=CAST(GETDATE() AS DATE)").iloc[0, 0]

    col1, col2, col3 = st.columns(3)
    col1.metric("Orders Today", orders_today)
    col2.metric("Customers", total_customers)
    col3.metric("Today's Revenue ($)", f"{revenue_today:.2f}")

    st.markdown("---")
    st.subheader("📊 Analytics")

    # Feedback Rating Distribution (existing) with smaller figure size.
    feedback_df = run_query("""
        SELECT Rating, COUNT(*) AS Count
        FROM FEEDBACK
        GROUP BY Rating
        ORDER BY Rating
    """)
    fig1, ax1 = plt.subplots(figsize=(5,3))
    ax1.bar(feedback_df["Rating"], feedback_df["Count"], color='skyblue')
    ax1.set_title("Feedback Rating Distribution")
    ax1.set_xlabel("Rating")
    ax1.set_ylabel("Count")
    st.pyplot(fig1)

    # Dish Popularity (existing) with smaller figure size.
    dish_df = run_query("""
        SELECT D.Name AS DishName, SUM(OD.Quantity) AS TotalSold
        FROM ORDER_DETAILS OD
        JOIN DISH D ON OD.DishID = D.DishID
        GROUP BY D.Name
        ORDER BY TotalSold DESC
    """)
    fig2, ax2 = plt.subplots(figsize=(5,3))
    ax2.bar(dish_df["DishName"], dish_df["TotalSold"], color='orange')
    ax2.set_title("Top Dishes Sold (Join Query)")
    ax2.set_ylabel("Quantity Sold")
    ax2.set_xticklabels(dish_df["DishName"], rotation=45, ha='right')
    st.pyplot(fig2)

    # Stored Procedure: Top Dishes Sold (new addition) with smaller figure size.
    st.subheader("📊 Top Dishes Sold (Stored Procedure)")
    top_dishes = run_query("EXEC sp_GetTopDishesSold @TopN = 5")
    if not top_dishes.empty:
        fig3, ax3 = plt.subplots(figsize=(5,3))
        ax3.bar(top_dishes["DishName"], top_dishes["TotalQuantitySold"], color='green')
        ax3.set_title("Top 5 Dishes Sold (SP)")
        ax3.set_ylabel("Total Quantity Sold")
        ax3.set_xticklabels(top_dishes["DishName"], rotation=45, ha='right')
        st.pyplot(fig3)
    else:
        st.info("No data returned from sp_GetTopDishesSold.")

    # Average Order Value (just a metric)
    aov_value = run_query("""
        SELECT AVG(Amount) AS AvgOrderValue
        FROM PAYMENT
    """).iloc[0, 0]
    col4, _, _ = st.columns(3)
    col4.metric("💵 Avg Order Value", f"${aov_value:.2f}")

    # -------------------------------
    # Additional Metrics using UDFs (modified)
    st.markdown("---")
    st.subheader("Additional Metrics")
    # Overall Customer Satisfaction (average of all ratings)
    overall_rating = run_query("""
        SELECT ROUND(AVG(CAST(Rating AS DECIMAL(3,1))),1) AS OverallRating
        FROM FEEDBACK
    """).iloc[0, 0]
    # Average Dish Rating using fn_GetAverageDishRating; user still inputs a Dish ID.
    dish_id = st.number_input("Enter Dish ID for Average Dish Rating", min_value=1, value=1, key="dish_id")
    dish_rating = run_query("SELECT dbo.fn_GetAverageDishRating(?) AS AvgDishRating", [dish_id]).iloc[0, 0]

    colA, colB = st.columns(2)
    colA.metric("Overall Customer Satisfaction", f"{overall_rating}")
    colB.metric("Average Dish Rating", f"{dish_rating}")

# =========================
# 📦 INVENTORY
# =========================
elif page == "📦 Inventory":
    st.header("📦 Inventory Management")
    action = st.selectbox("Choose Action", [
        "View Inventory", "Low Stock View", "Add Item", "Update Item", "Delete Item"
    ])

    if action == "View Inventory":
        df_inv = run_query("SELECT * FROM INVENTORY")
        st.dataframe(df_inv)

    elif action == "Low Stock View":
        st.subheader("⚠️ Low Stock Ingredients")
        low_stock = run_query("SELECT * FROM vw_LowStockInventory")
        st.dataframe(low_stock)

    elif action == "Add Item":
        with st.form("add_inv"):
            restaurant_id = st.number_input("RestaurantID", value=1)
            supplier_id = st.number_input("SupplierID", value=1)
            ingredient = st.text_input("Ingredient")
            stock = st.number_input("Stock Level", min_value=0, step=1)
            restocked_date = st.date_input("Last Restocked Date")
            reorder_threshold = st.number_input("Reorder Threshold", min_value=1, step=1)
            submitted = st.form_submit_button("Add Inventory Item")
            if submitted:
                execute_query("""
                    INSERT INTO INVENTORY (RestaurantID, SupplierID, IngredientName, StockLevel, LastRestockedDate, ReorderThreshold)
                    VALUES (?, ?, ?, ?, ?, ?)""",
                    (restaurant_id, supplier_id, ingredient, stock, restocked_date, reorder_threshold))
                st.success("Item added successfully.")

    elif action == "Update Item":
        inventory_id = st.number_input("Inventory ID to Update", min_value=1)
        new_stock = st.number_input("New Stock Level", min_value=0, step=1)
        if st.button("Update Stock"):
            execute_query("UPDATE INVENTORY SET StockLevel=? WHERE InventoryID=?", (new_stock, inventory_id))
            st.success("Inventory updated.")

    elif action == "Delete Item":
        del_inv_id = st.number_input("Inventory ID to Delete", min_value=1)
        if st.button("Delete Inventory Item"):
            execute_query("DELETE FROM INVENTORY WHERE InventoryID=?", (del_inv_id,))
            st.success("Item deleted.")

# =========================
# 🧑 CUSTOMERS
# =========================
elif page == "🧑 Customers":
    st.header("🧑 Customer Management")
    action = st.selectbox("Action", ["View Customers", "Add Customer", "Update Customer", "Delete Customer"])

    if action == "View Customers":
        customers = run_query("SELECT * FROM CUSTOMER")
        st.dataframe(customers)

    elif action == "Add Customer":
        with st.form("add_cust"):
            name = st.text_input("Full Name")
            email = st.text_input("Email")
            contact = st.text_input("Contact")
            address = st.text_area("Address")
            submitted = st.form_submit_button("Add Customer")
            if submitted:
                execute_query("INSERT INTO CUSTOMER (FullName, Email, Contact, Address) VALUES (?, ?, ?, ?)",
                              (name, email, contact, address))
                st.success("Customer added.")

    elif action == "Update Customer":
        cust_id = st.number_input("Customer ID", min_value=1)
        new_contact = st.text_input("New Contact Number")
        if st.button("Update Contact"):
            execute_query("UPDATE CUSTOMER SET Contact=? WHERE CustomerID=?", (new_contact, cust_id))
            st.success("Customer updated.")

    elif action == "Delete Customer":
        del_cust_id = st.number_input("Customer ID to Delete", min_value=1)
        if st.button("Delete Customer"):
            execute_query("DELETE FROM CUSTOMER WHERE CustomerID=?", (del_cust_id,))
            st.success("Customer deleted.")

# =========================
# 🧾 ORDERS
# =========================
elif page == "🧾 Orders":
    st.header("🧾 Orders")

    st.subheader("All Orders with Dish Details")
    order_details = run_query("""
        SELECT O.OrderID, C.FullName AS Customer, D.Name AS Dish, OD.Quantity, OD.Subtotal,
               P.PaymentType, P.Amount, O.OrderDate
        FROM ORDERS O
        JOIN CUSTOMER C ON O.CustomerID = C.CustomerID
        JOIN ORDER_DETAILS OD ON O.OrderID = OD.OrderID
        JOIN DISH D ON OD.DishID = D.DishID
        JOIN PAYMENT P ON O.OrderID = P.OrderID
        ORDER BY O.OrderDate DESC
    """)
    st.dataframe(order_details)

    st.subheader("📋 Customer Feedback with Dish Details (View)")
    feedback_view = run_query("SELECT * FROM vw_CustomerFeedbackWithDishDetails")
    st.dataframe(feedback_view)

    st.subheader("Place New Order")
    with st.form("new_order"):
        customer_id = st.number_input("CustomerID", min_value=1)
        restaurant_id = st.number_input("RestaurantID", min_value=1)
        dish_id = st.number_input("DishID", min_value=1)
        quantity = st.number_input("Quantity", min_value=1)
        payment_type = st.selectbox("Payment Type", ["Cash", "Credit Card", "Debit Card"])
        card_number = st.text_input("Card Number (if card)")
        expiry = st.date_input("Expiration (if card)")
        cvv = st.text_input("CVV (if card)")
        submitted = st.form_submit_button("Submit Order")
        if submitted:
            query = "EXEC sp_InsertOrderWithDetailsAndPayment ?, ?, NULL, ?, ?, ?, ?, ?, ?"
            result = run_query(query, [customer_id, restaurant_id, dish_id, quantity, payment_type, card_number or None, expiry or None, cvv or None])
            st.write(result)

# =========================
# 🛎️ RESERVATIONS
# =========================
elif page == "🛎️ Reservations":
    st.header("🛎️ Reservation Management")
    res_action = st.selectbox("Select Action", ["View Reservations", "CRUD Operations"])
    if res_action == "View Reservations":
        status_filter = st.selectbox("Reservation Status", ["Pending", "Confirmed", "Canceled"])
        reservations = run_query("EXEC sp_GetReservationListByStatus ?", [status_filter])
        st.dataframe(reservations)
    else:
        crud_action = st.selectbox("CRUD Operation", ["Add Reservation", "Update Reservation", "Delete Reservation"])
        if crud_action == "Add Reservation":
            with st.form("add_res"):
                cid = st.number_input("CustomerID")
                rid = st.number_input("RestaurantID")
                date = st.date_input("Reservation Date")
                time = st.time_input("Time Slot")
                size = st.number_input("Party Size", min_value=1)
                status = st.selectbox("Status", ["Pending", "Confirmed", "Canceled"])
                if st.form_submit_button("Add Reservation"):
                    execute_query("""
                        INSERT INTO RESERVATION (CustomerID, RestaurantID, ReservationDate, TimeSlot, PartySize, Status)
                        VALUES (?, ?, ?, ?, ?, ?)""", (cid, rid, date, time, size, status))
                    st.success("Reservation added.")
        elif crud_action == "Update Reservation":
            res_id = st.number_input("Reservation ID")
            new_status = st.selectbox("New Status", ["Pending", "Confirmed", "Canceled"])
            if st.button("Update Reservation"):
                execute_query("UPDATE RESERVATION SET Status=? WHERE ReservationID=?", (new_status, res_id))
                st.success("Reservation updated.")
        elif crud_action == "Delete Reservation":
            res_id = st.number_input("Reservation ID to Delete")
            if st.button("Delete Reservation"):
                execute_query("DELETE FROM RESERVATION WHERE ReservationID=?", (res_id,))
                st.success("Reservation deleted.")

# =========================
# 👩‍🍳 STAFF
# =========================
elif page == "👩‍🍳 Staff":
    st.header("👩‍🍳 Staff Management")
    staff_option = st.selectbox("Select Option", ["Summary", "CRUD Operations"])
    if staff_option == "Summary":
        st.dataframe(run_query("SELECT * FROM vw_StaffWorkSummary"))
    else:
        crud_action = st.selectbox("CRUD Operation", ["Add Staff", "Update Staff", "Delete Staff"])
        if crud_action == "Add Staff":
            with st.form("add_staff"):
                # Use a drop-down for RestaurantID showing only the IDs.
                restaurants_df = run_query("SELECT RestaurantID, Name FROM RESTAURANT ORDER BY RestaurantID")
                if not restaurants_df.empty:
                    restaurant_id = st.selectbox(
                        "Restaurant ID",
                        options=restaurants_df["RestaurantID"].tolist()
                    )
                else:
                    restaurant_id = st.number_input("RestaurantID", value=1)
                name = st.text_input("Full Name")
                contact = st.text_input("Contact")
                role = st.selectbox("Role", ['Chef', 'Waiter', 'Manager', 'Bartender', 'Host', 'Cashier', 'Sous Chef'])
                if st.form_submit_button("Add Staff"):
                    execute_query("INSERT INTO STAFF (RestaurantID, FullName, ContactNumber, Role) VALUES (?, ?, ?, ?)",
                                  (restaurant_id, name, contact, role))
                    st.success("Staff added.")
        elif crud_action == "Update Staff":
            sid = st.number_input("Staff ID", min_value=1)
            new_role = st.selectbox("New Role", ['Chef', 'Waiter', 'Manager', 'Bartender', 'Host', 'Cashier', 'Sous Chef'])
            if st.button("Update Staff"):
                execute_query("UPDATE STAFF SET Role=? WHERE StaffID=?", (new_role, sid))
                st.success("Staff updated.")
        elif crud_action == "Delete Staff":
            sid = st.number_input("Staff ID to Delete", min_value=1)
            if st.button("Delete Staff"):
                execute_query("DELETE FROM STAFF WHERE StaffID=?", (sid,))
                st.success("Staff deleted.")
        # Always show the current staff table after CRUD operations.
        st.subheader("Current Staff List")
        st.dataframe(run_query("SELECT * FROM STAFF ORDER BY StaffID"))
