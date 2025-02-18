-- 3. Анализ продавцов
-- 3.1 Какие продавцы генерируют больше всего заказов?
SELECT os.seller_id,
	   COUNT(DISTINCT oo.order_id) number_of_orders
FROM olist_order_items ooi
JOIN olist_sellers os
ON ooi.seller_id = os.seller_id
JOIN olist_orders oo
ON ooi.order_id = oo.order_id
WHERE oo.order_status NOT IN ('canceled', 'unavailable') -- Считаем только релевантные заказы
GROUP BY os.seller_id
ORDER BY number_of_orders DESC
LIMIT 10 -- Для наглядности выводим продавцов с количеством заказов более 1000;
-- 3.2 Какие продавцы имеют наиболее низкие оценки?
SELECT os.seller_id,
	   ROUND(AVG(oor.review_score), 2) avg_review_score,
	   COUNT(DISTINCT oo.order_id) number_of_orders
FROM olist_order_items ooi
JOIN olist_sellers os
ON ooi.seller_id = os.seller_id
JOIN olist_orders oo
ON ooi.order_id = oo.order_id
JOIN olist_order_reviews oor
ON ooi.order_id = oor.order_id
WHERE oo.order_status NOT IN ('canceled', 'unavailable') -- Считаем только релевантные заказы
GROUP BY os.seller_id
HAVING COUNT(DISTINCT oor.order_id) >= 50 -- Отсеиваем продавцов с небольшим количеством заказов
ORDER BY avg_review_score ASC
LIMIT 5 -- Для наглядности выводим продавцов с оценкой ниже 3.0