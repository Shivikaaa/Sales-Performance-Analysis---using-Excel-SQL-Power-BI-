

-------------------------------- For Data Preparation --------------------------------

-- Dropping the observations(rows) if MCN is null or storeID is null or Cash_Memo_No

        delete from [TRANSACTION]
        where MCN is null or Store_ID is  null or Cash_Memo_No is null
        
-- Joining both tables considering Transaction table as base table.

        select * into Final_Data
        from [TRANSACTION] as a
        left join CUSTOMER as b
        on a.MCN = b.CustomerID
     
-- Calculating the discount variable using formula (Discount = TotalAmount-SaleAmount)


        ALTER TABLE final_data
        ADD Discount AS (TotalAmount-SaleAmount)

-- Filtering the Final_Data using sample_flag=1 to export this data into Excel for further analysis.

         select * into sample_data
         from Final_Data
         where Sample_flag = 1

----------------------------------------------------------------------------------------------------------------------------------

-- Counting the number of observations with any of the variables having null value/missing values.

       select count(*) as [Number of Observations having null value/missing values]
       from ( 
              select * from Final_Data
              where ItemCount IS NULL or	TransactionDate IS NULL or TotalAmount IS NULL	or SaleAmount IS NULL 
			  or SalePercent	IS NULL or 	Dep1Amount IS NULL or	Dep2Amount IS NULL	or Dep3Amount IS NULL or
			  Dep4Amount	IS NULL or CustID IS NULL	or Gender IS NULL	or [Location] IS NULL or	Age	IS NULL 
			  or Cust_seg IS NULL	or Sample_flag IS NULL or	CustomerID IS NULL
          
              ) as x


-- Numbers of Distinct customers that have shopped : 

        select count(*) as [Number of Customers]
        from (
               select distinct CustomerID
               from Final_Data
               where CustomerID is not null
        	 
        	   ) as y

-- Number of shoppers (customers) visiting more than 1 store  :

        select count(*) as [Number of shoppers (customers) visiting more than 1 store]
        from (
              select CustomerID , count(distinct Store_ID) as counts
              from Final_Data 
              group by customerid
              having count(distinct Store_ID) > 1

            ) as y

-- Distribution of shoppers by the day of the week( to analse the customer's shopping behavior on each day of week ) : 

      select format(transactiondate,'dddd') as [Day] , count(mcn) as [Number of Customers] , count(transactiondate) 
      [Number of Transactions] , sum(SaleAmount) as [Total Sale Amount] , sum(itemcount) as [Total Quantity]
      from Final_Data
      group by format(transactiondate,'dddd')

-- Average revenue per customer by each location : 

      select mcn as [CustomerID] , [Location] ,  avg(saleamount) as [Average Revenue] 
      from Final_Data
      group by mcn , [Location]

-- Average revenue per customer by each store : 

      select mcn as [CustomerID] , Store_ID ,  avg(saleamount) as [Average Revenue] 
      from Final_Data 
      group by mcn , Store_ID

--  Department spend by store wise : 

      select store_id , sum(Dep1Amount) as [TotalSpend_Dep1], sum(Dep2Amount) as [TotalSpend_Dep2],
      sum(Dep3Amount) as [TotalSpend_Dep3] , sum(Dep4Amount) as [TotalSpend_Dep4]
      from Final_Data
      group by store_id

--  Latest Transaction date and the Oldest Transaction date  : 

       select min(transactiondate) as [Oldest Transaction Date] , 
       max(transactiondate) as [Latest Transaction Date]
       from final_data

-- Number of months of data provided for the analysis : :

       
	   select  cast(round(DATEDIFF(DAY,(select min(transactiondate) from final_data) ,  
	   (select max(transactiondate) from final_data))/30.417 , 0) as int) as        
	   [Number of Months for which the data is provided for analysis]

--  Top 3 locations in terms of spend and total contribution of sales out of total sales : 

         select top 3 [Location] , sum(saleamount) as [Total Spend] , 
         sum(saleamount)/(select sum(saleamount) from Final_Data) * 100 as 
         [Total Contribution of Sales Out of Total Sales in %age]
         from final_data
         group by [Location]
         order by sum(saleamount) desc	   

-- Customer count and Total Sales by Gender : 

        select Gender , count(mcn) as [Customer Count],
	    sum(saleamount) as [Total Sales]
        from Final_Data
        where gender is not null
        group by gender

--Q.12 What is total  discount and percentage of discount given by each location?

        select  [Location] , sum(discount) as [Total Discount]
        , (sum(discount)/sum(totalamount)) * 100 as [ %age of Discount]
        from Final_Data
        where [location] is not null
        group by [location]

-- Segment of customers contributing maximum sales : 

       select cust_seg 
       from ( 
             select top 1 Cust_seg , sum(saleamount) as [ Total Sales] 
             from Final_Data
             group by Cust_seg
             order by sum(saleamount) desc
	       ) as y

-- Average transaction value by location, gender, segment : 

       select [Location] , Gender , cust_seg , avg(saleamount) as [Average Transaction]
       from Final_Data
       where [Location] is not null
       group by [location] , gender , cust_seg
       order by [Location]

-- Creating a Customer_360 Table : 

       select * into Customer_360
	   from ( 

             select MCN as [Customer_ID] , Gender, [Location], Age, Cust_seg , count(MCN) as [Number of Transactions] , 
             sum(itemcount) as [No_of_items] , sum(saleamount) as Total_sale_amount,  avg(saleamount) as [Average_transaction_value],
             sum(Dep1Amount) as[TotalSpend_Dep1] , sum(Dep2Amount) as [TotalSpend_Dep2] , 	sum(Dep3Amount) as [TotalSpend_Dep3] ,
             sum(Dep4Amount) as [TotalSpend_Dep4] , 
             COUNT(CASE WHEN Dep1Amount <> 0 THEN 1 ELSE NULL END) as No_Transactions_Dep1 , 
             COUNT(CASE WHEN dep2amount <> 0 THEN 1 ELSE NULL END) as No_Transactions_Dep2 ,
             COUNT(CASE WHEN dep3amount <> 0 THEN 1 ELSE NULL END) as No_Transactions_Dep3 ,  
             COUNT(CASE WHEN dep4amount <> 0 THEN 1 ELSE NULL END) as No_Transactions_Dep4 ,
             
             COUNT(CASE WHEN format(transactiondate , 'dddd') not in ('Saturday' , 'Sunday')
             THEN 1 ELSE NULL END) as No_Transactions_Weekdays , 
             COUNT(CASE WHEN format(transactiondate , 'dddd') in ('Saturday' , 'Sunday') 
             THEN 1 ELSE NULL END) as No_Transactions_Weekends , 
			 DENSE_RANK() over ( order by sum(saleamount) desc ) as [Rank_based_on_Spend] ,
             NTILE(10) OVER (ORDER BY sum(saleamount) desc) AS Decile
             from Final_Data
             where gender is not null
             group by MCN , Gender, [Location] , Age , Cust_seg

	 ) as x



