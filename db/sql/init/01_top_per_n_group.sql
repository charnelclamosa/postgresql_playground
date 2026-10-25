-- Exercise 01: Top-N per group
CREATE TABLE products (
  product_id   INT PRIMARY KEY,
  product_name TEXT NOT NULL,
  category     TEXT NOT NULL
);

CREATE TABLE order_items (
  order_item_id INT PRIMARY KEY,
  order_id      INT NOT NULL,
  product_id    INT NOT NULL REFERENCES products(product_id),
  quantity      INT NOT NULL,
  unit_price    NUMERIC(10,2) NOT NULL
);

INSERT INTO products VALUES
 (1,  'Laptop Pro',    'Electronics'),
 (2,  'Phone X',       'Electronics'),
 (3,  'Headphones',    'Electronics'),
 (4,  'USB Cable',     'Electronics'),
 (5,  'Desk Chair',    'Furniture'),
 (6,  'Standing Desk', 'Furniture'),
 (7,  'Bookshelf',     'Furniture'),
 (8,  'Notebook',      'Stationery'),
 (9,  'Pen Set',       'Stationery'),
 (10, 'Stapler',       'Stationery');

INSERT INTO order_items VALUES
 (1,  101, 2, 3,   800.00),
 (2,  102, 2, 2,   800.00),
 (3,  103, 1, 1,  1200.00),
 (4,  104, 1, 1,  1200.00),
 (5,  105, 3, 10,  150.00),
 (6,  106, 3, 6,   150.00),
 (7,  107, 4, 60,    5.00),
 (8,  108, 4, 40,    5.00),
 (9,  109, 5, 2,   250.00),
 (10, 110, 5, 3,   250.00),
 (11, 111, 6, 1,   600.00),
 (12, 112, 6, 2,   600.00),
 (13, 113, 7, 4,   120.00),
 (14, 114, 8, 120,   3.00),
 (15, 115, 8, 80,    3.00),
 (16, 116, 9, 50,   12.00);