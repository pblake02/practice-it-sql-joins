-- SQLite

-- Returns the schema for each table
-- select sql from sqlite_master where name in ('DimCustomer', 'DimCurrency','DimProduct');

--INNER JOIN without using JOIN
-- SELECT *
-- FROM DimProductCategory, DimDepartmentGroup;

-- SELECT *
-- FROM DimProductCategory, DimDepartmentGroup
-- WHERE DimProductCategory.ProductCategoryKey = DimDepartmentGroup.DepartmentGroupKey;

-- Ch2

-- Self Join
-- SELECT A.EnglishProductName, B.EnglishProductName, A.ProductSubCategoryKey
-- FROM DimProduct A
-- INNER JOIN DimProduct B
-- ON A.ProductKey <> B.ProductKey 
--   AND A.ProductSubCategoryKey = B.ProductSubCategoryKey
-- ORDER BY A.ProductSubCategoryKey;

-- Practice: Write a SQL query that returns the employee name and their manager's name using the EmployeeKey and ParentEmployeeKey

-- My answer:
SELECT 
      B.EmployeeKey,
      B.FirstName as "Manager's first name",
      B.LastName as "Manager's last name",
      A.EmployeeKey, A.ParentEmployeeKey,
      A.FirstName as "Employee's First Name",
      A.LastName  as "Employee's Last Name"
FROM DimEmployee A
INNER JOIN DimEmployee B
ON A.ParentEmployeeKey = B.EmployeeKey
ORDER BY A.ParentEmployeeKey;


-- Solution:
-- Select E.EmployeeKey as EmployeeKey,
-- E.FirstName as Employee_First_Name,
-- E.LastName as Employee_Last_Name,
-- E.ParentEmployeeKey,
-- M.EmployeeKey,
-- M.FirstName as Manager_First_Name,
-- M.LastName as Manager_Last_Name
-- from DimEmployee E
-- join DimEmployee M
-- on E.ParentEmployeeKey = M.EmployeeKey
-- ORDER BY M.EmployeeKey;


-- Ch3

drop view if exists customer_email_a;
create view customer_email_a as -- e
select CustomerKey, EmailAddress
from DimCustomer
where  EmailAddress like '%a%@adventure-works.com';

drop view if exists customer_address_us;
create view customer_address_us  as -- a
select CustomerKey, AddressLine1, AddressLine2, C.GeographyKey
from DimCustomer C
join DimGeography G 
ON C.GeographyKey = G.GeographyKey
where  CountryRegionCode = 'US';

-- 3.3.1
-- My answers:
select d.CustomerKey, d.FirstName, d.LastName,
      e.EmailAddress,
      a.GeographyKey
from DimCustomer d
left join customer_email_a e
  on d.CustomerKey = e.CustomerKey
left join customer_address_us a
  on e.CustomerKey = a.CustomerKey
-- where e.EmailAddress is null AND a.GeographyKey is null
limit 15;


select d.CustomerKey, d.FirstName, d.LastName,
      e.EmailAddress,
      a.GeographyKey
from DimCustomer d
left join customer_address_us a
  on d.CustomerKey = a.CustomerKey
left join customer_email_a e
  on e.CustomerKey = a.CustomerKey
--   where e.EmailAddress is null AND a.GeographyKey is null
limit 15;


-- 3.3.2
-- My answer:
select d.ProductKey, s.ProductKey, sum(s.salesamount) as 'Total Sales'
from DimProduct d
left join FactInternetSales s
on d.ProductKey = s.ProductKey
-- where s.ProductKey is not null
group by d.ProductKey;

-- Solution:
SELECT p.ProductKey, 
 sum(s.SalesAmount) as Sum_of_Sales
from DimProduct p
left join FactInternetSales s using(ProductKey)
group by p.ProductKey


-- 3.3.3
-- My answer:
select d.ProductKey, d.EnglishProductName, s.OrderDate, s.OrderQuantity, s.salesamount
from  FactInternetSales s
left join DimProduct d
on d.ProductKey = s.ProductKey;

-- Solution:
select  DimProduct.ProductKey, 
DimProduct.EnglishProductName, 
FactInternetSales.OrderDate, 
FactInternetSales.OrderQuantity, 
FactInternetSales.SalesAmount 
from DimProduct
left join FactInternetSales
on DimProduct.ProductKey = FactInternetSales.ProductKey
order by DimProduct.ProductKey;


-- 3.5.1
-- My answers:

SELECT
  -- r.ResellerKey,
  r.ResellerName,
  g.CountryRegionCode,
  -- s.ResellerKey,z
  s.SalesOrderNumber,
  -- p.ProductKey,
  p.EnglishProductName as ProductName,
  -- sb.ProductSubCategoryKey,
  c.EnglishProductCategoryName as ProductCategoryName,
  sb.EnglishProductSubCategoryName as ProductSubCategoryName,
  s.SalesAmount,
-- Window functions for fun
  AVG(s.SalesAmount) OVER(PARTITION BY sb.ProductSubCategoryKey) as subcat_avg,
  MIN(s.SalesAmount) OVER(PARTITION BY sb.ProductSubCategoryKey) as subcat_min,
  MAX(s.SalesAmount) OVER(PARTITION BY sb.ProductSubCategoryKey) as subcat_max,
  RANK() OVER(ORDER BY s.SalesAmount DESC) as overall_rank,
  RANK() OVER(PARTITION BY sb.ProductSubCategoryKey ORDER BY s.SalesAmount DESC) as subcat_rank
FROM DimReseller r
JOIN DimGeography g
  ON r.GeographyKey = g.GeographyKey
-- ***Note: There are some Resellers with no sales thus different rec counts if use a left vs inner join from the DimReseller to the FactResellerSales table (see below)
JOIN FactResellerSales s
-- LEFT JOIN FactResellerSales s
  ON r.ResellerKey = s.ResellerKey
LEFT JOIN DimProduct p
  ON s.ProductKey = p.ProductKey
LEFT JOIN DimProductSubCategory sb
  ON p.ProductSubCategoryKey = sb.ProductSubCategoryKey
LEFT JOIN DimProductCategory c
  ON sb.ProductCategoryKey = c.ProductCategoryKey
-- Filters
WHERE g.CountryRegionCode = 'US'
  -- AND
  -- (s.SalesOrderNumber is null or
  -- p.ProductKey is null or
  -- p.EnglishProductName is null or
  -- sb.ProductSubCategoryKey is null or
  -- c.EnglishProductCategoryName is null or
  -- sb.EnglishProductSubCategoryName is null)
  -- ORDER BY s.SalesAmount DESC, sb.ProductCategoryKey, sb.ProductSubCategoryKey
  ;


-- Solution:
Select 
-- R.ResellerKey, -- Line added by me to do additional recon
ResellerName,
AddressLine1,
AddressLine2,
G.City,
G.StateProvinceCode,
G.PostalCode,
G.CountryRegionCode,
S.ProductKey,
P.ProductSubcategoryKey,
S.SalesAmount
FROM
DimReseller as R
LEFT JOIN FactResellerSales as S
 ON R.ResellerKey = S.ResellerKey
INNER JOIN DimGeography as G
 ON R.GeographyKey = G.GeographyKey
LEFT JOIN DimProduct as P
 ON S.ProductKey = P.ProductKey
WHERE G.CountryRegionCode = 'US'
-- Lines added by me to do additional recon
--   AND (S.ProductKey is null or
-- P.ProductSubcategoryKey is null or
-- S.SalesAmount is null)
ORDER BY S.SalesAmount ASC;


-- 4.5.1
-- My answer:

-- Select i.CustomerKey, c.CustomerKey
Select i.*, c.*
from FactInternetSales i
LEFT JOIN customer_address_us c
ON i.CustomerKey = c.CustomerKey
-- WHERE i.CustomerKey = c.CustomerKey
UNION ALL
-- Select i.CustomerKey, c.CustomerKey
Select i.*, c.*
from customer_address_us c
LEFT JOIN FactInternetSales i
ON i.CustomerKey = c.CustomerKey
-- WHERE i.CustomerKey = c.CustomerKey
ORDER BY i.CustomerKey;
