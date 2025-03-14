# SQL Analysis for E-Commerce Dataset

Этот раздел содержит SQL-запросы для анализа данных из **Brazilian E-Commerce Public Dataset by Olist**. В нем представлены ключевые аналитические исследования, демонстрирующие навыки работы с SQL.

## Разделы анализа

### 1. Анализ времени обработки заказов
- Среднее время от заказа до доставки по месяцам.
- Анализ задержек доставки: средняя и медианная величина, процент задержек, отличие медианы в каждой категории от общей медианы.

### 2. Анализ продавцов
- Продавцы с наибольшим числом заказов.
- Продавцы с самыми низкими отзывами.

### 3. Как регион влияет на покупки?
- Топ-регионы по количеству заказов.
- Среднее время доставки и процент отказов по регионам.

### 4. Какие категории товаров выгоднее всего продавать?
- Категории с наибольшим средним чеком.
- Категории с наибольшим числом возвратов.

### 5. Какие методы оплаты предпочитают клиенты?
- Наиболее популярные платежные методы.
- Различия в среднем чеке в зависимости от способа оплаты.

### 6. Ранжирование товаров
- Топ-10 самых продаваемых товаров в каждой категории.
- Самые дорогие/дешевые категории (по среднему и медиане) (топ-3).

## Файлы
Каждый файл содержит SQL-запросы и комментарии, поясняющие логику анализа.

## Как использовать
1. Открыть SQL-файл с интересующим анализом.
2. Запустить запросы в **PostgreSQL** (рекомендуемая СУБД).
3. Анализировать полученные результаты.

**Примечание:** Датасет предварительно загружен в PostgreSQL, структура таблиц соответствует исходному формату Olist.
