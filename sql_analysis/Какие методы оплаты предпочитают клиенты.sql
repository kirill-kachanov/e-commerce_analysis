-- 5. Какие методы оплаты предпочитают клиенты?
-- 5.1 Какие платежные методы используют чаще всего?
-- Итоговый результат. Считаем количество использований того или иного вида оплаты,
-- а также процент каждого способа от общего числа
SELECT oop.payment_type, 
	   COUNT(*) number_of_payments,
	   ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 2) percent_of_payments
FROM olist_order_payments oop
JOIN olist_orders oo
ON oop.order_id = oo.order_id
WHERE oo.order_status NOT IN ('canceled', 'unavailable')
GROUP BY oop.payment_type
ORDER BY number_of_payments DESC;

-- 5.2 Есть ли разница в среднем чеке в зависимости от способа оплаты?
-- Объединение таблиц для удобства дальнейшей работы
WITH order_items_grouped AS (
	SELECT order_id,
		   SUM(price) ttl_price, 
		   SUM(freight_value) ttl_freight_value
	FROM olist_order_items
	GROUP BY order_id
)
-- Итоговый результат. Как и в прошлом запросе, считаем AOV как с учетом фрахта, так и без.
SELECT oop.payment_type,
	   COUNT(*) number_of_payments,
	   ROUND(AVG(oip.ttl_price), 2) aov_wo_freight,
	   ROUND(AVG(oip.ttl_price + oip.ttl_freight_value), 2) aov_w_freight
FROM olist_order_payments oop
JOIN olist_orders oo
ON oop.order_id = oo.order_id
JOIN order_items_grouped oip
ON oo.order_id = oip.order_id
WHERE oo.order_status NOT IN ('canceled', 'unavailable')
GROUP BY oop.payment_type
ORDER BY aov_w_freight DESC;