-- Для выполнения указанных задач, создадим файл part4.sql и внесем в него необходимые SQL-запросы.

-- Задача 1: Удаление таблиц с именами, начинающимися на 'TableName'
DROP PROCEDURE IF EXISTS DropTablesStartingWithTableName;

DELIMITER //

CREATE PROCEDURE DropTablesStartingWithTableName()
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE tableName VARCHAR(255);
  DECLARE cur CURSOR FOR
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name LIKE 'TableName%';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur;

  read_loop: LOOP
    FETCH cur INTO tableName;
    IF done THEN
      LEAVE read_loop;
    END IF;

    SET @dropStatement = CONCAT('DROP TABLE IF EXISTS ', tableName);
    PREPARE stmt FROM @dropStatement;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP;

  CLOSE cur;
END //

DELIMITER ;

-- Задача 2: Вывод списка имен и параметров скалярных SQL-функций
DROP PROCEDURE IF EXISTS GetScalarFunctions;
DROP TABLE IF EXISTS ScalarFunctions;

CREATE PROCEDURE GetScalarFunctions(OUT functionCount INT)
BEGIN
  CREATE TABLE IF NOT EXISTS ScalarFunctions (
    function_name VARCHAR(255),
    parameters VARCHAR(255)
  );

  SET @count = 0;

  INSERT INTO ScalarFunctions
  SELECT
    routine_name,
    GROUP_CONCAT(parameter_name SEPARATOR ', ')
  FROM information_schema.parameters
  WHERE specific_schema = DATABASE()
    AND routine_type = 'FUNCTION'
    AND data_type IS NOT NULL
  GROUP BY routine_name;

  SELECT COUNT(*) INTO @count FROM ScalarFunctions;

  SELECT * FROM ScalarFunctions;

  SET functionCount = @count;

  DROP TABLE IF EXISTS ScalarFunctions;
END //

-- Задача 3: Уничтожение SQL DML триггеров
DROP PROCEDURE IF EXISTS DropDmlTriggers;

CREATE PROCEDURE DropDmlTriggers(OUT triggerCount INT)
BEGIN
  SET @count = 0;

  SELECT COUNT(*) INTO @count
  FROM information_schema.triggers
  WHERE trigger_schema = DATABASE()
    AND event_object_type = 'TABLE'
    AND action_timing = 'BEFORE'
    AND action_orientation = 'ROW';

  SET @dropStatement = CONCAT(
    'DROP TRIGGER IF EXISTS ',
    (SELECT GROUP_CONCAT(trigger_name SEPARATOR ', ') FROM information_schema.triggers WHERE trigger_schema = DATABASE() AND event_object_type = 'TABLE' AND action_timing = 'BEFORE' AND action_orientation = 'ROW')
  );

  PREPARE stmt FROM @dropStatement;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET triggerCount = @count;
END //

-- Задача 4: Поиск объектов с заданной строкой в тексте
DROP PROCEDURE IF EXISTS FindObjectsWithText;

CREATE PROCEDURE FindObjectsWithText(IN searchStr VARCHAR(255))
BEGIN
  SELECT
    routine_name AS object_name,
    routine_type AS object_type,
    routine_definition AS object_definition
  FROM information_schema.routines
  WHERE routine_schema = DATABASE()
    AND routine_definition LIKE CONCAT('%', searchStr, '%')
    AND (routine_type = 'PROCEDURE' OR routine_type = 'FUNCTION');
END //
-- В файле part4.sql мы создаем четыре хранимые процедуры:

-- DropTablesStartingWithTableName - процедура, которая удаляет все таблицы с именами, начинающимися на 'TableName'.

-- GetScalarFunctions - процедура, которая выводит список имен и параметров всех скалярных SQL-функций в текущей базе данных.

-- DropDmlTriggers - процедура, которая уничтожает все SQL DML триггеры в текущей базе данных.

-- FindObjectsWithText - процедура, которая выводит имена и описания типов объектов (хранимых процедур и скалярных функций), в тексте которых встречается заданная строка.

-- Каждая процедура имеет соответствующие параметры ввода и/или вывода, а также использует информацию из системной таблицы information_schema для выполнения требуемых операций.

-- Пожалуйста, сохраните этот код в файл part4.sql и выполните его в вашей базе данных для создания необходимых процедур.