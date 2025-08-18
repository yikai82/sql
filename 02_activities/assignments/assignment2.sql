/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 

We tell them, no problem! We can produce a list with all of the appropriate details. 
Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

WITH name_combined AS(

	SELECT *
	,coalesce(nullif(product_size,''),'') product_size_new				-- replace null with a blank 
	,coalesce(nullif(product_qty_type,''),'unit') product_qty_type_new 	-- replace null/blank to 'unit'
	FROM product
)

SELECT
product_name || ', ' || product_size_new || ' (' || product_qty_type_new || ')' as product_name_combined
-- product_name || ', ' || product_size_new || ' (' || product_qty_type_new || ')' IS NULL
FROM name_combined;



--- Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

-- 1.1 USE row_number
SELECT
customer_id
,market_date
,row_number()OVER(PARTITION BY customer_id ORDER BY market_date ASC) market_visit_number
	-- customer id =1 max_visit_number = 246
FROM customer_purchases


-- 1.2 Use dense_rank'
SELECT 
customer_id
,market_date
,dense_rank()OVER(PARTITION BY customer_id ORDER BY market_date ASC) market_visit_number
	-- customer id =1 max_visit_number = 107
FROM customer_purchases 


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

-- 2.1 USE row_number
-- It wil return the most recent visit date 
SELECT x.*

FROM ( 
	SELECT
	customer_id
	,product_id
	,market_date
	,vendor_id
	,row_number()OVER(PARTITION BY customer_id ORDER BY market_date DESC) visit_number_latest
	FROM customer_purchases
) x 
WHERE visit_number_latest = 1;


-- 2.2 Use dense_rank
-- It will include all the vendor visit on the same date
SELECT x.*

FROM (
	SELECT 
	-- DISTINCT  	-- TEST with comment out or uncomment DISTIST
					-- uncomment: 39 rows [DISTINCT: ON)
					-- comment out: 52 rows [DISTINCT: OFF) 
	customer_id
	,product_id
	,market_date
	,vendor_id
	,dense_rank()OVER(PARTITION BY customer_id ORDER BY market_date DESC) visit_number_latest
	FROM customer_purchases
) x 
WHERE visit_number_latest = 1;


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

-- Use dense_rank as the same day visit will still count as the same visit.

SELECT x.*
, customer_first_name
, customer_last_name
, product_name

FROM (
	SELECT 
	DISTINCT  		-- TEST with comment out or uncomment DISTIST
					-- uncomment: 3371 rows [DISTINCT: ON)
					-- comment out: 4221 rows [DISTINCT: OFF) 
	customer_id
	,product_id
	,market_date
	,vendor_id
	,dense_rank()OVER(PARTITION BY customer_id ORDER BY market_date ASC) market_visit_number
	,count()OVER(PARTITION BY customer_id, product_id ORDER BY market_date ASC) as item_purhcase_time
	FROM customer_purchases
) x
-- WHERE customer_id = 1 AND product_id = 1  -- uncomment to allow searching for specific customer and product 
JOIN customer c
	ON c.customer_id = x.customer_id
JOIN product p
	ON p.product_id = x.product_id

ORDER BY customer_id, market_date DESC

		

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT *
,trim(substr(product_name, insert_pos)) as description

FROM( 
	SELECT * 
	,hypen_post+1 as insert_pos

	FROM (
		SELECT 
		product_name
		,nullif(instr(product_name, '-'),0) as hypen_post
		FROM product
));
	
-- Test wth trim and substr 	
-- SELECT
-- trim(substr('Habanero Peppers - Organic', 19))


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */


-- Step 1: temp table creation
--delete table if exists
DROP TABLE IF EXISTS temp.daily_sales;

--make and define the table 
CREATE TABLE IF NOT EXISTS temp.daily_sales AS 

SELECT DISTINCT
market_date
, round(daily_sales_amount,2) as daily_sales_amount
 
FROM (
	SELECT 
	market_date
	-- , product_id
	-- , vendor_id
	-- , customer_id
	, quantity*cost_to_customer_per_qty as sales
	, sum(quantity*cost_to_customer_per_qty) OVER(PARTITION BY market_date) as daily_sales_amount

	FROM customer_purchases
)

-- 1.2  
SELECT
market_date
,daily_sales_amount

FROM (
	SELECT * 
	, row_number()OVER(ORDER BY daily_sales_amount DESC) as rank_from_the_highest 
	FROM daily_sales

)

SELECT market_date, max(daily_sales_amount), 'the best day' as best_or_worst_day
FROM daily_sales
UNION
SELECT market_date, min(daily_sales_amount), 'the_worst_day' as best_or_worst_day
FROM daily_sales;


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--1) create a temp table for cross 
DROP TABLE IF EXISTS temp.cross_table;
CREATE TABLE IF NOT EXISTS temp.cross_table AS 
SELECT DISTINCT 
vendor_id
, product_id
, original_price
FROM vendor_inventory --vendor_id in (4,7,8) 
ORDER BY vendor_id, product_id; 

--2) create a hypothetical sell table 
DROP TABLE IF EXISTS hypo_sell_table; 
CREATE TABLE IF NOT EXISTS hypo_sell_table as  

SELECT x.*
, vendor_name
, product_name
	FROM (
		SELECT
		customer_id 
		, vendor_id 
		, product_id 
		, original_price
		FROM customer
		CROSS JOIN cross_table
)x
JOIN vendor v
	ON v.vendor_id = x.vendor_id
JOIN product p
	ON p.product_id = x.product_id

	
--3) calculation 
SELECT DISTINCT
product_id
, product_name
, vendor_id
, vendor_name
-- , original_price*5 as hypo_amount
, sum(original_price*5) OVER (PARTITION BY product_id ORDER BY vendor_id) as hypo_amount_per_product  

FROM hypo_sell_table;



-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units; 
CREATE TABLE IF NOT EXISTS product_units AS 

SELECT * 
, datetime('now', '-5 hours') as snapshot_timestamp -- convert to est timezone 
FROM product
WHERE product_qty_type = 'unit'
ORDER by product_id;

	
/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES ('24', 'Buldak Carbonara Ramen', 'small',NULL,'unit', datetime('now','-5 hours'));

SELECT * FROM product_units; -- check 

-- DELETE
/* 1. Delete the older record for the whatever product you added. 
HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_id = 24;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;*/

ALTER TABLE product_units
ADD current_quantity INT; 
UPDATE product_units SET current_quantity = ifnull(current_quantity,0); 

SELECT * FROM product_units;  -- view table 

/*Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.
HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

--1) check if all the product have records in the inventory 
SELECT product_id FROM product_units 
INTERSECT
SELECT DISTINCT product_id FROM vendor_inventory; -- only product_id IN (3,4,5,7,8,16) are existing in both


--2) call out the latest quanity 
DROP TABLE IF EXISTS temp.latest_inventory; 
CREATE TABLE IF NOT EXISTS temp.latest_inventory as 

SELECT * 
FROM (
	SELECT * 
	, row_number()OVER(PARTITION BY product_id ORDER BY market_date DESC) as rank_latest 
	FROM vendor_inventory
)
WHERE rank_latest = 1 AND product_id in (3,4,5,7,8,16)


SELECT * FROM latest_inventory --check the latest inventory 

--3) UPDATE the table product_units
UPDATE product_units as pu
SET current_quantity = (
	SELECT li.quantity
	FROM latest_inventory li
	WHERE li.product_id = pu.product_id
);

UPDATE product_units SET current_quantity = ifnull(current_quantity,0);
UPDATE product_units SET snapshot_timestamp = datetime('now', '-5 hours');

SELECT * FROM product_units; --to check final output 






---------------------------------------------------
--------- TEMP TABLE: temp_product_units ----------
DROP TABLE IF EXISTS temp_product_units;
CREATE TABLE IF NOT EXISTS temp.temp_product_units as
SELECT * FROM product_units;

-- WHERE product_id IN (3,4,5,7,8,16); 
-- to view temp_product_units
SELECT * FROM temp_product_units;
----------------------------------------------------
----------------------------------------------------
