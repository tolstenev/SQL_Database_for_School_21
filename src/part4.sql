DROP TABLE IF EXISTS
    "TableName1",
    "TableName2",
    "TableName3",
    "OtherTable1",
    "OtherTable2";

DROP FUNCTION IF EXISTS myfunction;
DROP FUNCTION IF EXISTS mytrigger_function;

DROP TRIGGER IF EXISTS mytrigger ON TableName1;

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
CREATE FUNCTION myfunction(param1 INT, param2 VARCHAR) RETURNS VARCHAR AS
$$
DECLARE
    result VARCHAR;
BEGIN
    -- Логика функции
    result := 'Результат: ' || param1 || ' ' || param2;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера
CREATE OR REPLACE FUNCTION mytrigger_function() RETURNS TRIGGER AS
$$
BEGIN
    -- Логика триггера
    -- Например, перед вставкой записи в таблицу TableName1
    IF NEW.name IS NULL THEN
        RAISE EXCEPTION 'Имя не может быть пустым!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mytrigger
    BEFORE INSERT
    ON "TableName1"
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

DROP PROCEDURE IF EXISTS drop_tables_starting_with;

CREATE OR REPLACE PROCEDURE drop_tables_starting_with(p_table_name_prefix text)
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
          AND tables.table_name LIKE p_table_name_prefix || '%' -- Имена таблиц, начинающиеся с переданного префикса
        LOOP
            -- Формируем и выполняем запрос на удаление таблицы
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(table_name) || ' CASCADE';
        END LOOP;
END;
$$;

-- Тест
-- Вывод всех таблиц в текущей схеме
SELECT table_name, table_schema
FROM information_schema.tables
WHERE table_schema = current_schema();
-- Вызов процедуры с удалением таблиц, начинающихся с 'TableName'
CALL drop_tables_starting_with('TableName');
-- Вывод оставшихся таблиц в текущей схеме
SELECT table_name, table_schema
FROM information_schema.tables
WHERE table_schema = current_schema();

-- -- Задача 1: Удаление таблиц с именами, начинающимися на 'TableName'
-- DROP PROCEDURE IF EXISTS DropTablesStartingWithTableName;
--
-- DELIMITER //
--
-- CREATE PROCEDURE DropTablesStartingWithTableName()
-- BEGIN
--   DECLARE done INT DEFAULT FALSE;
--   DECLARE tableName VARCHAR(255);
--   DECLARE cur CURSOR FOR
--     SELECT table_name
--     FROM information_schema.tables
--     WHERE table_schema = DATABASE() AND table_name LIKE 'TableName%';
--   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
--
--   OPEN cur;
--
--   read_loop: LOOP
--     FETCH cur INTO tableName;
--     IF done THEN
--       LEAVE read_loop;
--     END IF;
--
--     SET @dropStatement = CONCAT('DROP TABLE IF EXISTS ', tableName);
--     PREPARE stmt FROM @dropStatement;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--   END LOOP;
--
--   CLOSE cur;
-- END //
--
-- DELIMITER ;
--
-- -- Задача 2: Вывод списка имен и параметров скалярных SQL-функций
-- DROP PROCEDURE IF EXISTS GetScalarFunctions;
-- DROP TABLE IF EXISTS ScalarFunctions;
--
-- CREATE PROCEDURE GetScalarFunctions(OUT functionCount INT)
-- BEGIN
--   CREATE TABLE IF NOT EXISTS ScalarFunctions (
--     function_name VARCHAR(255),
--     parameters VARCHAR(255)
--   );
--
--   SET @count = 0;
--
--   INSERT INTO ScalarFunctions
--   SELECT
--     routine_name,
--     GROUP_CONCAT(parameter_name SEPARATOR ', ')
--   FROM information_schema.parameters
--   WHERE specific_schema = DATABASE()
--     AND routine_type = 'FUNCTION'
--     AND data_type IS NOT NULL
--   GROUP BY routine_name;
--
--   SELECT COUNT(*) INTO @count FROM ScalarFunctions;
--
--   SELECT * FROM ScalarFunctions;
--
--   SET functionCount = @count;
--
--   DROP TABLE IF EXISTS ScalarFunctions;
-- END //
--
-- -- Задача 3: Уничтожение SQL DML триггеров
-- DROP PROCEDURE IF EXISTS DropDmlTriggers;
--
-- CREATE PROCEDURE DropDmlTriggers(OUT triggerCount INT)
-- BEGIN
--   SET @count = 0;
--
--   SELECT COUNT(*) INTO @count
--   FROM information_schema.triggers
--   WHERE trigger_schema = DATABASE()
--     AND event_object_type = 'TABLE'
--     AND action_timing = 'BEFORE'
--     AND action_orientation = 'ROW';
--
--   SET @dropStatement = CONCAT(
--     'DROP TRIGGER IF EXISTS ',
--     (SELECT GROUP_CONCAT(trigger_name SEPARATOR ', ') FROM information_schema.triggers WHERE trigger_schema = DATABASE() AND event_object_type = 'TABLE' AND action_timing = 'BEFORE' AND action_orientation = 'ROW')
--   );
--
--   PREPARE stmt FROM @dropStatement;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
--
--   SET triggerCount = @count;
-- END //
--
-- -- Задача 4: Поиск объектов с заданной строкой в тексте
-- DROP PROCEDURE IF EXISTS FindObjectsWithText;
--
-- CREATE PROCEDURE FindObjectsWithText(IN searchStr VARCHAR(255))
-- BEGIN
--   SELECT
--     routine_name AS object_name,
--     routine_type AS object_type,
--     routine_definition AS object_definition
--   FROM information_schema.routines
--   WHERE routine_schema = DATABASE()
--     AND routine_definition LIKE CONCAT('%', searchStr, '%')
--     AND (routine_type = 'PROCEDURE' OR routine_type = 'FUNCTION');
-- END //
-- -- В файле part4.sql мы создаем четыре хранимые процедуры:
--
-- -- DropTablesStartingWithTableName - процедура, которая удаляет все таблицы с именами, начинающимися на 'TableName'.
--
-- -- GetScalarFunctions - процедура, которая выводит список имен и параметров всех скалярных SQL-функций в текущей базе данных.
--
-- -- DropDmlTriggers - процедура, которая уничтожает все SQL DML триггеры в текущей базе данных.
--
-- -- FindObjectsWithText - процедура, которая выводит имена и описания типов объектов (хранимых процедур и скалярных функций), в тексте которых встречается заданная строка.
--
-- -- Каждая процедура имеет соответствующие параметры ввода и/или вывода, а также использует информацию из системной таблицы information_schema для выполнения требуемых операций.
--
-- -- Пожалуйста, сохраните этот код в файл part4.sql и выполните его в вашей базе данных для создания необходимых процедур.