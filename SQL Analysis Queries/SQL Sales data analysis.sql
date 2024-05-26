--- Inspecting data
SELECT *FROM [AyoubPortfolio].[dbo].[sales_data_sample]

--- Checking unique values 

select distinct status from [dbo].[sales_data_sample] --Nice one to plot
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] --Nice one to plot
select distinct COUNTRY from [dbo].[sales_data_sample] --Nice one to plot
select distinct DEALSIZE from [dbo].[sales_data_sample] --Nice one to plot
select distinct TERRITORY from [dbo].[sales_data_sample] --Nice one to plot

-- ANALYSIS:
-- Let's start by grouping sales by Productline :
select PRODUCTLINE, SUM (sales) AS Revenue
from [AyoubPortfolio].[dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 DESC

-- Grouping sales by Years :
select YEAR_ID, SUM (sales) AS Revenue
from [AyoubPortfolio].[dbo].[sales_data_sample]
group by YEAR_ID
order by 2 DESC

-- Grouping sales by Dealsize :
select DEALSIZE, SUM (sales) AS Revenue
from [AyoubPortfolio].[dbo].[sales_data_sample]
group by DEALSIZE
order by 2 DESC

--- What was the best month for sales in a specific year? How much earned that month?
select MONTH_ID, SUM (sales) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
from [AyoubPortfolio].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2003 -- Change year to see the rest
group by MONTH_ID
order by 2 DESC

--- November seems to be the month, what product do they sell in November(MOUNTH_ID 11), Classic i believe 
select MONTH_ID, PRODUCTLINE,  SUM (sales) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
from [AyoubPortfolio].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2003 and MONTH_ID = 11  -- November
group by MONTH_ID, PRODUCTLINE
order by 3 DESC

--- Who is our best customer (this could be best answered with RFM Analysis):
DROP TABLE IF EXISTS #rfm;

WITH rfm AS
(
	SELECT 
		CUSTOMERNAME,
		SUM(sales) AS MonetaryValue,
		AVG(sales) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) AS max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) AS Recency
	FROM [AyoubPortfolio].[dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
),
rfm_calc AS 
(
	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
	FROM rfm AS r
)
SELECT 
	c.*, 
	rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	CONCAT(CAST(rfm_recency AS VARCHAR), CAST(rfm_frequency AS VARCHAR), CAST(rfm_monetary AS VARCHAR)) AS rfm_cell_string
INTO #rfm
FROM rfm_calc AS c;



SELECT 
	CUSTOMERNAME,
	rfm_recency,
	rfm_frequency,
	rfm_monetary,
	CASE 
		WHEN rfm_cell_string IN (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers' --lost customers
		WHEN rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' --(Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string IN (311, 411, 331,412) THEN 'new customers'
		WHEN rfm_cell_string IN (221,222, 223,232,234, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string IN (323, 333, 321, 422, 332, 432, 421, 423) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
	END AS rfm_segment
FROM #rfm;

--- What products are most often sold together? 
--- Select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

SELECT distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [AyoubPortfolio].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc


---EXTRAs----
--- What city has the highest number of sales in a specific country?

select city, sum (sales) Revenue
from [AyoubPortfolio].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



--- What is the best product in United States?

select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [AyoubPortfolio].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc



