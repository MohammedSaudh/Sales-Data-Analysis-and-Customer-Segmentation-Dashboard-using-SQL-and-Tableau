SELECT * 
FROM sales_data_sample

---Checking Unique Values
SELECT DISTINCT status FROM sales_data_sample --Good Data to plot
SELECT DISTINCT year_id FROM sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample --Good Data to plot
SELECT DISTINCT COUNTRY FROM sales_data_sample --Good Data to plot
SELECT DISTINCT DEALSIZE FROM sales_data_sample
SELECT DISTINCT TERRITORY FROM sales_data_sample --Good Data to plot

---ANALYSIS
--GROUP SALES BY PRODUCT LINE
SELECT PRODUCTLINE, SUM(sales) Revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--GROUP SALES BY Year
SELECT year_id AS Year, SUM(sales) Revenue
FROM sales_data_sample
GROUP BY year_id
ORDER BY 2 DESC

--GROUP SALES BY DEALSIZE
SELECT DEALSIZE, SUM(sales) Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

---SALES IN EACH MONTH in the Different Years
SELECT YEAR_ID AS Year, MONTH_ID AS Month, SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
GROUP BY YEAR_ID, MONTH_ID
ORDER BY 3 DESC	

---November SEEMS TO be the Month where the Revenue is greatest so we will furhter explore this data
SELECT YEAR_ID, MONTH_ID, PRODUCTLINE, SUM(SALES) as Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE MONTH_ID = 11
GROUP BY YEAR_ID, MONTH_ID, PRODUCTLINE
ORDER BY 4 DESC



--RFM Analysis(To divide customers into different categories)
;WITH rfm AS	
(
	SELECT
		CUSTOMERNAME,
		SUM(SALES) AS Monetory,
		AVG(SALES) AS AgMonetory,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) as Recency
	FROM sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc AS(
	SELECT r.*,
	
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency, 
		NTILE(4) OVER (ORDER BY Frequency) rfm_Frequency,
		NTILE(4) OVER (ORDER BY Monetory) rfm_Monetory
	FROM rfm r
)
SELECT c.*,rfm_recency+rfm_Frequency+rfm_Monetory as rfm_score,
cast(rfm_recency AS VARCHAR) + cast(rfm_frequency AS VARCHAR) + cast(rfm_Monetory AS VARCHAR) rfm_score_string
INTO #rfm
FROM rfm_calc c

SELECT Monetory, rfm_Monetory, Frequency, rfm_Frequency, Recency, rfm_recency
FROM #rfm


---Split customers into various categories depening on RFM Score
SELECT CUSTOMERNAME, rfm_recency, rfm_Frequency, rfm_Monetory,rfm_score_string,
	CASE
		WHEN rfm_score_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customer' --lost customers
		WHEN rfm_score_string in (133, 134, 143, 244, 334, 343, 344, 221, 232, 144, 234) THEN 'slipping_away' --big spenders Who havent Purchased in a while
		WHEN rfm_score_string in (311, 411, 331, 412) THEN 'new_customer'
		WHEN rfm_score_string in (222, 223, 233, 322, 421) THEN 'potential_churner'
		WHEN rfm_score_string in (323, 333, 321, 422, 332, 432) THEN 'active'
		WHEN rfm_score_string in (433, 434, 443, 444) THEN 'loyal'
	end rfm_segment
FROM #RFM


---What products are often sold together
SELECT DISTINCT ORDERNUMBER, STUFF(
	
	(SELECT ','+ PRODUCTCODE
	FROM sales_data_sample p
	WHERE ORDERNUMBER in
		(
		SELECT ORDERNUMBER
		FROM (
				SELECT ORDERNUMBER, COUNT(*) rn
				FROM sales_data_sample
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
			) m 
			WHERE rn = 2
			)
			AND p.ORDERNUMBER = s.ORDERNUMBER
			for xml path(''))
			,1,1,'') Productcodes
FROM sales_data_sample s
ORDER BY 2 DESC





SELECT CUSTOMERNAME,Recency, Frequency ,Monetory, rfm_Monetory, Frequency, rfm_Frequency, Recency, rfm_recency 
FROM #rfm

SELECT *
FROM #rfm