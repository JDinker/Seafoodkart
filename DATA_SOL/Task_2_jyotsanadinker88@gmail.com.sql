--Q1. BEGIN

SELECT COUNT(DISTINCT(U.USER_ID)) AS TOTAL_USERS 
FROM users AS U;

--Q1. END

--Q2. BEGIN

SELECT F.USER_ID, COUNT(F.COOKIE_ID) AS AVG_OF_COOKIE 
FROM Final_Raw_Data AS F
GROUP BY F.[USER_ID]
ORDER BY F.[USER_ID] ASC;

--Q2. END 

--Q3. BEGIN

SELECT F.USER_ID, MONTH(F.EVENT_TIME) AS MONTH_, COUNT(F.VISIT_ID) AS COUNT_OF_VISIT
FROM Final_Raw_Data AS F
GROUP BY F.USER_ID, F.EVENT_TIME
ORDER BY COUNT_OF_VISIT DESC;

--Q3.  END

--Q4. BEGIN

SELECT F.event_type, COUNT(F.event_name) AS NUM_OF_EVENTS 
FROM Final_Raw_Data AS F
GROUP BY F.event_type;

--Q4. END

-- Q5. BEGIN


--END

--Q6BEGIN

--END

--Q7. BEGIN

SELECT TOP 3 F.page_name, COUNT(F.event_name) AS NUM_OF_VIEWS 
FROM Final_Raw_Data AS F
WHERE F.event_name = 'PAGE VIEW'
GROUP BY F.page_name
ORDER BY NUM_OF_VIEWS DESC;

--Q7.END

--Q8.BEGIN

SELECT P.product_category, P.Views_count AS NUM_VIWES,
P.Add_to_cart_count AS NUM_CART_ADDS 
FROM Product_category_level_summary AS P;

--END
