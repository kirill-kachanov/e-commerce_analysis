-- Бизнес-кейсы
--  1. Как регион влияет на покупки?
-- 1.1 Какие штаты заказывают больше всего?
SELECT customer_state, COUNT(*) total_orders
FROM olist_orders ord
RIGHT JOIN olist_customers cust -- Используем RIGHT JOIN, так как есть вероятность, что заказы были не из всех штатов
ON ord.customer_id = cust.customer_id
AND ord.order_status = 'delivered' -- Берем только эту категорию, так как от остальных заказов покупатели еще могут отказаться или заказ может быть не доставлен
GROUP BY customer_state
ORDER BY total_orders DESC;

-- 1.2 Какое среднее время доставки, процент задержек и процент отказов у каждого региона?
-- Соединение двух таблиц для удобства дальнейшей работы
WITH combined_orders_customers AS (
	SELECT * FROM olist_orders ord
	RIGHT JOIN olist_customers cust -- Используем RIGHT JOIN, так как есть вероятность, что заказы были не из всех штатов
	ON ord.customer_id = cust.customer_id 
),
-- Считаем среднее время доставки
avg_del_time AS (
	SELECT customer_state,
		   ROUND (AVG (EXTRACT (EPOCH FROM order_delivered_customer_date - order_purchase_timestamp)) / 86400, 2) avg_delivery_days
	FROM combined_orders_customers
	WHERE order_status = 'delivered'
	GROUP BY customer_state),
-- Считаем общее количество заказов с задержкой
total_delays AS (
	SELECT customer_state, 
		   COUNT(*) ttl_delays
	FROM combined_orders_customers
	WHERE order_estimated_delivery_date < order_delivered_customer_date
	AND order_status = 'delivered'
	GROUP BY customer_state),
-- Считаем общее количество заказов
total_orders AS (
	SELECT customer_state, 
		   COUNT(*) ttl_orders
	FROM combined_orders_customers
	WHERE order_status = 'delivered' -- Берем только эту категорию, так как от остальных заказов покупатели еще могут отказаться или заказ может быть не доставлен
	GROUP BY customer_state),
-- Процент задержек заказов в каждом регионе
delay_percentage AS (
	SELECT td.customer_state, 
		   ttl_delays, ttl_orders, 
		   ROUND((ttl_delays::numeric / ttl_orders) * 100, 2) delay_percentage
	FROM total_delays td
	JOIN total_orders tor
	ON td.customer_state = tor.customer_state),
-- Всего отменено заказов
total_cancellations AS (
	SELECT customer_state, 
		   COUNT(*) ttl_cancellations
	FROM combined_orders_customers
	WHERE order_status = 'canceled'
	GROUP BY customer_state),
-- Процент отмененных заказов в каждом регионе
cancellation_percentage AS (
	SELECT tor.customer_state,  
		   ROUND(COALESCE((ttl_cancellations::numeric / (ttl_cancellations + ttl_orders)) * 100, 0), 2) cancellation_percentage
	FROM total_cancellations tc
	RIGHT JOIN total_orders tor -- Используем RIGHT JOIN, так как отмены могли быть не во всех регионах
	ON tc.customer_state = tor.customer_state)
-- Итоговый результат
SELECT cp.customer_state,
	   avg_delivery_days,
	   delay_percentage,
	   cancellation_percentage
FROM avg_del_time adt
JOIN delay_percentage dp
ON adt.customer_state = dp.customer_state
JOIN cancellation_percentage cp
ON dp.customer_state = cp.customer_state;