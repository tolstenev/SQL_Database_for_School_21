-- TODO: проверить все ограничения в таблицах
-- в таблице recommendations рекомендовать можно только того, у кого был на проверке, то есть в поле peer можно добавлять записи checked_peer из transferred_points, а в recommended_peer можно добавлять только checking_peer соответствующего checked_peer
-- Таблица time_tracking. Состояние (1 - пришел, 2 - вышел). В течение одного дня должно быть одинаковое количество записей с состоянием 1 и состоянием 2 для каждого пира. Записи должны идти в чередующемся порядке 1, 2, 1, 2 и т.д.

-- Задачи:
-- добавить тестовые инсерты на проверку ограничений и триггеров
-- добавить комментарии

-- CREATE DATABASE info_21;


-- CREATE SCHEMA IF NOT EXISTS public;


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
    peer       varchar(16),
    task       varchar(32),
    date_check date,
    CONSTRAINT ch_checks_current_date CHECK (date_check <= current_date),
    CONSTRAINT fk_checks_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_checks_task FOREIGN KEY (task) REFERENCES tasks (title)
);

-- Создание типа перечисления для статуса проверки
CREATE TYPE state_of_check AS ENUM ('start', 'success', 'failure');

-- Создание таблицы p2p
CREATE TABLE p2p
(
    id            serial primary key,
    check_id      int not null,
    checking_peer varchar(16),
    state_check   state_of_check,
    time_check    timestamp,
    CONSTRAINT ch_p2p_current_time CHECK (time_check <= current_timestamp),
    CONSTRAINT fk_p2p_check_id FOREIGN KEY (check_id) REFERENCES checks (id),
    CONSTRAINT fk_p2p_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_p2p UNIQUE (check_id, state_check)
);

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

CREATE TRIGGER check_state_first_record_in_p2p
    BEFORE INSERT
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION check_state_first_record_in_p2p();

CREATE OR REPLACE FUNCTION check_time_second_record_in_p2p()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM p2p
            WHERE state_check = 'start'
              AND NEW.time_check <= time_check
        ) THEN
        RAISE EXCEPTION 'invalid time for the new p2p record';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_time_second_record_in_p2p
    BEFORE INSERT
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION check_time_second_record_in_p2p();

-- Создание таблицы verter
CREATE TABLE verter
(
    id          serial primary key,
    check_id    int,
    state_check state_of_check,
    time_check  timestamp,
    CONSTRAINT ch_verter_current_time CHECK (time_check <= current_timestamp),
    CONSTRAINT fk_verter_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

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

CREATE TRIGGER trigger_check_verter_date
    BEFORE INSERT
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_verter_date();

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

CREATE TRIGGER check_state_first_record_in_verter
    BEFORE INSERT
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_state_first_record_in_verter();

CREATE OR REPLACE FUNCTION check_time_second_record_in_verter()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM verter
            WHERE state_check = 'start'
              AND NEW.time_check <= time_check
        ) THEN
        RAISE EXCEPTION 'invalid time for the new verter table record';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_time_second_record_in_verter
    BEFORE INSERT
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_time_second_record_in_verter();

-- Создание таблицы transferred_points
CREATE TABLE transferred_points
(
    id            serial primary key,
    checking_peer varchar(16),
    checked_peer  varchar(16),
    points_amount int default 1,
    CONSTRAINT ch_range_points_amount CHECK (points_amount >= 0),
    CONSTRAINT fk_transferred_points_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT fk_transferred_points_checked_peer FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Создание таблицы friends
CREATE TABLE friends
(
    id    serial primary key,
    peer1 varchar(16),
    peer2 varchar(16),
    CONSTRAINT ch_prevent_self_friend CHECK (peer1 != peer2),
    CONSTRAINT fk_friends_peer1 FOREIGN KEY (peer1) REFERENCES peers (nickname),
    CONSTRAINT fk_friends_peer2 FOREIGN KEY (peer2) REFERENCES peers (nickname),
    CONSTRAINT unique_friends UNIQUE (peer1, peer2)
);

-- -- Проверка на запрет дублирования в таблице friends
-- INSERT INTO friends (id, peer1, peer2)
-- VALUES (6, 'manhunte', 'cherigra');
-- -- Проверка на запрет дружбы с самим собой
-- INSERT INTO friends (id, peer1, peer2)
-- VALUES (7, 'manhunte', 'manhunte');

-- Создание таблицы recommendations
CREATE TABLE recommendations
(
    id               serial primary key,
    peer             varchar(16),
    recommended_peer varchar(16),
    CONSTRAINT ch_prevent_self_recommendation CHECK (peer != recommended_peer),
    CONSTRAINT fk_recommendations_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_recommendations_recommended_peer FOREIGN KEY (recommended_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_recommendations UNIQUE (peer, recommended_peer)
);

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
        RAISE EXCEPTION 'invalid recommendation: recommended_peer must be a checking_peer of the corresponding checked_peer';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_recommendation
    BEFORE INSERT
    ON recommendations
    FOR EACH ROW
EXECUTE FUNCTION check_recommendation();

-- -- Проверка на запрет дублирования в таблице recommendations
-- INSERT INTO recommendations (id, peer, recommended_peer)
-- VALUES (6, 'cherigra', 'manhunte');
-- -- Проверка на запрет дружбы с самим recommendations
-- INSERT INTO recommendations (id, peer, recommended_peer)
-- VALUES (7, 'manhunte', 'manhunte');

-- Создание таблицы xp
CREATE TABLE xp
(
    id        serial primary key,
    check_id  int,
    xp_amount int,
    CONSTRAINT ch_xp_amount_range CHECK (xp_amount >= 0),
    CONSTRAINT fk_xp_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Создание таблицы time_tracking
CREATE TABLE time_tracking
(
    id            serial primary key,
    peer_nickname varchar(16),
    date_track          date,
    time_track          time,
    state_track         int,
    CONSTRAINT fk_time_tracking_peer_nickname FOREIGN KEY (peer_nickname) REFERENCES peers (nickname),
    CONSTRAINT ch_state_track CHECK (state_track IN (1, 2))
);

-- ТРИГГЕРЫ

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
        RAISE EXCEPTION 'maximum number of records with the same check_id reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что добавляемая запись проверки в таблицу p2p не является третьей
CREATE TRIGGER p2p_check_two_records_trigger
    BEFORE
        INSERT
        OR
        UPDATE
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
        RAISE EXCEPTION 'maximum number of records with the same check_id reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, что добавляемая запись проверки в таблицу verter не является третьей
CREATE TRIGGER verter_check_two_records_trigger
    BEFORE
        INSERT
        OR
        UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION verter_check_two_records();

-- Проверяет, что время проверки Verter'ом не раньше, чем окончание проверки P2P
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

-- Проверяет, что время проверки Verter'ом не раньше, чем окончание проверки P2P
CREATE TRIGGER check_verter_time_trigger
    BEFORE
        INSERT
        OR
        UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_verter_time();

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

-- -- Импорт данных из CSV файла
-- SELECT ImportTableFromCSV('xp', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/xp.csv');
-- SELECT ImportTableFromCSV('peers', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/peers.csv');
-- SELECT ImportTableFromCSV('tasks', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/tasks.csv');
-- SELECT ImportTableFromCSV('checks', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/checks.csv');
-- SELECT ImportTableFromCSV('p2p', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/p2p.csv');
-- SELECT ImportTableFromCSV('verter', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/verter.csv');
-- SELECT ImportTableFromCSV('transferred_points', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/transferred_points.csv');
-- SELECT ImportTableFromCSV('friends', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/friends.csv');
-- SELECT ImportTableFromCSV('recommendations', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/recommendations.csv');
-- SELECT ImportTableFromCSV('xp', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/xp.csv');
-- SELECT ImportTableFromCSV('time_tracking', ',', '/Volumes/YONNARGE_HP/docs/projects/sql/sql2/src/data/time_tracking.csv');

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
SELECT ImportTableFromCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
SELECT ImportTableFromCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
SELECT ImportTableFromCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
SELECT ImportTableFromCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
SELECT ImportTableFromCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
SELECT ImportTableFromCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
SELECT ImportTableFromCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
SELECT ImportTableFromCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
SELECT ImportTableFromCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
SELECT ImportTableFromCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');

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