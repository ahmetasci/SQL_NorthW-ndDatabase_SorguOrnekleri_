Use Northwind

--1)Employee Tablosundaki  çalýþanlarýn hangi yöneticiye baðlý olduðunu listeleyen sql kodu
SELECT e.firstname + ' ' + e.lastname AS 'Rapor Veren',e.EmployeeID, m.firstname + ' ' + m.lastname AS 'Müdür', m.EmployeeID
from Employees e INNER JOIN Employees m on e.ReportsTo=m.EmployeeID
Order By [Rapor Veren]
--******************************************************************************************************************
--2)En pahalý ürünü satýn alan ilk üç müþterileri listeleyin(Product Name , Company Name ,UnitPrice)
SELECT TOP 3 c.CompanyName, p.ProductName, od.UnitPrice*od.Quantity
FROM Orders o 
	INNER JOIN Customers c ON c.CustomerID = o.CustomerID
	INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
	INNER JOIN Products p ON p.ProductID = od.ProductID
	ORDER BY od.UnitPrice*od.Quantity DESC
--********************************************************************************************************************

--3)1996 yýlýndaki  sipariþlerin sevkiyat þirketinin adý içinde (i ve p-karýþýk sýrada olabilir)harfleri geçenleri OrderID sine göre listeleyiniz
SELECT DISTINCT s.CompanyName 
	FROM Orders o INNER JOIN Shippers s 
	ON s.ShipperID = o.ShipVia
	--WHERE  o.OrderDate > '1996-01-01' and o.OrderDate < '1997-01-01'
	--And s.CompanyName LIKE '%i%p%'
	WHERE  YEAR(o.OrderDate) = 1996 And (s.CompanyName LIKE '%i%p%' OR s.CompanyName LIKE '%p%i%')
--************************************************************************************************************************

--4)Ayný kategorilere sahip ürünlerin sayýsý, Toplam Birim Fiyatý ve Toplam Birim Fiyat Ortalamasýný alýp büyükten  küçüðe listeleyin
SELECT c.CategoryName, COUNT(p.ProductID) AS 'Ürün Adedi', SUM(UnitPrice) as 'Toplam Fiyat', AVG(UnitPrice) AS 'ORTALAMA'
	From Products p 
	INNER JOIN Categories c ON p.CategoryID = c.CategoryID
	GROUP BY c.CategoryName
	ORDER By [ORTALAMA] DESC
--*************************************************************************************************************************
--5)Her kategorinin en çok satýþ yapan ürününü gösteriniz

SELECT  c. CategoryName,
	MAX(od.Quantity*od.UnitPrice) as SatisTutari FROM Categories c
	INNER JOIN Products p ON c.CategoryID = p.CategoryID
	INNER JOIN [Order Details] od ON od.ProductID = p.ProductID
	GROUP BY c. CategoryName
	ORDER BY SatisTutari DESC

--2.YOL - Yusuf (Dogru)

select CategoryName,ProductName,
sum([Order Details].Quantity*[Order Details].UnitPrice) as SatisTutari into temp
from Categories
inner join Products on Products.CategoryID=Categories.CategoryID
inner join [Order Details] on [Order Details].ProductID=Products.ProductID
group by CategoryName,ProductName
order by SatisTutari desc

select bt.* from temp bt
inner join
(select CategoryName,max(SatisTutari) mxSatis from temp group by CategoryName) t
on bt.CategoryName=t.CategoryName and bt.SatisTutari=t.mxSatis
order by mxSatis desc

--3.Yol - Gunisigi (MAX(od.Quantity*od.UnitPrice) as SatisTutari yerine SUM(od.Quantity*od.UnitPrice) as SatisTutari) yazilirsa dogru olur
-- SatisTutari smallint null yerine SatisTutari int null olmali

declare @tbl table(CategoryName nvarchar(15) null, SatisTutari smallint null, ProductID int null)

insert into @tbl(CategoryName, SatisTutari, ProductID)
Select c.CategoryName, MAX(od.Quantity*od.UnitPrice) as SatisTutari, od.ProductID
From Categories c
Inner join Products p on c.CategoryID = p.CategoryID
Inner join [Order Details] od on p.ProductID = od.ProductID
group by c.CategoryName, od.ProductID
order by 2 desc;

select p.ProductName, ana.*
from @tbl as ana
inner join (select CategoryName, MAX(SatisTutari) as SatisTutari from @tbl group by CategoryName)
 as alt on ana.CategoryName= alt.CategoryName 
and ana.SatisTutari =alt.SatisTutari
left join Products as p on p.ProductID=ana.ProductID

--**********************************************************************************************************

--6)Eastern Region'ýna kayýtlý olan tüm Employee listesini getir.

SELECT Employees.FirstName + ' ' + Employees.LastName as Name 
FROM Employees INNER JOIN (SELECT DISTINCT EmployeeTerritories.EmployeeID FROM EmployeeTerritories INNER JOIN 
									(SELECT Territories.TerritoryID FROM Territories 
										INNER JOIN Region ON Region.RegionID = Territories.RegionID WHERE Region.RegionDescription = 'Eastern') t 
											ON t.TerritoryID = EmployeeTerritories.TerritoryID) et
						  ON et.EmployeeID = Employees.EmployeeID
-- 2. yol
  SELECT DISTINCT e.EmployeeID , e.FirstName , e.LastName FROM Employees AS e 
  INNER JOIN EmployeeTerritories AS et ON e.EmployeeID = et.EmployeeID
  INNER JOIN Territories AS t ON et.TerritoryID = t.TerritoryID
  INNER JOIN Region AS r ON r.RegionID = t.RegionID
  WHERE r.RegionDescription = 'Eastern'
--***************************************************************************************************************************
--7)Þirket adlarýný ve yapmýþ olduklarý toplam þipariþleri listele, toplam sipariþe göre desc sýrala

SELECT DISTINCT Customers.CompanyName, a.TotalOrder FROM Customers 
INNER JOIN (SELECT Orders.CustomerID, COUNT(Orders.CustomerID) as TotalOrder FROM Orders GROUP BY Orders.CustomerID) a
ON Customers.CustomerID = a.CustomerID ORDER BY a.TotalOrder DESC

--2.Yol
   SELECT c.CompanyName , SUM(od.UnitPrice*Quantity) AS [Toplam Satýþ Tutarý] FROM Customers AS c 
   INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
   INNER JOIN [Order Details] AS od ON od.OrderID = o.OrderID
   GROUP BY c.CompanyName
   ORDER BY [Toplam Satýþ Tutarý] DESC

--*********************************************************************************************************
--8)Hangi Þirket Hangi ürünü ne kadar aldý

SELECT Customers.CompanyName, q2.OrderDate, q2.ProductName, q2.TotalOrder FROM Customers
INNER JOIN(SELECT Orders.CustomerID, Orders.OrderDate, q1.ProductName, q1.TotalOrder FROM Orders 
				INNER JOIN (SELECT ProductName, o.OrderID, o.TotalOrder FROM Products 
							INNER JOIN (SELECT [Order Details].OrderID, [Order Details].ProductID, SUM([Order Details].Quantity) as TotalOrder 
							FROM [Order Details] INNER JOIN Products ON Products.ProductID = [Order Details].ProductID GROUP BY [Order Details].ProductID, [Order Details].OrderID) as o
							ON o.ProductID = Products.ProductID) q1 
				ON q1.OrderID = Orders.OrderID) q2
ON q2.CustomerID = Customers.CustomerID 
ORDER BY q2.ProductName, q2.TotalOrder DESC

--2.Yol
   SELECT  c.CompanyName , p.ProductName , SUM(od.Quantity) AS [Toplam Sipariþ Adedi] FROM Customers AS c
   INNER JOIN Orders AS o ON c.CustomerID = o.CustomerID
   INNER JOIN [Order Details] AS od ON od.OrderID = o.OrderID
   INNER JOIN Products AS p ON p.ProductID = od.ProductID
   GROUP BY c.CompanyName , p.ProductName
   ORDER BY [Toplam Sipariþ Adedi]

--*********************************************************************************************************

--9)En çok satýþý apan 3 Employee'nin primini 200 yap ve bastýr

SELECT TOP 3 Employees.FirstName + ' ' + Employees.LastName as Name, q2.EmployeeTotal, 200.00 as Prim FROM Employees
INNER JOIN (SELECT Orders.EmployeeID, SUM(q1.OrderTotalPrice) as EmployeeTotal FROM Orders 
			INNER JOIN (SELECT OrderID, SUM([Order Details].Quantity * [Order Details].UnitPrice) as OrderTotalPrice FROM [Order Details] GROUP BY [Order Details].OrderID) q1
			ON q1.OrderID = Orders.OrderID
			GROUP BY Orders.EmployeeID) q2
ON q2.EmployeeID = Employees.EmployeeID
ORDER BY q2.EmployeeTotal DESC

--2.Yol
   SELECT  TOP 3 e.EmployeeID , SUM(od.Quantity*od.UnitPrice) AS [Elemanýn satýþ miktarý] , 200 AS [Prim] FROM Employees AS e 
   INNER JOIN Orders AS o ON e.EmployeeID = o.EmployeeID
   INNER JOIN [Order Details] AS od ON o.OrderID = od.OrderID
   GROUP BY e.EmployeeID 
   ORDER BY SUM(od.Quantity*od.UnitPrice) DESC

--*****************************************************************************************************************
--10)Hangi bölgede hangi ürün category'e göre en çok satýlmýþtýr. En çok satýþ yapan category

--1.Cevap

select CategoryName,TerritoryDescription,ProductName,count(ProductName) from Categories c 
inner join Products p on c.CategoryID= p.CategoryID 
inner join [Order Details] od on od.ProductID= p.ProductID 
inner join Orders o on od.OrderID=o.OrderID 
inner join Employees e on o.EmployeeID=e.EmployeeID
inner join EmployeeTerritories et on e.EmployeeID=et.EmployeeID
inner join Territories t on t.TerritoryID=et.TerritoryID
group by TerritoryDescription,CategoryName,ProductName
order by COUNT(ProductName) desc

--2. Cevap

SELECT Territories.TerritoryDescription, q2.CategoryName, q2.ProductName, SUM(q1.Price) as Total FROM Territories
INNER JOIN EmployeeTerritories ON EmployeeTerritories.TerritoryID = Territories.TerritoryID
INNER JOIN Employees ON EmployeeTerritories.EmployeeID = Employees.EmployeeID
INNER JOIN Orders ON Orders.EmployeeID = Employees.EmployeeID
INNER JOIN (SELECT [Order Details].Quantity * [Order Details].UnitPrice as Price, [Order Details].OrderID, [Order Details].ProductID FROM [Order Details]) q1 ON q1.OrderID = Orders.OrderID
INNER JOIN (SELECT Categories.CategoryName, Products.ProductName, Products.ProductID FROM Categories INNER JOIN Products ON Products.CategoryID = Categories.CategoryID) q2
	ON q2.ProductID = q1.ProductID
GROUP BY Territories.TerritoryDescription, q2.CategoryName, q2.ProductName
ORDER BY Territories.TerritoryDescription, Total DESC
--**************************************************************************************************

--11)Kimseye rapor vermeyen çalýsanlarýn satýþ yaptýðý müþterilerin ülkeleri ve o ülkeye kaç adet satýþ yaptýðýný listele

SELECT Country, COUNT(*) FROM Customers INNER JOIN Orders ON Customers.CustomerID=Orders.CustomerID
		WHERE Orders.EmployeeID IN
			(SELECT EmployeeID FROM Employees WHERE ReportsTo IS NULL)
				GROUP BY Country

--2.YOL

SELECT e.EmployeeID , e.FirstName , e.LastName , c.Country , SUM(od.Quantity) AS [TOTAL SALES] FROM Employees AS e
   INNER JOIN Orders AS o ON o.EmployeeID=e.EmployeeID
   INNER JOIN Customers AS c ON c.CustomerID=o.CustomerID
   INNER JOIN [Order Details] AS od ON od.OrderID = o.OrderID
   WHERE e.ReportsTo is NULL 
   GROUP BY e.EmployeeID , e.FirstName , e.LastName , c.Country 
--****************************************************************************************************************

--12)Products tablosunda Unit Price'larý ortalamanýn üzerinde olan ürün adlarý nelerdir ve hangi ülkelere satýlmýþtýr?

SELECT P.ProductName, C.Country FROM Products P INNER JOIN [Order Details] od on P.ProductID=od.ProductID
INNER JOIN Orders O ON od.OrderID=O.OrderID
INNER JOIN Customers C ON O.CustomerID=C.CustomerID
WHERE od.UnitPrice > (SELECT AVG([Order Details].UnitPrice) FROM [Order Details])
GROUP BY C.Country,P.ProductName

--2.YOL
  SELECT p.ProductName , c.Country , p.UnitPrice   FROM Customers AS c
  INNER JOIN Orders AS o 
  ON o.CustomerID = c.CustomerID
  INNER JOIN [Order Details] AS od 
  ON od.OrderID = o.OrderID
  INNER JOIN Products AS p 
  ON p.ProductID = od.ProductID
  WHERE p.UnitPrice > (SELECT AVG(UnitPrice) FROM Products)
  GROUP BY p.ProductName , c.Country , p.UnitPrice
  ORDER BY p.UnitPrice
  --************************************************************************************************************

--13) Herhangi bir kategoride en çok satýþ yapan 5 firma

select top 5 s.CompanyName, SUM(od.Quantity) as adet,sum(od.Quantity*od.UnitPrice) as gelir,c.CategoryName
from Suppliers s 
	inner join Products p 
	on s.SupplierID=p.SupplierID
	inner join [Order Details] od 
	on p.ProductID=od.ProductID 
	inner join Categories c 
	on p.CategoryID=c.CategoryID  
	group by  c.CategoryName,s.CompanyName 
order by SUM(od.Quantity) desc

--**************************************************************************************************************

 --14) OrderDate ve RequiredDate arasý 30 günden fazla olanlarýn kategorisi ve adeti 
 SELECT C.CategoryName , Count(*) AS Amount FROM Orders O
 JOIN [Order Details] OD ON OD.OrderID=O.OrderID
 JOIN Products P ON P.ProductID = OD.ProductID
 JOIN Categories C ON P.CategoryID = C.CategoryID

 WHERE DATEDIFF(day, OrderDate,RequiredDate)>30 --datedýff iki tarih arasýndaki farký alýr
 GROUP BY C.CategoryName

--************************************************************************************************************

 --15) ORDER DATE 1996.08.01 ile 1997.01.01 arasýndaki SHIPCITY Madrid olan kayýtlarýn COMPANYNAME bul.

select CompanyName,OrderDate, ShipCity from Orders inner join Customers 
on Orders.CustomerID=Customers.CustomerID where ShipCity='Madrid' and 
OrderDate between '1996.08.01' and '1997.01.01'

--*****************************************************************************************************************