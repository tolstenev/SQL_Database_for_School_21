-- -------------------------------------------------------------------------------------- --
-- Чистка
-- -------------------------------------------------------------------------------------- --

-- DROP TRIGGER IF EXISTS xp_check_success_p2p ON xp;
-- DROP TRIGGER IF EXISTS xp_check_xp_amount_trigger ON xp;
-- DROP TRIGGER IF EXISTS xp_check_success_verter ON xp;
-- DROP TRIGGER IF EXISTS verter_check_success_p2p_trigger ON verter;
-- DROP TRIGGER IF EXISTS add_start_p2p_check ON p2p;

-- DROP FUNCTION IF EXISTS check_success_p2p();
-- DROP FUNCTION IF EXISTS check_xp_amount();
-- DROP FUNCTION IF EXISTS check_success_verter();
-- DROP FUNCTION IF EXISTS add_start_p2p_check();
-- DROP FUNCTION IF EXISTS add_verter_check();
-- DROP FUNCTION IF EXISTS add_p2p_check();

-- -------------------------------------------------------------------------------------- --
-- 1) Написать процедуру добавления P2P проверки
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION add_p2p_check(
    checked_peer VARCHAR(16),
    checking_peer VARCHAR(16),
    task_title VARCHAR(32),
    state_check state_of_check,
    time_check timestamp
)
RETURNS VOID
LANGUAGE plpgsql
AS
$$
DECLARE check_id_max INTEGER;
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
	VALUES (check_id_max, checking_peer, state_check, time_check);

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

CREATE  OR REPLACE FUNCTION add_verter_check(
    checked_peer VARCHAR(16),
    task_title VARCHAR(32),
    state_check state_of_check,
    time_check timestamp
) RETURNS VOID AS
$$
DECLARE
    latestSuccessfulP2PCheckID INT;
BEGIN
    -- Получение ID последней успешной P2P проверки для задания
    SELECT MAX(id)
    INTO latestSuccessfulP2PCheckID
    FROM checks
    WHERE checks.task = task_title
      AND checks.peer = checked_peer;

    -- Добавление записи в таблицу Verter
    INSERT INTO verter (check_id, state_check, time_check)
    VALUES (latestSuccessfulP2PCheckID, state_check, time_check);

END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------------------------- --
-- 3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints
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

-- -------------------------------------------------------------------------------------- --
-- Поле Check ссылается на успешную проверку Если запись не прошла проверку, не добавлять её в таблицу.
-- -------------------------------------------------------------------------------------- --

CREATE OR REPLACE FUNCTION check_success_p2p()
    RETURNS TRIGGER AS
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
UPDATE ON xp
FOR EACH ROW EXECUTE FUNCTION check_success_p2p();



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
                     AND state_check = 'success'
               )
    INTO verter_check_success;

    IF (NOT verter_check_exists AND verter_check_success) OR (verter_check_exists AND NOT verter_check_success) THEN
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

-- -------------------------------------------------------------------------------------- --
-- Проверка
-- -------------------------------------------------------------------------------------- --

-- Шестая проверка
SELECT add_p2p_check('manhunte', 'nyarlath', 'C2_Simple_Bash_Utils', 'start', '2023-08-02');
SELECT add_p2p_check('manhunte', 'nyarlath', 'C2_Simple_Bash_Utils', 'success', '2023-08-02 11:00:00');
SELECT add_verter_check('manhunte', 'C2_Simple_Bash_Utils', 'start', '2023-08-02 12:00:00');
SELECT add_verter_check('manhunte', 'C2_Simple_Bash_Utils', 'failure', '2023-08-02 12:00:01');

-- Fail verter
INSERT INTO xp (check_id, xp_amount)
VALUES (6, 150);

-- Седьмая проверка
SELECT add_p2p_check('nyarlath', 'pollare', 'C2_Simple_Bash_Utils', 'start', '2023-08-02');
SELECT add_p2p_check('nyarlath', 'pollare', 'C2_Simple_Bash_Utils', 'success', '2023-08-02  11:00:00');
SELECT add_verter_check('nyarlath', 'C2_Simple_Bash_Utils', 'start', '2023-08-02 12:00:00');
SELECT add_verter_check('nyarlath', 'C2_Simple_Bash_Utils', 'success', '2023-08-02 12:00:01');

-- Fail max xp
INSERT INTO xp (check_id, xp_amount)
VALUES (7, 550);

-- Sucess max xp
INSERT INTO xp (check_id, xp_amount)
VALUES (7, 250);

-- Восьмая проверка
SELECT add_p2p_check('pollare', 'manhunte', 'Pool', 'start', '2023-08-02 11:00:00');
SELECT add_p2p_check('pollare', 'manhunte', 'Pool', 'success', '2023-08-02 11:00:10');

-- Sucess
INSERT INTO xp (check_id, xp_amount)
VALUES (8, 150);

-- Девятая проверка
SELECT add_p2p_check('pollare', 'manhunte', 'C2_Simple_Bash_Utils', 'start', '2023-08-02 11:01:00');
SELECT add_p2p_check('pollare', 'manhunte', 'C2_Simple_Bash_Utils', 'success', '2023-08-02 11:01:10');
SELECT add_verter_check('pollare', 'C2_Simple_Bash_Utils', 'start', '2023-08-02 12:00:00');
SELECT add_verter_check('pollare', 'C2_Simple_Bash_Utils', 'failure', '2023-08-02 12:00:01');

-- Fail verter
INSERT INTO xp (check_id, xp_amount)
VALUES (9, 250);

-- Проверка содержимого таблиц
SELECT * FROM XP;

SELECT * FROM checks;

SELECT * FROM p2p;

SELECT * FROM verter;

SELECT * FROM transferred_points;