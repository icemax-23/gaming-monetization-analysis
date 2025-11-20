/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Андрей Череповский
 * Дата: 23.03
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

       -- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT 
    COUNT(*) AS total_players, -- Общее количество игроков
    SUM(payer) AS paying_players, -- Количество платящих игроков
    AVG(payer) AS paying_players_percentage -- Доля платящих игроков
FROM 
    fantasy.users
WHERE 
    id IN (SELECT DISTINCT id FROM fantasy.events WHERE amount > 0); -- Учитываем только игроков с ненулевыми транзакциями
    
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT
    r.race AS race, -- Название расы
    SUM(u.payer) AS paying_players, -- Количество платящих игроков
    COUNT(u.id) AS total_players, -- Общее количество игроков
    ROUND(SUM(u.payer) * 1.0 / COUNT(u.id) * 100, 2) AS paying_players_percentage -- Доля платящих игроков
FROM
    fantasy.users u -- 
JOIN
    fantasy.race r ON u.race_id = r.race_id
GROUP BY
    r.race
ORDER BY
    paying_players_percentage DESC;
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT
    COUNT(*) AS total_purchases, -- Общее количество покупок
    ROUND(SUM(amount)::numeric, 2) AS total_amount, -- Суммарная стоимость всех покупок
    ROUND(MIN(amount)::numeric, 2) AS min_amount, -- Минимальная стоимость покупки
    ROUND(MAX(amount)::numeric, 2) AS max_amount, -- Максимальная стоимость покупки
    ROUND(AVG(amount)::numeric, 2) AS avg_amount, -- Среднее значение стоимости покупки
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS median_amount, -- Медиана стоимости покупки
    ROUND(STDDEV(amount)::numeric, 2) AS stddev_amount -- Стандартное отклонение стоимости покупки
FROM
    fantasy.events;
-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT 
    COUNT(amount) AS zero_amount_count, -- Абсолютное количество покупок с нулевой стоимостью
    ROUND((COUNT(amount)::numeric / (SELECT COUNT(*) FROM fantasy.events) * 100), 2) AS zero_amount_percentage -- Доля от общего числа покупок
FROM 
    fantasy.events 
WHERE 
    amount = 0;
-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
SELECT
    CASE
        WHEN u.payer = 1 THEN 'Платящие игроки'
        WHEN u.payer = 0 THEN 'Неплатящие игроки'
    END AS player_category, -- Категория игроков
    COUNT(DISTINCT u.id) AS total_players, -- Общее количество игроков, совершивших покупки
    ROUND(AVG(purchase_count)::numeric, 2) AS avg_purchases_per_player, -- Среднее количество покупок на игрока
    ROUND(AVG(total_amount)::numeric, 2) AS avg_total_amount_per_player -- Средняя суммарная стоимость покупок на игрока
FROM
    fantasy.users u
INNER JOIN (
    SELECT
        id,
        COUNT(*) AS purchase_count, -- Количество покупок для каждого игрока
        SUM(amount) AS total_amount -- Суммарная стоимость покупок для каждого игрока
    FROM
        fantasy.events
    WHERE
        amount > 0 -- Исключаем нулевые транзакции
    GROUP BY
        id
) e ON u.id = e.id
GROUP BY
    u.payer;
-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
SELECT
    i.game_items AS epic_item, -- Название эпического предмета
    COUNT(e.item_code) AS total_sales, -- Общее количество продаж
    ROUND(COUNT(e.item_code)::numeric / (SELECT COUNT(*) FROM fantasy.events) * 100, 2) AS sales_percentage, -- Доля продаж от всех продаж
    ROUND(COUNT(DISTINCT e.id)::numeric / (SELECT COUNT(DISTINCT id) FROM fantasy.events) * 100, 2) AS players_percentage -- Доля игроков, купивших предмет
FROM
    fantasy.items i
LEFT JOIN
    fantasy.events e ON i.item_code = e.item_code
GROUP BY
    i.game_items
ORDER BY
    players_percentage DESC; -- Сортировка по популярности среди игроков
-- Часть 2. Решение ad hoc-задач
--2.1
SELECT
    r.race AS race, -- Название расы
    COUNT(DISTINCT u.id) AS total_players, -- Общее количество зарегистрированных игроков
    COUNT(DISTINCT e.id) AS players_with_purchases, -- Количество игроков, совершивших покупки
    ROUND(COUNT(DISTINCT e.id)::numeric / COUNT(DISTINCT u.id) * 100, 2) AS players_with_purchases_percentage, -- Доля игроков, совершивших покупки
    ROUND(SUM(u.payer) FILTER (WHERE e.id IS NOT NULL)::numeric / COUNT(DISTINCT e.id) * 100, 2) AS paying_players_percentage, -- Доля платящих игроков среди совершивших покупки
    ROUND(AVG(purchase_count)::numeric, 2) AS avg_purchases_per_player, -- Среднее количество покупок на одного игрока
    ROUND((SUM(total_lepestki_spent) / SUM(purchase_count))::numeric, 2) AS avg_lepestki_spent_per_purchase, -- Среднее количество «райских лепестков», потраченных за одну покупку
    ROUND(AVG(total_lepestki_spent)::numeric, 2) AS avg_total_lepestki_spent_per_player -- Среднее количество «райских лепестков», потраченных на одного игрока
FROM
    fantasy.race r
LEFT JOIN
    fantasy.users u ON r.race_id = u.race_id
LEFT JOIN (
    SELECT
        id,
        COUNT(*) AS purchase_count, -- Количество покупок для каждого игрока
        SUM(amount) AS total_lepestki_spent -- Суммарное количество «райских лепестков», потраченных каждым игроком
    FROM
        fantasy.events
    GROUP BY
        id
) e ON u.id = e.id
GROUP BY
    r.race
ORDER BY
    race;
-- 2.2 
WITH purchase_intervals AS (
    SELECT
        id,
        date,
        EXTRACT(EPOCH FROM (date::timestamp - LAG(date::timestamp) OVER (PARTITION BY id ORDER BY date))) / 86400 AS days_between_purchases -- Интервал в днях
    FROM
        fantasy.events
    WHERE
        amount > 0 -- Исключаем покупки с нулевой стоимостью
),
player_purchases AS (
    SELECT
        id,
        COUNT(*) AS total_purchases, -- Общее количество покупок
        AVG(days_between_purchases) AS avg_days_between_purchases -- Средний интервал в днях
    FROM
        purchase_intervals
    GROUP BY
        id
    HAVING
        COUNT(*) >= 25 -- Учитываем только активных игроков
),
player_groups AS (
    SELECT
        id,
        total_purchases,
        avg_days_between_purchases,
        NTILE(3) OVER (ORDER BY total_purchases DESC) AS frequency_group -- Разделение на три группы
    FROM
        player_purchases
)
SELECT
    CASE
        WHEN frequency_group = 1 THEN 'высокая частота'
        WHEN frequency_group = 2 THEN 'умеренная частота'
        WHEN frequency_group = 3 THEN 'низкая частота'
    END AS frequency_category, -- Категория частоты
    COUNT(DISTINCT pg.id) AS total_players, -- Общее количество игроков
    COUNT(DISTINCT u.id) FILTER (WHERE u.payer = 1) AS paying_players, -- Количество платящих игроков
    ROUND(COUNT(DISTINCT u.id) FILTER (WHERE u.payer = 1)::numeric / COUNT(DISTINCT pg.id) * 100, 2) AS paying_players_percentage, -- Доля платящих игроков
    ROUND(AVG(pg.total_purchases), 2) AS avg_purchases_per_player, -- Среднее количество покупок на одного игрока
    ROUND(AVG(pg.avg_days_between_purchases), 2) AS avg_days_between_purchases -- Средний интервал в днях между покупками
FROM
    player_groups pg
LEFT JOIN
    fantasy.users u ON pg.id = u.id
GROUP BY
    frequency_group
ORDER BY
    frequency_group;
-- Привет Артем ! надеюсь все правильно 
