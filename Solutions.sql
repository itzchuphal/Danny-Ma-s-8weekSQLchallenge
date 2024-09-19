-- Solution



/*
What is the total amount each customer spent at the restaurant?
*/


select s.customer_id, sum(m.price) as total_purchase
from sales s 
join menu m on s.product_id = m.product_id
group by s.customer_id
order by 2 desc;


/*
How many days has each customer visited the restaurant?
*/


with cte as 
		(select *
		, dense_rank() over(partition by customer_id order by order_date) as rnk
		from sales)
select customer_id, max(rnk) as no_of_days
from cte 
group by customer_id;


/*
What was the first item from the menu purchased by each customer?
*/


with cte as 
		(select *
		, rank() over(partition by customer_id order by order_date ) as rnk
		from sales),
	 cte2 as 
	    (select cte.customer_id, m.product_id, m.product_name
		, row_number() over(partition by customer_id) as rn
		from cte 
		join menu m on cte.product_id = m.product_id
		where cte.rnk = 1
		order by cte.customer_id desc)
select customer_id, product_name
from cte2
where rn = 1
order by 1;


/*
What is the most purchased item on the menu and how many times was it purchased by all customers?
*/


with cte as 
		(select m.product_name, count(1) as total_order
		, rank() over(order by count(1) desc) as rnk
		from sales s 
		join menu m on m.product_id = s.product_id
		group by m.product_name)
select product_name, total_order
from cte
where rnk = 1;


/*
Which item was the most popular for each customer?
*/


with cte as
		(select customer_id, product_id, count(1)
		, rank() over(partition by customer_id order by count(1) desc) as rk
		from sales
		group by customer_id, product_id)
select cte.customer_id, m.product_name
from cte 
join menu m on cte.product_id = m.product_id
where rk = 1
order by 1;


/*
Which item was purchased first by the customer after they became a member?
*/


with cte as
		(select s.*
		, rank() over(partition by s.customer_id order by s.order_date ) as rk
		from sales s
		join members m on s.customer_id = m.customer_id 
		where s.order_date > m.join_date)
select cte.customer_id, m.product_name as first_order_as_member
from cte 
join menu m on cte.product_id = m.product_id
where rk = 1
order by 1;


/*
Which item was purchased just before the customer became a member?
*/


with cte as 
		(select s.*
		, rank() over(partition by s.customer_id order by s.order_date desc) as rk
		from sales s
		join members m on s.customer_id = m.customer_id 
		where s.order_date < m.join_date)
select cte.customer_id, m.product_name
from cte 
join menu m on m.product_id = cte.product_id
where rk = 1
order by 1;


/*
What is the total items and amount spent for each member before they became a member?
*/


select s.customer_id, count(1) as total_items, sum(mu.price) as total_amount
from sales s
join members m on s.customer_id = m.customer_id 
join menu mu on mu.product_id = s.product_id
where s.order_date < m.join_date
group by s.customer_id
order by 1;


/*
If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
*/


with cte as 
		(select s.customer_id, s.product_id, sum(m.price) as total_amount
		from sales s
		join menu m on s.product_id = m.product_id
		group by s.customer_id, s.product_id),
	 cte2 as	
	 	(select cte.customer_id, cte.product_id, m.product_name, m.price, total_amount
		, case when m.product_name = 'sushi' then cte.total_amount*2 else 0 end as sushi_point
		, (total_amount*10 + case when m.product_name = 'sushi' then cte.total_amount*2 else 0 end) as total_points
		from cte
		join menu m on cte.product_id = m.product_id)
select customer_id, sum(total_points)
from cte2
group by customer_id


/*
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?
*/


with cte as 
		(select s.customer_id, menu.price*10*2 as member_points
		from sales s 
		join menu on menu.product_id = s.product_id
		join members m on s.customer_id = m.customer_id
		where order_date between join_date and join_date + 7)
select customer_id, sum(member_points) as total_points
from cte
group by customer_id;


/*
For every order placed by each customer, show the product name, product price.
Also show if the customer is a member or not at the time of placing the order.
*/


with cte as
		(select s.customer_id, s.order_date, m.product_name, m.price
		from sales s
		join menu m on s.product_id = m.product_id)
select cte.*
, case when cte.order_date >= mb.join_date then 'Y' else 'N' end as member
from cte
left join members mb on cte.customer_id = mb.customer_id
order by 1, 2


/*
Rank the orders of the members only from their joining date. 
When the order was placed and the customer was not a member at that time, then display null.
*/


with cte as
		(select s.customer_id, s.order_date, m.product_name, m.price
		from sales s
		join menu m on s.product_id = m.product_id),
	 cte2 as 
		(select cte.*
		, case when cte.order_date >= mb.join_date then 'Y' else 'N' end as member
		from cte
		left join members mb on cte.customer_id = mb.customer_id)
select *
, case when member = 'Y' then (rank() over(partition by customer_id, member order by order_date))
 end as ranking
from cte2
order by 1
		









