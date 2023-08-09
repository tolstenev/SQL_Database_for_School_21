-- Задачи:
-- [->] добавить тестовые инсерты на проверку ограничений и триггеров
-- [->] добавить комментарии
-- подумать о триггерах на удаление

-- CREATE DATABASE info_21;


CREATE SCHEMA IF NOT EXISTS public;


DROP TABLE IF EXISTS peers,
    tasks,
    p2p,
    verter,
    checks,
    transferred_points,
    friends,
    recommendations,
    xp,
    time_tracking CASCADE;


DROP TYPE IF EXISTS state_of_check;

-- Создание типа перечисления для статуса проверки
CREATE TYPE state_of_check AS ENUM ('start', 'success', 'failure');

-- ------------------------------------ СОЗДАНИЕ ТАБЛИЦ ------------------------------------ --

-- Создание таблицы peers
CREATE TABLE peers
(
    nickname varchar(16) primary key not null,
    birthday date                    not null
);

-- Создание таблицы tasks
CREATE TABLE tasks
(
    title       varchar(32) primary key not null,
    parent_task varchar(32),
    max_xp      int                     not null,
    CONSTRAINT ch_range_max_xp CHECK (max_xp >= 0),
    CONSTRAINT fk_tasks_parent_task FOREIGN KEY (parent_task) REFERENCES tasks (title)
);

-- Создание таблицы checks
CREATE TABLE checks
(
    id         serial primary key,
    peer       varchar(16) not null,
    task       varchar(32) not null,
    date_check date        not null,
    CONSTRAINT ch_checks_current_date CHECK (date_check <= current_date),
    CONSTRAINT fk_checks_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_checks_task FOREIGN KEY (task) REFERENCES tasks (title)
);

-- Создание таблицы p2p
CREATE TABLE p2p
(
    id            serial primary key,
    check_id      int            not null,
    checking_peer varchar(16)    not null,
    state_check   state_of_check not null,
    time_check    timestamp      not null,
    CONSTRAINT ch_p2p_current_time CHECK (time_check <= current_timestamp),
    CONSTRAINT fk_p2p_check_id FOREIGN KEY (check_id) REFERENCES checks (id),
    CONSTRAINT fk_p2p_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_p2p UNIQUE (check_id, state_check)
);

-- Создание таблицы verter
CREATE TABLE verter
(
    id          serial primary key,
    check_id    int            not null,
    state_check state_of_check not null,
    time_check  timestamp      not null,
    CONSTRAINT ch_verter_current_time CHECK (time_check <= current_timestamp),
    CONSTRAINT fk_verter_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Создание таблицы transferred_points
CREATE TABLE transferred_points
(
    id            serial primary key,
    checking_peer varchar(16)   not null,
    checked_peer  varchar(16)   not null,
    points_amount int default 1 not null,
    CONSTRAINT ch_range_points_amount CHECK (points_amount >= 0),
    CONSTRAINT fk_transferred_points_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT fk_transferred_points_checked_peer FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Создание таблицы friends
CREATE TABLE friends
(
    id    serial primary key,
    peer1 varchar(16) not null,
    peer2 varchar(16) not null,
    CONSTRAINT ch_prevent_self_friend CHECK (peer1 != peer2),
    CONSTRAINT fk_friends_peer1 FOREIGN KEY (peer1) REFERENCES peers (nickname),
    CONSTRAINT fk_friends_peer2 FOREIGN KEY (peer2) REFERENCES peers (nickname),
    CONSTRAINT unique_friends UNIQUE (peer1, peer2)
);

-- Создание таблицы recommendations
CREATE TABLE recommendations
(
    id               serial primary key,
    peer             varchar(16) not null,
    recommended_peer varchar(16) not null,
    CONSTRAINT ch_prevent_self_recommendation CHECK (peer != recommended_peer),
    CONSTRAINT fk_recommendations_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_recommendations_recommended_peer FOREIGN KEY (recommended_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_recommendations UNIQUE (peer, recommended_peer)
);

-- Создание таблицы xp
CREATE TABLE xp
(
    id        serial primary key,
    check_id  int not null,
    xp_amount int not null,
    CONSTRAINT ch_xp_amount_range CHECK (xp_amount >= 0),
    CONSTRAINT fk_xp_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Создание таблицы time_tracking
CREATE TABLE time_tracking
(
    id            serial primary key,
    peer_nickname varchar(16),
    date_track    date not null,
    time_track    time not null,
    state_track   int  not null,
    CONSTRAINT fk_time_tracking_peer_nickname FOREIGN KEY (peer_nickname) REFERENCES peers (nickname),
    CONSTRAINT ch_state_track CHECK (state_track IN (1, 2)),
    CONSTRAINT ch_date_track CHECK (date_track <= CURRENT_DATE),
    CONSTRAINT ch_time_track CHECK (time_track <= CURRENT_TIME)
);


-- ------------------------------------ ФУНКЦИИ ИМПОРТА И ЭКСПОРТА ------------------------------------ --

-- Функция импорта данных из CSV файла в указанную таблицу
CREATE OR REPLACE FUNCTION ImportTableFromCSV(IN table_name TEXT, IN
    delimiter CHAR, IN file_path TEXT) RETURNS VOID
    LANGUAGE plpgsql AS
$$
BEGIN
    EXECUTE format('COPY %I FROM %L WITH (FORMAT CSV, DELIMITER %L, HEADER)', table_name, file_path, delimiter);
END;
$$;

-- Функция экспорта данных из указанной таблицы в CSV файл
CREATE OR REPLACE FUNCTION ExportTableToCSV(IN table_name TEXT, IN
    delimiter CHAR, IN file_path TEXT) RETURNS VOID
    LANGUAGE plpgsql AS
$$
BEGIN
    EXECUTE format('COPY %I TO %L WITH (FORMAT CSV, DELIMITER %L, HEADER)', table_name, file_path, delimiter);
END;
$$;

-- Импорт данных из CSV файла
SELECT ImportTableFromCSV('peers', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/peers.csv');
SELECT ImportTableFromCSV('tasks', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/tasks.csv');
SELECT ImportTableFromCSV('checks', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/checks.csv');
SELECT ImportTableFromCSV('p2p', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/p2p.csv');
SELECT ImportTableFromCSV('verter', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/verter.csv');
SELECT ImportTableFromCSV('transferred_points', ',',
                          '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/transferred_points.csv');
SELECT ImportTableFromCSV('friends', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/friends.csv');
SELECT ImportTableFromCSV('recommendations', ',',
                          '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/recommendations.csv');
SELECT ImportTableFromCSV('xp', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/xp.csv');
SELECT ImportTableFromCSV('time_tracking', ',',
                          '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/time_tracking.csv');

-- -- Экспорт данных в CSV файл
-- SELECT ExportTableToCSV('peers', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/peers.csv');
-- SELECT ExportTableToCSV('tasks', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/tasks.csv');
-- SELECT ExportTableToCSV('checks', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/checks.csv');
-- SELECT ExportTableToCSV('p2p', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/p2p.csv');
-- SELECT ExportTableToCSV('verter', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/verter.csv');
-- SELECT ExportTableToCSV('transferred_points', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/transferred_points.csv');
-- SELECT ExportTableToCSV('friends', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/friends.csv');
-- SELECT ExportTableToCSV('recommendations', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/recommendations.csv');
-- SELECT ExportTableToCSV('xp', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/xp.csv');
-- SELECT ExportTableToCSV('time_tracking', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/time_tracking.csv');

-- -- Импорт данных из CSV файла
-- SELECT ImportTableFromCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
-- SELECT ImportTableFromCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
-- SELECT ImportTableFromCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
-- SELECT ImportTableFromCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
-- SELECT ImportTableFromCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
-- SELECT ImportTableFromCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
-- SELECT ImportTableFromCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
-- SELECT ImportTableFromCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
-- SELECT ImportTableFromCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
-- SELECT ImportTableFromCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');

-- -- Экспорт данных в CSV файл
-- SELECT ExportTableToCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
-- SELECT ExportTableToCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
-- SELECT ExportTableToCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
-- SELECT ExportTableToCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
-- SELECT ExportTableToCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
-- SELECT ExportTableToCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
-- SELECT ExportTableToCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
-- SELECT ExportTableToCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
-- SELECT ExportTableToCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
-- SELECT ExportTableToCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');

-- ------------------------------------ ТРИГГЕРЫ ------------------------------------ --

-- Проверяет, что parent_task не может быть null (кроме "Pool")
CREATE OR REPLACE FUNCTION check_parent_task()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.title != 'Pool' AND NEW.parent_task IS NULL THEN
        RAISE EXCEPTION 'parent_task must be not null';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что parent_task не может быть null (кроме "Pool")
CREATE TRIGGER trigger_check_parent_task
    BEFORE INSERT OR UPDATE
    ON tasks
    FOR EACH ROW
EXECUTE FUNCTION check_parent_task();

-- Тест: parent_task не может быть null
-- Ожидается ERROR: parent_task must be not null
-- INSERT INTO tasks (title, max_xp)
-- VALUES ('Intra', 100500);

-- Проверяет, что добавляемая в p2p проверка имеет такую же дату, что и в checks
CREATE OR REPLACE FUNCTION check_date_p2p()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NOT EXISTS(
            SELECT 1
            FROM checks
            WHERE id = NEW.check_id
              AND date_check = NEW.time_check::date
        ) THEN
        RAISE EXCEPTION 'new record in p2p must have the same date in checks';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что добавляемая в p2p проверка имеет такую же дату, что и в checks
CREATE TRIGGER trigger_check_date_p2p
    BEFORE INSERT OR UPDATE
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION check_date_p2p();

-- Тест: добавляемая в p2p проверка имеет дату, отличающуюся от checks
-- Ожидание ERROR: new record in check must have the same date in p2p
-- INSERT INTO checks (id, peer, task, date_check)
-- VALUES (6, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-02');
-- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- VALUES (11, 6, 'tamelabe', 'start', '2023-07-03 22:30:00.000000');

-- Проверяет, что первая запись в p2p для соответствующей проверки должна иметь статус 'start'
CREATE OR REPLACE FUNCTION check_state_first_record_in_p2p()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NOT EXISTS(
            SELECT 1
            FROM p2p
            WHERE check_id = NEW.check_id
        ) THEN
        IF NEW.state_check != 'start' THEN
            RAISE EXCEPTION 'only records with state "start" are allowed when check_id does not exist in p2p table';
        END IF;
    END IF;

    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

-- Проверяет, что первая запись в p2p для соответствующей проверки должна иметь статус 'start'
CREATE TRIGGER check_state_first_record_in_p2p
    BEFORE INSERT
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION check_state_first_record_in_p2p();

-- Тест на первую запись не со статусом 'start' в p2p
-- Ожидается ERROR: only records with state "start" are allowed when check_id does not exist in p2p table
-- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- VALUES (11, 6, 'tamelabe', 'failure', '2023-07-05 22:30:00.000000');

-- Проверяет, что добавляемая в p2p запись не раньше чем запись start для соответствующей проверки
CREATE OR REPLACE FUNCTION check_time_second_record_in_p2p()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM p2p
            WHERE state_check = 'start'
              AND check_id = NEW.check_id
              AND NEW.time_check <= time_check
        ) THEN
        RAISE EXCEPTION 'time_check for the new p2p record should be after start record';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что добавляемая в p2p запись не раньше чем запись start для соответствующей проверки
CREATE TRIGGER trigger_check_time_second_record_in_p2p
    BEFORE INSERT
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION check_time_second_record_in_p2p();

-- Тест, что добавляемая в p2p запись не раньше чем запись start для соответствующей проверки
-- INSERT INTO checks (id, peer, task, date_check)
-- VALUES (6, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-02');
-- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- VALUES (11, 6, 'tamelabe', 'start', '2023-07-02 22:30:00.000000');
-- Ожидается ERROR: time_check for the new p2p record should be after start record
-- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- VALUES (12, 6, 'tamelabe', 'failure', '2023-07-02 10:30:00.000000');


-- Проверяет, что verter проверяет в тот же день, что и p2p
CREATE OR REPLACE FUNCTION check_verter_date()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM checks
            WHERE id = NEW.check_id
              AND date_check != NEW.time_check::date
        ) THEN
        RAISE EXCEPTION 'the record must have the same date in checks table';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что проверка verter'ом проходит в тот же день, что и p2p
CREATE TRIGGER trigger_check_verter_date
    BEFORE INSERT
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_verter_date();

-- Тест, что проверка verter'ом проходит в тот же день, что и p2p
-- Ожидается ERROR: the record must have the same date in checks table
-- INSERT INTO verter (id, check_id, state_check, time_check)
-- VALUES (7, 6, 'start', '2023-07-05 22:45:00.000000');


-- Проверяет, что первая запись в verter имеет статус 'start'
CREATE OR REPLACE FUNCTION check_state_first_record_in_verter()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NOT EXISTS(
            SELECT 1
            FROM verter
            WHERE check_id = NEW.check_id
        ) THEN
        IF NEW.state_check != 'start' THEN
            RAISE EXCEPTION 'only records with state "start" are allowed when check_id does not exist in verter table';
        END IF;
    END IF;

    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

-- Проверяет, что первая запись в verter имеет статус 'start'
CREATE TRIGGER check_state_first_record_in_verter
    BEFORE INSERT
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_state_first_record_in_verter();

-- Тест, что первая запись в verter не имеет статус 'start'
-- INSERT INTO verter (id, check_id, state_check, time_check)
-- VALUES (7, 6, 'failure', '2023-07-02 22:45:00.000000');

-- Проверяет, что время проверки verter'ом не раньше, чем окончание проверки p2p
CREATE OR REPLACE FUNCTION check_verter_time() RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
        -- Запрашиваем только одну строку с единственным значением 1.
        -- Это делается для оптимизации запроса, поскольку нам не нужны фактические данные из таблицы,
        -- нам нужно только узнать, есть ли хотя бы одна запись, удовлетворяющая условию.
            SELECT 1
            FROM p2p
            WHERE p2p.check_id = NEW.check_id
              AND p2p.time_check > NEW.time_check
        ) THEN
        RAISE EXCEPTION 'verter checking time cannot be earlier than p2p checking time';
    END IF;

    RETURN NEW;
END ;
$$ LANGUAGE plpgsql;

-- Проверяет, что время проверки verter'ом не раньше, чем окончание проверки p2p
CREATE TRIGGER check_verter_time_trigger
    BEFORE
        INSERT
        OR
        UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_verter_time();

-- Тест, что время проверки verter'ом не раньше, чем окончание проверки p2p
-- INSERT INTO verter (id, check_id, state_check, time_check)
-- VALUES (7, 6, 'start', '2023-07-02 22:45:00.000000');

-- Тест, что добавляемая в verter запись не раньше чем запись start для соответствующей проверки
CREATE OR REPLACE FUNCTION check_time_second_record_in_verter()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT time_check
            FROM verter
            WHERE state_check = 'start'
              AND NEW.check_id = check_id
              AND NEW.time_check <= time_check
        ) THEN
        RAISE EXCEPTION 'time_check for the new verter record should be after start record';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Тест, что добавляемая в verter запись не раньше чем запись start для соответствующей проверки
CREATE TRIGGER trigger_check_time_second_record_in_verter
    BEFORE INSERT
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_time_second_record_in_verter();

-- Тест, что добавляемая в verter запись не раньше чем запись start для соответствующей проверки
-- -- Если не было выполнено ранее, выполнить:
-- -- INSERT INTO checks (id, peer, task, date_check)
-- -- VALUES (6, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-02');
-- -- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- -- VALUES (11, 6, 'tamelabe', 'start', '2023-07-02 22:30:00.000000');
-- Тест:
-- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- VALUES (12, 6, 'tamelabe', 'success', '2023-07-02 22:40:00.000000');
-- INSERT INTO verter (id, check_id, state_check, time_check)
-- VALUES (7, 6, 'start', '2023-07-02 22:45:00.000000');
-- Ожидается ERROR: time_check for the new verter record should be after start record
-- INSERT INTO verter (id, check_id, state_check, time_check)
-- VALUES (8, 6, 'failure', '2023-07-02 22:42:00.000000');


-- Проверяет, что рекомендуемый пир проводил проверку рекомендующего
CREATE OR REPLACE FUNCTION check_recommendation()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM transferred_points
            WHERE checked_peer = NEW.peer
              AND checking_peer = NEW.recommended_peer
        ) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'recommended_peer must be a checking_peer of the corresponding checked_peer';
    END IF;
END ;
$$ LANGUAGE plpgsql;

-- Проверяет, что рекомендуемый пир проводил проверку рекомендующего
CREATE TRIGGER trigger_check_recommendation
    BEFORE INSERT
    ON recommendations
    FOR EACH ROW
EXECUTE FUNCTION check_recommendation();

-- Тест: рекомендуемый пир не проводил проверку рекомендующего
-- INSERT INTO recommendations (id, peer, recommended_peer)
-- VALUES (6, 'manhunte', 'cherigra');

-- Проверяет корректность записей в time_tracking
CREATE OR REPLACE FUNCTION check_time_tracking()
    RETURNS TRIGGER AS
$$
DECLARE
    count_state_1 integer;
    count_state_2 integer;
BEGIN
    SELECT COUNT(*)
    INTO count_state_1
    FROM time_tracking
    WHERE peer_nickname = NEW.peer_nickname
      AND date_track = NEW.date_track
      AND state_track = 1;

    SELECT COUNT(*)
    INTO count_state_2
    FROM time_tracking
    WHERE peer_nickname = NEW.peer_nickname
      AND date_track = NEW.date_track
      AND state_track = 2;

    IF count_state_1 != count_state_2 THEN
        RAISE EXCEPTION 'in time_tracking the number of state 1 and state 2 entries must be equal for each peer and date';
    END IF;

    IF count_state_1 = count_state_2 THEN
        IF (SELECT state_track
            FROM time_tracking
            WHERE peer_nickname = NEW.peer_nickname
              AND date_track = NEW.date_track
            ORDER BY time_track DESC
            LIMIT 1) = 1 THEN
            IF NEW.state_track = 1 THEN
                RAISE EXCEPTION 'state 2 entry is missing before state 1 entry in time_tracking';
            END IF;
        ELSE
            IF NEW.state_track = 2 THEN
                RAISE EXCEPTION 'state 1 entry is missing before state 2 entry in time_tracking';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет корректность записей в time_tracking
CREATE TRIGGER trigger_check_time_tracking
    BEFORE INSERT
    ON time_tracking
    FOR EACH ROW
EXECUTE FUNCTION check_time_tracking();

-- Тест: добавление записи со статусом входа без выхода
-- Ожидается ERROR: state 2 entry is missing before state 1 entry in time_tracking
-- INSERT INTO time_tracking (id, peer_nickname, date_track, time_track, state_track)
-- VALUES (7, 'tamelabe', '2023-07-02', '10:00:00', 1);
-- INSERT INTO time_tracking (id, peer_nickname, date_track, time_track, state_track)
-- VALUES (8, 'tamelabe', '2023-07-02', '11:00:00', 1);

-- Тест: добавление записи со статусом выхода без входа (первая запись за день)
-- -- Ожидается ERROR: state 1 entry is missing before state 2 entry in time_tracking
-- INSERT INTO time_tracking (id, peer_nickname, date_track, time_track, state_track)
-- VALUES (8, 'tamelabe', '2023-07-02', '19:00:00', 2);

-- -- Тест: добавление записи со статусом выхода без входа (не первая запись за день)
-- -- Ожидается ERROR: state 1 entry is missing before state 2 entry in time_tracking
-- INSERT INTO time_tracking (id, peer_nickname, date_track, time_track, state_track)
-- VALUES (8, 'tamelabe', '2023-07-01', '19:00:00', 2);

-- Проверяет на завершение родительского таска для добавляемой записи проверки в таблицу check
CREATE OR REPLACE FUNCTION check_parent_task_in_xp() RETURNS trigger AS
$$
BEGIN
    IF (SELECT parent_task
        FROM tasks
        WHERE tasks.title = NEW.task
          AND parent_task IS NOT NULL) IS NOT NULL THEN
        -- Проверяем наличие записи в тpаблице xp по parent_task
        IF NOT EXISTS(SELECT 1
                      FROM xp
                               JOIN checks ON xp.check_id = checks.id
                      WHERE checks.peer = NEW.peer
                        AND checks.task IN (SELECT parent_task
                                            FROM tasks
                                            WHERE tasks.title = NEW.task)) THEN
            RAISE EXCEPTION 'parent task is not completed';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет на завершение родительского таска для добавляемой записи проверки в таблицу check
CREATE TRIGGER check_xp_completed_trigger
    AFTER INSERT OR UPDATE
    ON checks
    FOR EACH ROW
EXECUTE FUNCTION check_parent_task_in_xp();

-- Тест: родительский таск для добавляемой записи в checks не выполнен
-- Ожидается ERROR: parent task is not completed
-- INSERT INTO checks (id, peer, task, date_check)
-- VALUES (7, 'manhunte', 'C3_s21_stringplus', '2023-07-02');


-- Проверяет, что добавляемая запись проверки в таблицу p2p не является третьей
CREATE OR REPLACE FUNCTION p2p_check_two_records() RETURNS TRIGGER AS
$$
DECLARE
    count_records INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO count_records
    FROM p2p
    WHERE check_id = NEW.check_id;

    IF count_records >= 2 THEN
        RAISE EXCEPTION 'maximum number of records with the same check_id in p2p reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Тест: попытка добавить третью запись для проверки в таблицу p2p
-- -- Если не было выполнено ранее, выполнить:
-- -- INSERT INTO checks (id, peer, task, date_check)
-- -- VALUES (6, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-02');
-- -- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- -- VALUES (11, 6, 'tamelabe', 'start', '2023-07-02 22:30:00.000000');
-- -- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- -- VALUES (12, 6, 'tamelabe', 'success', '2023-07-02 22:40:00.000000');
-- Ожидается ERROR: maximum number of records with the same check_id reached
-- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- VALUES (13, 6, 'tamelabe', 'failure', '2023-07-05 22:50:00.000000');

-- Проверяет, что добавляемая запись проверки в таблицу p2p не является третьей
CREATE TRIGGER p2p_check_two_records_trigger
    BEFORE INSERT OR UPDATE
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION p2p_check_two_records();

-- Проверяет, что добавляемая запись проверки в таблицу verter не является третьей
CREATE OR REPLACE FUNCTION verter_check_two_records() RETURNS TRIGGER AS
$$
DECLARE
    count_records INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO count_records
    FROM verter
    WHERE check_id = NEW.check_id;

    IF count_records >= 2 THEN
        RAISE EXCEPTION 'maximum number of records with the same check_id in verter reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что добавляемая запись проверки в таблицу verter не является третьей
CREATE TRIGGER verter_check_two_records_trigger
    BEFORE INSERT OR UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION verter_check_two_records();

-- Тест: попытка добавить третью запись для проверки в таблицу verter
-- -- Если не было выполнено ранее, выполнить:
-- -- INSERT INTO checks (id, peer, task, date_check)
-- -- VALUES (6, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-02');
-- -- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- -- VALUES (11, 6, 'tamelabe', 'start', '2023-07-02 22:30:00.000000');
-- -- INSERT INTO p2p (id, check_id, checking_peer, state_check, time_check)
-- -- VALUES (12, 6, 'tamelabe', 'success', '2023-07-02 22:40:00.000000');
-- -- INSERT INTO verter (id, check_id, state_check, time_check)
-- -- VALUES (7, 6, 'start', '2023-07-02 22:45:00.000000');
-- -- INSERT INTO verter (id, check_id, state_check, time_check)
-- -- VALUES (8, 6, 'success', '2023-07-02 22:46:00.000000');
-- Ожидается ERROR: maximum number of records with the same check_id reached
-- INSERT INTO verter (id, check_id, state_check, time_check)
-- VALUES (8, 5, 'failure', '2023-07-05 22:47:00.000000');
