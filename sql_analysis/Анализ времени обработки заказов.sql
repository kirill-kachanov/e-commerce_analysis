-- 1. Анализ времени обработки заказов
-- 1.1 Среднее время от заказа до доставки по месяцам.
SELECT TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month,
	   COUNT(*) number_of_orders,
	   ROUND(AVG(EXTRACT (EPOCH FROM order_delivered_customer_date - order_purchase_timestamp) / 86400), 2) avg_delivery_time
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
ORDER BY year_month;

-- 1.2 Анализ задержек доставки: средняя и медианная величина, процент задержек, отличие медианы в каждой категории от общей медианы.
-- Объединение таблиц для удобства дальнейшей работы
WITH order_items_products AS (	
	SELECT ooi.order_id, 
	   	   op.product_category_name
    FROM olist_order_items ooi
    JOIN olist_products op 
	ON ooi.product_id = op.product_id
    GROUP BY ooi.order_id, op.product_category_name
),
-- Считаем медианную задержку товара
ttl_median_delay AS (
SELECT ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM oo.order_delivered_customer_date - oo.order_estimated_delivery_date))::numeric / 86400, 2) ttl_median_delay
FROM olist_orders oo
JOIN order_items_products oip
ON oo.order_id = oip.order_id
WHERE oo.order_status = 'delivered' -- Используем только доставленные заказы, так как другие статусы способны исказить значения
AND oo.order_estimated_delivery_date < oo.order_delivered_customer_date
)
-- Итоговый результат
SELECT oip.product_category_name,
	   ROUND(AVG(EXTRACT(EPOCH FROM oo.order_delivered_customer_date - oo.order_estimated_delivery_date)) / 86400, 2) avg_delay,
	   ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM oo.order_delivered_customer_date - oo.order_estimated_delivery_date))::numeric / 86400, 2) median_delay,
	   ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM oo.order_delivered_customer_date - oo.order_estimated_delivery_date))::numeric / 86400 - 
	   (SELECT ttl_median_delay FROM ttl_median_delay), 2) deviation_from_the_overall_median,
	   COUNT(oo.order_id) number_of_delays,
	   ROUND(COUNT(oo.order_id) * 100 / SUM(COUNT(*)) OVER(), 2) percent_of_delays	   
FROM olist_orders oo
JOIN order_items_products oip
ON oo.order_id = oip.order_id
WHERE oo.order_status = 'delivered'
AND oo.order_estimated_delivery_date < oo.order_delivered_customer_date
GROUP BY oip.product_category_name
