-- -------------------------------------------------------------------------------------- --
-- Чистка
-- -------------------------------------------------------------------------------------- --

DROP FUNCTION IF EXISTS check_success_p2p() CASCADE;
DROP FUNCTION IF EXISTS check_xp_amount() CASCADE;
DROP FUNCTION IF EXISTS check_success_verter() CASCADE;
DROP FUNCTION IF EXISTS add_start_p2p_check() CASCADE;
DROP FUNCTION IF EXISTS add_verter_check() CASCADE;
DROP FUNCTION IF EXISTS add_p2p_check() CASCADE;

DROP TRIGGER IF EXISTS xp_check_success_p2p ON xp;
DROP TRIGGER IF EXISTS xp_check_xp_amount_trigger ON xp;
DROP TRIGGER IF EXISTS xp_check_success_verter ON xp;
DROP TRIGGER IF EXISTS verter_check_success_p2p_trigger ON verter;
DROP TRIGGER IF EXISTS add_start_p2p_check ON p2p;

-- -------------------------------------------------------------------------------------- --
-- 1) Написать процедуру добавления P2P проверки
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION add_p2p_check(
    checked_peer  varchar(16),
    checking_peer varchar(16),
    task_title    varchar(32),
    state_check   state_of_check,
    time_check    timestamp
)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
DECLARE
    check_id_max int;
BEGIN
    -- Добавление записи в таблицу Checks
    IF state_check = 'start' THEN
        INSERT INTO checks (peer, task, date_check)
        VALUES (checked_peer, task_title, time_check::date);
    END IF;

    -- Получение максимального значения id из таблицы checks
    SELECT MAX(id) INTO check_id_max FROM checks WHERE peer = checked_peer AND task = task_title;

    -- Добавление записи в таблицу P2P
    INSERT INTO p2p (check_id, checking_peer, state_check, time_check)
    VALUES (check_id_max, checking_peer, state_check, time_check::time);

    -- Конец функции, транзакция будет автоматически завершена

EXCEPTION
    -- Обработка ошибок
    WHEN OTHERS THEN
        -- Откат транзакции
        ROLLBACK;
        -- Повторное возбуждение исключения
        RAISE;
END;
$$;

-- -------------------------------------------------------------------------------------- --
-- 2) Написать процедуру добавления проверки Verter'ом
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION add_verter_check(
    checked_peer varchar(16),
    task_title   varchar(32),
    state_check  state_of_check,
    time_check   time
) RETURNS VOID AS
$$
DECLARE
    latest_successful_p2p_check_id int;
BEGIN
    -- Получение ID последней успешной P2P проверки для задания
    SELECT MAX(id)
    INTO latest_successful_p2p_check_id
    FROM checks
    WHERE checks.task = task_title
      AND checks.peer = checked_peer;

    -- Добавление записи в таблицу Verter
    INSERT INTO verter (check_id, state_check, time_check)
    VALUES (latest_successful_p2p_check_id, state_check, time_check);

END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------------------------- --
-- 3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P,
--                      изменить соответствующую запись в таблице transferred_points
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION add_start_p2p_check() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.state_check = 'start' THEN
        INSERT INTO transferred_points (checking_peer, checked_peer)
        VALUES (NEW.checking_peer, (SELECT peer FROM checks WHERE id = NEW.check_id));
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_start_p2p_check
    BEFORE
        INSERT
        OR
        UPDATE
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION add_start_p2p_check();

-- -------------------------------------------------------------------------------------- --
-- 4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
-- -------------------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------------------- --
-- Количество XP не превышает максимальное доступное для проверяемой задачи
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION check_xp_amount() RETURNS TRIGGER AS
$$
BEGIN
    DECLARE
        max_xp_value int;
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

-- -------------------------------------------------------------------------------------- --
-- Проверяет, не превышает ли добавляемое значение xp максимально возможное для данного задания
-- перед добавлением/изменением в таблице xp
-- -------------------------------------------------------------------------------------- --

CREATE TRIGGER xp_check_xp_amount_trigger
    BEFORE
        INSERT
        OR
        UPDATE
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_xp_amount();

-- -------------------------------------------------------------------------------------- --
-- Поле Check ссылается на успешную проверку Если запись не прошла проверку, не добавлять её в таблицу.
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION check_success_p2p() RETURNS TRIGGER AS
$$
BEGIN
    -- Проверка, что можно ссылаться только на успешные P2P проверки
    IF NOT EXISTS(
            SELECT 1
            FROM checks
                     JOIN p2p ON checks.id = p2p.check_id
            WHERE checks.id = NEW.check_id
              AND p2p.state_check = 'success'
        ) THEN
        RAISE EXCEPTION 'you can only refer to successful p2p checks';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verter_check_success_p2p_trigger
    BEFORE INSERT OR UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_success_p2p();


CREATE TRIGGER xp_check_success_p2p
    BEFORE
        INSERT
        OR
        UPDATE
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_success_p2p();

-- -------------------------------------------------------------------------------------- --
-- Функция для таблицы xp, которая проверяет, что проверка Verter'ом является успешной или отсутствует:
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION check_success_verter() RETURNS TRIGGER AS
$$
DECLARE
    verter_check_success boolean;
    verter_check_exists  boolean;
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
                     AND state_check = 'success'
               )
    INTO verter_check_success;

    IF (NOT verter_check_exists AND verter_check_success) OR (verter_check_exists AND NOT verter_check_success) THEN
        RAISE EXCEPTION 'there are not successful verter check';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------------------------- --
-- Проверяет есть ли успешная проверка verter'ом задания
-- перед добавлением/изменением в таблице xp
-- -------------------------------------------------------------------------------------- --

CREATE TRIGGER xp_check_success_verter
    BEFORE
        INSERT
        OR
        UPDATE
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_success_verter();

-- -------------------------------------------------------------------------------------- --
-- Проверка
-- -------------------------------------------------------------------------------------- --

-- Проверка
SELECT add_p2p_check('rossetel', 'nyarlath', 'C2_SimpleBashUtils', 'start', '2023-08-02 10:00:00');
SELECT add_p2p_check('rossetel', 'nyarlath', 'C2_SimpleBashUtils', 'success', '2023-08-02 11:00:00');
SELECT add_verter_check('rossetel', 'C2_SimpleBashUtils', 'start', '12:00:00');
SELECT add_verter_check('rossetel', 'C2_SimpleBashUtils', 'failure', '12:00:01');

-- Fail verter
-- ERROR:  there are not successful verter check
INSERT INTO xp (check_id, xp_amount)
VALUES ((SELECT MAX(id) FROM checks WHERE peer = 'rossetel' AND task = 'C2_SimpleBashUtils'), 150);

-- Проверка
SELECT add_p2p_check('violette', 'rossetel', 'C2_SimpleBashUtils', 'start', '2023-08-02 10:00:00');
SELECT add_p2p_check('violette', 'rossetel', 'C2_SimpleBashUtils', 'success', '2023-08-02  11:00:00');
SELECT add_verter_check('violette', 'C2_SimpleBashUtils', 'start', '12:00:00');

-- Fail verter
-- ERROR:  there are not successful verter check
INSERT INTO xp (check_id, xp_amount)
VALUES ((SELECT MAX(id) FROM checks WHERE peer = 'violette' AND task = 'C2_SimpleBashUtils'), 250);

SELECT add_verter_check('violette', 'C2_SimpleBashUtils', 'success', '12:00:01');

-- Fail max xp
-- ERROR:  xp_amount exceeds max_xp
INSERT INTO xp (check_id, xp_amount)
VALUES ((SELECT MAX(id) FROM checks WHERE peer = 'violette' AND task = 'C2_SimpleBashUtils'), 550);

-- Sucсess max xp
INSERT INTO xp (check_id, xp_amount)
VALUES ((SELECT MAX(id) FROM checks WHERE peer = 'violette' AND task = 'C2_SimpleBashUtils'), 250);

-- Проверка
SELECT add_p2p_check('violette', 'rossetel', 'C3_s21_string+', 'start', '2023-08-02 11:00:00');
SELECT add_p2p_check('violette', 'rossetel', 'C3_s21_string+', 'success', '2023-08-02 11:00:10');

-- Sucсess
INSERT INTO xp (check_id, xp_amount)
VALUES ((SELECT MAX(id) FROM checks WHERE peer = 'violette' AND task = 'C3_s21_string+'), 150);

-- Проверка
SELECT add_p2p_check('nyarlath', 'violette', 'C3_s21_string+', 'start', '2023-08-03 11:01:00');
SELECT add_p2p_check('nyarlath', 'violette', 'C3_s21_string+', 'success', '2023-08-03 11:01:10');
SELECT add_verter_check('nyarlath', 'C3_s21_string+', 'start', '12:00:00');
SELECT add_verter_check('nyarlath', 'C3_s21_string+', 'failure', '12:00:01');

-- Fail verter
-- ERROR:  there are not successful verter check
INSERT INTO xp (check_id, xp_amount)
VALUES ((SELECT MAX(id) FROM checks WHERE peer = 'nyarlath' AND task = 'C3_s21_string+'), 250);

-- Проверка содержимого таблиц
SELECT *
FROM XP;

SELECT *
FROM checks;

SELECT *
FROM p2p;

SELECT *
FROM verter;

SELECT *
FROM transferred_points;