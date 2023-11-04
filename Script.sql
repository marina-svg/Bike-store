-- 1a What store has the most number of orders, ordered quantity , revenue and discount  in total?
select  s.store_name,
       count(distinct o.order_id) as order_amount,
       sum(oi.quantity) as quantity_amount,
       round(sum(oi.list_price * oi.quantity),2) as turnover,
       round(sum(oi.quantity*(oi.list_price/(100-oi.discount)*oi.discount)),2) as total_discount_sum
from orders o join stores s on  o.store_id = s.store_id
join order_items oi on o.order_id = oi.order_id
group by s.store_name
order by order_amount desc
;


-- What store has the most revenue,  number of orders , quantity of ordered items, discount via timeframe?

select o.order_date,
       s.store_name,
       count( distinct o.order_id) as order_amount,
       sum(oi.quantity) as quantity_amount,
       round(sum(oi.list_price * oi.quantity),2) as turnover,
       round(sum(oi.quantity*(oi.list_price/(100-oi.discount)*oi.discount)),2) as total_discount_sum
from orders o join stores s on  o.store_id = s.store_id
join order_items oi on o.order_id = oi.order_id
group by o.order_date, s.store_name
order by o.order_date asc
;

-- -- What store has the most revenue, number of orders, quantity of ordered items, discount per month?

select date_format (o.order_date, '%Y-%m') as time_period,
       s.store_name,
	   count(distinct o.order_id) as order_amount,
       sum(oi.quantity) as quantity_amount,
       round(sum(oi.list_price * oi.quantity),2) as turnover,
       round(sum(oi.quantity*(oi.list_price/(100-oi.discount)*oi.discount)),2) as total_discount_sum
from orders o join stores s on  o.store_id = s.store_id
join order_items oi on o.order_id = oi.order_id
group by time_period, s.store_name
order by time_period asc
;

-- statistics of ammount of ordered items and turnover and prices per states and cities.

select c.customer_id,  
count(distinct o.order_id) as amount_of_orders, 
sum(oi.quantity) as amount_of_ordered_items, 
round(sum(oi.quantity*oi.list_price),2) as sums_of_orders, 
c.state, 
c.city from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id=oi.order_id
group by c.customer_id,  c.state, c.city
order by amount_of_orders desc;




-- If byers made more than 1 buy and in which store?

with cte as (
    select
     order_id,
     sum( quantity) as total_ordered,
    case when sum( quantity) = 1 then 'small size'
         when sum( quantity) >= 2 and sum( quantity) <=5 then 'medium size'
         else 'big size' end as order_size
from order_items
group by order_id
order by total_ordered desc
) select  s.store_name, c.order_size, count(c.order_size) as amount_of_orders from cte c
join orders o on c.order_id= o.order_id
join stores s on o.store_id=s.store_id
group by  s.store_name, c.order_size
order by s.store_name
;

 -- can make one table with repeat buyers CaTEGORIES OF BUYESR BY REPET AND AMOUNT OF SPENT MONEY.
 


 with cte as (select oo.customer_id,round(sum(oi.quantity*oi.list_price),2) as sum_of_purchase from order_items oi
 join orders oo on oi.order_id = oo.order_id
 group by oo.customer_id)
 select o.customer_id, count(o.order_id) as num_of_purchases,
 if (count(o.order_id) = 1, 'One time buyer', 'Repeated_buyer') as buyer_type,
  case when c.sum_of_purchase < 3000 then 'Low cost order <3000'
	   when c.sum_of_purchase > 3000 and c.sum_of_purchase < 15000 then 'Medium cost order between 3000 and 15000'
       else 'High cost order > 15000' end as order_type
 from  cte c join orders o on c.customer_id =o.customer_id
-- group by o.customer_id, c.first_name, c.last_name, c.city, c.state
group by o.customer_id
;
 


 
 
-- Statistics of shipped on time/late orders? which store has most late orders?



with cte as (select  s.store_name, o.shipped_date, o.required_date,
       case when o.shipped_date > o.required_date then 'late delivery'
       when o.shipped_date <= o.required_date then  'on time delivery' 
       else 'no information' end as delivery_status
 from orders o join stores s on o.store_id = s.store_id
  )
 select store_name, delivery_status, count(delivery_status) as num_of_status
        from cte
        where delivery_status = 'late delivery' or delivery_status = 'on time delivery'
group by store_name, delivery_status
order by store_name;


Create view Delivery_status_table as (select  o.store_id, s.store_name, o.shipped_date, o.required_date,
       case when o.shipped_date > o.required_date then 'late delivery'
       when o.shipped_date <= o.required_date then  'on time delivery' 
       else 'no information' end as delivery_status
 from orders o
 join stores s on s.store_id = o.store_id)
 ;
 
 

drop function if exists KPI_result;
delimiter $$
create function KPI_result( p_store text, p_delivery_status text) returns decimal(10,2)
deterministic
Begin
declare v_count_del_status  decimal(10,2);
declare v_total_del_status decimal(10,2);
declare KPI decimal(10,2);

 select count(delivery_status) into v_count_del_status  from Delivery_status_table 
 where (p_delivery_status = delivery_status ) and
 (p_store = store_name)
;
 
 select count(delivery_status) into v_total_del_status from Delivery_status_table 
 where (delivery_status = 'late delivery' or delivery_status = 'on time delivery')
 and (p_store = store_name);
set  KPI = round((v_count_del_status/v_total_del_status)*100,2);
return kpi;
end$$
delimiter ;

select BikeStore.KPI_result('Rowlett Bikes','late delivery') as KPI;

-- table with KPI results

create table KPIResults (
store_id int,
store_name text,
kpi decimal(10,2)
);
insert into KPIResults(store_id, store_name, kpi) 
VALUES (1, 'Santa Cruz Bikes',  BikeStore.KPI_result('Santa Cruz Bikes','on time delivery')),
	   (2, 'Baldwin Bikes', BikeStore.KPI_result('Baldwin Bikes','on time delivery')),
	   (3, 'Rowlett Bikes', BikeStore.KPI_result('Rowlett Bikes','on time delivery'));

SELECT * FROM KPIResults;


-- Which manager has most of orders? most of revenue? most orederd items?


with cte as (select order_id, 
			sum(quantity) as total_ordered, 
            sum(quantity*list_price) as revenue from order_items
			group by order_id)
select o.staff_id, st.first_name, st.last_name,  
count(c.order_id) as num_of_orders, 
sum(c.total_ordered) as total_ordred_items, 
round(sum(c.revenue),2) as total_revenue from cte c 
		join orders o on c.order_id = o.order_id join
		staffs st on o.staff_id = st.staff_id
		group by o.staff_id, st.first_name, st.last_name;


-- Which brand of bicycle is the most popular? name of bycycle? model year? category?

create view ordered_products as (
with cte as (  select product_id,
			sum(quantity) as total_ordered,
            round(sum(quantity*list_price),2) as revenue_item
            from order_items
            group by product_id)
				select c.product_id, p.product_name, b.brand_name, c.category_name, p.model_year, c.total_ordered, c.revenue_item
                from cte c 
				join products p on c.product_id = p.product_id
                join brands b on p.brand_id=b.brand_id
                join categories c on c.category_id=p.category_id)
			;
select * from ordered_products;
-- !! can add comparison with average price of brand/category bla bla with max and min price/avg price via all bikes

select brand_name, sum(total_ordered) as total_ordered, round(sum(revenue_item),2) as total_brand_revenue from ordered_products
group by brand_name
order by total_ordered desc;

select product_name, sum(total_ordered) as total_ordered, round(sum(revenue_item),2) as total_product_revenue from ordered_products
group by product_name
order by total_ordered desc;  

select model_year, sum(total_ordered) as total_ordered, round(sum(revenue_item),2) as total_model_year_revenue from ordered_products
group by model_year
order by total_ordered desc; 

select category_name, sum(total_ordered) as total_ordered, round(sum(revenue_item),2) as total_category_revenue from ordered_products
group by category_name
order by total_ordered desc;          

select brand_name, category_name, product_name, model_year,
sum(total_ordered) over (partition by brand_name ) as orders_per_brand,
sum(total_ordered) over (partition by category_name ) as orders_per_category,
sum(total_ordered) over (partition by product_name ) as orders_per_perduct,
sum(total_ordered) over (partition by model_year ) as orders_per_model
from ordered_products;


 


