DROP TABLE IF EXISTS
    "TableName1",
    "TableName2",
    "TableName3",
    "OtherTable1",
    "OtherTable2";

DROP FUNCTION IF EXISTS test_function_1;
DROP FUNCTION IF EXISTS test_function_2;
DROP FUNCTION IF EXISTS test_function_3;
DROP FUNCTION IF EXISTS mytrigger_function;

DROP TRIGGER IF EXISTS mytrigger ON "TableName1";

-- Создание базы данных
-- CREATE DATABASE metadatabase;
CREATE SCHEMA IF NOT EXISTS public;

-- Создание таблицы TableName1
CREATE TABLE "TableName1"
(
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50),
    age  INT
);

-- Создание таблицы TableName2
CREATE TABLE "TableName2"
(
    id      SERIAL PRIMARY KEY,
    address VARCHAR(100),
    city    VARCHAR(50)
);

-- Создание таблицы TableName3
CREATE TABLE "TableName3"
(
    id    SERIAL PRIMARY KEY,
    email VARCHAR(100),
    phone VARCHAR(20)
);

-- Создание остальных таблиц
CREATE TABLE "OtherTable1"
(
    id          SERIAL PRIMARY KEY,
    description TEXT
);

CREATE TABLE "OtherTable2"
(
    id       SERIAL PRIMARY KEY,
    category VARCHAR(50),
    price    DECIMAL(10, 2)
);

-- Создание функции
-- Создание тестовых функций
CREATE OR REPLACE FUNCTION test_function_1(p_param1 integer, p_param2 text)
    RETURNS integer
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p_param1 + length(p_param2);
END;
$$;

CREATE OR REPLACE FUNCTION test_function_2(p_param1 date)
    RETURNS text
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN to_char(p_param1, 'YYYY-MM-DD');
END;
$$;

CREATE OR REPLACE FUNCTION test_function_3()
    RETURNS void
    LANGUAGE plpgsql
AS $$
BEGIN
    -- Функция без параметров
    NULL;
END;
$$;

-- Создание триггера
CREATE OR REPLACE FUNCTION mytrigger_function() RETURNS TRIGGER AS
$$
BEGIN
    -- Логика триггера
    -- Например, перед вставкой записи в таблицу TableName1
    IF NEW.price IS NULL THEN
        RAISE EXCEPTION '"price" cannot be a null';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mytrigger
    BEFORE INSERT
    ON "OtherTable2"
    FOR EACH ROW
EXECUTE FUNCTION mytrigger_function();

-- Заполнение таблицы TableName1
INSERT INTO "TableName1" (name, age)
VALUES ('John', 25),
       ('Alice', 30),
       ('Michael', 40),
       ('Emma', 27),
       ('David', 35);

-- Заполнение таблицы TableName2
INSERT INTO "TableName2" (address, city)
VALUES ('123 Main St', 'New York'),
       ('456 Elm St', 'Los Angeles'),
       ('789 Oak St', 'Chicago'),
       ('321 Pine St', 'San Francisco'),
       ('654 Maple St', 'Seattle');

-- Заполнение таблицы TableName3
INSERT INTO "TableName3" (email, phone)
VALUES ('john@example.com', '123-456-7890'),
       ('alice@example.com', '987-654-3210'),
       ('michael@example.com', '555-555-5555'),
       ('emma@example.com', '111-222-3333'),
       ('david@example.com', '999-888-7777');

-- Заполнение остальных таблиц
INSERT INTO "OtherTable1" (description)
VALUES ('Description 1'),
       ('Description 2'),
       ('Description 3'),
       ('Description 4'),
       ('Description 5');

INSERT INTO "OtherTable2" (category, price)
VALUES ('Category 1', 10.99),
       ('Category 2', 20.50),
       ('Category 3', 5.99),
       ('Category 4', 15.75),
       ('Category 5', 8.49);


-- -------------------------------------------------------------------------------------- --
-- 1) Создать хранимую процедуру, которая, не уничтожая базу данных, уничтожает все те таблицы текущей базы данных,
-- имена которых начинаются с фразы 'TableName'.
-- -------------------------------------------------------------------------------------- --


DROP PROCEDURE IF EXISTS drop_tables_starting_with_table_name;

CREATE OR REPLACE PROCEDURE drop_tables_starting_with_table_name()
    LANGUAGE plpgsql
AS
$$
DECLARE
    table_name text;
BEGIN
    -- Получаем список таблиц текущей базы данных
    FOR table_name IN
        SELECT tables.table_name
        FROM information_schema.tables AS tables
        WHERE tables.table_schema = current_schema() -- Текущая схема
          AND tables.table_name LIKE 'TableName%' -- Имена таблиц, начинающиеся с 'TableName'
        LOOP
            -- Формируем и выполняем запрос на удаление таблицы
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(table_name) || ' CASCADE';
        END LOOP;
END;
$$;

-- -- Тест
-- -- Вывод всех таблиц в текущей схеме
-- SELECT table_name, table_schema
-- FROM information_schema.tables
-- WHERE table_schema = current_schema();
-- -- Вызов процедуры с удалением таблиц, начинающихся с 'TableName'
-- CALL drop_tables_starting_with_table_name();
-- -- Вывод оставшихся таблиц в текущей схеме
-- SELECT table_name, table_schema
-- FROM information_schema.tables
-- WHERE table_schema = current_schema();


-- -------------------------------------------------------------------------------------- --
-- 2) Создать хранимую процедуру с выходным параметром, которая выводит список имен и параметров
-- всех скалярных SQL функций пользователя в текущей базе данных. Имена функций без параметров не выводить.
-- Имена и список параметров должны выводиться в одну строку. Выходной параметр возвращает количество найденных функций.
-- -------------------------------------------------------------------------------------- --

DROP PROCEDURE IF EXISTS get_scalar_functions_with_parameters;

CREATE OR REPLACE PROCEDURE get_scalar_functions_with_parameters(OUT function_count integer)
LANGUAGE plpgsql
AS $$
DECLARE
    function_name text;
    parameter_list text;
BEGIN
    function_count := 0; -- Инициализируем счетчик функций

    -- Получаем список функций пользователя с параметрами
    FOR function_name, parameter_list IN
        SELECT p.proname, pg_catalog.pg_get_function_arguments(p.oid)
        FROM pg_catalog.pg_proc p
        LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = current_schema() -- Текущая схема
            AND p.prorettype <> 'cstring'::pg_catalog.regtype -- Исключаем функции с возвращаемым типом cstring
            AND pg_catalog.pg_function_is_visible(p.oid)
            AND pg_catalog.pg_get_function_arguments(p.oid) <> '' -- Исключаем функции без параметров
    LOOP
        RAISE NOTICE '%(%): %', function_name, parameter_list, function_count;
        function_count := function_count + 1;
    END LOOP;
END;
$$;

-- -- Тест
-- Вызов процедуры и вывод списка функций. Вывод смотреть в консоли PostgreSQL
-- DO $$
-- DECLARE
--     function_count integer;
-- BEGIN
--     CALL get_scalar_functions_with_parameters(function_count);
--     RAISE NOTICE 'Function count: %', function_count;
-- END;
-- $$;
-- -- Ожидаемый вывод:
-- test_function_1(p_param1 integer, p_param2 text): 0
-- test_function_2(p_param1 date): 1
-- get_scalar_functions_with_parameters(OUT function_count integer): 2
-- drop_all_triggers(OUT trigger_count integer): 3
-- search_objects_by_sql_text(IN search_text text): 4
-- Function count: 5



-- -------------------------------------------------------------------------------------- --
-- 3) Создать хранимую процедуру с выходным параметром, которая уничтожает все SQL DML триггеры
-- в текущей базе данных. Выходной параметр возвращает количество уничтоженных триггеров.
-- -------------------------------------------------------------------------------------- --

DROP PROCEDURE IF EXISTS drop_all_triggers;

CREATE OR REPLACE PROCEDURE drop_all_triggers(OUT trigger_count INT)
AS
$$
DECLARE
    table_rec RECORD;
    trigger_rec RECORD;
    drop_trigger_sql TEXT;
BEGIN
    trigger_count := 0;

    -- Получаем список таблиц с триггерами в текущей базе данных
    FOR table_rec IN (
        SELECT event_object_table AS table_name
        FROM information_schema.triggers
        GROUP BY table_name
    )
    LOOP
        -- Получаем список триггеров для каждой таблицы
        FOR trigger_rec IN (
            SELECT trigger_name
            FROM information_schema.triggers
            WHERE event_object_table = table_rec.table_name
        )
        LOOP
            -- Формируем SQL-запрос для удаления триггера
            drop_trigger_sql := 'DROP TRIGGER ' || trigger_rec.trigger_name || ' ON "' || table_rec.table_name || '"';

            -- Выполняем SQL-запрос для удаления триггера
            EXECUTE drop_trigger_sql;

            -- Увеличиваем счетчик уничтоженных триггеров
            trigger_count := trigger_count + 1;
        END LOOP;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- -- Тест
-- -- Вывод всех триггеров в текущей схеме
-- SELECT  event_object_table AS table_name ,trigger_name
-- FROM information_schema.triggers
-- GROUP BY table_name, trigger_name
-- ORDER BY table_name, trigger_name;
-- -- Вызываем процедуру и получаем количество уничтоженных триггеров в переменную trigger_count
-- DO $$
-- DECLARE
--     trigger_count integer;
-- BEGIN
--     CALL drop_all_triggers(trigger_count);
--     RAISE NOTICE 'Number of dropped triggers: %', trigger_count;
-- END;
-- $$;
-- -- Триггеров в текущей схеме отсутствуют
-- SELECT  event_object_table AS table_name ,trigger_name
-- FROM information_schema.triggers
-- GROUP BY table_name, trigger_name
-- ORDER BY table_name, trigger_name;


-- -------------------------------------------------------------------------------------- --
-- 4) Создать хранимую процедуру с входным параметром, которая выводит имена и описания типа объектов
-- (только хранимых процедур и скалярных функций), в тексте которых на языке SQL встречается строка,
-- задаваемая параметром процедуры.
-- -------------------------------------------------------------------------------------- --


DROP PROCEDURE IF EXISTS search_objects_by_sql_text;

CREATE OR REPLACE PROCEDURE search_objects_by_sql_text(IN search_text text)
LANGUAGE plpgsql
AS $$
DECLARE
    object_record record;
BEGIN
    -- Поиск хранимых процедур и скалярных функций, содержащих заданный текст
    FOR object_record IN
        SELECT proname AS object_name, prokind AS object_type, pg_get_functiondef(p.oid) AS object_definition
        FROM pg_proc p
        WHERE p.prokind IN ('f', 'p') -- Только скалярные функции и хранимые процедуры
            AND pg_get_functiondef(p.oid) ILIKE '%' || search_text || '%' -- Поиск текста в определении объекта
    LOOP
        RAISE NOTICE 'Object Name: %, Object Type: %, Object Definition: %', object_record.object_name, object_record.object_type, object_record.object_definition;
    END LOOP;
END;
$$;

-- -- Тест: Поиск объектов, содержащих текст "p_param2". Вывод смотреть в консоли PostgreSQL
-- CALL search_objects_by_sql_text('p_param2');
-- -- Ожидаемый результат:
-- -- Object Name: test_function_1, Object Type: f, Object Definition: CREATE OR REPLACE FUNCTION public.test_function_1(p_param1 integer, p_param2 text)
-- -- RETURNS integer
-- -- LANGUAGE plpgsql
-- -- AS $function$
-- -- BEGIN
-- -- RETURN p_param1 + length(p_param2);
-- -- END;

-- Тест: Поиск объектов, содержащих текст "YYYY-MM-DD"
CALL search_objects_by_sql_text('YYYY-MM-DD');
-- Ожидаемый результат:
-- Object Name: test_function_2, Object Type: f, Object Definition: CREATE OR REPLACE FUNCTION public.test_function_2(p_param1 date)
-- RETURNS text
-- LANGUAGE plpgsql
-- AS $function$
-- BEGIN
-- RETURN to_char(p_param1, 'YYYY-MM-DD');
-- END;