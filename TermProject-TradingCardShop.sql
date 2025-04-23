-- Term Project: Trading Card Shop
-- Reese and Robert

-- Create the project’s database
CREATE DATABASE tradingCardShopDB;

-- Select the newly created database to use
USE tradingCardShopDB;

-- Create the table for card suppliers
CREATE TABLE Supplier (
  supplier_id   INT AUTO_INCREMENT PRIMARY KEY,        -- Unique ID for each supplier
  name          VARCHAR(100) NOT NULL,                 -- Name of the supplier (required)
  contact_email VARCHAR(100) UNIQUE NOT NULL           -- Unique contact email (required)
);

-- Create table to store card information
CREATE TABLE Card (
  card_id      INT AUTO_INCREMENT PRIMARY KEY,         -- Unique ID for each card
  name         VARCHAR(100) NOT NULL,                  -- Card name (required)
  rarity       ENUM('Common','Uncommon','Rare','Mythic') NOT NULL,  -- Rarity category
  price        DECIMAL(8,2) NOT NULL CHECK (price > 0),-- Price, must be a positive number
  supplier_id  INT NOT NULL,                           -- Foreign key to the supplier
  FOREIGN KEY (supplier_id)
    REFERENCES Supplier(supplier_id)                   -- Reference to supplier table
    ON DELETE RESTRICT                                 -- Prevent deletion if linked to card
    ON UPDATE CASCADE                                  -- Update card if supplier_id changes
);

-- Create inventory table to track card stock levels
CREATE TABLE Inventory (
  card_id INT PRIMARY KEY,                             -- Primary key, also foreign key to Card
  quantity INT NOT NULL CHECK (quantity >= 0),         -- Quantity in stock, cannot be negative
  FOREIGN KEY (card_id)
    REFERENCES Card(card_id)                           -- References Card table
    ON DELETE CASCADE                                  -- If card is deleted, delete inventory too
);

-- Create table to store customer data
CREATE TABLE Customer (
  customer_id  INT AUTO_INCREMENT PRIMARY KEY,         -- Unique customer ID
  first_name   VARCHAR(50) NOT NULL,                   -- Customer's first name (required)
  last_name    VARCHAR(50) NOT NULL,                   -- Customer's last name (required)
  email        VARCHAR(100) UNIQUE NOT NULL,           -- Unique email address (required)
  phone        VARCHAR(20)                             -- Optional phone number
);

-- Create table for customer orders
CREATE TABLE `Order` (
  order_id     INT AUTO_INCREMENT PRIMARY KEY,         -- Unique order ID
  customer_id  INT NOT NULL,                           -- References a customer
  order_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Defaults to current time
  status       ENUM('Pending','Shipped','Cancelled') NOT NULL DEFAULT 'Pending', -- Order status
  FOREIGN KEY (customer_id)
    REFERENCES Customer(customer_id)                   -- Reference to Customer table
    ON DELETE RESTRICT                                 -- Can't delete customer with orders
    ON UPDATE CASCADE,                                 -- Auto-update customer_id if it changes
  INDEX idx_order_date (order_date)                    -- Index to optimize date lookups
);

-- Create table for individual items in an order
CREATE TABLE OrderItem (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,        -- Unique ID for each order line item
  order_id      INT NOT NULL,                          -- References the order
  card_id       INT NOT NULL,                          -- References the card being purchased
  quantity      INT NOT NULL CHECK (quantity > 0),     -- Quantity must be more than zero
  unit_price    DECIMAL(8,2) NOT NULL,                 -- Price per unit at time of order
  FOREIGN KEY (order_id)
    REFERENCES `Order`(order_id)                       -- Link to Order
    ON DELETE CASCADE                                  -- Delete order items if order is deleted
    ON UPDATE CASCADE,
  FOREIGN KEY (card_id)
    REFERENCES Card(card_id)                           -- Link to Card
    ON DELETE RESTRICT                                 -- Cannot delete card in an order
    ON UPDATE CASCADE
);

-- Define a trigger that adjusts inventory when an order item is added
DELIMITER $$                                            -- Change the delimiter to define trigger body
CREATE TRIGGER trg_after_orderitem_insert
AFTER INSERT ON OrderItem                               -- Trigger fires after an OrderItem is inserted
FOR EACH ROW                                            -- Executes for each inserted row
BEGIN
  -- Subtract ordered quantity from inventory
  UPDATE Inventory
    SET quantity = quantity - NEW.quantity
  WHERE card_id = NEW.card_id;

  -- If resulting quantity is negative, raise an error
  IF (SELECT quantity FROM Inventory WHERE card_id = NEW.card_id) < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'This card has no more in stock!'; -- Custom error message
  END IF;
END$$
DELIMITER ;                                             -- Reset the delimiter to default

-- Insert sample suppliers
INSERT INTO Supplier (name, contact_email)
VALUES
  ('Pats', 'pats@cards.com'),                           -- Supplier 1
  ('CardCastle', 'cardcastle@yahoo.com');               -- Supplier 2

-- Insert sample cards with different rarities and prices
INSERT INTO Card (name, rarity, price, supplier_id)
VALUES
  ('Exodia', 'Mythic', 100.00, 1),
  ('Black Lotus', 'Rare', 25.00, 1),
  ('Sol Ring', 'Uncommon', 5.00, 2),
  ('Swamp', 'Uncommon', 0.10, 1),
  ('Mountain', 'Uncommon', 0.10, 1),
  ('Island', 'Uncommon', 0.10, 1),
  ('Forest', 'Uncommon', 0.10, 1),
  ('Plains', 'Uncommon', 0.10, 1),
  ('Pikachu', 'Mythic', 1000.00, 2);

-- Insert initial inventory quantities for each card
INSERT INTO Inventory (card_id, quantity)
VALUES
  (1, 5),   -- Exodia: 5 in stock
  (2, 25),  -- Black Lotus: 25 in stock
  (3, 100), -- Sol Ring: 100 in stock
  (4, 50),
  (5, 50),
  (6, 50),
  (7, 50),
  (8, 50),
  (9, 1);   -- Pikachu: only 1 in stock

-- Insert sample customer information
INSERT INTO Customer (first_name, last_name, email, phone)
VALUES
  ('Reese', 'Herron', 'reese@example.com', '1112223333'),
  ('Seto',   'Kaiba', 'blueeyes@yugioh.com','9998887777'),
  ('Billy', 'TheKid', 'billy@bobby.com', '1234567891');

-- Insert sample orders for each customer
INSERT INTO `Order` (customer_id)
VALUES
  (1),  -- Reese's order
  (2),  -- Kaiba's order
  (3);  -- Billy's order

-- Add order items (purchases) to the orders
INSERT INTO OrderItem (order_id, card_id, quantity, unit_price)
VALUES
  (1, 1, 1, 100.00), -- Reese buys 1 Exodia
  (1, 3, 2, 5.00),   -- Reese buys 2 Sol Rings
  (2, 2, 1, 25.00);  -- Kaiba buys 1 Black Lotus

-- ------------------------------
-- Complex Queries Section
-- ------------------------------

-- Query 1: Show all cards in stock with supplier info
SELECT c.card_id, c.name, c.rarity, c.price, s.name AS supplier_name, i.quantity
FROM Card c
JOIN Supplier s ON c.supplier_id = s.supplier_id
JOIN Inventory i ON c.card_id = i.card_id
WHERE i.quantity > 0;

-- Query 2: Show customers who spent more than the average total order value
SELECT o.customer_id, c.first_name, c.last_name, SUM(oi.quantity * oi.unit_price) AS total_spent
FROM `Order` o
JOIN OrderItem oi ON o.order_id = oi.order_id
JOIN Customer c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.first_name, c.last_name
HAVING total_spent > (
    SELECT AVG(total_spent)
    FROM (
        SELECT SUM(oi.quantity * oi.unit_price) AS total_spent
        FROM `Order` o
        JOIN OrderItem oi ON o.order_id = oi.order_id
        GROUP BY o.customer_id
    ) AS subquery
);

-- Query 3: Use a transaction to update order status and inventory
START TRANSACTION;                                      -- Begin transaction

-- Set order status to "Shipped"
UPDATE `Order`
SET status = 'Shipped'
WHERE order_id = 1;

-- Reduce inventory for all items in the shipped order
UPDATE Inventory i
JOIN OrderItem oi ON i.card_id = oi.card_id
SET i.quantity = i.quantity - oi.quantity
WHERE oi.order_id = 1;

COMMIT;                                                 -- Save changes

-- Query 4: Use window function to rank cards by price within rarity groups
SELECT card_id, name, rarity, price,
       RANK() OVER (PARTITION BY rarity ORDER BY price DESC) AS price_rank
FROM Card;

-- Query 5: Increase prices of all cards from supplier 1 by 10%
UPDATE Card c
JOIN Supplier s ON c.supplier_id = s.supplier_id
SET c.price = c.price * 1.10
WHERE s.supplier_id = 1;

-- Query 6: Delete all 'Pending' orders placed before Jan 1, 2024
DELETE o
FROM `Order` o
JOIN OrderItem oi ON o.order_id = oi.order_id
WHERE o.status = 'Pending' AND o.order_date < '2024-01-01';
