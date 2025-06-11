--These queries were written for Microsoft SQL Server

-- Create a table employees with columns id, name, salary, and department.
CREATE TABLE employees (
	empID INT NOT NULL,
	empName VARCHAR(100) NOT NULL,
    salary DECIMAL(6,2) NOT NULL,
	department VARCHAR(25) NOT NULL,
	PRIMARY KEY (empID)
);

-- Create a table audit_log to store changes made to the salary column in employees.
CREATE TABLE audit_log (
	changedID INT NOT NULL,
	changeDate DATE NOT NULL,
    changeDetails VARCHAR(200) NOT NULL,
	PRIMARY KEY (changedID)
);

-- a BEFORE UPDATE trigger named salary_update_trigger logs any changes to the salary into the audit_log.

CREATE TRIGGER salary_update_trigger
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF OLD.salary != NEW.salary THEN
  	    INSERT INTO audit_log(changedID, changeDate, oldSalary, newSalary)
  	    VALUES (OLD.empID, NOW(), OLD.salary, NEW.salary);
    END IF;
END;


-- Updating the salary of an employee, and verifying that the change is logged, tests the trigger.
INSERT INTO employees (empID, empName, salary, department)
VALUES (1, 'Larry Dinkins', 17000.00, 'Fraud Detection');

UPDATE employees 
SET salary = 18000.00
WHERE empID = 1;

SELECT * FROM audit_log;


-- Looping Through Records with a Cursor

-- Create a table products with columns id, product_name, and price.
CREATE TABLE products (
	prodID INT NOT NULL,
	prodName VARCHAR(100) NOT NULL,
    price DECIMAL(6,2) NOT NULL,
	PRIMARY KEY (prodID)
);

-- A stored procedure named discount_high_prices uses a cursor to loop through products priced above 100 and reduces their prices by 10%.
DELIMITER $$
CREATE PROCEDURES discount_high_prices()
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE product_id INT;
	DECLARE product_price DECIMAL(10,2);

	DECLARE product_cursor CURSOR FOR
		SELECT prodID, price FROM products WHERE price > 100;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	OPEN product_cursor;

	price_loop: LOOP
		FETCH product_cursor INTO product_id, product_price;
		IF done THEN
			LEAVE price_loop
		END IF;

		UPDATE products SET price = product_price * 0.9 WHERE prodID = product_id
	END LOOP price_loop;

	CLOSE product_cursor;
END$$
DELIMITER ;


-- Test the procedure,  checking the price changes before and after running the cursor.
INSERT INTO products(prodID, prodName, price)
VALUES (1, 'Spoon', 125.00);
CALL discount_high_prices();
SELECT * FROM products;



-- Create tables orders and customers.
CREATE TABLE orders(
	orderID INT AUTO_INCREMENT PRIMARY KEY,
	customer_name VARCHAR(50) NOT NULL,
	order_amount DECIMAL(10,2)
);

CREATE TABLE customers(
	customerID INT AUTO_INCREMENT PRIMARY KEY,
	customer_name VARCHAR(50),
	email VARCHAR(100) NOT NULL
);
-- A stored procedure named dynamic_select that takes a table name as input and dynamically selects all rows from that table.
DELIMITER $$

CREATE PROCEDURE dynamic_select(table_name VARCHAR(50))
BEGIN
	SET @sql = CONCAT('SELECT * FROM ', table_name);
	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;

END $$

DELIMITER ;


-- Test the procedure by passing different table names like orders and customers.
INSERT INTO orders (customer_name, order_amount)
VALUES ('Tracey', 32), ('Stuart', 1), ('Rahul', 3);

INSERT INTO customers (customer_name, email)
VALUES ('Tracey', 'spaceytracey@myspace.com'), ('Stuart', 'sfmculloch@efs.co.uk'), ('Rahul', 'rh328@leicester.org.uk');

CALL dynamic_select(orders);
CALL dynamic_select(customers);


-- Create a table transactions with columns id, account_number, and amount.
CREATE TABLE transactions (
	transactionID INT AUTO_INCREMENT PRIMARY KEY,
	account_number VARCHAR(20) UNIQUE,
	ammount DECIMAL(10,2) NOT NULL
);


-- Create a table error_log with columns id, error_message, and error_time to store error logs.
CREATE TABLE error_log (
	errorID INT AUTO_INCREMENT PRIMARY KEY,
	error_message VARCHAR(255),
	error_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- a stored procedure process_transaction tries to insert a record into the transactions table and logs an error in the error_log table if the transaction fails.
DELIMITER $$

CREATE PROCEDURE process_transaction(account_number VARCHAR(20), ammount DECIMAL(10,2))
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		INSERT INTO error_log (error_message)
		VALUES ('Transaction failed, due to SQL error, possible account number duplication');
	END;

	INSERT INTO transactions (account_number, ammount)
	VALUES (account_number, amount);

END $$
DELIMITER ;



-- Test the procedure by attempting to insert a duplicate record and logging the error.
CALL process_transaction('5748290684230', 420);
CALL process_transaction('5748290684230', 420);
SELECT * FROM transactions;
SELECT * FROM error_log;