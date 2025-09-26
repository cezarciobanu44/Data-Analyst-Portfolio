--SQL 
--Using adventure works 2019 

--In this project my goal is to analyse cluster of related questions and progress from general to specific analysis.
--Here is an overview of step-by-step approach:


	--Clustering questions (from general : total sales   to sales by region ,period, customer segment, and product)allows you to tell a business story, not just show isolated findings.
	--Moving from a general overview to more detailed mirrors best practices in business analysis and dashboarding.
	--Preparing and cleaning data before analysis will ensure answers that are accurate, explainable, and easily visualized in BI tools.
	--Last I will analyse the relationship between region, customer ,and product.
	
--Data Gathering, Preparation, and Cleaning.
--Data Gathering and Initial Cleaning for Sales Analysis.
--Collect and prepare sales data with relevant columns to answer:
--Total sales and number of orders by year (already done).
--Total sales by region.
--Total sales by periods.
--Identify periods and regions with highest/lowest sales.
--cleaning initial SQL query.
--I handled rows with missing or nulls.
--Converted dated to useful granularities (year, quarter, month) for time-based grouping.
--Use inner join to keep only valid territory.


SELECT
    st.Name AS TerritoryName,
    YEAR(soh.OrderDate) AS SalesYear,
    SUM(soh.TotalDue) AS TotalSales,
    COUNT(DISTINCT soh.SalesOrderID) AS OrdersCount
FROM
Sales.SalesOrderHeader soh
INNER JOIN
    Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
WHERE
    soh.OrderDate IS NOT NULL
    AND soh.TotalDue IS NOT NULL
GROUP BY
    st.Name,
    YEAR(soh.OrderDate)
ORDER BY
    SalesYear DESC,
    TotalSales DESC;
	
--1.	INNER JOIN between SalesOrderHeader and SalesTerritory ensures only sales with valid region data are included.
--Using inner join here filters out orders with NULL or invalid TerritoryID.
--If business context requires including unassigned territories, use LEFT JOIN and handle nulls accordingly.
--Filtering OrderDate IS NOT NULL and TotalDue IS NOT NULL guarantees only meaningful sales records are analyzed.
--Records missing these fields represent incomplete or invalid data.
--Grouping by both territory name and sales year allows aggregation for sales per year and region—critical to answer the “sales by region” and “sales by year” questions.
--Selecting distinct SalesOrderIDs for order counts avoids duplication if multiple rows per order exist.
--Sorting by year (desc) and then total sales (desc) shows recent high-sales regions at the top.

--Check Territory Table for Region Consistency
SELECT
    TerritoryID,
    Name,
    [Group],
    COUNT(*) OVER () AS TotalTerritories
FROM
    Sales.SalesTerritory
ORDER BY
    TerritoryID;
	
--Sales and Profitability Overview:

--What are the total sales and number of orders per year?
--What are the total sales by region?
--Which regions generate the most sales?
--What are the total sales by period (quarter, month)?
--Which periods have the highest and lowest sales?
--What are the possible factors contributing to low or high sales during these periods or in these regions.

select
year (orderdate) as salesyear,
SUM(TotalDue) AS TotalSales,
COUNT(DISTINCT SalesOrderID) AS OrdersCount 
from sales.SalesOrderHeader
GROUP BY
    YEAR(OrderDate)
ORDER BY
    SalesYear desc;
	
--most and least profitable products

SELECT
  p.Name AS ProductName,
  SUM(sod.LineTotal) AS TotalRevenue,
  SUM(pch.StandardCost * sod.OrderQty) AS TotalCost,
  SUM(sod.LineTotal) - SUM(pch.StandardCost * sod.OrderQty) AS TotalProfit
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductCostHistory pch ON p.ProductID = pch.ProductID
  AND soh.OrderDate >= pch.StartDate
  AND (pch.EndDate IS NULL OR soh.OrderDate <= pch.EndDate)
GROUP BY p.Name
ORDER BY TotalProfit DESC;  

--What are the most popular products by quantity sold?
SELECT
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.OrderQty) AS TotalQuantitySold
FROM
    Sales.SalesOrderDetail AS sod
    INNER JOIN Production.Product AS p ON sod.ProductID = p.ProductID
GROUP BY
    p.ProductID, p.Name
ORDER BY
    TotalQuantitySold DESC;
	
	
	
	--What are the most profitable products by revenue?
select
sod.ProductID,
[name]as productname,
avg(orderqty)as avgorderqty,
avg(lastreceiptcost)as avgproductioncost,
avg(unitprice)as avgunitprice,
avg(unitpricediscount)as avgunitdiscount,
avg(pch.StandardCost)as avgstandartcost,
max(startdate)as lateststartdate,
count(enddate)as enddate
from sales.salesorderdetail as sod
inner join production.ProductCostHistory as pch
on sod.ProductID=pch.ProductID
inner join purchasing.productvendor as ppv
on sod.ProductID=ppv.productid
inner join Production.Product as pp
on sod.ProductID=pp.ProductID
where pch.StandardCost>0  
and unitpricediscount is not null
group by 
sod.ProductID,
[name]


	--Which product categories generate the most/least sales and profits?
SELECT 
    pc.Name AS CategoryName,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.OrderQty) AS TotalUnitsSold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY TotalRevenue DESC;

	--What is the inventory turnover rate for each product or product category?
select
sso.Productid,
sum(orderqty)as total_order_qty,
pp.ProductSubcategoryID,
pps.ProductCategoryID,
ppc.[Name],
avg(quantity)as avg_quantity,
case when avg(quantity) =0 then null
 else cast(sum(sso.orderqty)as float)/avg(quantity)
 end as inventory_turnover_rate
from Sales.SalesOrderDetail as sso
join production.product as pp
on sso.productid=pp.productid
join Production.ProductSubcategory as pps
on pp.ProductSubcategoryID=pps.ProductSubcategoryID
join Production.ProductCategory as ppc
on pps.ProductCategoryID=ppc.ProductCategoryID
join Production.ProductInventory as ppv
on  sso.productid=ppv.ProductID
group by
	sso.Productid,
	pp.ProductSubcategoryID,
	pps.ProductCategoryID,
	ppc.[Name]
order by 
	inventory_turnover_rate desc
	
--1)	What are the seasonal demand patterns for specific products or categories?
SELECT
    pc.Name AS CategoryName,
    YEAR(soh.OrderDate) AS SalesYear,
    DATEPART(quarter, soh.OrderDate) AS SalesQuarter,
    SUM(sod.OrderQty) AS TotalUnitsSold
FROM
    Sales.SalesOrderHeader soh
INNER JOIN 
    Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN 
    Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN 
    Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN
    Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE
    soh.OrderDate IS NOT NULL
GROUP BY
    pc.Name,
    YEAR(soh.OrderDate),
    DATEPART(quarter, soh.OrderDate)
ORDER BY
    pc.Name,
    SalesYear,
    SalesQuarter;

--Which customers generate the highest revenue?
select
	soh.CustomerID,
	sum(TotalDue)as totalrevenue,
	StoreID,
	FirstName, 
	LastName,
	ss.[Name]
from Sales.SalesOrderHeader as soh
LEFT JOIN Sales.Customer AS sc ON soh.CustomerID = sc.CustomerID
LEFT JOIN Person.Person AS pp ON sc.PersonID = pp.BusinessEntityID
LEFT JOIN Sales.Store AS ss ON sc.StoreID = ss.BusinessEntityID
group by 
	soh.CustomerID,
	StoreID,
	FirstName, 
	LastName,
	ss.[Name]
order by sum(TotalDue)desc

--Which customers or segments (e.g., individual vs. store) place the most repeat orders?
SELECT
    soh.CustomerID,
    sc.StoreID,
    pp.FirstName,
    pp.LastName,
    ss.Name AS StoreName,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    CASE 
        WHEN sc.StoreID IS NOT NULL THEN 'Store' 
        ELSE 'Individual' 
    END AS CustomerSegment
FROM Sales.SalesOrderHeader soh
LEFT JOIN Sales.Customer sc ON soh.CustomerID = sc.CustomerID
LEFT JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
LEFT JOIN Sales.Store ss ON sc.StoreID = ss.BusinessEntityID
GROUP BY
    soh.CustomerID,
    sc.StoreID,
    pp.FirstName,
    pp.LastName,
    ss.Name
ORDER BY
    TotalOrders DESC;


--What is the geographic distribution of top customers (by sales/region/country)?
SELECT
    soh.CustomerID,
    c.StoreID,
    pp.BusinessEntityID AS PersonBusinessEntityID,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS CustomerName,
    a.City,
    sp.Name AS StateProvince,
    sp.CountryRegionCode,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
LEFT JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person AS pp ON c.PersonID = pp.BusinessEntityID
LEFT JOIN Sales.Store AS st ON c.StoreID = st.BusinessEntityID
LEFT JOIN Person.BusinessEntityAddress AS bea ON bea.BusinessEntityID = c.PersonID OR bea.BusinessEntityID = c.StoreID
LEFT JOIN Person.Address AS a ON bea.AddressID = a.AddressID
LEFT JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
GROUP BY
    soh.CustomerID,
    c.StoreID,
    pp.BusinessEntityID,
    pp.FirstName,
    pp.LastName,
    a.City,
    sp.Name,
    sp.CountryRegionCode
ORDER BY
    TotalSales DESC;
	
--Which customer segments are the most and least profitable?
SELECT
    CASE 
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Individual'
    END AS CustomerSegment,
    SUM(soh.TotalDue) AS TotalRevenue,
    COUNT(DISTINCT soh.CustomerID) AS NumberOfCustomers
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY
    CASE 
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Individual'
    END
ORDER BY
    TotalRevenue DESC;
	
--	Are there trends or patterns in customer purchasing over time?
SELECT
    soh.CustomerID,
    YEAR(soh.OrderDate) AS PurchaseYear,
    DATEPART(quarter, soh.OrderDate) AS PurchaseQuarter,
    COUNT(soh.SalesOrderID) AS NumberOfOrders,
    SUM(soh.TotalDue) AS TotalRevenue,
    AVG(soh.TotalDue) AS AvgOrderValue
FROM Sales.SalesOrderHeader soh
WHERE soh.OrderDate IS NOT NULL
GROUP BY
    soh.CustomerID,
    YEAR(soh.OrderDate),
    DATEPART(quarter, soh.OrderDate)
ORDER BY
    soh.CustomerID,
    PurchaseYear,
    PurchaseQuarter;
	
--Who is the top-performing salespersons based on total sales volume?
SELECT
    sp.BusinessEntityID,
    p.FirstName,
    p.LastName,
    SUM(soh.TotalDue) AS TotalSalesVolume
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesPerson AS sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee AS e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
GROUP BY
    sp.BusinessEntityID,
    p.FirstName,
    p.LastName
ORDER BY
    TotalSalesVolume DESC;


--How does sales performance compare against targets or quotas?
SELECT
    p.FirstName,
    p.LastName,
    YEAR(spqh.QuotaDate) AS QuotaYear,
    DATEPART(QUARTER, spqh.QuotaDate) AS QuotaQuarter,
    SUM(soh.TotalDue) AS ActualSales,
    spqh.SalesQuota,
    CASE
        WHEN spqh.SalesQuota = 0 THEN NULL
        ELSE CAST(SUM(soh.TotalDue) AS FLOAT) / spqh.SalesQuota * 100
    END AS PercentOfQuota
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesPersonQuotaHistory AS spqh ON YEAR(soh.OrderDate) = YEAR(spqh.QuotaDate)
    AND DATEPART(QUARTER, soh.OrderDate) = DATEPART(QUARTER, spqh.QuotaDate)
    AND soh.SalesPersonID = spqh.BusinessEntityID
JOIN Sales.SalesPerson AS sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee AS e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
GROUP BY
    p.FirstName,
    p.LastName,
    YEAR(spqh.QuotaDate),
    DATEPART(QUARTER, spqh.QuotaDate),
    spqh.SalesQuota
ORDER BY
    QuotaYear DESC,
    QuotaQuarter DESC,
    PercentOfQuota DESC;


--How do employee sales performance patterns differ by region or over time?

SELECT
    sp.BusinessEntityID,
    p.FirstName,
    p.LastName,
    st.Name AS TerritoryName,
    YEAR(soh.OrderDate) AS SalesYear,
    DATEPART(quarter, soh.OrderDate) AS SalesQuarter,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY
    sp.BusinessEntityID,
    p.FirstName,
    p.LastName,
    st.Name,
    YEAR(soh.OrderDate),
    DATEPART(quarter, soh.OrderDate)
ORDER BY
    TerritoryName,
    SalesYear,
    SalesQuarter,
    TotalSales DESC;
	
--Gross Margin Trend by Product Line
SELECT
    pc.Name AS ProductLine,
    YEAR(soh.OrderDate) AS SalesYear,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(pch.StandardCost * sod.OrderQty) AS TotalCost,
    SUM(sod.LineTotal - (pch.StandardCost * sod.OrderQty)) AS GrossMargin,
    100.0 * SUM(sod.LineTotal - (pch.StandardCost * sod.OrderQty)) / NULLIF(SUM(sod.LineTotal),0) AS GrossMarginPct
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN Production.ProductCostHistory pch ON p.ProductID = pch.ProductID
    AND soh.OrderDate >= pch.StartDate
    AND (pch.EndDate IS NULL OR soh.OrderDate <= pch.EndDate)
GROUP BY pc.Name, YEAR(soh.OrderDate)
ORDER BY SalesYear DESC, GrossMargin DESC;


-- Gross Margin Trend by Sales Territory
SELECT
    st.Name AS Territory,
    YEAR(soh.OrderDate) AS SalesYear,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(pch.StandardCost * sod.OrderQty) AS TotalCost,
    SUM(sod.LineTotal - (pch.StandardCost * sod.OrderQty)) AS GrossMargin,
    100.0 * SUM(sod.LineTotal - (pch.StandardCost * sod.OrderQty)) / NULLIF(SUM(sod.LineTotal),0) AS GrossMarginPct
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductCostHistory pch ON p.ProductID = pch.ProductID
    AND soh.OrderDate >= pch.StartDate
    AND (pch.EndDate IS NULL OR soh.OrderDate <= pch.EndDate)
GROUP BY st.Name, YEAR(soh.OrderDate)
ORDER BY SalesYear DESC, GrossMargin DESC;

--How do discounts and promotions impact overall profitability?
SELECT
    pc.Name AS ProductCategory,
    SUM(sod.UnitPrice * sod.OrderQty) AS TotalSalesBeforeDiscount,
    SUM(sod.UnitPrice * sod.UnitPriceDiscount * sod.OrderQty) AS TotalDiscountAmount,
    SUM(sod.LineTotal) AS TotalSalesAfterDiscount,
    SUM(sod.LineTotal) - SUM(pch.StandardCost * sod.OrderQty) AS GrossMarginAfterDiscount
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN Production.ProductCostHistory pch ON p.ProductID = pch.ProductID
    AND soh.OrderDate >= pch.StartDate
    AND (pch.EndDate IS NULL OR soh.OrderDate <= pch.EndDate)
GROUP BY pc.Name
ORDER BY GrossMarginAfterDiscount DESC;


--	What are the most and least profitable customer segments, products, and vendors?
SELECT
    CASE 
        WHEN c.StoreID IS NOT NULL THEN 'Store' 
        ELSE 'Individual' 
    END AS CustomerSegment,
    SUM(sod.LineTotal) - SUM(pch.StandardCost * sod.OrderQty) AS TotalProfit
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Production.ProductCostHistory pch ON sod.ProductID = pch.ProductID
    AND soh.OrderDate >= pch.StartDate
    AND (pch.EndDate IS NULL OR soh.OrderDate <= pch.EndDate)
GROUP BY
  CASE WHEN c.StoreID IS NOT NULL THEN 'Store' ELSE 'Individual' END
ORDER BY TotalProfit DESC;


--most and least profitable vendors 
SELECT
    v.Name AS VendorName,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(pch.StandardCost * sod.OrderQty) AS TotalCost,
    SUM(sod.LineTotal) - SUM(pch.StandardCost * sod.OrderQty) AS TotalProfit
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
LEFT JOIN Production.ProductCostHistory pch ON p.ProductID = pch.ProductID 
    AND soh.OrderDate >= pch.StartDate
    AND (pch.EndDate IS NULL OR soh.OrderDate <= pch.EndDate)
GROUP BY v.Name
ORDER BY TotalProfit DESC;

--total sales by region and country over the years

SELECT
    st.Name AS Region,
    spc.Name AS Country,
    YEAR(soh.OrderDate) AS SalesYear,
    SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
JOIN Sales.SalesTerritory spc ON st.TerritoryID = spc.TerritoryID
GROUP BY st.Name, spc.Name, YEAR(soh.OrderDate)
ORDER BY SalesYear, Region, Country;


--Territory Dimension table
SELECT DISTINCT
    TerritoryID,
    [Name] AS TerritoryName,
    CountryRegionCode,
    [Group] AS TerritoryGroup
FROM Sales.SalesTerritory
WHERE TerritoryID IS NOT NULL;

