/*
Question 1:
We are running a specific discount scheme in our Northwind Organization. 
Every month we will select a particular category and provide a discount based on the chosen category.

The rules of the discount are as follows:
If the total order value is <50, we give 5% discount.
If the total order value is >=50 but <100, we give 10% discount
if the total order value is >100, we give 15% discount.

Write a stored procedure that will achieve this. 
We need to update the table(s) to reflect the discount. 
Remember, we give a discount to orders with a specific category and not to all the categories.
*/

USE Northwind
GO
CREATE	procedure Category_Discount
		@selectedCategory varchar(50)
as
begin

UPDATE [Order Details]
set Discount = .05
where OrderID in
(select OrderID, SUM([Order Details].UnitPrice) AS Total_Order_Price
FROM [Order Details] INNER JOIN Products on Products.ProductID = [Order Details].ProductID
INNER JOIN [Categories] on Products.CategoryID = [Categories].CategoryID
WHERE CategoryName =  @selectedCategory
GROUP BY OrderID
having SUM([Order Details].UnitPrice) > 50)

UPDATE [Order Details]
set Discount = .15
where OrderID in
(select OrderID, SUM([Order Details].UnitPrice) AS Total_Order_Price
FROM [Order Details] INNER JOIN Products on Products.ProductID = [Order Details].ProductID
INNER JOIN [Categories] on Products.CategoryID = [Categories].CategoryID
WHERE CategoryName =  @selectedCategory
GROUP BY OrderID
having SUM([Order Details].UnitPrice) < 100)

UPDATE [Order Details]
set Discount = .10
where OrderID in
(select OrderID, SUM([Order Details].UnitPrice) AS Total_Order_Price
FROM [Order Details] INNER JOIN Products on Products.ProductID = [Order Details].ProductID
INNER JOIN [Categories] on Products.CategoryID = [Categories].CategoryID
WHERE CategoryName =  @selectedCategory
GROUP BY OrderID
having SUM([Order Details].UnitPrice) => 50
AND SUM([Order Details].UnitPrice) < 100)

end

/*
Question 2:
Write a function that returns the number of employees based on a region. 
By region, we mean the region the employee serves and not the region where the employee lives. 
Execute the function to demonstrate the correctness.
*/
/*Function:*/
USE Northwind
GO

Create Function Employee_Work_Region
	(@selectedRegion varchar(50))
	Returns table
AS
Return (
Select EmployeeID
FROM Employees
WHERE Region = @selectedRegion);

/*Query: */
USE Northwind
GO
SELECT *
from Employee_Work_Region('WA');

/*
Question 3:
(70) A Customer can request an expedite delivery of all the orders that the customer placed. 
Given a customer id, we follow the following rules for expedite delivery.  
(Some of you already used the difference between ship date and required date as a way to expedite delivery, I will accept it also.)

(1) If orders are within ten days of delivery (the difference between the order date and shipping date  < 10), 
we refuse the expedite delivery but create a set of such orders.  
As part of the stored procedure, we will print such rows using a select statement. 

(2) If orders are going to make more than ten days to deliver (the difference between the order date and shipping date > 10), 
we expedite the shipping date by one week (by shipping it earlier). At the same time, 
we will charge the customers double for the freight. Update tables accordingly.  

Now we want to allow the customer to expedite delivery for a specific order. 
We will refuse delivery if it is not possible based on our rules or update the order for expedite delivery and return the new expedite date. 
If the expedite delivery is not possible we will just return the current shipping date. 
Implement this and demonstrate implementation by executing the stored procedure or function.
*/

/*Function: */
USE Northwind
GO

create Procedure Expedite_Order
	(@CustomerID nchar(50), 
	@OrderID int)

AS
begin
	declare @DifferenceDate as int
	declare @SpecificOrderDate as datetime
	declare @SpecificShipDate as datetime
	declare @NewDate as datetime

	select @SpecificOrderDate = (select OrderDate from Orders
								where CustomerID = @CustomerID
								and OrderID = @OrderID)

	select @SpecificShipDate =  (select ShippedDate from Orders
								where CustomerID = @CustomerID
								and OrderID = @OrderID)

	select @DifferenceDate =	(select DATEDIFF(dd, @SpecificOrderDate, @SpecificShipDate) AS DifferenceDate)
	select @NewDate =			(Select DATEADD(dd, -7, @SpecificShipDate) as NewDate)

if (@DifferenceDate > 10) 
	begin
	UPDATE Orders
	set Freight = Freight * 2
	Where CustomerID = @CustomerID
	And OrderID = @OrderID

	UPDATE Orders
	set ShippedDate = @NewDate
	Where CustomerID = @CustomerID
	And OrderID = @OrderID
	
	print 'Your order has been expidited. New ship date is: '
	print @NewDate
	end

else
begin
	print 'Unable to expidite your order. Current ship date is: ' 
	print @SpecificShipDate
end
end

/*Query*/
use Northwind
GO
Execute Expedite_Order 'VINET', '10248'

/*
(30) Northwind customers call the support team at the Northwind company to have their questions answered about their orders. 
When a customer support representative receives a call, 
the representative asks typically for the phone number of the customer and search based on the phone number. 
The support staff is complaining that the search based on the phone number is slow. 
Propose and implement a solution to the situation.
*/

/*Proposal:

To speed up searches we need to improve the data structure behind the queries. 
If we create a unique index, we should be able to improve search times.
We should also leave some space in the index so we do not have to rebuild it each time we get a new customer
*/

/*Implementation: */
USE Northwind
GO
Create unique index i_Customers
On Customers (Phone)
With fillfactor = 80
