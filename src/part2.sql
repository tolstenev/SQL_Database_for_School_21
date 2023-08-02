-- 1) Написать процедуру добавления P2P проверки
-- Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время. 
-- Если задан статус "start", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю). 
-- Добавить запись в таблицу P2P. 
-- Если задан статус "start", в качестве проверки указать только что добавленную запись, иначе указать проверку с незавершенным P2P этапом.

-- Создание процедуры добавления P2P проверки

CREATE PROCEDURE add_p2p_check(
  IN checked_peer VARCHAR(16),
  IN checking_peer VARCHAR(16),
  IN task_title VARCHAR(32),
  IN state  state_of_check,
  IN time timestamp
)
DECLARE
    check_id_max INTEGER;
BEGIN
  -- Добавление записи в таблицу Checks
  IF state = 'start' THEN
    INSERT INTO checks (peer, task)
    VALUES (checked_peer, task_title);
  END IF;
  SELECT MAX(id) INTO check_id_max FROM check_id;
  -- Добавление записи в таблицу P2P
  INSERT INTO p2p (check_id, checking_peer, state, time)
  VALUES (check_id_max, checking_peer, state, time);
END;
$$ LANGUAGE plpgsql;

-- 2) Написать процедуру добавления проверки Verter'ом
-- Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время. 
-- Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего задания с самым поздним (по времени) успешным P2P этапом)

-- Ниже представлен скрипт part2.sql, который содержит процедуру AddVerterCheck для добавления проверки Verter'ом, а также тестовые запросы/вызовы для каждого пункта.

-- Создание процедуры добавления проверки Verter'ом

CREATE PROCEDURE add_verter_check(
  IN checked_peer VARCHAR(16),
  IN task_title VARCHAR(32),
  IN state  state_of_check,
  IN time timestamp
)
BEGIN
  DECLARE latestSuccessfulP2PCheckID INT;

  -- Получение ID последней успешной P2P проверки для задания
  SELECT MAX(check_id) INTO latestSuccessfulP2PCheckID
  FROM p2p
  JOIN checks ON p2p.check_id = checks.id
  WHERE checks.task = task_title AND p2p.state = 'success' AND checks.peer = checked_peer;

  -- Добавление записи в таблицу Verter
  INSERT INTO verter (check_id, state, time)
  VALUES (latestSuccessfulP2PCheckID, state, time);
END;
$$ LANGUAGE plpgsql;
-- Тестовые запросы/вызовы для каждого пункта
-- Добавление проверки Verter'ом
CALL add_verter_check('manhunte', 'C2_Simple_Bash_Utils', 'start', NOW());
CALL add_verter_check('manhunte', 'C2_Simple_Bash_Utils', 'success', NOW());


-- 3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints

CREATE OR REPLACE FUNCTION add_start_p2p_check() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.state = 'start' THEN
    INSERT INTO transferred_points (checking_peer, checked_peer)
    VALUES (NEW.checking_peer, (SELECT peer FROM checks WHERE id = NEW.check_id));
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_start_p2p_check
BEFORE
INSERT
OR
UPDATE ON p2p
FOR EACH ROW EXECUTE FUNCTION add_start_p2p_check();

-- Тестовые запросы/вызовы для каждого пункта
-- Добавление P2P проверки со статусом "start"
CALL add_p2p_check('manhunte', 'nyarlath', 'C2_Simple_Bash_Utils', 'start', NOW());
-- Добавление P2P проверки со статусом "failure"
CALL add_p2p_check('manhunte', 'nyarlath', 'C2_Simple_Bash_Utils', 'failure', NOW());

-- Проверка изменений в таблице TransferredPoints
SELECT * FROM TransferredPoints;


-- 4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
-- Запись считается корректной, если:

-- Количество XP не превышает максимальное доступное для проверяемой задачи
-- Поле Check ссылается на успешную проверку
-- Если запись не прошла проверку, не добавлять её в таблицу.

-- Проверяет есть ли успешная проверка p2p задания
-- перед добавлением/изменением в таблице xp

CREATE TRIGGER xp_check_success_p2p
BEFORE
INSERT
OR
UPDATE ON xp
FOR EACH ROW EXECUTE FUNCTION check_success_p2p();

-- Проверяет, что значение xp_amount не превышает max_xp для соответствующего задания:

CREATE OR REPLACE FUNCTION check_xp_amount() RETURNS TRIGGER AS $$
BEGIN
    DECLARE
        max_xp_value INT;
    BEGIN
        SELECT max_xp
        INTO max_xp_value
        FROM tasks
                 JOIN checks ON tasks.title = checks.task
        WHERE checks.id = NEW.check_id;

        -- Проверка, что xp_amount не превышает max_xp
        IF NEW.xp_amount > max_xp_value THEN
            RAISE EXCEPTION 'xp_amount exceeds max_xp';
        END IF;

        RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, не превышает ли добавляемое значение xp максимально возможное для данного задания
-- перед добавлением/изменением в таблице xp

CREATE TRIGGER xp_check_xp_amount_trigger
BEFORE
INSERT
OR
UPDATE ON xp
FOR EACH ROW EXECUTE FUNCTION check_xp_amount();

-- Функция для таблицы xp, которая проверяет, что проверка Verter'ом является успешной или отсутствует:

CREATE OR REPLACE FUNCTION check_success_verter() RETURNS TRIGGER AS $$
DECLARE
    verter_check_success BOOLEAN;
    verter_check_exists  BOOLEAN;
BEGIN
    SELECT EXISTS(
                   SELECT 1
                   FROM verter
                   WHERE check_id = NEW.check_id
               )
    INTO verter_check_exists;

    SELECT EXISTS(
                   SELECT 1
                   FROM verter
                   WHERE check_id = NEW.check_id
                     AND state = 'success'
               )
    INTO verter_check_success;

    IF (NOT verter_check_exists) OR verter_check_success THEN
        RAISE EXCEPTION 'there are not successful verter check';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет есть ли успешная проверка verter'ом задания
-- перед добавлением/изменением в таблице xp

CREATE TRIGGER xp_check_success_verter
BEFORE
INSERT
OR
UPDATE ON xp
FOR EACH ROW EXECUTE FUNCTION check_success_verter();

CREATE TRIGGER verter_check_success_p2p_trigger
    BEFORE
        INSERT
        OR
        UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_success_p2p();
-- Тестовые запросы/вызовы для каждого пункта

-- Добавление корректной записи в таблицу XP
INSERT INTO xp (check_id, xp_amount)
VALUES (8, 100);

-- Попытка добавления некорректной записи в таблицу XP
INSERT INTO xp (check_id, xp_amount)
VALUES (9, 200);

-- Проверка содержимого таблицы XP
SELECT * FROM XP;