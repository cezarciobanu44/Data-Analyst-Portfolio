--These SQL extracts build a star schema for a Power BI project.

--fact table.
SELECT
    soh.SalesOrderID,
    sod.SalesOrderDetailID,
    soh.OrderDate,
    soh.CustomerID,
    soh.SalesPersonID,
    soh.TerritoryID,
    sod.ProductID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID

--Vendor Dimension Table.
SELECT
    v.BusinessEntityID AS VendorID,
    v.Name AS VendorName
FROM Purchasing.Vendor v

--Salesperson Employee Dimension Table.

SELECT 
    sp.SalesPersonID,
    p.FirstName,
    p.LastName
FROM Sales.SalesPerson sp
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID



--Territory Dimension Table.
SELECT
    st.TerritoryID,
    st.Name AS TerritoryName,
    st.CountryRegionCode,
    st.TerritoryGroup
FROM Sales.SalesTerritory st



-- Date Dimension Table.

SELECT 
    DISTINCT 
    CAST(OrderDate AS DATE) AS OrderDate,
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    DAY(OrderDate) AS Day,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    DATENAME(MONTH, OrderDate) AS MonthName
FROM Sales.SalesOrderHeader


--Product Dimension Table.

SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    psc.Name AS Subcategory,
    pc.Name AS Category,
    p.Color,
    p.Size,
    p.StandardCost,
    p.ListPrice
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID


--Customer Dimension Table.

SELECT
    c.CustomerID,
    c.AccountNumber,
    c.PersonID,
    c.StoreID,
    CASE 
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Individual'
    END AS CustomerSegment,
    p.FirstName,
    p.LastName,
    s.Name AS StoreName,
    c.TerritoryID
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
