-- Term Project: Trading Card Shop
-- Reese and Robert

-- Create and Use database
CREATE DATABASE tradingCardShopDB;
USE tradingCardShopDB;

-- Create Tables
CREATE TABLE Supplier (
  supplier_id   INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  contact_email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Card (
  card_id      INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(100) NOT NULL,
  rarity       ENUM('Common','Uncommon','Rare','Mythic') NOT NULL,
  price        DECIMAL(8,2) NOT NULL CHECK (price > 0),
  supplier_id  INT NOT NULL,
  FOREIGN KEY (supplier_id)
    REFERENCES Supplier(supplier_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
);

CREATE TABLE Inventory (
  card_id INT PRIMARY KEY,
  quantity INT NOT NULL CHECK (quantity >= 0),
  FOREIGN KEY (card_id)
    REFERENCES Card(card_id)
    ON DELETE CASCADE
);

CREATE TABLE Customer (
  customer_id  INT AUTO_INCREMENT PRIMARY KEY,
  first_name   VARCHAR(50) NOT NULL,
  last_name    VARCHAR(50) NOT NULL,
  email        VARCHAR(100) UNIQUE NOT NULL,
  phone        VARCHAR(20)
);

CREATE TABLE `Order` (
  order_id     INT AUTO_INCREMENT PRIMARY KEY,
  customer_id  INT NOT NULL,
  order_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status       ENUM('Pending','Shipped','Cancelled') NOT NULL DEFAULT 'Pending',
  FOREIGN KEY (customer_id)
    REFERENCES Customer(customer_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  INDEX idx_order_date (order_date)
);

CREATE TABLE OrderItem (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id      INT NOT NULL,
  card_id       INT NOT NULL,
  quantity      INT NOT NULL CHECK (quantity > 0),
  unit_price    DECIMAL(8,2) NOT NULL,
  FOREIGN KEY (order_id)
    REFERENCES `Order`(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (card_id)
    REFERENCES Card(card_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
);


-- Trigger: When adding to OrderItem, we remove a quantity from inventory unless it would go into the negative
DELIMITER $$
CREATE TRIGGER trg_after_orderitem_insert
AFTER INSERT ON OrderItem
FOR EACH ROW
BEGIN
  UPDATE Inventory
    SET quantity = quantity - NEW.quantity
  WHERE card_id = NEW.card_id;
  IF (SELECT quantity FROM Inventory WHERE card_id = NEW.card_id) < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'This card has no more in stock!';
  END IF;
END$$
DELIMITER ;

-- Sample Data
INSERT INTO Supplier (name, contact_email)
VALUES
  ('Pats', 'pats@cards.com'),
  ('CardCastle', 'cardcastle@yahoo.com');

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

INSERT INTO Inventory (card_id, quantity)
VALUES
  (1, 5),
  (2, 25),
  (3, 100),
  (4, 50),
  (5, 50),
  (6, 50),
  (7, 50),
  (8, 50),
  (9, 1);

INSERT INTO Customer (first_name, last_name, email, phone)
VALUES
  ('Reese', 'Herron', 'reese@example.com', '1112223333'),
  ('Seto',   'Kaiba', 'blueeyes@yugioh.com','9998887777'),
  ('Billy', 'TheKid', 'billy@bobby.com', '1234567891');

INSERT INTO `Order` (customer_id)
VALUES
  (1), (2), (3);

INSERT INTO OrderItem (order_id, card_id, quantity, unit_price)
VALUES
  (1, 1, 1, 100.00), -- Reese buying 1 Exodia
  (1, 3, 2, 5.00),   -- Reese also buying 2 Sol Ring
  (2, 2, 1, 25.00);  -- Kaiba buys a Black Lotus
  
  -- Section: Complex Queries for Project Requirements
-- Query 1: Join Query
-- Find all cards in stock (quantity > 0) along with their supplier names.
SELECT c.card_id, c.name, c.rarity, c.price, s.name AS supplier_name, i.quantity
FROM Card c
JOIN Supplier s ON c.supplier_id = s.supplier_id
JOIN Inventory i ON c.card_id = i.card_id
WHERE i.quantity > 0;

-- Query 2: Subquery
-- Find customers who have spent more than the average total order value.
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

-- Query 3: Transaction
-- Update the status of an order to 'Shipped' and decrease inventory for all items in that order, within a transaction.
START TRANSACTION;
UPDATE `Order`
SET status = 'Shipped'
WHERE order_id = 1;
UPDATE Inventory i
JOIN OrderItem oi ON i.card_id = oi.card_id
SET i.quantity = i.quantity - oi.quantity
WHERE oi.order_id = 1;
COMMIT;

-- Query 4: Window Function
-- Rank cards by price within each rarity category.
SELECT card_id, name, rarity, price,
       RANK() OVER (PARTITION BY rarity ORDER BY price DESC) AS price_rank
FROM Card;

-- Query 5: Join Query with Update
-- Update the price of all cards supplied by a specific supplier (e.g., supplier_id = 1) by increasing it by 10%.
UPDATE Card c
JOIN Supplier s ON c.supplier_id = s.supplier_id
SET c.price = c.price * 1.10
WHERE s.supplier_id = 1;

-- Query 6: Join Query with Delete
-- Delete all orders that are still 'Pending' and were placed before a certain date (e.g., 2024-01-01).
DELETE o
FROM `Order` o
JOIN OrderItem oi ON o.order_id = oi.order_id
WHERE o.status = 'Pending' AND o.order_date < '2024-01-01';
