-- 2. Ранжирование товаров
-- 2.1 Вывести топ-10 самых продаваемых товаров в каждой категории
-- Объединение таблиц и подсчет количества заказанных товаров 
WITH number_of_products AS (
	SELECT ooi.product_id,
		   COUNT(*) number_of_products
	FROM olist_orders oo
	JOIN olist_order_items ooi
	ON oo.order_id = ooi.order_id
	WHERE order_status NOT IN ('unavailable', 'canceled') -- Убираем из результата нерелевантные статусы заказа
	GROUP BY product_id
),
-- Ранжирование товаров в зависимости от их численности и категории
ranked_products AS (
	SELECT pcnt.product_category_name_english,
		   nop.product_id,
		   nop.number_of_products,
		   RANK () OVER (PARTITION BY pcnt.product_category_name_english ORDER BY nop.number_of_products DESC) product_rank
	FROM number_of_products nop
	JOIN olist_products op
	ON nop.product_id = op.product_id
	JOIN product_category_name_translation pcnt
	ON op.product_category_name = pcnt.product_category_name
)
-- Итоговый результат
SELECT product_category_name_english,
	   product_id,
	   number_of_products
FROM ranked_products
WHERE product_rank <= 10
ORDER BY product_category_name_english ASC, number_of_products DESC;
-- 2.2 Вывести самые дорогие/дешевые категории товаров (по 3 штуки) (по медиане и среднему).
-- Из-за специфики таблицы olist_order_items при которой в одном заказе могут быть несколько товаров из разных категорий,
-- я сначала считаю среднюю стоимость, группируя по номеру заказа и категории
WITH order_items_products AS (	
	SELECT ooi.order_id, 
	   	   op.product_category_name,
		   AVG(price) avg_price
    FROM olist_order_items ooi
    JOIN olist_products op 
	ON ooi.product_id = op.product_id
    GROUP BY op.product_category_name, ooi.order_id
),
-- Высчитываем среднее, медиану стоимости товаров в каждой категории, ранжируем их
ranked_categories AS (
	SELECT pcnt.product_category_name_english,
		   ROUND(AVG(avg_price), 2) avg_price,
		   ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_price)::numeric, 2) median_price,
		   RANK() OVER(ORDER BY AVG(avg_price) DESC) ranked_avg_price,
		   RANK() OVER(ORDER BY PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_price) DESC) ranked_median_price
	FROM order_items_products oip
	JOIN olist_orders oo
	ON oip.order_id = oo.order_id
	LEFT JOIN product_category_name_translation pcnt
	ON oip.product_category_name = pcnt.product_category_name
	GROUP BY pcnt.product_category_name_english
)
-- Итоговый результат
SELECT product_category_name_english,
	   avg_price,
	   NULL AS median_price,
	   'average' category_type -- Добавляем категорию, по которой выводим топ-3 с начала и конца
FROM ranked_categories
WHERE ranked_avg_price <= 3
OR ranked_avg_price > ((SELECT COUNT(*) FROM ranked_categories) - 3)

UNION

SELECT product_category_name_english,
	   NULL AS avg_price,
	   median_price,
	   'median' category_type -- Добавляем категорию, по которой выводим топ-3 с начала и конца
FROM ranked_categories
WHERE ranked_median_price <= 3
OR ranked_median_price > ((SELECT COUNT(*) FROM ranked_categories) - 3)
ORDER BY category_type, avg_price DESC, median_price DESC