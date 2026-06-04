create database intern;
use intern;
set sql_safe_updates = 0;
alter table dataset rename to sales;

select * from sales;

select 
sum(case when CustomerID is null or trim(CustomerID) = '' then 1 else 0 end) as null_id,
sum(case when Product is null or trim(Product) = '' then 1 else 0 end) as null_product,
sum(case when Quantity is null then 1 else 0 end) as null_Quantity,
sum(case when UnitPrice is null then 1 else 0 end) as null_price,
sum(case when ShippingAddress is null or trim(ShippingAddress) = '' then 1 else 0 end) as null_adress,
sum(case when PaymentMethod is null or trim(PaymentMethod) = '' then 1 else 0 end) as null_payment,
sum(case when OrderStatus is null or trim(OrderStatus) = '' then 1 else 0 end) as null_status,
sum(case when TrackingNumber is null or trim(TrackingNumber) = '' then 1 else 0 end) as null_tracker,
sum(case when ItemsInCart is null then 1 else 0 end) as null_in_CART,
sum(case when CouponCode is null or trim(CouponCode) = '' then 1 else 0 end) as null_coupon,
sum(case when ReferralSource is null or trim(ReferralSource) = '' then 1 else 0 end) as null_referral,
sum(case when TotalPrice is null then 1 else 0 end) as null_price
from sales;

-- Insights
-- CouponCode has 309 null values

select (sum(case when CouponCode is null or trim(CouponCode) = '' then 1 else 0 end)/count(*)) * 100 as null_percentage from sales;
-- percentage of null value are 25.75
-- We fill null categorical values with the mode during preprocessing. But for analysis, 
-- we replace null values with "No Coupon" so the missing values are treated as a separate category and the results become more accurate.

Update sales
set CouponCode = "No coupon"
where CouponCode is null or CouponCode = '';


select CouponCode ,count(*) as Total_frequency from sales
group by CouponCode;
-- SAVE10	286
-- FREESHIP	313
-- No coupon	309
-- WINTER15	292


select * from sales;

-- Now date is a text datatype it must be date time now we convert it to date time.

select str_to_date(Date,"%Y-%m-%d") as Date from sales; 
describe sales;


-- Created a new table sales_cleaned containing the cleaned dataset. 
-- Null and blank values in CouponCode were replaced with "No Coupon",
--  and the Date column was converted from text format to a proper date format.
-- All further EDA and business analysis were performed on sales_cleane

 
CREATE TABLE sales_cleaned AS
SELECT
    CustomerID,
    Product,
    Quantity,
    UnitPrice,
    STR_TO_DATE(Date, '%Y-%m-%d') AS OrderDate,
    ShippingAddress,
    PaymentMethod,
    OrderStatus,
    TrackingNumber,
    ItemsInCart,
    CASE
        WHEN CouponCode IS NULL OR TRIM(CouponCode) = ''
        THEN 'No Coupon'
        ELSE CouponCode
    END AS CouponCode,
    ReferralSource,
    TotalPrice
FROM sales;


-- Total number of products
select Product,sum(quantity) as quantity_sold from sales_cleaned
group by Product
order by  quantity desc;

-- Chair	562
-- Printer	542
-- Laptop	535
-- Desk	    508
-- Tablet	497
-- Monitor	480
-- Phone	411

-- Chair has the large number of solds and phone has the lowest number of sold.
-- there are three quantities that sold below 500 tablet,Monitor,phone.
-- 
-- revenue by products

select product,round(sum(TotalPrice),2) as Total_Sales from sales_cleaned
group by product
order by Total_Sales desc;

-- Chair	195620.11
-- Printer	195612.61
-- Laptop	192126.56
-- Tablet	186568.95
-- Monitor	175651.41
-- Desk	    167459.93
-- Phone	151722.39

-- Chair has the highest revenue among all the products and in top 3 products there is no such big difference in revenue
-- phone has the lowest revenue

-- Month over month 

with mom as (
select date_format(OrderDate,"%Y-%m") as Months , round(sum(TotalPrice),2) as Total_Sales from sales_cleaned
group by months) ,

trend as (
select * , lag(Total_sales,1) over (order by Months) as Previous_sales from mom)

select *, round((Total_sales-Previous_sales)/Previous_sales * 100,2) as Mom_trend from trend;


-- Key Findings:

-- Sales showed significant fluctuations throughout the period, indicating seasonal demand patterns and varying customer purchasing behavior.
-- The highest positive growth was recorded in June 2024 (+143.89%), where sales increased from 27,909.11 to 68,068.54.
-- Another strong growth period occurred in May 2023 (+130.03%), suggesting a major increase in orders or promotional activity.
-- The largest decline was observed in September 2023 (-45.68%), followed by May 2024 (-43.75%), indicating sharp drops in monthly revenue.
-- Sales recovered quickly after several declines, demonstrating resilience in overall business performance.
-- The latest months show a positive trend:
-- April 2025: -18.82%
-- May 2025: +36.38%
-- June 2025: +22.24%
-- Business Insight
-- The business experiences periods of rapid growth followed by sharp declines, suggesting the influence of seasonality, promotions, or changing customer demand.
-- Months with exceptional growth (May 2023, June 2024, October 2023) should be investigated to identify successful strategies that can be replicated.
-- Months with significant declines (September 2023, May 2024) should be analyzed further to understand potential causes such as reduced demand, inventory issues, or fewer marketing campaigns.
-- The positive growth in the most recent months indicates improving sales momentum.

-- Payment Method

select PaymentMethod, count(*) as total_payments from sales_cleaned
group by PaymentMethod
order by total_payments desc;

-- Online	    258
-- Cash	        246
-- Credit Card	234
-- Debit Card	232
-- Gift Card	230

-- most number of payments were make through online then cash and 
-- peope also did payments by giftcards to take advantage of discount or cashback.alter


-- order status

select OrderStatus , count(*) as occurence from sales_cleaned
group by OrderStatus 
order by occurence desc;

-- Cancelled	250
-- Returned	   247
-- Pending	   237
-- Shipped	   235
-- Delivered	231

-- A high number of cancelled and returned orders is not a positive sign for the business.
-- Reducing cancellations and returns can help increase revenue and improve customer satisfaction.
-- The business should investigate the reasons behind these orders and take steps to minimize them.

-- Total CouponCode
select CouponCode , count(*) as Total_coupons from sales_cleaned
group  by CouponCode
order by Total_coupons desc;

-- FREESHIP	313
-- No coupon	309
-- WINTER15	292
-- SAVE10	286
-- Freeship has the large number of coupon and we create a no coupon for the null so that no coupon dominates the others but there are 
-- equal distribution of couponcode 

-- Total products sold by Coupon Code

WITH product_sales AS (
    SELECT
        CouponCode,
        Product,
        COUNT(*) AS Total_Sold,
        ROW_NUMBER() OVER (
            PARTITION BY CouponCode
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM sales_cleaned
    GROUP BY CouponCode, Product
)

SELECT
    CouponCode,
    Product,
    Total_Sold
FROM product_sales
WHERE rn <= 3
ORDER BY CouponCode, Total_Sold DESC;

-- Printers and Tablets are the most popular products across multiple coupon categories,
-- while different coupon codes show different product preferences, helping the business design targeted promotions.


-- Total referralsource
select ReferralSource , count(*) as Total_Referral from sales_cleaned
group  by ReferralSource
order by Total_Referral desc;

-- Instagram	259
-- Email	250
-- Google	241
-- Facebook	228
-- Referral	222

-- Instagram is the top referral source with 259 orders, 
-- followed by Email and Google, indicating that social media and digital marketing channels are driving most customer traffic and sales.

-- Total products sold by referralsource 

WITH product_sales AS (
    SELECT
        ReferralSource,
        Product,
        COUNT(*) AS Total_Sold,
        ROW_NUMBER() OVER (
            PARTITION BY ReferralSource
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM sales_cleaned
    GROUP BY ReferralSource, Product
)

SELECT
    ReferralSource,
    Product,
    Total_Sold
FROM product_sales
WHERE rn <= 3
ORDER BY ReferralSource, Total_Sold DESC;

-- Instagram generated the highest orders, with Desk, Tablet, and Chair being the top-selling products. 
-- Printers performed strongly across Email, Facebook, and Google, while Referral traffic showed a preference for Laptops and Phones. 
-- This indicates that customer product preferences vary by marketing channel, which can help optimize targeted campaigns.

 -- SOME KPI'S
 
 select round(avg(TotalPrice),2) as AOV from sales_cleaned;
-- The Average Order Value (AOV) is ₹1,053.97, indicating that customers tend to make purchases of relatively high value,
-- which is a positive sign for business revenue.

select round(Sum(TotalPrice),2) as Total_revenue from sales_cleaned ;

-- Total Revenue generated from all the products 1264761.96

select sum(quantity) as Total_quantity from sales_cleaned ;

-- Total quantity sold 3535

select floor(avg(ItemsInCart)) as Avh_items_in_cart from sales_cleaned; 

-- Avg items in cart 5

-- Cancellation Rate

select 
sum(case when OrderStatus = "Cancelled" then 1 else 0 end)/count(*) *100 as Cancellation_rate from sales_cleaned;

-- cancellation rate is  higher 20.88 over all products

-- Return Rate

select 
sum(case when OrderStatus = "Returned" then 1 else 0 end)/count(*) *100 as Return_rate from sales_cleaned;
-- Return rate is 20.5833

-- By looking at the Total Quantity sold and revenue generated is good and customer spends high income as Aov is quite good and higher
-- Cancellation Rate and return rate is also higher which negatively impact the business revenue and overall growth
-- find the cause for this is reduce both cancellation return is important for the buisness for stability
-- the reason for cancellation should be anything like delays in delivery, product gets cheap after order, 
-- At the time of delivery maybe the person is not available, mistakenly order for fun and many more things
-- The reason for return maybe products quality is not good, customer is not satisfy with product , 
-- some customer uses the product and return it later, products mismatch.

-- Overall to improve the revenue and growth we reduce the cancellation and return rate so that it doesn't effect the buisness negatively.

-- Products with high cancellation 

select Product , OrderStatus , count(*) as Total_Cancellation from sales_cleaned
where OrderStatus = "Cancelled"
group by  Product , OrderStatus
order by Total_Cancellation desc;

-- Chair	Cancelled	45
-- Printer	Cancelled	35
-- Monitor	Cancelled	35
-- Laptop	Cancelled	35
-- Desk	   Cancelled   35
-- Tablet	Cancelled	34
-- Phone	Cancelled	31

-- Chair has the largest Number of Cancellations and mobile has the lowest 
--  only chair has over 40 cancellation i.e., 45 other than that every product has between 30-35

-- The reason for the chair cancellation maybe that people find cheaper than online price, chair is big in size maybe customer thinks 
-- that the chair get damaged so they cancelled it and in electronics people sometimes not believe in quality of the product
-- which ordered online due to scams. To reduce cancellations, the business can provide genuine customer reviews, 
-- product warranties, detailed product descriptions, and secure delivery assurances."


-- -- Products with high  returns

select Product , OrderStatus , count(*) as Total_Cancellation from sales_cleaned
where OrderStatus = "Returned"
group by  Product , OrderStatus
order by Total_Cancellation desc;

-- Tablet	Returned	43
-- Laptop	Returned	39
-- Printer	Returned	38
-- Monitor	Returned	36
-- Desk	Returned	    32
-- Phone	Returned	31
-- Chair	Returned	28

-- Electronics products have the highest number of returns, which may be due to 
-- customer dissatisfaction, product mismatches, quality issues, or damage during delivery.
-- In contrast, chairs have the lowest return rate. To reduce returns, the seller should ensure product quality, 
-- provide accurate product descriptions, and verify that products match customer expectations before shipping.

-- contribution of ReferralSource in cancellation

select ReferralSource, count(*) as Total_cancellation from sales_cleaned
where OrderStatus = "Cancelled"
group by ReferralSource
order by Total_cancellation desc;

-- Email	    59
-- Google	    58
-- Referral 	50
-- Facebook 	42
-- Instagram	41

-- Email and Google has the highest number of cancellation 
-- Instagram and facebook have the less

-- contribution of Couponcode in cancellation

select CouponCode, count(*) as Total_cancellation from sales_cleaned
where OrderStatus = "Cancelled"
group by CouponCode
order by Total_cancellation desc;

-- FREESHIP	67
-- WINTER15	67
-- No coupon	58
-- SAVE10	58

-- Their is equal contribution of cancellation in the coupon code by all the coupons. But still coupon code might aslo be the 
-- reason for cancellations

-- contribution of ReferralSource in Return

select ReferralSource, count(*) as Total_cancellation from sales_cleaned
where OrderStatus = "Returned"
group by ReferralSource
order by Total_cancellation desc;


-- Facebook	56
-- Instagram	55
-- Email	49
-- Referral	44
-- Google	43

-- There are no such huge different in cancellation by all the sources but facebook and instagram has the high number of cancellation
-- that might be because there are many fake sellers over internet so people just order by clicking the add and they liked the product and order it
-- and after that they cancelled the product at the time of delievery beacuse most of the orders which customer orders from internet they might be not 
-- found them again after order so this might be a one reason.

-- contribution of Couponcode in Return

select CouponCode, count(*) as Total_return from sales_cleaned
where OrderStatus = "Returned"
group by CouponCode
order by Total_return desc;

-- No coupon	76
-- WINTER15	63
-- FREESHIP	61
-- SAVE10	47

-- No coupon has the highest number of returns , most of the return has reasons that customer not find it good,
-- product mismatch , quality issue, anything which is not good in customer's point of view.


-- Revenue loss by cancellation
select Product , round(sum(TotalPrice),2) as revenue from sales_cleaned
where OrderStatus = "Cancelled"
group by Product
order by revenue desc;

-- Chair contributed the highest cancelled order value (₹48,660.98), followed by Laptop and Tablet. These products 
-- account for the largest share of potential revenue loss from cancellations and should be analyzed further to identify the underlying causes.


-- Revenue loss by Returns
select Product , round(sum(TotalPrice),2) as revenue from sales_cleaned
where OrderStatus = "Returned"
group by Product
order by revenue desc;



-- Tablet contributed the highest returned order value (₹42,525.86), followed by Monitor (₹40,524.60) and Laptop (₹39,654.30). 
-- These products account for the largest share of potential revenue loss due to returns and
--  may require further investigation into product quality, customer expectations, or delivery-related issues.

-- One interesting observation:

-- Chair had the highest cancellation revenue loss (₹48,660.98).
-- Tablet had the highest return revenue loss (₹42,525.86).

-- This suggests:

-- Customers tend to cancel Chairs before receiving them.
-- Customers tend to return Tablets after receiving them.

-- Revenue by Referral Source
select ReferralSource , round(sum(TotalPrice),2) as revenue from sales_cleaned
group by ReferralSource
order by revenue desc;

-- Instagram	275285.45
-- Email	261808.55
-- Google	250441.48
-- Facebook	250410.9
-- Referral	226815.58
-- Insta is the only platform through which highest revenue generated from any referral and
-- other than this all other referral have similiar revenue

-- Revenue by Coupon Code
select CouponCode , round(sum(TotalPrice),2) as revenue from sales_cleaned
group by CouponCode
order by revenue desc;

-- FREESHIP	335036.99
-- No coupon	322401.41
-- SAVE10	304840.02
-- WINTER15	302483.54

-- freeship Has the highest revenue Because kost of the people order the itmes and after delievery the charges are getting little higher 
-- so if their is no shiping charges people might order more. But here are the almost same revenue generated by all the coupon more than 30000
 

-- Monthly Cancellation Trend
with mom as (
select date_format(OrderDate,"%Y-%m") as Months , count(*) as Total_Cancellation from sales_cleaned
where OrderStatus = "Cancelled"
group by Months),
trend as (
select Months , Total_Cancellation , lag(Total_Cancellation) over(order by Months) as Previous_month_cancellation
from mom)
select Months,Total_Cancellation,Previous_month_cancellation,
(Total_Cancellation-Previous_month_cancellation)/Previous_month_cancellation * 100 as Cancellation_trend 
from trend;

-- Cancellations are highly fluctuating, with no consistent upward or downward trend.
-- June is a recurring high-cancellation month, peaking at 14 cancellations in June 2025.
-- The lowest cancellations were recorded in May 2024 and September 2024 (4 each).
-- 2025 shows an increasing cancellation trend, rising from 5 in January to 14 in June.
-- Large month-over-month spikes suggest possible issues related to seasonality, promotions, delivery delays, or customer satisfaction.



-- Monthly Return Trend
with mom as (
select date_format(OrderDate,"%Y-%m") as Months , SUM(TotalPrice) as Total_Revenue from sales_cleaned
group by Months),
trend as (
select * , lag(Total_Revenue) over(order by Months) as Previous_Month_Revenue from mom)

select Months , round(Total_Revenue,2) as Total_Revenue ,round(Previous_Month_Revenue,2) as Previous_Month_Revenue, round((Total_Revenue-Previous_Month_Revenue) /Previous_Month_Revenue * 100,2)as Monthly_Trend
from trend; 

-- Revenue shows significant month-to-month fluctuations, indicating seasonal demand and varying sales performance.
-- June 2024 recorded the highest revenue at ₹68,068.54, followed by May 2023 (₹63,836.84).
-- April 2023 recorded the lowest revenue at ₹27,751.71.
-- The largest revenue increase occurred in June 2024 (+143.89%), while the sharpest decline occurred in September 2023 (-45.68%).
-- Revenue in 2025 shows a positive recovery trend, increasing from ₹29,099 in January to ₹53,047 in June.
-- Revenue spikes in May–June suggest a potential seasonal peak period that can be leveraged through targeted marketing and inventory planning.

-- Top 5 Customers by Spending
select CustomerID, sum(TotalPrice) as Total_Revenue from sales_cleaned
group by CustomerID
Order by Total_Revenue desc
limit 5;
-- C38840	5723.23
-- C57276	3456.4
-- C67260	3390.8
-- C13877	3384.9
-- C18404	3370.2

-- Revenue Lost Due to Cancellations and Returns
select round(sum(TotalPrice),2) as Total_Revenue from sales_cleaned
where OrderStatus in ("Cancelled","Returned");

-- Total Revenue lost by the seller by the cancellation and Returns is 519673.91
SELECT
    ROUND(
        SUM(CASE
                WHEN OrderStatus IN ('Cancelled','Returned')
                THEN TotalPrice
                ELSE 0
            END) * 100.0 / SUM(TotalPrice),
        2
    ) AS Lost_Revenue_Percentage
FROM sales_cleaned;

-- Around 41.09% of total revenue is lost due to cancellations and returns. 
-- This is quite high and suggests the business should focus on reducing these orders to improve profits and achieve more stable growth.



-- Business Recomendations

-- The business has generated ₹1.26 million in total revenue with a healthy Average Order Value of ₹1,053.97, indicating strong customer spending.
-- However, the company's biggest challenge is the high number of cancellations and returns, which account for 41.09% of total revenue loss. 
-- Reducing these losses should be the top priority, as even a small improvement can significantly increase profitability.

-- The business should pay special attention to Chairs, which contribute the highest cancellation-related revenue loss, and Tablets, 
-- which contribute the highest return-related revenue loss. Investigating product quality, customer expectations, delivery performance, 
-- and product information for these products can help reduce future losses.

-- From a marketing perspective, Instagram is the strongest-performing referral source, generating the highest revenue and order volume. 
-- The company should continue investing in this channel and replicate successful strategies across other marketing platforms. 
-- Additionally, the FREESHIP coupon generated the highest revenue, suggesting that similar promotional campaigns can be effective in driving sales.

-- The analysis also shows that revenue tends to peak during May and June, indicating a seasonal opportunity. 
-- The business should ensure sufficient inventory, marketing efforts, and operational readiness during these periods to maximize revenue. 
-- Furthermore, cancellations are fairly evenly distributed across coupon codes, suggesting that coupons are not the primary cause of cancellations
--  and that greater focus should be placed on product and operational improvements.

-- Overall, the business should focus on reducing cancellations and returns, improving the performance of high-loss products, 
-- leveraging successful marketing channels such as Instagram, and expanding effective promotional strategies to improve profitability 
-- and achieve sustainable growth.