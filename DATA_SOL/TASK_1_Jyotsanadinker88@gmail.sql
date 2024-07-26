--Q1. BEGIN

CREATE DATABASE Seafoodkart

-- Q1. END

SELECT TOP 1 * FROM [dbo].[campaign_identifier]
SELECT TOP 1 * FROM [dbo].[event_identifier]
SELECT TOP 1 * FROM [dbo].[events]
SELECT TOP 1 * FROM [dbo].[users]
SELECT TOP 1 * FROM[dbo].[page_heirarchy]

SELECT * FROM [dbo].[campaign_identifier]
SELECT * FROM [dbo].[event_identifier]
SELECT * FROM [dbo].[events]
SELECT * FROM [dbo].[users]
SELECT * FROM[dbo].[page_heirarchy]

--Q2. BEGIN

-- ALL DATA SET IMPORTED

--Q2. END

--Q3. BEGIN

--a.
ALTER TABLE DBO.USERS
ALTER COLUMN START_DATE DATE;

--b. 
ALTER TABLE [dbo].[events]
ALTER COLUMN EVENT_TIME DATETIME;

--c.
ALTER TABLE [dbo].[campaign_identifier]
ALTER COLUMN START_DATE DATE;

ALTER TABLE [dbo].[campaign_identifier]
ALTER COLUMN END_DATE DATE;

--Q3 END

--Q4. BEGIN

SELECT COUNT(*) AS CAMPAIGN_ID FROM campaign_identifier;
SELECT COUNT(*) AS EVENT_TYPE FROM event_identifier;
SELECT COUNT(*) AS VISIT_ID FROM events;
SELECT COUNT(*) AS [USER_ID] FROM users;
SELECT COUNT(*) AS PAGE_ID FROM page_heirarchy;

--Q4 END

--Q5. BEGIN
CREATE TABLE Final_Raw_Data (PAGE_ID TINYINT,PAGE_NAME NVARCHAR(50),PRODUCT_CATEGORY NVARCHAR(50),PRODUCT_ID TINYINT NULL,
                         USER_ID INT,COOKIE_ID NVARCHAR(50),START_DATE DATE NULL,VISIT_ID NVARCHAR(50),EVENT_TYPE INT,
						 SEQUENCE_NUMBER int,EVENT_TIME DATETIME,EVENT_NAME NVARCHAR(50), CAMPAIGN_ID  INT NULL,
						 PRODUCT INT,CAMPAIGN_NAME NVARCHAR(50), END_DATE DATE NULL);

INSERT INTO Final_Raw_Data (EVENT_TYPE,COOKIE_ID,EVENT_TIME,PAGE_ID,SEQUENCE_NUMBER,VISIT_ID,EVENT_NAME,
                           PAGE_NAME,PRODUCT_CATEGORY,PRODUCT_ID,CAMPAIGN_ID,CAMPAIGN_NAME,END_DATE,PRODUCT,
						   START_DATE,USER_ID)

SELECT E.event_type,E.cookie_id, E.event_time,E.page_id,E.sequence_number,E.visit_id,
EI.event_name,
P.page_name,P.product_category,P.product_id,
C.campaign_id,C.campaign_name,C.end_date,C.products,C.start_date,
U.user_id
FROM events AS E
LEFT JOIN event_identifier AS EI
ON EI.event_type = E.event_type
LEFT JOIN users AS U
ON U.cookie_id = E.cookie_id
LEFT JOIN page_heirarchy AS P
ON E.page_id = P.page_id
LEFT JOIN campaign_identifier AS C 
ON C.start_date = U.start_date 

--TO CHECK TABLE 
SELECT * FROM Final_Raw_Data

--Q5. END


--Q6. BEGIN

SELECT * INTO Product_level_Summary FROM
         (
       SELECT F.PRODUCT_ID, 
       SUM(CASE WHEN F.EVENT_NAME = 'PURCHASE' THEN 1 ELSE 0 END) AS PURCHASE,
	   SUM(CASE WHEN F.EVENT_NAME = 'ADD TO CART' THEN 1 ELSE 0 END) AS ADD_TO_CART,
	   SUM(CASE WHEN F.EVENT_NAME = 'PAGE VIEW' THEN 1 ELSE 0 END) AS PAGE_VIEW,
	   SUM(CASE WHEN F.event_name = 'Add to Cart' AND F.event_name <> 'PURCHASE' THEN 1 ELSE 0 END) AS ABANDONED_CART

FROM Final_Raw_Data AS F 
GROUP BY F.PRODUCT_ID) AS A
ORDER BY PRODUCT_ID;

--TO CHECK TABLE 
    SELECT * FROM Product_level_Summary

--Q6. END 

--Q7. BEGIN

CREATE TABLE Product_category_level_summary (
    PRODUCT_CATEGORY NVARCHAR(50), 
    Views_count INT,
    Add_to_cart_count INT,
    Abandoned_cart_count INT,
    Purchase_count INT
);

INSERT INTO Product_category_level_summary (PRODUCT_CATEGORY,Views_count)
SELECT P.product_category , COUNT(*) AS Page_View_Type
FROM events AS E
INNER JOIN users AS U 
ON E.cookie_id = U.cookie_id
INNER JOIN event_identifier AS EI
ON EI.event_type = E.event_type
INNER JOIN page_heirarchy AS P
ON P.page_id = E.page_id
WHERE EI.event_name = 'PAGE VIEW'
GROUP BY P.product_category

UPDATE Product_category_level_summary
SET add_to_cart_count = (
    SELECT COUNT(*) AS add_to_cart_count
FROM events AS E
INNER JOIN users AS U 
ON E.cookie_id = U.cookie_id
INNER JOIN event_identifier AS EI
ON EI.event_type = E.event_type
INNER JOIN page_heirarchy AS P
ON P.page_id = E.page_id
    WHERE event_name = 'Add to Cart' AND P.product_category = Product_category_level_summary.PRODUCT_CATEGORY)
	
UPDATE Product_category_level_summary
SET purchase_count = (
     SELECT COUNT(*) AS purchase_count
FROM events AS E
INNER JOIN users AS U 
ON E.cookie_id = U.cookie_id
INNER JOIN event_identifier AS EI
ON EI.event_type = E.event_type
INNER JOIN page_heirarchy AS P
ON P.page_id = E.page_id
    WHERE event_name = 'Purchase' AND P.product_category = Product_category_level_summary.PRODUCT_CATEGORY)


UPDATE Product_category_level_summary
SET abandoned_cart_count = (
     SELECT COUNT(*) AS abandoned_cart_count
FROM events AS E
INNER JOIN users AS U 
ON E.cookie_id = U.cookie_id
INNER JOIN event_identifier AS EI
ON EI.event_type = E.event_type
INNER JOIN page_heirarchy AS P
ON P.page_id = E.page_id
    WHERE EI.event_name = 'Add to Cart' 
    AND NOT EXISTS (
        SELECT 1 
        FROM page_heirarchy AS P
		INNER JOIN events AS E
		ON E.page_id = P.page_id
        WHERE EI.event_name = 'PURCHASE' 
    ) AND P.product_category = Product_category_level_summary.PRODUCT_CATEGORY
);

-- TO CHECK TABLE
SELECT * FROM Product_category_level_summary

--Q7. END

--Q8. BEGIN

CREATE TABLE Visit_Summary (USER_ID INT,VISIT_ID NVARCHAR(50),VISIT_START_TIME DATETIME , CAMPAIGN_NAME NVARCHAR(50),
                             PAGE_VIEWS INT,PURCHASE INT,IMPRESSION INT, CLICK INT,ADD_TO_CART INT,
							 CART_PRODUCTS VARCHAR(MAX));
                           
INSERT INTO Visit_Summary (USER_ID,VISIT_ID,VISIT_START_TIME ,CAMPAIGN_NAME,CART_PRODUCTS ,IMPRESSION ,CLICK ,
                           PAGE_VIEWS, PURCHASE,ADD_TO_CART ) 
SELECT 
    F.[user_id],
    F.visit_id,
    MIN(F.event_time) AS VISIT_START_TIME,
	MAX(CAMPAIGN_NAME) AS CAMPAIGN_NAME,
	STRING_AGG(visit_id, ', ') WITHIN GROUP (ORDER BY SEQUENCE_NUMBER) AS CART_PRODUCTS,
    SUM(CASE WHEN F.EVENT_NAME='AD IMPRESSION' THEN 1 ELSE 0 END) AS IMPRESSION,
    SUM(CASE WHEN F.EVENT_NAME='AD CLICK' THEN 1 ELSE 0 END) AS CLICK ,
    SUM(CASE WHEN F.EVENT_NAME='PAGE VIEW' THEN 1 ELSE 0 END) AS PAGE_VIEW,
    SUM(CASE WHEN F.EVENT_NAME='PURCHASE' THEN 1 ELSE 0 END) AS PURCHASE,
    SUM(CASE WHEN F.EVENT_NAME='ADD TO CART' THEN 1 ELSE 0 END) AS ADD_TO_CART
FROM Final_Raw_Data AS F
WHERE 
       F.EVENT_NAME = 'ADD TO CART' OR F.EVENT_NAME ='AD IMPRESSION' OR F.EVENT_NAME='AD CLICK'
	   OR F.EVENT_NAME='PAGE VIEW' OR F.EVENT_NAME='PURCHASE'
    GROUP BY F.[user_id],F.visit_id
ORDER BY [USER_ID] ASC;

--TO CHECK TABLE
SELECT * FROM Visit_Summary

--Q8. END
 