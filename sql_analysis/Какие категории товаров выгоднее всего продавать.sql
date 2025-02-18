-- 4. Какие категории товаров выгоднее всего продавать?
-- 4.1 Какие категории имеют максимальный средний чек?
-- Учитывая тот факт, что в таблицах olist_order_items, olist_order_payments данные о заказах могут не совпадать, то подойдем консервативно
-- и будем учитывать только те заказы, которые присутствуют в обеих таблицах.
-- Также из популяции исключим позиции, имеющие статус "canceled" и "unavailable", так как первые - это возвраты, а вторые имеют неизвестный статус.
-- Обе эти категории могут исказить размер среднего чека.
-- Обработаем таблицы для удобного объединения
WITH order_items_grouped AS (
	SELECT ooi.order_id, 
		   op.product_category_name, 
		   SUM(price) ttl_price, 
		   SUM(freight_value) ttl_freight_value
	FROM olist_order_items ooi
	JOIN olist_products op
	ON ooi.product_id = op.product_id
	GROUP BY order_id, product_category_name
),
-- Объединение таблиц для удобства дальнейшей работы
order_payments_grouped AS (
	SELECT order_id, 
		   SUM(payment_value) ttl_payment_value
	FROM olist_order_payments
	GROUP BY order_id
),
-- Считаем AOV без и с учетом стоимости фрахта
aov_categories AS (
	SELECT oig.product_category_name, 
		   ROUND(AVG(ttl_price), 2) aov_wo_freight, 
		   ROUND(AVG(ttl_price + ttl_freight_value), 2) aov_w_freight
	FROM olist_orders oo
	JOIN order_payments_grouped opg
	ON oo.order_id = opg.order_id
	JOIN order_items_grouped oig
	ON opg.order_id = oig.order_id
	WHERE order_status NOT IN ('canceled', 'unavailable')
	GROUP BY oig.product_category_name
)
-- Итоговый результат
SELECT pnt.product_category_name_english, 
	   ac.aov_wo_freight, 
	   ac.aov_w_freight
FROM aov_categories ac
LEFT JOIN product_category_name_translation pnt
ON ac.product_category_name = pnt.product_category_name
ORDER BY ac.aov_w_freight DESC;

-- 4.2 В каких категориях больше всего возвратов?
-- Объединение таблиц для удобства дальнейшей работы
WITH order_items_products AS (	
	SELECT ooi.order_id, 
	   op.product_category_name
    FROM olist_order_items ooi
    JOIN olist_products op 
	ON ooi.product_id = op.product_id
    GROUP BY ooi.order_id, op.product_category_name
),
-- Считаем общее количество заказов
category_orders AS (
    SELECT product_category_name, 
		   COUNT(*) total_orders
    FROM order_items_products
    GROUP BY product_category_name),
-- Считаем количество возвратов
category_cancellations AS (
    SELECT oip.product_category_name, 
		   COUNT(*) number_of_cancellations
    FROM order_items_products oip
    JOIN olist_orders oo 
	ON oip.order_id = oo.order_id
    WHERE oo.order_status = 'canceled'
    GROUP BY oip.product_category_name
)
-- Итоговый результат
SELECT cc.product_category_name,
       cc.number_of_cancellations,
       ROUND((cc.number_of_cancellations::numeric / co.total_orders) * 100, 2) AS percent_of_cancellations
FROM category_cancellations cc
JOIN category_orders co 
ON cc.product_category_name = co.product_category_name
ORDER BY percent_of_cancellations DESC, number_of_cancellations;